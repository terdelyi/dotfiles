# Sourced for every zsh invocation, including non-interactive ones that skip
# .zshrc (e.g. `zsh -c ...`, Claude Code's Bash tool). .zshrc lazy-loads nvm
# via a function that shadows this in interactive shells, so this only backs
# non-interactive ones where that function is never defined.
export NVM_DIR="$HOME/.nvm"

# Resolve nvm's default alias to an installed version without sourcing nvm.sh
# (slow); find avoids zsh's fatal "no matches" on an unexpanded glob, so a
# missing nvm or alias just leaves PATH untouched.
if [[ -r "$NVM_DIR/alias/default" ]]; then
  _nvm_default=$(<"$NVM_DIR/alias/default")
  _nvm_bin=$(find "$NVM_DIR/versions/node" -maxdepth 1 -name "${_nvm_default}*" 2>/dev/null | sort -V | tail -1)
  [[ -n $_nvm_bin && -d "$_nvm_bin/bin" ]] && export PATH="$_nvm_bin/bin:$PATH"
  unset _nvm_default _nvm_bin
fi
