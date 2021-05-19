## Setting Up Debian Or Ubuntu
Start with essentials like curl, or allowing numlock to work on boot
```
sudo apt-get install build-essential numlockx
```
Now for language tools
```
sudo apt-get install nodejs
```
Now for Vim and package manager
```
sudo apt-get update
sudo apt-get install vim tmux git
git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
```
Now that vim and Vundler are installed, we can copy the `.vimrc` to the home directory.
```
curl https://raw.githubusercontent.com/NathanielInman/Dot-Files/master/.vimrc -o ~/.vimrc
```
Finally we setup zsh
```
sudo apt-get install zsh
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
```
Lets ensure that zsh will have fish-like syntax highlighting & autocompletion
```
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```
Download the personal theme to use with oh-my-zsh
```
curl https://raw.githubusercontent.com/NathanielInman/dot-files/master/pragmata.zsh-theme -o ~/.oh-my-zsh/themes/pragmata.zsh-theme
```
Now finally set up your zsh run commands file with the better one here.
```
curl https://raw.githubusercontent.com/NathanielInman/Dot-Files/master/.zshrc -o ~/.zshrc
```
To reacquire the configuration without terminating the current session
```
source ~/.zshrc
```
Now lets add npm global ability
```
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
# now open ~/.zshrc with vim and add "~/.npm-global/bin" to PATH
source ~/.zshrc
```
Now let's add diff-so-fancy and `n` node version manager
```
npm i -g diff-so-fancy n
```
Add fd replacement
```
sudo apt install fd-find
```
