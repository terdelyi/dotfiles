# dotfiles

Personal macOS setup: zsh config, Git config, and a Homebrew bundle.

## Install

```bash
git clone https://github.com/terdelyi/dotfiles.git ~/.dotfiles
. ~/.dotfiles/install.sh [personal|work]
```

The profile is asked for if omitted, and remembered in `~/.dotfiles.profile`
afterwards — pass it again to switch. A non-interactive run with no profile
stops rather than guessing. Safe to re-run; every step is idempotent.

## Machine profiles

`homebrew/Brewfile` is installed everywhere. `Brewfile.personal` and
`Brewfile.work` add to it, and the profile picks one. Both are tracked, so the
work machine's list is reviewable rather than the personal list minus whatever
got skipped by hand.

A single Brewfile with `if ENV['WORK']` in it looks like the obvious
alternative but does not work: Homebrew strips every environment variable not
named `HOMEBREW_*` before reading the file, so the condition silently never
fires.

The profile also decides the Git identity prompt, and whether `mac/.macos` sets
the computer name — a work machine is usually named by IT. Everything else,
Valet and DBngin included, is installed on both.

## Git identity

Name, email and signing keys live in `~/.gitconfig.local`, untracked and
included from `git/.gitconfig`. The installer prompts for name and email on a
fresh machine and leaves the keys blank:

```gitconfig
[user]
	name = Your Name
	email = you@example.com
	signingkey = ssh-ed25519 AAAA...   # public half, used by 1Password
	gpgsigningkey = 0123456789ABCDEF   # read by set_gpg_signing_key
```

Skip the prompt and git refuses to commit until the email is filled in, which
is deliberate — a placeholder would otherwise author commits from the wrong
address on a work machine.

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
