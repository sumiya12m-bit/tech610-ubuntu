# MongoDB 8.2.5 Provisioning Script — Documentation

Start with `#!/bin/bash` at the start of bash script (used for user data on AWS) so Linux is aware to use bash interpreter.

## Step 1 — Update the Sources List

```bash
echo update the sources list...
sudo apt-get update -y
echo Done!
```

**What it does:** Refreshes Ubuntu's list of available packages from all configured repositories. This ensures the system knows about the latest versions of software before installing anything.

---

## Step 2 — Upgrade Available Packages

```bash
echo upgrade any packages available...
sudo apt-get upgrade -y
echo Done!
```

**What it does:** Upgrades all currently installed packages to their latest versions. The `-y` flag automatically confirms any prompts so the script doesn't pause waiting for user input.

---

## Step 3 — Install the MongoDB GPG Key

```bash
echo install GPG key...
curl -fsSL https://pgp.mongodb.com/server-8.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg \
   --dearmor
echo Done!
```

**What it does:** Downloads MongoDB's official GPG (GNU Privacy Guard) security key and saves it to the system keyring. This key is used to verify that packages downloaded from MongoDB's repository are genuine and haven't been tampered with. Without this, Ubuntu won't trust the MongoDB repository.

---

## Step 4 — Create the MongoDB Repository List File

```bash
echo create list file...
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.2.list
echo Done!
```

**What it does:** Adds MongoDB's official package repository to Ubuntu's list of software sources. This tells Ubuntu where to download MongoDB from. Key parts of this command:

- `arch=amd64,arm64` — works on both Intel/AMD and ARM processors
- `signed-by=` — links to the GPG key installed in Step 3
- `noble` — the codename for Ubuntu 24.04 LTS
- `mongodb-org/8.2` — specifies MongoDB version 8.2

---

## Step 5 — Update the Sources List Again

```bash
echo update the sources list...
sudo apt-get update
echo Done!
```

**What it does:** Runs `apt-get update` again after adding the MongoDB repository in Step 4. This is necessary so Ubuntu can read the new MongoDB repository and make its packages available to install. Without this second update, the MongoDB packages from Step 4 wouldn't be found.

---

## Step 6 — Install MongoDB

```bash
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
```

**What it does:** Installs MongoDB version 8.2.5 and all its required components. Each package has a specific role:

| Package | Purpose |
|---|---|
| `mongodb-org` | Meta package that pulls in all MongoDB components |
| `mongodb-org-database` | The core database engine |
| `mongodb-org-server` | The `mongod` daemon — the main MongoDB server process |
| `mongodb-mongosh` | The modern MongoDB Shell for interacting with the database |
| `mongodb-org-shell` | The legacy MongoDB shell |
| `mongodb-org-mongos` | The MongoDB sharding router (for distributed deployments) |
| `mongodb-org-tools` | Utilities like `mongodump`, `mongorestore`, `mongoexport` |
| `mongodb-org-database-tools-extra` | Additional database tools |

Pinning each package to `=8.2.5` ensures a consistent, tested version is installed rather than whatever the latest happens to be.

---

## What Happens Next

After this script runs successfully, add these steps to fully configure MongoDB:

```bash
# Start the MongoDB service
sudo systemctl start mongod

# Enable MongoDB to start automatically on reboot
sudo systemctl enable mongod

# Verify MongoDB is running
sudo systemctl status mongod
```

Verify the version installed:

```bash
mongod --version
mongosh --version
```