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

# Search recursively for a phrase in all files starting
# in current directory
search(){
  grep -nr $1 ./
}
# Search recursively for a phrase in all files starting
# in current directory and show results with an extra 
# 3 lines above and below
searchDetailed(){
  grep -nrC 3 $1 ./
}
# Search recursively for filenames matching phrase starting
# in current directory
searchFiles(){
  find . -type f -name $1
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
