#!/usr/bin/env bash
# ============================================================================
# jsdotfiles installer — symlinks tracked dotfiles into $HOME.
#
#   ./install.sh          symlink dotfiles (backs up anything in the way)
#   ./install.sh --omz    also install oh-my-zsh + powerlevel10k + plugins
#   ./install.sh --help
#
# Safe to re-run (idempotent). Existing real files are moved to *.backup.<ts>.
# ============================================================================
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
TS="$(date +%Y%m%d%H%M%S)"

info() { printf '\033[0;34m›\033[0m %s\n' "$*"; }
ok()   { printf '\033[0;32m✓\033[0m %s\n' "$*"; }
warn() { printf '\033[0;33m!\033[0m %s\n' "$*"; }

# link <repo-relative-src> <absolute-dest>
link() {
  local src="$DOTFILES/$1" dest="$2"
  if [ ! -e "$src" ]; then warn "missing in repo, skipping: $1"; return; fi
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ]; then
    rm "$dest"
  elif [ -e "$dest" ]; then
    mv "$dest" "$dest.backup.$TS"
    warn "backed up existing $dest -> $dest.backup.$TS"
  fi
  ln -s "$src" "$dest"
  ok "$dest -> $src"
}

# copy <repo-relative-src> <absolute-dest>
# Like link(), but writes a real file. Needed for paths that sandboxed apps must
# read (e.g. ~/Library/KeyBindings) — a symlink out to the repo gets blocked by
# the app sandbox. Trade-off: edits to the repo file need a re-run of install.sh.
copy() {
  local src="$DOTFILES/$1" dest="$2"
  if [ ! -e "$src" ]; then warn "missing in repo, skipping: $1"; return; fi
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ]; then
    rm "$dest"
  elif [ -e "$dest" ]; then
    mv "$dest" "$dest.backup.$TS"
    warn "backed up existing $dest -> $dest.backup.$TS"
  fi
  cp "$src" "$dest"
  ok "$dest (copy of $src)"
}

install_symlinks() {
  info "Linking dotfiles from $DOTFILES"
  link shell/zshrc        "$HOME/.zshrc"
  link shell/zprofile     "$HOME/.zprofile"
  link shell/bashrc       "$HOME/.bashrc"
  link shell/aliases.zsh  "$HOME/.aliases.zsh"
  link shell/env.zsh      "$HOME/.env.zsh"
  link shell/path.zsh     "$HOME/.path.zsh"
  link shell/fzf.zsh      "$HOME/.fzf.zsh"
  link shell/fzf.bash     "$HOME/.fzf.bash"
  link git/gitconfig      "$HOME/.gitconfig"
  link vim/vimrc          "$HOME/.vimrc"
  link tmux/tmux.conf     "$HOME/.tmux.conf"
  link zellij/config.kdl  "$HOME/.config/zellij/config.kdl"
  link p10k/p10k.zsh      "$HOME/.p10k.zsh"

  # macOS-only: Cocoa key bindings. COPIED, not symlinked — sandboxed apps
  # (Notes, Mail, …) can't follow a symlink out to the repo.
  if [ "$OS" = "Darwin" ]; then
    copy macos/DefaultKeyBinding.dict "$HOME/Library/KeyBindings/DefaultKeyBinding.dict"
  fi

  # Secrets: never symlinked. Seed from template if absent.
  if [ ! -f "$HOME/.secrets.zsh" ]; then
    cp "$DOTFILES/shell/secrets.zsh.example" "$HOME/.secrets.zsh"
    chmod 600 "$HOME/.secrets.zsh"
    warn "created ~/.secrets.zsh from template — fill in your real values"
  fi
}

install_omz() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing oh-my-zsh"
    RUNZSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
  local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  clone() { [ -d "$2" ] || git clone --depth=1 "$1" "$2"; }
  info "Installing powerlevel10k + plugins"
  clone https://github.com/romkatv/powerlevel10k.git           "$custom/themes/powerlevel10k"
  clone https://github.com/zsh-users/zsh-autosuggestions       "$custom/plugins/zsh-autosuggestions"
  clone https://github.com/zsh-users/zsh-syntax-highlighting   "$custom/plugins/zsh-syntax-highlighting"
  clone https://github.com/MichaelAquilina/zsh-you-should-use  "$custom/plugins/you-should-use"
  ok "oh-my-zsh stack ready"
}

main() {
  local do_omz=0
  for arg in "$@"; do
    case "$arg" in
      --omz)  do_omz=1 ;;
      --help|-h)
        sed -n '2,12p' "$0"; exit 0 ;;
      *) warn "unknown arg: $arg" ;;
    esac
  done

  install_symlinks
  [ "$do_omz" -eq 1 ] && install_omz

  echo
  ok "Done. Next steps:"
  echo "   1. Edit ~/.secrets.zsh with your real tokens (if you use them)."
  echo "   2. Start a new shell:  exec zsh -l   (or 'reload')"
  [ "$do_omz" -eq 0 ] && echo "   3. First time on this box? run: ./install.sh --omz"
  [ "$OS" = "Darwin" ] && echo "   4. macOS: see README for iTerm2 (Right Option = Esc+) & IntelliJ keymap."
}

main "$@"
