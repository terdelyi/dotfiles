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

## Functions

| Function | What it does |
| --- | --- |
| `set_gpg_signing_key [key-id] [email]` | Sets up OpenPGP commit signing for the current repo. Defaults to the key ID in the function, sets `user.email` only if given. |
| `set_ssh_signing_key [public-key] [email]` | Same, for SSH signing. |
| `get_gpg_key_id <email>` | Prints the GPG key IDs matching an email, as a JSON array. |
| `sync_valet_hosts` | Mirrors every linked Valet site into `/etc/hosts`. Valet resolves `*.test` over DNS, so a connected VPN takes it over and every local site stops resolving. Requires `sudo`. |
| `valet` | Wraps the real `valet`: adds `valet sync-hosts`, and re-syncs after a successful `link` or `unlink`. |
| `mysql` | Runs the newest MySQL client installed by DBngin. |
