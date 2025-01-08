#!/bin/zsh

# Function to set or change the GPG key for signing commits in a Git repository
set_gpg_signing_key() {
    repo_path="$(pwd)"
    local gpg_key_id=${1:-"0F7F96EC6F3C0C38"}
    local email=${2:-""}

    if [ ! -d "$repo_path/.git" ]; then
        echo "Error: $repo_path is not a valid Git repository."
        return 1
    fi

    cd "$repo_path" || return 1

    git config gpg.format openpgp
    git config user.signingkey "$gpg_key_id"
    git config commit.gpgSign true
    git config commit.tag true

    if [ -n "$email" ]; then
        git config user.email "$email"
        echo "User email set to $email for repository at $repo_path"
    fi

    echo "GPG signing key set to $gpg_key_id for repository at $repo_path"
}

# Function to set or change the SSH key for signing commits in a Git repository
set_ssh_signing_key() {
    repo_path="$(pwd)"
    local ssh_key=${1:-"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEYEzp7aGJuhbHOgvwD2XriBk1YuvlpZcJ3WAoanos+G"}
    local email=${2:-""}

    if [ ! -d "$repo_path/.git" ]; then
        echo "Error: $repo_path is not a valid Git repository."
        return 1
    fi

    cd "$repo_path" || return 1

    git config gpg.format ssh
    git config user.signingkey "$ssh_key"
    git config commit.gpgSign true
    git config commit.tag true

    if [ -n "$email" ]; then
        git config user.email "$email"
        echo "User email set to $email for repository at $repo_path"
    fi

    echo "GPG signing key set to $ssh_key for repository at $repo_path"
}

get_gpg_key_id() {
  local email=$1

  if [ -z "$email" ]; then
    echo "Email address is required"
    return 1
  fi

  # Extract the key ID associated with the provided email address
  gpg --list-keys --with-colons | \
    awk -F: -v email="$email" '$0 ~ email && /^pub/ {print $5}' | \
    jq -R -s -c 'split("\n")[:-1]'
}