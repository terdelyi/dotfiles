# dotfiles

Personal macOS setup: zsh config, Git config, and a Homebrew bundle.

## Install

Clone the repo:

```bash
git clone https://github.com/terdelyi/dotfiles.git ~/.dotfiles
```

Then run the installer for generic system setup:

```bash
. ~/.dotfiles/install.sh
```

It is safe to re-run — every step is idempotent.

## Git identity

Name, email and signing keys live in `~/.gitconfig.local`, which is not tracked
here — `git/.gitconfig` includes it. The installer seeds a placeholder version
on a fresh machine; fill it in before your first commit:

```gitconfig
[user]
	name = Your Name
	email = you@example.com
	signingkey = ssh-ed25519 AAAA...   # public half, used by 1Password
	gpgsigningkey = 0123456789ABCDEF   # read by set_gpg_signing_key
```

The installer also writes `~/.ssh/allowed_signers` from those values, which is
what `git log --show-signature` verifies against — signing works without it,
verifying does not.

A second identity is an `includeIf` in the same file:

```gitconfig
[includeIf "gitdir:~/Code/work/"]
	path = ~/.gitconfig.work
```

## Functions

| Function | What it does |
| --- | --- |
| `set_gpg_signing_key [key-id] [email]` | Sets up OpenPGP commit signing for the current repo. Defaults to `user.gpgsigningkey` from `~/.gitconfig.local`, sets `user.email` only if given. |
| `set_ssh_signing_key [public-key] [email]` | Same, for SSH signing, defaulting to `user.signingkey`. |
| `get_gpg_key_id <email>` | Prints the GPG key IDs matching an email, as a JSON array. |
| `sync_valet_hosts` | Mirrors every linked Valet site into `/etc/hosts`. Valet resolves `*.test` over DNS, so a connected VPN takes it over and every local site stops resolving. Requires `sudo`. |
| `valet` | Wraps the real `valet`: adds `valet sync-hosts`, and re-syncs after a successful `link` or `unlink`. |
| `mysql` | Runs the newest MySQL client installed by DBngin. |
