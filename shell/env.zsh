# ============================================================================
# ~/.env.zsh  (managed by jsdotfiles) — tool environment, portable.
# ============================================================================

# --- nvm (Node Version Manager) ---------------------------------------------
# Works whether nvm is a brew formula (mac) or the official install (~/.nvm).
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
for _nvm in \
  "/opt/homebrew/opt/nvm/nvm.sh" \
  "/usr/local/opt/nvm/nvm.sh" \
  "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" \
  "$NVM_DIR/nvm.sh"; do
  if [ -s "$_nvm" ]; then . "$_nvm"; break; fi
done
unset _nvm
for _nvmc in \
  "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" \
  "$NVM_DIR/bash_completion"; do
  if [ -s "$_nvmc" ]; then . "$_nvmc"; break; fi
done
unset _nvmc

# --- Google Cloud SDK -------------------------------------------------------
[ -d "$HOME/dev/google-cloud-sdk" ] && export CLOUDSDK_HOME="$HOME/dev/google-cloud-sdk"
