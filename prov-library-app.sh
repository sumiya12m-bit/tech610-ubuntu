#!/bin/bash

# ── System Update ──────────────────────────────────────
sudo apt update -y
sudo apt upgrade -y

# ── Install nginx ──────────────────────────────────────
sudo apt install nginx -y

# ── Configure Nginx as Reverse Proxy ──────────────────
sudo sed -i 's|try_files $uri $uri/ =404;|proxy_pass http://localhost:5000;|' /etc/nginx/sites-available/default
sudo nginx -t
sudo systemctl restart nginx

# ── Install Java 17 ───────────────────────────────────
sudo apt install openjdk-17-jdk -y

# ── Install Maven ──────────────────────────────────────
sudo apt install maven -y

# ── Clone repo to get app files ────────────────────────
git clone https://github.com/sumiya12m-bit/tech610-ubuntu.git

# ── Set environment variables ──────────────────────────
export DB_HOST=jdbc:mysql://172.31.62.97:3306/library
export DB_USER=admin
export DB_PASS=password123

# ── Run the app ────────────────────────────────────────
cd ~/tech610-ubuntu/LibraryProject2
mvn spring-boot:run