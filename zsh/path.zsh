# Add directories to the PATH and prevent to add the same directory multiple times upon shell reload.
add_to_path() {
  if [[ -d "$1" ]] && [[ ":$PATH:" != *":$1:"* ]]; then
    export PATH="$1:$PATH"
  fi
}

# Load global Composer tools
add_to_path "$HOME/.composer/vendor/bin"

# Load global Node installed binaries
add_to_path "$HOME/.node/bin"

# Ruby
add_to_path "/opt/homebrew/opt/ruby/bin"
if (( $+commands[ruby] )); then
  export GEM_HOME="$(ruby -e 'puts Gem.user_dir')"
  add_to_path "$GEM_HOME/bin"
fi

# Python
add_to_path "/opt/homebrew/opt/python/libexec/bin"

# Binaries installed by pipx and friends
add_to_path "$HOME/.local/bin"

# Project-local binaries. Two rules here are load-bearing. They are resolved
# absolutely and re-resolved on every cd: a bare relative "vendor/bin" in PATH
# is matched against whatever directory the shell happens to be standing in, so
# any repo you clone could drop a vendor/bin/ls and have it run. And they are
# appended rather than prepended, so a project can supply phpunit or pint but
# cannot shadow ls, git or sudo - `composer install` writes straight into
# vendor/bin, which makes a dependency enough to hijack a system command.
typeset -ga _project_bins=()

_sync_project_bins() {
  local dir
  local -a kept=()

  # Drop whatever we added for the directory we just left. (Ie) is an exact
  # match, so a path containing glob characters is compared literally.
  for dir in $path; do
    if (( ! ${_project_bins[(Ie)$dir]} )); then
      kept+=("$dir")
    fi
  done

  path=($kept)
  _project_bins=()

  for dir in "$PWD/vendor/bin" "$PWD/node_modules/.bin"; do
    if [[ -d "$dir" ]] && (( ! ${path[(Ie)$dir]} )); then
      _project_bins+=("$dir")
      path+=("$dir")
    fi
  done
}

autoload -U add-zsh-hook
add-zsh-hook chpwd _sync_project_bins
_sync_project_bins
