#!/bin/bash
# Variable declaration
ZSH_THEME="pragmata"
HIST_STAMPS="dd.mm.yyyy"
plugins=(git)

# User configuration
export ZSH=$HOME/.oh-my-zsh
source $ZSH/oh-my-zsh.sh
export PATH=/usr/local/bin:$HOME/bin:/usr/local/sbin:$N_PREFIX:$PATH
export LANG=en_US.UTF-8

# All aliases
alias gbclean=$'git branch --merged master | grep -v \'^[ *]*master$\' | xargs git branch -d'
alias ls='lsd'
alias search='rg'
alias tree='lsd --tree'
alias cat='bat'
alias rvimtmp='rm -i `find . | grep .swp$`'
alias searchFiles='fd'
alias du='ncdu --color dark -rr -x --exclude .git --exclude node_modules'
alias top='htop'

# Show lines of a specified file $3 starting at $1, ending with $2
showLines(){
  sed -n "$1,$2p" $3
}

#Alias for finding process by port and killing it
killPort(){
  lsof -ti tcp:$1 | xargs kill
}

# Create a directory and cd into it
walk(){
  mkdir -p $1
  cd $1
}

# Recursively remove all contents of a directory from
# within that directory, or by specifying it
close(){
  if [ -n "$1" ]; then
    rm -rf $1
  else
    rm -rf -- "$(pwd -P)" && cd ..
  fi
}
