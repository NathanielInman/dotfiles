#!/bin/bash

# Auto-start Hyprland on tty1 login
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  exec start-hyprland
fi

# User configuration
export PATH=/usr/local/bin:$HOME/.local/bin:$HOME/bin:/usr/local/sbin:$HOME/n/bin:$PATH
export PATH=$HOME/.npm-global/bin:$PATH # global node/npm bin
export PATH=$HOME/.cargo/bin:$PATH # rust bin
export PATH=$HOME/.pyenv/bin:$PATH # python
export PNPM_HOME=$HOME/.local/share/pnpm
export PATH=$PNPM_HOME:$PATH # node path
export LANG=en_US.UTF-8
export ZSH=$HOME/.oh-my-zsh
export EDITOR=/usr/bin/neovide
export SPLIT='v' # split terminal vertically

# Variable declaration used by oh-my-zsh
HIST_STAMPS="dd.mm.yyyy"
plugins=(git history zsh-syntax-highlighting zsh-autosuggestions fzf)

# Start by inheriting default os oh-my-zsh (git aliases, etc)
source $HOME/.oh-my-zsh/oh-my-zsh.sh

# My aliases
alias vim='nvim' # old habits die hard
alias vi='nvim' # older habits die even harder
alias p='pnpm' # pnpm is so difficult for the fingers
alias yay='paru' # paru is rust, yay is go. alias due to muscle memory
alias yeet='paru -Rcs' # always forget remove flags
alias ssh='TERM=xterm-color ssh' # some terminals need this set explicitly
alias icat='chafa'
alias gbclean=$'git branch --merged master | grep -v \'^[ *]*master$\' | xargs git branch -d'
alias ls='eza' # 1:1 ls replacement
alias l='ls -lbF' # list, size, type
alias ll='ls -al' # long, list
alias llm='ll --sort=modified' # list, long, sort by modification date
alias la='ls -lbhHigUmuSa' # all list
alias lx='ls -lbhHigUmuSa@' # all list and extended
alias lS='eza -1' # just names
alias search='rg -F --hidden --max-columns=120'
alias searchAround='rg --hidden --max-columns=120 -C'
alias tree='broot -c :pt "$@" -sdp'
alias cat='bat'
alias rvimtmp='rm -i `find . | grep .swp$`'
alias searchFiles='fd'
alias du='ncdu --color dark -rr -x --exclude .git --exclude node_modules'
alias top='glances'
alias pbcopy='wl-copy' # pbcopy < ./filename.txt (pb stands for pasteboard, see osx pbcopy man)
alias pbpaste='wl-paste' # pbpaste > ./filename.txt
alias calendar='rusti-cal'
alias cal='calendar'
alias weather='curl https://v2d.wttr.in/~oak+grove+missouri'
alias has="curl -sL https://git.io/_has | bash -s" # dependency checker to validate versions
alias ps="procs"
alias dict="sdcv"
alias nnn="yazi" # yazi is faster with better controls and everything built-in
alias tv="tidy-viewer" # an easy way to preview csv files
alias disk="duf" # better version of df (disk free)
alias history="atuin search -i" # have search be interactive search

# Vim mode (default mode is insert)
bindkey -v

# My Functions
gbprune () {
  gfa
  git fetch -p
  for branch in $(git for-each-ref --format '%(refname) %(upstream:track)' refs/heads | awk '$2 == "[gone]" {sub("refs/heads/", "", $1); print $1}'); do git branch -D "$branch"; done
}
walk () {
  mkdir -p -- "$1" && cd -P -- "$1"
}
close () {
  read REPLY"?Remove current directory? [Y/n] "
  if [[ ! $REPLY =~ ^[Nn]$ ]] then
    rm -rf -- "$(pwd -P)" && cd ..
  fi
}

# Route `claude` to personal vs work profile based on the current git remote.
# Work is any repo whose origin lives under gitlab.com/digitalturbine — it runs
# against the work Claude subscription with its own CLAUDE_CONFIG_DIR so its
# OAuth login never crosses with the personal one. Override with --work / --personal.
claude () {
  local profile=""
  local -a args=()
  for arg in "$@"; do
    case "$arg" in
      --work) profile=work ;;
      --personal) profile=personal ;;
      *) args+=("$arg") ;;
    esac
  done

  if [[ -z "$profile" ]]; then
    local remote
    remote=$(git remote get-url origin 2>/dev/null)
    if [[ "$remote" == https://gitlab.com/digitalturbine/* || "$remote" == git@gitlab.com:digitalturbine/* ]]; then
      profile=work
    else
      profile=personal
    fi
  fi

  if [[ "$profile" == work ]]; then
    print -P "%B%F{black}%K{yellow}                                                  %k%f%b"
    print -P "%B%F{black}%K{yellow}   ██  WORK  ·  digitalturbine (subscription)  ██%k%f%b"
    print -P "%B%F{black}%K{yellow}                                                  %k%f%b"
    CLAUDE_CONFIG_DIR="$HOME/.claude-work" \
      command claude "${args[@]}"
  else
    print -P "%B%F{white}%K{blue}                                                  %k%f%b"
    print -P "%B%F{white}%K{blue}   ██  PERSONAL  ·  nate (OAuth)               ██ %k%f%b"
    print -P "%B%F{white}%K{blue}                                                  %k%f%b"
    command claude "${args[@]}"
  fi
}

# Plugin bootstraps
eval "$(zoxide init zsh)"
eval "$(pyenv init -)"

# det33 godot
alias compass='cd ~/Sites/det33-godot && dotnet build && godot-mono --path . res://Scenes/Test/CompassTest.tscn'
alias det33='cd ~/Sites/det33-godot && dotnet build && godot-mono --path . res://Scenes/Main/Boot.tscn'
alias gym='cd ~/Sites/det33-godot && dotnet build && godot-mono --path . res://Scenes/Test/AbilityTest.tscn'

# tintin
alias au-mardios='ssh nate@159.203.80.149 -t "tmux attach -t adventuresunlimited"'

# streamdeck command simplification
alias lightson='keylightctl switch --light 8A95 --brightness 3 on & keylightctl switch --light 9F74 --brightness 50 on'
alias lightsoff='keylightctl switch --light 8A95 off & keylightctl switch --light 9F74 off'

# we want to use brew on OSX, and keep broot config only on Arch
if uname -a | grep -q 'Darwin'; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  source /home/nate/.config/broot/launcher/bash/br
fi


. "$HOME/.atuin/bin/env"

eval "$(atuin init zsh --disable-up-arrow)"
eval "$(starship init zsh)"

source /home/nate/.config/broot/launcher/bash/br

# bun completions
[ -s "/home/nate/.bun/_bun" ] && source "/home/nate/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

alias claude-mem='/home/nate/.bun/bin/bun "/home/nate/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'

# pnpm
export PNPM_HOME="/home/nate/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
jiratransitions() {
  curl -s -u "$JIRA_USERNAME:$JIRA_API_TOKEN" \
    "https://digital-turbine.atlassian.net/rest/api/3/issue/$1/transitions" \
    | jq -r '.transitions[] | "\(.id)\t\(.name)"'
}
