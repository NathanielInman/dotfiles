#!/bin/bash

# User configuration
export PATH=/usr/local/bin:$HOME/bin:/usr/local/sbin:$HOME/n/bin:$PATH
export LANG=en_US.UTF-8
export ZSH=$HOME/.oh-my-zsh

# Variable declaration used by oh-my-zsh
ZSH_THEME="pragmata"
HIST_STAMPS="dd.mm.yyyy"
plugins=(git history zsh-syntax-highlighting zsh-autosuggestions)

# Start by inheriting default os oh-my-zsh (git aliases, etc)
source $HOME/.oh-my-zsh/oh-my-zsh.sh

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

# Vim mode (default mode is insert)
bindkey -v
