## Setting Up AWS Users
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
