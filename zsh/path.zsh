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

# Use project specific binaries before global ones
add_to_path "vendor/bin"
add_to_path "node_modules/.bin"

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
