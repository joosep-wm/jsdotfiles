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
  # Capture via $() so the "unknown option: --zsh" that old fzf prints to stderr is
  # swallowed (a process-sub's stderr escapes the outer redirect) and fzf's own exit
  # status — not source's — decides whether the fallback runs.
  if _fzf_init="$(fzf --zsh 2>/dev/null)"; then
    eval "$_fzf_init"
  else
    for _f in \
      /usr/share/doc/fzf/examples/key-bindings.zsh \
      /usr/share/fzf/key-bindings.zsh \
      /usr/share/doc/fzf/examples/completion.zsh \
      /usr/share/fzf/completion.zsh; do
      [ -f "$_f" ] && source "$_f"
    done
    unset _f
  fi
  unset _fzf_init
fi
