# Variable declaration
ZSH_THEME="nate"
HIST_STAMPS="dd.mm.yyyy"
plugins=(git)

# User configuration
export ZSH=$HOME/.oh-my-zsh
source $ZSH/oh-my-zsh.sh
export PATH=/usr/local/bin:$HOME/bin:/usr/local/sbin:$PATH
export LANG=en_US.UTF-8

# All aliases 
alias ls='exa -GF'
alias ga='git add -A'
alias gc='git commit -m'
alias gp='git push --follow-tags'
alias gf='git fetch -p origin'
alias gl='git log'
alias gs='git status'
alias gco='git checkout'
alias gshow='git show'
alias gpull='git pull'
alias termpdf='~/termpdf'
alias k2pdfopt='~/k2pdfopt'
alias rvimtmp='rm -i `find . | grep .swp$`'

# Alias grep command for search
search(){
  grep -nr $1 ./
}
searchFiles(){
  find . -type f -name $1
}

# If I search and find a line number but want to see what's near that
# number, I can output specified start and end lines to output
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
