#!/bin/bash

# ── System Update 
sudo apt update -y
sudo apt upgrade -y

# Install nginx
sudo apt install nginx -y

# ── Install Node.js v20 
curl -sL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh
sudo bash nodesource_setup.sh
sudo apt install nodejs -y

git clone https://github.com/davidrichardharvey/tech610-tic-tac-toe

# ── Install dependencies and start the app 
cd /tech610-tic-tac-toe/app
cd ~/app
sudo npm install pm2 -g
npm install
pm2 kill 
pm2 start index.js

# ── Configure Nginx as Reverse Proxy 
sudo sed -i 's|try_files $uri $uri/ =404;|proxy_pass http://localhost:3000;|' /etc/nginx/sites-available/default

sudo nginx -t
sudo systemctl restart nginx