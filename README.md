# Dot-Files
Configuration files for VIM, Tmux and more

## Minimalistic and Documented
I try to make sure that all of my configuration files are documented in the case that myself or others don't remember what certain things do. This is particularly helpful with vim commands that aren't used so often or just simple refreshing oneself.

## Setting Up Digital Ocean

After initialization of the server, we need access to root.

> Click on reset root password

You will receive an email with a password

> Click on login to console

> Use `root` for username

> Use the emailed password for password

> Enter emailed password again, then enter new password followed by confirmation

```
adduser test
gpasswd -a test sudo
```

Then on the client, use that username and password to copy the ssh key to the server
```
ssh-copy-id test@SERVER_IP_ADDRESS
```

## Setting Up Node on Debian-based OS
```
curl -sL https://deb.nodesource.com/setup_5.x | sudo -E bash -
sudo apt-get install -y nodejs build-essential
```
## Basic Vim setup on Debian-based OS
```
sudo apt-get update
sudo apt-get install vim tmux git
git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
```
Then replace the existing `~/.vimrc` with the one in this repository
## Switching to Zsh with theme
```
sudo apt-get install zsh
chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
```
Then replace the existing `~/.zshrc` with the one in this repository
