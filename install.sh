#!/usr/bin/env bash
# ============================================================================
# jsdotfiles installer — symlinks tracked dotfiles into $HOME, and (optionally)
# installs the CLI tools the dotfiles expect.
#
#   ./install.sh              symlink dotfiles + report any missing tools
#   ./install.sh --link-only  symlink dotfiles only (skip the tool check)
#   ./install.sh --tools      also install missing tools (zsh, fzf, zoxide,
#                             zellij, vim, tmux, git) via the system package
#                             manager, then set zsh as the login shell
#   ./install.sh --omz        also install oh-my-zsh + powerlevel10k + plugins
#   ./install.sh --help
#
# Flags combine — a fresh box is usually:  ./install.sh --tools --omz
# Safe to re-run (idempotent). Existing real files are moved to *.backup.<ts>.
# Linux installs use apt (with sudo) and fall back to upstream installers when
# a package is missing or too old; non-apt distros get manual hints instead.
# ============================================================================
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"
TS="$(date +%Y%m%d%H%M%S)"

info() { printf '\033[0;34m›\033[0m %s\n' "$*"; }
ok()   { printf '\033[0;32m✓\033[0m %s\n' "$*"; }
warn() { printf '\033[0;33m!\033[0m %s\n' "$*"; }

# Use sudo only when we're not root and it's available.
SUDO=""
if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then SUDO="sudo"; fi

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

# ---------------------------------------------------------------------------
# Tools the dotfiles expect, one row per tool:
#   binary | apt package | brew formula | linux fallback fn
# The fallback runs on apt-based systems when apt has no usable package
# (zellij isn't packaged; fzf/zoxide are often too old). ~/.local/bin is
# already on PATH (see shell/path.zsh), so that's where fallbacks land.
# ---------------------------------------------------------------------------
TOOLS="\
zsh|zsh|zsh|
git|git|git|
vim|vim|vim|
tmux|tmux|tmux|
fzf|fzf|fzf|fallback_fzf
zoxide|zoxide|zoxide|fallback_zoxide
zellij||zellij|fallback_zellij
"

APT_UPDATED=0
apt_install() {
  if [ "$APT_UPDATED" -eq 0 ]; then $SUDO apt-get update -qq && APT_UPDATED=1; fi
  $SUDO apt-get install -y "$1"
}

fallback_fzf() {
  info "Installing fzf from upstream (apt package unavailable/too old)"
  [ -d "$HOME/.fzf" ] || git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  "$HOME/.fzf/install" --bin
  mkdir -p "$HOME/.local/bin"
  ln -sf "$HOME/.fzf/bin/fzf" "$HOME/.local/bin/fzf"
}

fallback_zoxide() {
  info "Installing zoxide from upstream (apt package unavailable/too old)"
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
}

fallback_zellij() {
  info "Installing zellij from upstream release (not packaged in apt)"
  local arch target
  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64)  target="x86_64-unknown-linux-musl" ;;
    aarch64|arm64) target="aarch64-unknown-linux-musl" ;;
    *) warn "no zellij prebuilt binary for arch '$arch' — install it manually"; return 0 ;;
  esac
  mkdir -p "$HOME/.local/bin"
  local tmp; tmp="$(mktemp -d)"
  curl -sSfL "https://github.com/zellij-org/zellij/releases/latest/download/zellij-${target}.tar.gz" \
    | tar -xz -C "$tmp"
  mv "$tmp/zellij" "$HOME/.local/bin/zellij"
  chmod +x "$HOME/.local/bin/zellij"
  rm -rf "$tmp"
}

install_hint() {
  local apt="$1" brew="$2"
  if [ "$OS" = "Darwin" ]; then
    [ -n "$brew" ] && printf 'brew install %s' "$brew" || printf 'see upstream docs'
  elif [ -n "$apt" ]; then
    printf 'sudo apt install %s' "$apt"
  else
    printf 'see upstream docs'
  fi
}

check_tools() {
  info "Checking tools the dotfiles expect"
  local bin apt brew fb missing=0
  while IFS='|' read -r bin apt brew fb; do
    [ -z "$bin" ] && continue
    if command -v "$bin" >/dev/null 2>&1; then
      ok "$bin"
    else
      missing=1
      warn "$bin missing  —  $(install_hint "$apt" "$brew")"
    fi
  done <<EOF
$TOOLS
EOF
  if [ "$missing" -eq 1 ]; then
    info "Install the missing ones automatically with:  ./install.sh --tools"
  else
    ok "all expected tools present"
  fi
}

install_one_tool() {
  local bin="$1" apt="$2" brew="$3" fb="$4"
  if command -v "$bin" >/dev/null 2>&1; then ok "$bin already installed"; return; fi
  info "Installing $bin"
  if [ "$OS" = "Darwin" ]; then
    if [ -n "$brew" ] && command -v brew >/dev/null 2>&1; then
      brew install "$brew" || warn "brew install $brew failed"
    elif [ -n "$fb" ]; then
      "$fb" || warn "$bin fallback install failed"
    else
      warn "cannot auto-install $bin on macOS — install Homebrew first"
    fi
  else
    if command -v apt-get >/dev/null 2>&1 && [ -n "$apt" ]; then
      apt_install "$apt" || warn "apt couldn't install $apt — trying fallback"
    fi
    if ! command -v "$bin" >/dev/null 2>&1 && [ -n "$fb" ]; then
      "$fb" || warn "$bin fallback install failed"
    fi
  fi
  if command -v "$bin" >/dev/null 2>&1; then
    ok "$bin installed"
  else
    warn "$bin still not on PATH (a fresh shell may be needed)"
  fi
}

set_default_shell() {
  command -v zsh >/dev/null 2>&1 || { warn "zsh not installed — skipping chsh"; return; }
  case "${SHELL:-}" in
    *zsh) ok "login shell already zsh"; return ;;
  esac
  local zsh_path; zsh_path="$(command -v zsh)"
  # zsh must be listed in /etc/shells before chsh will accept it.
  if ! grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
    echo "$zsh_path" | $SUDO tee -a /etc/shells >/dev/null || true
  fi
  info "Setting default shell to $zsh_path (may prompt for your password)"
  chsh -s "$zsh_path" || warn "chsh failed — set it manually: chsh -s $zsh_path"
}

install_tools() {
  if [ "$OS" != "Darwin" ] && ! command -v apt-get >/dev/null 2>&1; then
    warn "automatic install supports macOS (brew) and apt-based Linux only."
    warn "your system has neither — install these manually:"
    check_tools
    return
  fi
  info "Installing missing tools (sudo may prompt for your password)"
  local bin apt brew fb
  while IFS='|' read -r bin apt brew fb; do
    [ -z "$bin" ] && continue
    install_one_tool "$bin" "$apt" "$brew" "$fb"
  done <<EOF
$TOOLS
EOF
  set_default_shell
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
  local do_omz=0 do_tools=0 link_only=0
  for arg in "$@"; do
    case "$arg" in
      --omz)        do_omz=1 ;;
      --tools)      do_tools=1 ;;
      --link-only)  link_only=1 ;;
      --help|-h)
        sed -n '3,17p' "$0"; exit 0 ;;
      *) warn "unknown arg: $arg" ;;
    esac
  done

  install_symlinks

  if [ "$do_tools" -eq 1 ]; then
    install_tools
  elif [ "$link_only" -eq 0 ]; then
    check_tools
  fi

  [ "$do_omz" -eq 1 ] && install_omz

  echo
  ok "Done. Next steps:"
  echo "   1. Edit ~/.secrets.zsh with your real tokens (if you use them)."
  echo "   2. Start a new shell:  exec zsh -l   (or 'reload')"
  [ "$do_omz" -eq 0 ] && echo "   3. First time on this box? run: ./install.sh --tools --omz"
  [ "$OS" = "Darwin" ] && echo "   4. macOS: see README for iTerm2 (Right Option = Esc+) & IntelliJ keymap."
}

main "$@"
