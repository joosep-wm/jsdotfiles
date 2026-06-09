# ============================================================================
# ~/.fzf.zsh  (managed by jsdotfiles) — fzf key bindings & completion, portable.
# ============================================================================
if command -v fzf >/dev/null 2>&1; then
  # brew keg location (mac) — harmless elsewhere
  [ -d /opt/homebrew/opt/fzf/bin ] && case ":$PATH:" in
    *":/opt/homebrew/opt/fzf/bin:"*) ;;
    *) PATH="$PATH:/opt/homebrew/opt/fzf/bin" ;;
  esac

  # fzf >= 0.48 ships everything via `fzf --zsh`; fall back to distro example files.
  if ! source <(fzf --zsh) 2>/dev/null; then
    for _f in \
      /usr/share/doc/fzf/examples/key-bindings.zsh \
      /usr/share/fzf/key-bindings.zsh \
      /usr/share/doc/fzf/examples/completion.zsh \
      /usr/share/fzf/completion.zsh; do
      [ -f "$_f" ] && source "$_f"
    done
    unset _f
  fi
fi
