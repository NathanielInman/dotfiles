# Set up paths and language library
export LANG=en_US.UTF-8
export ZSH=$HOME/.oh-my-zsh
export PATH=/usr/local/bin:$HOME/bin:$PATH

ZSH_THEME="bureau"
plugins=(git)

# User configuration
source $ZSH/oh-my-zsh.sh

# All aliases 
alias ls='ls -GFh'
alias ga='git add -A'
alias gc='git commit -m'
alias gp='git push --follow-tags'
alias gf='git fetch -p origin'
alias gl='git log'
alias gs='git status'
alias gco='git checkout'
alias gshow='git show'
alias gpull='git pull'

# Alias grep command for search
search(){
  grep -nr $1 ./
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
