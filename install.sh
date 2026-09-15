#!/bin/sh

echo "Setting up Mac..."

# Check for Oh My Zsh and install if we don't have it
if test ! "$(which omz)"; then
  /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Check for Homebrew and install if we don't have it
if test ! "$(which brew)"; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

  echo "eval \"$(/opt/homebrew/bin/brew shellenv)\"" >> "$HOME/.zprofile"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Sets OhMyZSH config
ln -sfnw "$HOME/.dotfiles/zsh/.zshrc" "$HOME/.zshrc"

# Sets Git config
ln -sfnw "$HOME/.dotfiles/git/.gitconfig" "$HOME/.gitconfig"
ln -sfnw "$HOME/.dotfiles/git/.gitignore_global" "$HOME/.gitignore_global"

# Identity is machine-local and deliberately untracked, so .gitconfig includes
# it from here. Seed a template on a fresh machine; never clobber a real one.
gitconfig_local="$HOME/.gitconfig.local"

if test ! -f "$gitconfig_local"; then
  echo "Seeding $gitconfig_local - fill in your identity before committing..."

  cat > "$gitconfig_local" <<'EOF'
# Machine-local identity. Not tracked in ~/.dotfiles - included from
# git/.gitconfig. Add includeIf blocks here for per-directory identities.
[user]
	name = Your Name
	email = you@example.com
	# Public half of the signing key, as `ssh-ed25519 AAAA...`.
	signingkey =
	# Read by set_gpg_signing_key in zsh/functions.zsh.
	gpgsigningkey =
EOF

  chmod 600 "$gitconfig_local"
fi

# Stop macOS from forwarding our locale to every host we SSH into.
# /etc/ssh/ssh_config.d/100-macos.conf sets `SendEnv LANG LC_*`, which ships
# locale names the remote may not have generated, producing "cannot change
# locale" warnings and mangled UTF-8. Clearing them has to be parsed *after*
# that file, which rules out ~/.ssh/config - the user config is read before the
# system one - so this goes in a sibling that sorts later in the include.
ssh_locale_conf="/etc/ssh/ssh_config.d/200-no-locale-forwarding.conf"

if ssh -G dotfiles-install-probe 2>/dev/null | grep -qiE '^sendenv (lang|lc_)'; then
  echo "Disabling SSH locale forwarding in $ssh_locale_conf..."

  sudo tee "$ssh_locale_conf" > /dev/null <<'EOF'
# Managed by ~/.dotfiles/install.sh - re-run it if a macOS update removes this.
Host *
  SendEnv -LANG -LC_*
EOF

  sudo chmod 644 "$ssh_locale_conf"
fi

# Update Homebrew recipes
brew update

# Install dependencies with bundle
brew tap homebrew/bundle
brew bundle --file ./homebrew/Brewfile

# Create a projects directories
mkdir -p "$HOME/Code"

# Install Valet for PHP prototyping
composer global require laravel/valet
valet install
valet trust

# Set 1Password SSH agent
mkdir -p ~/.1password && ln -sfnw ~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock ~/.1password/agent.sock

# Start Mailpit
brew services start mailpit

# Set macOS preferences - we will run this last because this will reload the shell
. mac/.macos