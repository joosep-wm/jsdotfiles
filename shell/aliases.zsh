# ============================================================================
# ~/.aliases.zsh  (managed by jsdotfiles) — portable aliases (bash-compatible).
# ============================================================================
alias cskip='claude --dangerously-skip-permissions'
alias reload='exec $SHELL -l'   # reload the login shell after editing dotfiles

# When an ssh connection dies mid-zellij (e.g. laptop sleep), the remote never
# sends the sequences that turn off mouse/focus reporting, so the local tab
# types "35;152;3M" junk on scroll. Reset those modes after every ssh exit.
_reset_term_modes() {
  [ -t 1 ] && printf '\033[?1000l\033[?1002l\033[?1003l\033[?1006l\033[?1004l\033[?1049l\033[?25h'
}

# Auto-reconnecting ssh: redials dropped links (detected via ServerAlive* in
# ~/.ssh/config, since -M 0 disables autossh's own probe); a deliberate
# exit/detach ends it. GATETIME=0 keeps retrying even when the first attempt
# fails, e.g. no network right after wake. Falls back to plain ssh on boxes
# without autossh.
ssh() {
  if command -v autossh >/dev/null 2>&1; then
    AUTOSSH_GATETIME=0 autossh -M 0 "$@"
  else
    command ssh "$@"
  fi
  local rc=$?
  _reset_term_modes
  return $rc
}
