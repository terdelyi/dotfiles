#!/bin/sh

echo "Setting up Mac..."

# Every path below is anchored here rather than to the working directory. The
# README says to source this file, so a relative `mac/.macos` would resolve
# against whatever directory you happen to be standing in - and that step runs
# with sudo already primed. The symlink targets already assume this location.
DOTFILES_ROOT="$HOME/.dotfiles"

if test ! -f "$DOTFILES_ROOT/install.sh"; then
  echo "Expected the dotfiles at $DOTFILES_ROOT - clone them there and re-run." >&2
  return 1 2>/dev/null || exit 1
fi

# Check for Oh My Zsh and install if we don't have it. `omz` is a shell
# function rather than a binary, so `which omz` never finds it from this
# script - testing for it re-ran the installer on every pass.
if test ! -d "$HOME/.oh-my-zsh"; then
  /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Check for Homebrew and install if we don't have it
if test ! "$(which brew)"; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

  # The line has to reach .zprofile literally. Inside double quotes the
  # command substitution would run here instead, freezing today's paths into
  # the file - and its own quotes would nest and break the `eval`.
  brew_shellenv='eval "$(/opt/homebrew/bin/brew shellenv)"'

  if ! grep -qxF "$brew_shellenv" "$HOME/.zprofile" 2>/dev/null; then
    printf '%s\n' "$brew_shellenv" >> "$HOME/.zprofile"
  fi

  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Sets OhMyZSH config
ln -sfnw "$DOTFILES_ROOT/zsh/.zshrc" "$HOME/.zshrc"

# Sets Git config
ln -sfnw "$DOTFILES_ROOT/git/.gitconfig" "$HOME/.gitconfig"
ln -sfnw "$DOTFILES_ROOT/git/.gitignore_global" "$HOME/.gitignore_global"

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

# git verifies signatures against this file, so it has to name the same key the
# identity signs with. Derive both from the config rather than duplicating them.
# --includes is needed because --global turns include expansion off.
allowed_signers="$HOME/.ssh/allowed_signers"
signer_email=$(git config --global --includes --get user.email)
signer_key=$(git config --global --includes --get user.signingkey)

if test -n "$signer_email" && test -n "$signer_key"; then
  signer_line="$signer_email $signer_key"

  mkdir -p "$HOME/.ssh"
  touch "$allowed_signers"

  if ! grep -qxF "$signer_line" "$allowed_signers"; then
    echo "Trusting $signer_email in $allowed_signers..."
    echo "$signer_line" >> "$allowed_signers"
  fi

  chmod 600 "$allowed_signers"
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

# Install dependencies with bundle. The shared Brewfile goes on every machine;
# the profile decides what else. Keeping the split in two tracked files rather
# than conditionals inside one keeps the work machine's list reviewable, and
# sidesteps the fact that Homebrew scrubs any env var not named HOMEBREW_*,
# so a plain `if ENV['WORK']` in a Brewfile silently never fires.
profile_file="$HOME/.dotfiles.profile"

if test ! -f "$profile_file"; then
  echo "Which machine is this? [personal/work]"
  read -r profile

  case "$profile" in
    work) : ;;
    *) profile=personal ;;
  esac

  printf '%s\n' "$profile" > "$profile_file"
  echo "Recorded $profile in $profile_file - edit it to change profile."
fi

profile=$(cat "$profile_file")
profile_brewfile="$DOTFILES_ROOT/homebrew/Brewfile.$profile"

brew tap homebrew/bundle
brew bundle --file "$DOTFILES_ROOT/homebrew/Brewfile"

if test -f "$profile_brewfile"; then
  echo "Installing $profile extras..."
  brew bundle --file "$profile_brewfile"
else
  echo "No Brewfile for profile '$profile' - skipping extras." >&2
fi

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
. "$DOTFILES_ROOT/mac/.macos"