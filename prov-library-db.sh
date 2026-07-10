#!/bin/bash

# ── System Update ──────────────────────────────────────
sudo apt update -y
sudo apt upgrade -y

# ── Install MySQL ──────────────────────────────────────
sudo apt install mysql-server -y

# ── Start and Enable MySQL ─────────────────────────────
sudo systemctl start mysql
sudo systemctl enable mysql

# ── Configure MySQL to accept remote connections ───────
sudo sed -i 's/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

# ── Restart MySQL to apply changes ─────────────────────
sudo systemctl restart mysql

# ── Create database user ───────────────────────────────
sudo mysql -e "CREATE USER 'admin'@'%' IDENTIFIED BY 'password123';"
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%';"
sudo mysql -e "FLUSH PRIVILEGES;"

# ── Create library database ────────────────────────────
sudo mysql -e "CREATE DATABASE library;"

# Wait for network to be ready
sleep 10

# ── Clone repo to get library.sql ─────────────────────
git clone https://github.com/sumiya12m-bit/tech610-ubuntu.git

# ── Seed the database ─────────────────────────────────
sudo mysql library < /home/ubuntu/tech610-ubuntu/library.sql