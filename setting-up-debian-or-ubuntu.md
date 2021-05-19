## Setting Up Debian Or Ubuntu
Start with Node
```
sudo apt install nodejs build-essential
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
chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
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
