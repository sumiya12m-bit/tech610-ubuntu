#!/bin/bash

# ── System Update 
sudo apt update -y
sudo apt upgrade -y

# Install nginx
sudo apt install nginx -y

# ── Configure Nginx as Reverse Proxy 
sudo sed -i 's|try_files $uri $uri/ =404;|proxy_pass http://localhost:3000;|' /etc/nginx/sites-available/default

sudo nginx -t
sudo systemctl restart nginx

# ── Install Node.js v20 
curl -sL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh
sudo bash nodesource_setup.sh
sudo apt install nodejs -y

# ── Install unzip 
sudo apt install unzip -y

# ── Unzip the app 
unzip ~/nodejs20-sparta-tictactoe-v1-2.zip

# ── Install dependencies and start the app 
cd ~/app
sudo npm install pm2 -g
npm install
pm2 kill 
pm2 start index.js
