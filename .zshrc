#!/bin/bash

# Variable declaration
ZSH_THEME="pragmata"
HIST_STAMPS="dd.mm.yyyy"
plugins=(git)

# User configuration
export ZSH=$HOME/.oh-my-zsh
source $ZSH/oh-my-zsh.sh
export N_PREFIX="$HOME/n"
export PATH=/usr/local/bin:$HOME/bin:/usr/local/sbin:$N_PREFIX/bin:$PATH
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
