# Variable declaration
ZSH_THEME="powerlevel9k/powerlevel9k"
HIST_STAMPS="dd.mm.yyyy"
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
plugins=(git)

# User configuration
export ZSH=/Users/nateinman/.oh-my-zsh
source $ZSH/oh-my-zsh.sh
export LANG=en_US.UTF-8
export PATH=/usr/local/share/npm/lib/node_modules/grunt-cli/bin:$PATH
export PATH=~/.composer/vendor/bin:$PATH
export PATH=$(brew --prefix php56)/bin:$PATH
export PATH=$(brew --prefix python)/bin:$PATH
export PATH=$(brew --prefix vim)/bin:$PATH
export PATH=${PATH}:~/android-sdk-mac/tools
export RBENV_ROOT=/usr/local/var/rbenv
export webroot=/Library/WebServer/Documents/
export PATH=$PATH:/Applications/Postgres.app/Contents/Versions/9.4/bin

# shims for rbenv
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

# All aliases 
alias ls='ls -GFh'
alias t='tree -phCL 2'
alias ga='git add -A'
alias gc='git commit -m'
alias gp='git push --follow-tags'
alias gf='git fetch -p origin'
alias gl='git log'
alias gs='git status'
alias gco='git checkout'
alias gshow='git show'
alias gpull='git pull'

# Calculation command to do math on the cli
calc () {
  bc -l <<< "$@"
}

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
