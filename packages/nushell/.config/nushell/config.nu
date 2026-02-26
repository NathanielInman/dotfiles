use std/util "path add"

# paths for archlinux
path add "/usr/local/bin"
path add "/usr/local/sbin"
path add "~/.local/bin"
path add "~/bin"

# paths for rust
path add "~/.cargo/bin"

# paths for python
path add "~/.pyenv/bin"

# paths for javascript/node
path add "~/n/bin"
path add "~/.npm-global/bin"
path add "~/.local/share/pnpm"

# general configuration
$env.config.buffer_editor = "/usr/bin/neovide"
$env.config.show_banner = false

# Git specific aliases subsection from oh-my-zsh
alias ga = git add
alias gaa = git add --all
alias gam = git am
alias gb = git branch
alias gba = git branch --all
alias gca = git commit --verbose --all
alias gco = git checkout
alias gd = git diff
alias gf = git fetch
alias gfa = git fetch --all --tags --prune --jobs=10
alias gl = git pull
alias gp = git push
alias gsb = git status --short --branch

# My aliases
alias vim = nvim # old habits die hard
alias vi = nvim # older habits die even harder
alias p = pnpm # pnpm is so difficult for the fingers
alias yay = paru # paru is rust, yay is go. alias due to muscle memory
alias yeet = paru -Rcs # always forget remove flags
alias icat = chafa
alias gbclean = git branch --merged master | grep -v '^[ *]*master$' | xargs git branch -d
alias l = eza -lbF # list, size, type
alias ll = eza -al # long, list
alias llm = ll --sort=modified # list, long, sort by modification date
alias la = eza -lbhHigUmuSa # all list
alias lx = eza -lbhHigUmuSa@ # all list and extended
alias lS = eza -1 # just names
alias search = rg -F --hidden --max-columns=120
alias searchAround = rg --hidden --max-columns=120 -C
alias tree = broot -sdp
alias cat = bat
alias rvimtmp = rm -i `find . | grep .swp$`
alias searchFiles = fd
alias du = ncdu --color dark -rr -x --exclude .git --exclude node_modules
alias top = glances
alias calendar = rusti-cal
alias cal = calendar
alias weather = curl https://v2d.wttr.in/~oak+grove+missouri?u
alias has = curl -sL https://git.io/_has | bash -s
alias ps = procs
alias dict = sdcv
alias nnn = yazi # yazi is faster with better controls and everything built in
alias tv = tidy-viewer # an easy way to preview csv files like xsv
alias disk = duf # better version of df (disk free)

# Setup extra things
source ~/.zoxide.nu
source ~/.local/share/atuin/init.nu
source ~/.cache/carapace/init.nu
mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

use '/home/nate/.config/broot/launcher/nushell/br' *
