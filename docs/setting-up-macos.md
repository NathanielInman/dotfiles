## Setting Up MacOS

We need homebrew first as it's our main package manager
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
Now we can install some basic apps
- `diff-so-fancy`: git diffs look more beautiful
- `htop`: alternative to `top` command that's more robust
- `exa`: alternative to `ls` command that supports better colors and is faster
- `bat`: alternative to `cat` command with colors & better perf
- `fd`: alternative to `find` command except much faster
- `ripgrep`: search tool to find text within files, very fast
- `git`: every modern devs version control system, absolutely required
- `vim`: my preferred ide when not using neovim (gvim on linux)
- `zsh`: more robust than bash, fish-like conveniences with bash support
- `tmux`: any laymans terminal multiplexer, i use screen hotkeys predominately
- `python`: needed for data engineering & science, also req for many tools
- `reattach-to-user-namespace`: required for tmux to reclaim sessions
- `fzf`: fuzzy finder tool to help jumping around the system
- `zoxide`: a better way of using [cd](https://github.com/ajeetdsouza/zoxide)
- `pyenv`: python version management tool
- `broot`: a command similar to `tree` to quickly visualize directories
```
brew install diff-so-fancy htop exa bat fd ripgrep git vim zsh tmux python reattach-to-user-namespace fzf zoxide pyenv broot
```
Now we install `n` for managing node instead of using brew
```
curl -L https://git.io/n-install | bash
```
Now we update our python node package managers
```
pip3 install --upgrade pip
npm install -g npm npm-check-updates
```
Now for installing tmux package manager
```
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```
After doing so, we can copy `.tmux.conf` to the home directory.
```
curl https://raw.githubusercontent.com/NathanielInman/Dot-Files/master/.tmux.conf -o ~/.tmux.conf
curl https://raw.githubusercontent.com/NathanielInman/Dot-Files/master/.tmux.defaultLayout.conf -o ~/.tmux.defaultLayout.conf
```
Now for installing vim package manager
```
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
```
Now that Vundler is installed, we can copy the `.vimrc` to the home directory and install plugins.
```
curl https://raw.githubusercontent.com/NathanielInman/Dot-Files/master/.vimrc -o ~/.vimrc
vim +PluginInstall +qall
```
Now for configuring the shell.
```
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
```
Lets ensure that zsh will have fish-like syntax highlighting & autocompletion
```
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```
Download the personal theme to use with oh-my-zsh
```
curl https://raw.githubusercontent.com/NathanielInman/Dot-Files/master/.oh-my-zsh/themes/pragmata.zsh-theme -o ~/.oh-my-zsh/themes/pragmata.zsh-theme
```
Now finally set up your zsh run commands file with the better one here.
```
curl https://raw.githubusercontent.com/NathanielInman/Dot-Files/master/.zshrc -o ~/.zshrc
```
To have the theme available in the current terminal, source it up.
```
source ~/.zshrc
```
