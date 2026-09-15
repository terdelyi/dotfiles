# Path to your dotfiles.
export DOTFILES=$HOME/.dotfiles/zsh

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Minimal - Theme Settings
#export MNML_INSERT_CHAR="$"
#export MNML_PROMPT=(mnml_git mnml_keymap)
#export MNML_RPROMPT=('mnml_cwd 20')

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
#ZSH_THEME="sunaku"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="dd/mm/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
ZSH_CUSTOM=$DOTFILES

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(1password aws brew docker docker-compose git gh golang laravel macos)

source $ZSH/oh-my-zsh.sh

# User configuration

# Character handling only. Terminal emulators export a bare `LC_CTYPE=UTF-8`,
# but that depends on a GUI preference; without it we fall back to C and UTF-8
# breaks. LANG and LC_ALL are deliberately left unset: they only change
# collation, and C byte order is what scripts and servers use.
export LC_CTYPE=en_GB.UTF-8

# Fix for GPG TTY error: https://github.com/Homebrew/homebrew-core/issues/14737#issuecomment-309848851
GPG_TTY=$(tty)
export GPG_TTY

# Load nvm on first use. Sourcing nvm.sh eagerly cost about 0.23s of a 0.47s
# shell startup - half of it - and most shells never touch node. Stub the
# commands it provides; the first call replaces the stubs with the real thing
# and re-runs itself, so this is invisible in use.
export NVM_DIR="$HOME/.nvm"

if [[ -s $NVM_DIR/nvm.sh ]]; then
  _load_nvm() {
    unfunction nvm node npm npx 2>/dev/null
    . "$NVM_DIR/nvm.sh"
  }

  for _cmd in nvm node npm npx; do
    eval "$_cmd() { _load_nvm; $_cmd \"\$@\"; }"
  done

  unset _cmd
fi

# Autocomplete
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# What is this?
autoload -U promptinit; promptinit
prompt pure

export SSH_AUTH_SOCK=~/.1password/agent.sock
