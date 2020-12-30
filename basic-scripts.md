## Basic Scripts
There's commonly a lot of simple tasks one needs to complete with shell scripts from deploying, packaging or monitoring applications. These are helpful notes and bash commands I commonly use to accomplish these tasks.

### Packaging
Package the distribution folder into a tarball
```
cd distFolder && tar -czvf ../dist.tar.gz . && cd ..
```
Now we will deploy to the server. Make sure to replace `$username` and `$serverip` with the correct values
```
user=$(whoami)
rsync -avhtz -e 'ssh -i /Users/$user/.ssh/id_rsa' dist.tar.gz $username@$serverip:./
```
Now for extracting the package on the server, don't forget to replace `/var/opt/applicationName` with where you want the package to go as well as `$username` and `$serverip` with the correct values. It creates the destination folder if it doesn't exist, and then extracts the package to that destination folder, removes the package and exits the server.
```
ssh -i ~/.ssh/id_rsa $username@$serverip "sudo mkdir -p /var/opt/applicationName;sudo tar -C /var/opt/applicationName -zxvf dist.tar.gz;rm dist.tar.gz"
```
Alternatively you can use a `here document` if you have a lot of commands, to improve readability
```
ssh -i ~/.ssh/id_rsa $username@$serverip << EOF
  sudo mkdir -p /var/opt/applicationName
  sudo tar -C /var/opt/applicationName -zxvf dist.tar.gz
  rm dist.tar.gz
EOF
```

### Deploying
First we need to add a watcher that will restart our application when it crashes. Make sure to change `index.js` to the entry javascript file of the application that you would normally start with `node fileName.js`.
```
sudo npm install pm2 -g
pm2 start index.js
```
Now we need to add a startup script so when the server restarts for any reason we can start the application automatically. Make sure to replace `ubuntu` with the proper linux distro. For additional information refer to `pm2 -h` for help.
```
pm2 startup ubuntu
```
This will output a command, run the command supplied to generate and initiate the script.

### Monitoring Application
The following will get uptime statistics and restart information for the application.
```
pm2 info appName
```
The following will monitor realtime statics for the CPU 
```
pm2 monit
```

### Reverse Proxy
The following will help allow public users to access the application. It will use a generic nginx location block.
```
sudo apt-get install nginx
sudo vim /etc/nginx/sites-available/default
```
replace the entire contents with the following, while replacing the ip dictated and the domain if one is already allocated to the application.
```
server {
  listen 80;

  server_name applicationDomain.com;

  location / {
    proxy_pass http://APP_IP_ADDRESS:8080;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
  }
}
```
After finished restart the nginx server.
```
sudo service nginx restart
```
### Setting Up Mongodb
Start by using the official mongodb repo for apt-get
```
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
echo "deb http://repo.mongodb.org/apt/ubuntu "$(lsb_release -sc)"/mongodb-org/3.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.0.list
sudo apt-get update
```
Now install mongod and make sure it is running okay
```
sudo apt-get install -y mongodb-org
service mongod status
```
### Global Git Ignore
```
git config --global core.excludesfile ~/.gitignore_global
```
