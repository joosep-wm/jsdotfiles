# ============================================================================
# ~/.path.zsh  (managed by jsdotfiles) — PATH additions, portable.
# Each entry is added only if the directory actually exists, so this file is
# harmless on machines that don't have the given tool installed.
# ============================================================================

# Prepend $1 to PATH if it exists and isn't already present.
_prepend_path() {
  [ -d "$1" ] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;                 # already there
    *) PATH="$1:$PATH" ;;
  esac
}

# Homebrew-keg-only tools (macOS) — no-ops on Linux.
_prepend_path "/opt/homebrew/opt/python@3.12/libexec/bin"
_prepend_path "/opt/homebrew/opt/libpq/bin"
_prepend_path "/opt/homebrew/opt/ruby/bin"
_prepend_path "/opt/homebrew/lib/ruby/gems/3.4.0/bin"

# Cross-platform
_prepend_path "$HOME/.local/bin"

# qlty
export QLTY_INSTALL="$HOME/.qlty"
_prepend_path "$QLTY_INSTALL/bin"

export PATH
unset -f _prepend_path
