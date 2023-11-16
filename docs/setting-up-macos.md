## Setting Up MacOS

We need homebrew first as it's our main package manager
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
Now we can install some basic apps
```
brew install diff-so-fancy htop exa bat fd ripgrep git vim zsh tmux python reattach-to-user-namespace
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
curl https://raw.githubusercontent.com/NathanielInman/Dot-Files/master/pragmata.zsh-theme -o ~/.oh-my-zsh/themes/pragmata.zsh-theme
```
Now finally set up your zsh run commands file with the better one here.
```
curl https://raw.githubusercontent.com/NathanielInman/Dot-Files/master/.zshrc -o ~/.zshrc
```
To have the theme available in the current terminal, source it up.
```
source ~/.zshrc
```
