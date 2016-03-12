# Dot-Files
Configuration files for VIM, Tmux and more

## Minimalistic and Documented
I try to make sure that all of my configuration files are documented in the case that myself or others don't remember what certain things do. This is particularly helpful with vim commands that aren't used so often or just simple refreshing oneself.

## Setting Up AWS users
start by going root (aws requires you to login as `ubuntu`), then add your user, followed by adding the ssh key to authorized
```
sudo su -
adduser nate
gpasswd -a nate sudo
exit
sudo su nate
cd ~
mkdir .ssh
chmod 700 .ssh
touch .ssh/authorized_keys
chmod 600 .ssh/authorized_keys
```
then finally paste the ssh key into the `authorized_keys` file, log out and then login with the user.

## Setting Up Digital Ocean

After initialization of the server, we need access to root.

> Click on reset root password

You will receive an email with a password

> Click on login to console

> Use `root` for username

> Use the emailed password for password

> Enter emailed password again, then enter new password followed by confirmation

```
adduser nate
gpasswd -a nate sudo
```

Then on the client, use that username and password to copy the ssh key to the server
```
ssh-copy-id nate@SERVER_IP_ADDRESS
```

## Node Setup (DEBIAN)
```
curl -sL https://deb.nodesource.com/setup_5.x | sudo -E bash -
sudo apt-get install -y nodejs build-essential
```
## Vim Setup (DEBIAN)
```
sudo apt-get update
sudo apt-get install vim tmux git
git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
```
Then replace the existing `~/.vimrc` with the one in this repository
## Zsh Setup (DEBIAN)
```
sudo apt-get install zsh
chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
```
Then replace the existing `~/.zshrc` with the one in this repository

## Packaging and Deploying
Package the distribution folder into a tarball
```
cd distFolder && tar -czvf ../dist.tar.gz . && cd ..
```
Now we will deploy to the server. Make sure to replace `$username` and `$serverip` with the correct values
```
user=$(whoami)
rsync -avhtz -e 'ssh -i /Users/$user/.ssh/id_rsa' dist.tar.gz $username@$serverip:./
```
Now for extracting the package on the server, don't forget to replace `/var/opt/node` with where you want the package to go as well as `$username` and `$serverip` with the correct values.
```
ssh -i ~/.ssh/id_rsa $username@$serverip "sudo tar -C /var/opt/node -zxvf dist.tar.gz;rm dist.tar.gz"
```
