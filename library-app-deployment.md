# Library App (Java-MySQL) : 2-Tier Deployment Documentation

---

## Overview

This documents the full process of deploying the Library Java Spring Boot application with a MySQL database on AWS. The app was deployed across two separate VMs in a 2-tier architecture, progressing through 3 stages of automation.

### App Details
- **Language:** Java (Spring Boot)
- **Database:** MySQL
- **Build tool:** Maven
- **Port:** 5000
- **Test URL:** `http://<app-ip>/web/authors`

---

## Key Differences from TicTacToe Deployment

| | TicTacToe (Node.js) | Library App (Java) |
|---|---|---|
| Language | Node.js | Java |
| Database | MongoDB | MySQL |
| Package manager | npm | Maven |
| Process manager | PM2 | mvn spring-boot:run |
| Port | 3000 | 5000 |
| DB connection | MONGODB_URI | DB_HOST, DB_USER, DB_PASS |
| App VM size | t3.micro | t3.small (needs 2GB RAM) |
| DB VM size | t3.micro | t3.micro |
| DB setup | bindIp change only | Install MySQL + seed with SQL file |

---

## Architecture

```
Internet
│
▼
App VM (Ubuntu 24 - t3.small)
├── nginx (port 80) ← reverse proxy
├── Java Spring Boot app (Maven, port 5000)
└── DB_HOST → DB VM private IP:3306
│
│ private network
▼
DB VM (Ubuntu 24 - t3.micro)
└── MySQL 8.0 (bind-address: 0.0.0.0, port 3306)
└── library database (seeded with library.sql)
```

---

## Security Group Rules

### App VM
| Port | Protocol | Source | Purpose |
|---|---|---|---|
| 22 | SSH | My IP only | Terminal access |
| 80 | HTTP | 0.0.0.0/0 | nginx web server |
| 5000 | TCP | 0.0.0.0/0 | Java app direct access |

### DB VM
| Port | Protocol | Source | Purpose |
|---|---|---|---|
| 22 | SSH | My IP only | Terminal access |
| 3306 | TCP | 0.0.0.0/0 | MySQL database |

---

## Environment Variables

The app uses three environment variables to connect to the database:

| Variable | Description | Example Value |
|---|---|---|
| `DB_HOST` | Connection string | `jdbc:mysql://<db-private-ip>:3306/library` |
| `DB_USER` | MySQL username | `admin` |
| `DB_PASS` | MySQL password | `password123` |

---

## Stage 1 — Manual Deployment

### What We Did
Manually set up both VMs step by step to get the app working for the first time.

### DB VM Setup

**Step 1 — SSH in and install MySQL:**
```bash
sudo apt update -y
sudo apt upgrade -y
sudo apt install mysql-server -y
sudo systemctl start mysql
sudo systemctl enable mysql
```

**Step 2 — Backup and configure MySQL to accept remote connections:**
```bash
sudo cp /etc/mysql/mysql.conf.d/mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf.bak
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
```
Change `bind-address = 127.0.0.1` to `bind-address = 0.0.0.0`

```bash
sudo systemctl restart mysql
```

**Step 3 — Create database user and database:**
```bash
sudo mysql
```
```sql
CREATE USER 'admin'@'%' IDENTIFIED BY 'password123';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%';
FLUSH PRIVILEGES;
CREATE DATABASE library;
EXIT;
```

**Step 4 — SCP the library.sql file from local machine:**
```bash
scp -i ~/.ssh/sumiya-tech610-key.pem ~/Downloads/library-java17-mysql-app/library.sql ubuntu@<db-public-ip>:/home/ubuntu/
```

**Step 5 — Seed the database:**
```bash
sudo mysql library < library.sql
```

**Step 6 — Verify:**
```bash
sudo mysql
```
```sql
USE library;
SELECT * FROM authors;
EXIT;
```
Should return 4 authors ✅

---

### App VM Setup

**Step 1 — SSH in and install dependencies:**
```bash
sudo apt update -y
sudo apt upgrade -y
sudo apt install openjdk-17-jdk -y
sudo apt install maven -y
```

**Step 2 — Install and configure nginx:**
```bash
sudo apt install nginx -y
sudo sed -i 's|try_files $uri $uri/ =404;|proxy_pass http://localhost:5000;|' /etc/nginx/sites-available/default
sudo nginx -t
sudo systemctl restart nginx
```

**Step 3 — SCP the app files from local machine:**
```bash
scp -i ~/.ssh/sumiya-tech610-key.pem -r ~/Downloads/library-java17-mysql-app/LibraryProject2 ubuntu@<app-public-ip>:/home/ubuntu/
```

**Step 4 — Set environment variables:**
```bash
export DB_HOST=jdbc:mysql://<db-private-ip>:3306/library
export DB_USER=admin
export DB_PASS=password123
```

**Step 5 — Run the app:**
```bash
cd ~/LibraryProject2
mvn spring-boot:run
```

Wait for:
```
Tomcat started on port(s): 5000
```
**Step 6 — Test in browser:**
```
http://<app-public-ip>/web/authors
```
Should show 4 authors ✅

### Deliverable 1
> App working manually — link posted to trainer

---

## Stage 2 — Bash Scripts

### What We Did
Automated both VM setups with bash scripts. App files and `library.sql` were pushed to GitHub so scripts could clone them automatically.

### prov-library-db.sh

```bash
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

# ── Clone repo to get library.sql ─────────────────────
git clone https://github.com/sumiya12m-bit/tech610-ubuntu.git

# ── Seed the database ──────────────────────────────────
sudo mysql library < /home/ubuntu/tech610-ubuntu/library.sql
```

### prov-library-app.sh

```bash
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
export DB_HOST=jdbc:mysql://<db-private-ip>:3306/library
export DB_USER=admin
export DB_PASS=password123

# ── Run the app ────────────────────────────────────────
cd ~/tech610-ubuntu/LibraryProject2
mvn spring-boot:run
```

### Blockers and Fixes in Stage 2

**Blocker 1 — Wrong mvn command**
Initially used `mvn spring-boot:start` which requires the app to be pre-built. On a fresh VM this fails because nothing has been compiled yet.

Fix: Changed to `mvn spring-boot:run` which builds and runs in one step.

**Blocker 2 — Wrong file path**
Used `/tech610-ubuntu/library.sql` which fails because scripts run from `/home/ubuntu` not `/`.

Fix: Changed to `/home/ubuntu/tech610-ubuntu/library.sql`

**Blocker 3 — Wrong DB private IP**
The DB private IP changes every time a new VM is launched. The script had a placeholder IP from a previous VM.

Fix: Always check the DB VM private IP in AWS console after launching and update the `DB_HOST` line before running the app script.

### How to Run

**DB VM:**
```bash
scp -i ~/.ssh/sumiya-tech610-key.pem ~/tech610/prov-library-db.sh ubuntu@<db-public-ip>:/home/ubuntu/
ssh -i ~/.ssh/sumiya-tech610-key.pem ubuntu@<db-public-ip>
chmod +x prov-library-db.sh
./prov-library-db.sh
```

**App VM:**
```bash
scp -i ~/.ssh/sumiya-tech610-key.pem ~/tech610/prov-library-app.sh ubuntu@<app-public-ip>:/home/ubuntu/
ssh -i ~/.ssh/sumiya-tech610-key.pem ubuntu@<app-public-ip>
chmod +x prov-library-app.sh
./prov-library-app.sh
```

### Deliverable 2
> Scripts working on fresh VMs — link posted to trainer

---

## Stage 3 — User Data

### What We Did
Pasted both scripts into the User Data section of the AWS launch wizard so both VMs configured themselves automatically on first boot with zero manual steps.

### Process

**DB VM:**
1. Launch fresh EC2 (Ubuntu 24, t3.micro, ports 22 and 3306)
2. Paste `prov-library-db.sh` into User Data
3. Wait 5-10 minutes for script to complete
4. Note the private IP from AWS console

**App VM:**
1. Update `DB_HOST` in `prov-library-app.sh` with new DB private IP
2. Launch fresh EC2 (Ubuntu 24, t3.small, ports 22, 80, 5000)
3. Paste updated `prov-library-app.sh` into User Data
4. Wait 5-10 minutes for script to complete
5. Visit `http://<app-public-ip>/web/authors`

### Where to Find User Data Logs
If something goes wrong:
```bash
sudo cat /var/log/cloud-init-output.log
```

### Blocker — Git Clone Failing in User Data

**Problem:** When running via User Data, the `git clone` command in `prov-library-db.sh` sometimes fails because the network isn't fully initialised when the script reaches that line. This meant the `library.sql` file wasn't available and the database seeding failed.

**Symptom:**
```bash
ls: cannot access '/home/ubuntu/tech610-ubuntu/': No such file or directory
ERROR 1146 (42S02): Table 'library.authors' doesn't exist
```
**Fix applied to script:** Added a `sleep 10` before the git clone to give the network time to initialise:
```bash
# Wait for network to be ready
sleep 10

# Clone repo to get library.sql
git clone https://github.com/sumiya12m-bit/tech610-ubuntu.git
```

**Manual workaround used during testing:**
```bash
git clone https://github.com/sumiya12m-bit/tech610-ubuntu.git
sudo mysql library < ~/tech610-ubuntu/library.sql
```

### Deliverable 3
> DB + app both run with User Data — link posted to trainer

---

## Testing the App

### Web UI
```
http://<app-public-ip>/web/authors      ← view all authors
http://<app-public-ip>/web/author/3      ← view author with id 3
```
### API
```
http://<app-public-ip>/authors            ← returns JSON
http://<app-public-ip>/author/3           ← returns JSON for author 3
```
---

## Troubleshooting

| Issue | Check | Fix |
|---|---|---|
| App not starting | `ps aux \| grep java` | Re-run with correct env variables |
| DB connection failed | Check `DB_HOST` has correct private IP | Update env variable and restart app |
| MySQL not running | `sudo systemctl status mysql` | `sudo systemctl start mysql` |
| bind-address wrong | `sudo cat /etc/mysql/mysql.conf.d/mysqld.cnf \| grep bind-address` | Run sed command manually |
| Authors table missing | `sudo mysql -e "USE library; SHOW TABLES;"` | Re-run `sudo mysql library < library.sql` |
| App port 5000 not responding | `curl http://localhost:5000/web/authors` | Check Maven build completed successfully |
| Git clone failed | `ls ~/tech610-ubuntu/` | Run `git clone` manually |

---

## Scripts Summary

| Script | Purpose | Stage Used |
|---|---|---|
| `prov-library-db.sh` | Installs MySQL, configures, seeds database | Stages 2 and 3 |
| `prov-library-app.sh` | Installs Java, Maven, nginx, runs app | Stages 2 and 3 |
