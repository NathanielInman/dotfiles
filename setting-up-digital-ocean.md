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
