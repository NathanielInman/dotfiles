#!/bin/bash
# Variable declaration
ZSH_THEME="pragmata"
HIST_STAMPS="dd.mm.yyyy"
plugins=(git)

# User configuration
export ZSH=$HOME/.oh-my-zsh
source $ZSH/oh-my-zsh.sh
export NODEVERSION=$(node -v | cut -c 2-)
export NODEBIN=/usr/local/Cellar/node/$NODEVERSION/bin
export PATH=/usr/local/bin:$HOME/bin:/usr/local/sbin:$NODEBIN:$PATH
export LANG=en_US.UTF-8

# All aliases
alias ls='lsd'
alias tree='lsd --tree'
alias cat='bat'
alias rvimtmp='rm -i `find . | grep .swp$`'
alias searchFiles='fd'

# Search recursively for a phrase in all files starting
# in current directory will return file name,line number
# and the line it found the result
search(){
  grep -nr $1 ./
}

# Search recursively for a phrase in all files starting
# in current directory and show results with an extra 
# 3 lines above and below. Will also return file name and
# line numbers for found results
searchDetailed(){
  grep -nrC 3 $1 ./
}

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
