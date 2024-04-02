#!/bin/bash

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
export NNN_OPTS="deH" # d = details, e = visual mode default, H = show hidden
export NNN_FIFO=/tmp/nnn.fifo # temporary buffer for previews
export NNN_PLUG='p:preview-tui;t:preview-tabbed' nnn
export SPLIT='v' # split kitty vertically

# Variable declaration used by oh-my-zsh
ZSH_THEME="pragmata"
HIST_STAMPS="dd.mm.yyyy"
plugins=(git history zsh-syntax-highlighting zsh-autosuggestions fzf)

# Start by inheriting default os oh-my-zsh (git aliases, etc)
source $HOME/.oh-my-zsh/oh-my-zsh.sh

# My aliases
alias p='pnpm' # pnpm is so difficult for the fingers
alias yay='paru' # paru is rust, yay is go. alias due to muscle memory
alias yeet='paru -Rcs' # always forget remove flags
alias ssh='TERM=xterm-color ssh' # kitty does weird things, set it explicitly
alias icat='kitty +kitten icat'
alias gbclean=$'git branch --merged master | grep -v \'^[ *]*master$\' | xargs git branch -d'
alias ls='exa' # 1:1 ls replacement
alias l='ls -lbF' # list, size, type
alias ll='ls -al' # long, list
alias llm='ll --sort=modified' # list, long, sort by modification date
alias la='ls -lbhHigUmuSa' # all list
alias lx='ls -lbhHigUmuSa@' # all list and extended
alias lS='exa -1' # just names
alias search='rg -F'
alias searchAround='rg -C'
alias tree='broot -c :pt "$@" -sdp'
alias cat='bat'
alias rvimtmp='rm -i `find . | grep .swp$`'
alias searchFiles='fd'
alias du='ncdu --color dark -rr -x --exclude .git --exclude node_modules'
alias top='glances'
alias pbcopy='xsel --clipboard --input' # pbcopy < ./filename.txt (pb stands for pasteboard, see osx pbcopy man)
alias pbpaste='xsel --clipboard --output' # pbpaste > ./filename.txt
alias calendar='rusti-cal'
alias cal='rusti-cal'
alias weather='curl v2d.wttr.in'
alias has="curl -sL https://git.io/_has | bash -s" # dependency checker to validate versions
alias ps="procs"
alias dict="sdcv"
alias nnn="nnn -$NNN_OPTS"
alias tv="tidy-viewer" # an easy way to preview csv files

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

# we want to use brew on OSX, and keep broot config only on Arch
if uname -a | grep -q 'Darwin'; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  source /home/nate/.config/broot/launcher/bash/br
fi

# Plugin bootstraps
eval "$(zoxide init zsh)"
eval "$(pyenv init -)"

# tintin
alias au-mardios='ssh nate@159.203.80.149 -t "tmux attach -t adventuresunlimited"'

# streamdeck command simplification
alias lightson='keylightctl switch --light 8A95 on & keylightctl switch --light 9F74 on'
alias lightsoff='keylightctl switch --light 8A95 off & keylightctl switch --light 9F74 off'

source /home/nate/.config/broot/launcher/bash/br
