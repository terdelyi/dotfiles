#!/bin/zsh

# Function to set or change the GPG key for signing commits in a Git repository
set_gpg_signing_key() {
    local repo_path="$PWD"
    local gpg_key_id=${1:-$(git config --global --includes --get user.gpgsigningkey)}
    local email=${2:-""}

    if [ -z "$gpg_key_id" ]; then
        echo "Error: no key given and user.gpgsigningkey is unset in ~/.gitconfig.local." >&2
        return 1
    fi

    # rev-parse also accepts subdirectories, worktrees and submodules, where
    # .git is a file rather than a directory.
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Error: $repo_path is not a Git repository." >&2
        return 1
    fi

    git config gpg.format openpgp
    git config user.signingkey "$gpg_key_id"
    git config commit.gpgSign true

    if [ -n "$email" ]; then
        git config user.email "$email"
        echo "User email set to $email for repository at $repo_path"
    fi

    echo "GPG signing key set to $gpg_key_id for repository at $repo_path"
}

# Function to set or change the SSH key for signing commits in a Git repository
set_ssh_signing_key() {
    local repo_path="$PWD"
    local ssh_key=${1:-$(git config --global --includes --get user.signingkey)}
    local email=${2:-""}

    if [ -z "$ssh_key" ]; then
        echo "Error: no key given and user.signingkey is unset in ~/.gitconfig.local." >&2
        return 1
    fi

    # rev-parse also accepts subdirectories, worktrees and submodules, where
    # .git is a file rather than a directory.
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Error: $repo_path is not a Git repository." >&2
        return 1
    fi

    git config gpg.format ssh
    git config user.signingkey "$ssh_key"
    git config commit.gpgSign true

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

# Valet serves *.test through /etc/resolver/test -> dnsmasq, which is plain DNS,
# and a connected VPN takes DNS over - breaking every site. /etc/hosts is read
# before DNS, so mirror the linked sites into it to survive the VPN. The marker
# text is load-bearing: it identifies the block to replace on the next sync.
sync_valet_hosts() {
  local begin="# BEGIN VALET VPN HOSTS"
  local end="# END VALET VPN HOSTS"
  local tld block site

  if (( ! $+commands[valet] )); then
    echo "valet is not installed" >&2
    return 1
  fi

  # `command` skips the wrapper below, which would otherwise re-enter valet.
  tld=$(command valet tld) || return 1

  block="$begin"$'\n'

  # (N-/) drops the glob when Sites is empty and follows each symlink, so a
  # project directory that has since been deleted does not get a hosts entry.
  for site in "$HOME/.config/valet/Sites"/*(N-/); do
    # The name is about to be written into /etc/hosts as root, so it has to be
    # a plausible hostname and nothing else - a directory name containing a
    # newline would otherwise append lines of its own to the file.
    if [[ ! "${site:t}" =~ '^[A-Za-z0-9][A-Za-z0-9._-]*$' ]]; then
      echo "Skipping ${site:t}: not a valid hostname" >&2
      continue
    fi

    block+="127.0.0.1 ${site:t}.${tld}"$'\n'
  done

  block+="$end"

  # One sudo call, so one password prompt: sed -i keeps a backup for free,
  # cat appends the new block, and mDNSResponder is what actually drops the
  # DNS cache - dscacheutil alone has not been enough for years.
  printf '%s\n' "$block" | sudo sh -c "
    sed -i '.bak' '/^$begin\$/,/^$end\$/d' /etc/hosts &&
    cat >> /etc/hosts || exit 1

    dscacheutil -flushcache
    killall -HUP mDNSResponder
  "
}

# Keep /etc/hosts in step with the site list automatically.
valet() {
  if [[ "$1" == "sync-hosts" ]]; then
    sync_valet_hosts
    return
  fi

  command valet "$@" || return

  case "$1" in
    link|unlink)
      sync_valet_hosts
      ;;
  esac
}

# DBngin does not put its MySQL client on the PATH, and the version directory
# changes on every upgrade, so resolve the newest one installed.
mysql() {
  local -a clients=(/Users/Shared/DBngin/mysql/*/bin/mysql(Nn))

  if (( $#clients == 0 )); then
    echo "No DBngin MySQL client under /Users/Shared/DBngin/mysql" >&2
    return 1
  fi

  command "$clients[-1]" "$@"
}
