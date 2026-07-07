# Tech 610 — AWS 2-Tier App Deployment Documentation

## Overview

This documents the full process of deploying a 2-tier TicTacToe application on AWS. We progressed through 4 stages, starting from manually running scripts all the way to fully automated image-based deployment where everything spins up with zero manual steps.

A **2-tier architecture** means the application is split across two separate virtual machines:
- **App VM** — runs the TicTacToe Node.js application and nginx web server
- **DB VM** — runs the MongoDB database that stores the app's data

They communicate with each other over AWS's internal private network.

### Architecture

Internet
│
▼
App VM (Ubuntu 24)
├── nginx (port 80) ← reverse proxy
├── TicTacToe Node.js app (PM2, port 3000)
└── MONGODB_URI → DB VM private IP:27017
│
│ private network
▼
DB VM (Ubuntu 24)
└── MongoDB 8.2.5 (bindIp: 0.0.0.0, port 27017)

---

## Security Group Rules

Security groups act as virtual firewalls — they control what traffic is allowed in and out of each VM. Each VM has its own security group with different rules because they serve different purposes.

### App VM
| Port | Protocol | Source | Purpose |
|---|---|---|---|
| 22 | SSH | My IP only | Secure terminal access |
| 80 | HTTP | 0.0.0.0/0 | nginx web server — users visit this |
| 3000 | TCP | 0.0.0.0/0 | Node.js app direct access |

### DB VM
| Port | Protocol | Source | Purpose |
|---|---|---|---|
| 22 | SSH | My IP only | Secure terminal access |
| 27017 | TCP | 0.0.0.0/0 | MongoDB — app VM connects on this port |

---

## Key Concepts

### What is a Reverse Proxy?
Nginx sits in front of the app and forwards incoming requests to it. Users visit port 80 (the standard web port) and nginx silently forwards the request to the app running on port 3000. The user never needs to know which port the app is on.

User → http://<ip>:80 → nginx → forwards to → localhost:3000 → TicTacToe app

### Why Use the Private IP for MongoDB?
AWS gives every EC2 instance two IP addresses:
- **Public IP** — changes every time you stop and start the VM
- **Private IP** — stays the same, used for communication between VMs inside AWS

Always use the **private IP** in your `MONGODB_URI` so the connection doesn't break when the VM restarts.

### Why bindIp: 0.0.0.0?
By default MongoDB only accepts connections from the same machine (`127.0.0.1` = localhost). Changing to `0.0.0.0` means MongoDB will accept connections from any IP address — which is needed so the app VM can connect to it remotely.

### Why PM2 Instead of npm start?
`npm start` stops running the moment you close the terminal or disconnect from SSH. PM2 runs the app as a background daemon — it keeps running after you disconnect and automatically restarts the app if it crashes.

### Why User Data Scripts Run from / (Root)
Scripts run via User Data execute from the `/` directory, not `/home/ubuntu`. Always use absolute paths:
```bash
cd /tech610-tic-tac-toe/app  ✅ correct
cd ~/tech610-tic-tac-toe/app ❌ won't work in User Data
```

---

## Stage 1 — Provision MongoDB with a Bash Script

### What We Did
Manually provisioned a MongoDB 8.2.5 database on a fresh Ubuntu 24 VM using a bash script.

### prov-db.sh
```bash
#!/bin/bash

## TESTED: 6/7/2026
## TESTED BY: Ramon
## TESTED ON: AWS, Ubuntu 24.04 LTS, t3.micro
## AIM: Work as a script + user data on fresh Ubuntu 24.04 LTS VM
## PURPOSE: Provision MongoDB 8.2.5 for TTT app

echo update the sources list...
sudo apt-get update -y
echo Done!

echo upgrade any packages available...
sudo apt-get upgrade -y
echo Done!

echo install GPG key...
curl -fsSL https://pgp.mongodb.com/server-8.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg \
   --dearmor
echo Done!

echo create list file...
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.2.list
echo Done!

echo update the sources list...
sudo apt-get update
echo Done!

echo install MongoDB...
sudo apt-get install -y \
   mongodb-org=8.2.5 \
   mongodb-org-database=8.2.5 \
   mongodb-org-server=8.2.5 \
   mongodb-mongosh \
   mongodb-org-shell=8.2.5 \
   mongodb-org-mongos=8.2.5 \
   mongodb-org-tools=8.2.5 \
   mongodb-org-database-tools-extra=8.2.5
echo Done!

echo configure bindIp...
sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf
echo Done!

echo enable MongoDB...
sudo systemctl enable mongod
echo Done!

echo start MongoDB...
sudo systemctl start mongod
echo Done!
```

### What Each Step Does

- **apt update & upgrade** — Refreshes Ubuntu's list of available packages and upgrades any outdated ones. Always done first to ensure you're working with the latest software.
- **GPG key** — Downloads MongoDB's official security key so Ubuntu can verify MongoDB packages are genuine and haven't been tampered with.
- **List file** — Adds MongoDB's official package repository to Ubuntu's software sources. The `noble` codename refers to Ubuntu 24.04 LTS.
- **Second apt update** — Runs again after adding the MongoDB repository so Ubuntu can register the new source and find the packages.
- **Install MongoDB** — Installs MongoDB 8.2.5 and all components. Pinned to `=8.2.5` to ensure a consistent, tested version is always installed.
- **bindIp sed command** — Automatically finds and replaces `bindIp: 127.0.0.1` with `bindIp: 0.0.0.0` in the MongoDB config file so it accepts remote connections.
- **enable** — Tells Ubuntu to automatically start MongoDB on every reboot.
- **start** — Starts MongoDB immediately so it's ready straight away.

### How to Test
```bash
# Check MongoDB is running
sudo systemctl status mongod

# Verify bindIp is set correctly
sudo cat /etc/mongod.conf | grep bindIp
# Should return: bindIp: 0.0.0.0

# Check MongoDB version
mongod --version
```

### Testing the sed Command
```bash
# Make a backup first
sudo cp /etc/mongod.conf /etc/mongod.conf.bak

# Run the sed command
sudo sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf

# Verify it worked
sudo cat /etc/mongod.conf | grep bindIp

# Restore backup to test again on a clean file
sudo cp /etc/mongod.conf.bak /etc/mongod.conf
```

---

## Stage 2 — Automate 2-Tier App Deployment with Bash Scripts

### What We Did
Connected the TicTacToe app to MongoDB by adding the `MONGODB_URI` environment variable to the app script. App VM automated with User Data, DB VM still run manually.

### What is MONGODB_URI?
An environment variable that tells the Node.js app where to find the MongoDB database:

mongodb://172.31.53.27:27017/tic-tac-toe
│           │          │       │
protocol   private IP   port   database name

### tictactoe.sh (App Script)
```bash
#!/bin/bash

# ── System Update
sudo apt update -y
sudo apt upgrade -y

# ── Install nginx
sudo apt install nginx -y

# ── Configure Nginx as Reverse Proxy
sudo sed -i 's|try_files $uri $uri/ =404;|proxy_pass http://localhost:3000;|' /etc/nginx/sites-available/default
sudo nginx -t
sudo systemctl restart nginx

# ── Install Node.js v20
curl -sL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh
sudo bash nodesource_setup.sh
sudo apt install nodejs -y

# ── Clone the app from GitHub
git clone https://github.com/davidrichardharvey/tech610-tic-tac-toe

# ── Install dependencies and start the app
cd /tech610-tic-tac-toe/app
sudo npm install pm2 -g
npm install

# ── Set MongoDB connection string
export MONGODB_URI=mongodb://<db-private-ip>:27017/tic-tac-toe

pm2 kill
pm2 start index.js
```

### Important Notes
- `MONGODB_URI` must be exported **before** `pm2 start` — the app needs to know where the database is before it launches
- Always use the DB VM's **private IP** not the public IP
- Use absolute path `cd /tech610-tic-tac-toe/app` because User Data runs from `/`
- nginx is configured before the app starts so the reverse proxy is ready immediately

### How to Verify
```bash
# Check app is running
pm2 status

# Check MONGODB_URI was picked up
pm2 env 0

# Check nginx is running
sudo systemctl status nginx

# Test reverse proxy locally
curl http://localhost:80
```

### Deliverable
> "DB script works, app run manually"

---

## Connecting the App to the Database

### Steps to Connect
1. Make sure the **DB VM is running first**
2. Set the environment variable with the DB VM's private IP:
```bash
export MONGODB_URI=mongodb://<db-private-ip>:27017/tic-tac-toe
```
3. Start the app:
```bash
pm2 start index.js
```

### Important
The DB VM just stores data — it doesn't show anything in the browser. Only the **App VM public IP** shows the TicTacToe game.

---

## Troubleshooting App Not Connecting to DB

Work through these checks in order — start with the easiest first.

### 1 — Is the database actually running?
```bash
sudo systemctl status mongod
# If not running:
sudo systemctl start mongod
```

### 2 — Is the environment variable set correctly?
```bash
pm2 env 0
# Check it shows the correct private IP
```

### 3 — Is bindIp set correctly on the DB VM?
```bash
sudo cat /etc/mongod.conf | grep bindIp
# Should return: bindIp: 0.0.0.0
```

### 4 — Does the app run without the database?
Visit `http://<app-public-ip>` — if it loads, nginx and PM2 are fine. The issue is specifically the DB connection.

### 5 — Are the DB security group rules correct?
Check in AWS console that port **27017** is open on the DB VM security group.

### General Troubleshooting Advice
- **Be systematic** — work through checks one at a time, don't change multiple things at once
- **Start with the easiest thing** — is the DB running? Is the env variable set? These take seconds to verify
- **Think about what's most likely** — wrong IP, missing env variable, MongoDB not running, or security group blocking the connection

---

## Stage 3 — Automate 2-Tier App Deployment with User Data

### What We Did
Both DB VM and App VM fully automated using User Data — zero manual steps required.

### Process
1. Launch fresh DB VM with `prov-db.sh` pasted into User Data
2. Wait 3-5 minutes for script to complete
3. Note the new DB VM private IP from AWS console
4. Update `MONGODB_URI` in `tictactoe.sh` with new DB private IP
5. Launch fresh App VM with updated `tictactoe.sh` pasted into User Data
6. Wait 3-5 minutes
7. Visit `http://<app-public-ip>` — app live with no manual steps

### Where to Find User Data Logs
```bash
sudo cat /var/log/cloud-init-output.log
```

### Troubleshooting Checklist
| Issue | Check | Fix |
|---|---|---|
| App not loading | `pm2 status` | `pm2 start index.js` |
| MongoDB not running | `sudo systemctl status mongod` | `sudo systemctl start mongod` |
| Wrong bindIp | `sudo cat /etc/mongod.conf \| grep bindIp` | Run sed command manually |
| Can't connect to DB | `curl http://<db-private-ip>:27017` | Check security group port 27017 |
| Wrong IP in URI | `pm2 env 0` | Update private IP and restart |
| Script path issues | Check paths use `/` not `~/` | Use absolute paths in User Data |

### Deliverable
> "DB + app both run with user data only"

---

## Stage 4 — Automate 2-Tier App Deployment with Images

### What We Did
Created custom AMIs from working VMs so new instances launch pre-configured — much faster and more reliable than running full scripts every time.

### What is an AMI?
A snapshot of a fully configured VM. When you launch a new instance from an AMI it starts exactly as it was when the snapshot was taken — all software installed, all config done.

### Why Images are Better Than Full Scripts
| | Full Script (Stage 3) | Image (Stage 4) |
|---|---|---|
| Boot time | 5-10 minutes | 1-2 minutes |
| Reliability | Depends on internet and repos | Pre-installed, always works |
| Script size | Full installation script | Tiny start script only |
| Consistency | Can vary if packages update | Always identical |

### Step 1 — Create the DB Image
1. EC2 dashboard → select running DB VM
2. **Actions → Image and templates → Create image**
3. Name: `tech610-sumiya-ready-to-run-tictactoe-db-image`
4. Click **Create image**
5. Wait for AMI to appear under **EC2 → AMIs**

### Step 2 — Launch DB VM from Image
1. **EC2 → AMIs** → select DB image
2. **Launch instance from AMI**
3. t3.micro, ports 22 and 27017 open
4. No User Data needed — everything already installed
5. Note the new private IP

### Step 3 — run-app-only.sh
Tiny script because everything is already installed on the app image:

```bash
#!/bin/bash

# ── Set MongoDB connection string
export MONGODB_URI=mongodb://<new-db-private-ip>:27017/tic-tac-toe

# ── Start the app
cd /tech610-tic-tac-toe/app
pm2 kill
pm2 start index.js
```

### Step 4 — Launch App VM from App Image
1. **EC2 → AMIs** → select app image
2. **Launch instance from AMI**
3. t3.micro, ports 22, 80, 3000 open
4. Paste `run-app-only.sh` into User Data
5. Launch and visit `http://<app-public-ip>`

### Deliverable
> "DB + app both run with images only"

---

## Progression Summary

| Stage | DB VM Setup | App VM Setup | Manual Steps |
|---|---|---|---|
| Stage 1 | Manual bash script | Not automated | SSH in and run script |
| Stage 2 | Manual bash script | User Data full script | DB still manual |
| Stage 3 | User Data full script | User Data full script | None |
| Stage 4 | Launch from image | Launch from image + tiny script | None |

---

## Scripts Summary

| Script | Purpose | When Used |
|---|---|---|
| `prov-db.sh` | Fully provisions MongoDB on a fresh VM | Stages 1, 2, 3 |
| `tictactoe.sh` | Fully provisions and starts the app on a fresh VM | Stages 2, 3 |
| `run-app-only.sh` | Just starts the app — everything already installed | Stage 4 with app image |