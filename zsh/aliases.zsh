# Shortcuts
alias copyssh='pbcopy < $HOME/.ssh/id_ed25519.pub'
alias reloadshell="omz reload"
alias reloaddns="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias phpstorm='open -a /Applications/PhpStorm.app "`pwd`"'

# Docker
# Compose v1 is end-of-life; the subcommand is the supported form.
alias docker-composer="docker compose"

# Git
alias gs="git status"
alias gb="git branch"
alias gc="git checkout"
alias gd="git diff"
alias gl="git log --oneline --decorate --color"
alias amend="git add . && git commit --amend --no-edit"
alias commit="git add . && git commit -m"
alias force="git push --force-with-lease"
alias nuke="git clean -df && git reset --hard"
alias pop="git stash pop"
alias prune="git fetch --prune"
alias pull="git pull"
alias push="git push"
alias resolve="git add . && git commit --no-edit"
alias stash="git stash -u"
alias unstage="git restore --staged ."
alias wip="commit wip"
alias setgpg="git config gpg.format gpg"
alias setssh="git config gpg.format ssh"

# Valet
alias va="valet php artisan"
alias vc="valet composer"
