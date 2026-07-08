# ============================================================================
# ~/.fzf.bash  (managed by jsdotfiles) — fzf for bash, portable.
# ============================================================================
if command -v fzf >/dev/null 2>&1; then
  [ -d /opt/homebrew/opt/fzf/bin ] && case ":$PATH:" in
    *":/opt/homebrew/opt/fzf/bin:"*) ;;
    *) PATH="$PATH:/opt/homebrew/opt/fzf/bin" ;;
  esac

  # Capture via $() so old fzf's "unknown option: --bash" stderr is swallowed
  # (it escapes the outer redirect) and fzf's exit status decides the fallback.
  if _fzf_init="$(fzf --bash 2>/dev/null)"; then
    eval "$_fzf_init"
  else
    for _f in \
      /usr/share/doc/fzf/examples/key-bindings.bash \
      /usr/share/fzf/key-bindings.bash \
      /usr/share/doc/fzf/examples/completion.bash \
      /usr/share/fzf/completion.bash; do
      [ -f "$_f" ] && source "$_f"
    done
    unset _f
  fi
  unset _fzf_init
fi
