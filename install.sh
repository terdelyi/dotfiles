#!/bin/sh

echo "Setting up Mac..."

# Check for Oh My Zsh and install if we don't have it
if test ! "$(which omz)"; then
  /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)"
fi

# Check for Homebrew and install if we don't have it
if test ! "$(which brew)"; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo "eval \"$(/opt/homebrew/bin/brew shellenv)\"" >> "$HOME/.zprofile"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Removes .zshrc from $HOME (if it exists) and symlinks the .zshrc file from the .dotfiles
rm -rf "$HOME/.zshrc"
ln -sw "$HOME/.dotfiles/zsh/.zshrc" "$HOME/.zshrc"

# Update Homebrew recipes
brew update

# Install dependencies with bundle
brew tap homebrew/bundle
brew bundle --file ./homebrew/Brewfile

# Create a projects directories
mkdir "$HOME/Code"

# Set macOS preferences - we will run this last because this will reload the shell
. /mac/.macos