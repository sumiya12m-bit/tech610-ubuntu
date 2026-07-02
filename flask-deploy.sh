#!/bin/bash

# ── System Update ──────────────────────────────────────
sudo apt update -y
sudo apt upgrade -y

# ── Install nginx ──────────────────────────────────────
sudo apt install nginx -y

# ── Configure Nginx as Reverse Proxy ──────────────────
sudo sed -i 's|try_files $uri $uri/ =404;|proxy_pass http://localhost:5000;|' \
  /etc/nginx/sites-available/default

sudo nginx -t
sudo systemctl restart nginx

# ── Install Python & pip ───────────────────────────────
sudo apt install python3 python3-pip python3-venv -y

# ── Set up virtual environment ─────────────────────────
cd /home/ubuntu
python3 -m venv venv
source venv/bin/activate

# ── Install dependencies ───────────────────────────────
pip install -r requirements.txt

# ── Start app with Gunicorn ────────────────────────────
gunicorn --bind 0.0.0.0:5000 flask_app:app --daemon