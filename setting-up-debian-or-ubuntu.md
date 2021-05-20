## Setting Up Debian Or Ubuntu
Start with essentials like curl, or allowing numlock to work on boot
```
sudo apt-get install build-essential numlockx
```
Before we start getting into stuff, lets ensure we're not commiting things we shouldn't
```
git config --global core.excludesFile '~/.gitignore'
curl https://raw.githubusercontent.com/NathanielInman/dot-files/master/.gitignore -o ~/.gitignore
```
Now for language tools
```
sudo apt-get install nodejs
```
Now for Vim and package manager
```
sudo apt-get update
sudo apt-get install vim tmux git
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
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
## i3 from scratch
Make basic home folders
```
mkdir ~/Sites #will hold our projects
mkdir ~/Pictures #will hold backgrounds etc
mkdir -p ~/.config/i3
mkdir ~/.config/i3blocks
```
Grab necessary packages for i3
```
sudo add-apt-repository ppa:kgilmer/speed-ricer
sudo apt-get update
sudo apt-get install i3 i3-gaps i3bar i3blocks i3status picom feh lm-sensors
```
Grab the background and set its loader fehbg
```
curl https://raw.githubusercontent.com/NathanielInman/dot-files/master/arch-bg.jpg -o ~/Pictures/arch-bg.jpg
curl https://raw.githubusercontent.com/NathanielInman/Dot-Files/master/arch/fehbg -o ~/.fehbg
```
Grab transparency files for picom and load it
```
curl https://raw.githubusercontent.com/NathanielInman/dot-files/master/arch/.picom.conf -o ~/.picom.conf
```
Grab i3 configurations
```
curl https://raw.githubusercontent.com/NathanielInman/Dot-Files/master/arch/i3.conf -o ~/.config/i3/config
curl https://raw.githubusercontent.com/NathanielInman/Dot-Files/master/arch/i3blocks.conf -o ~/.config/i3blocks/config.conf
```
