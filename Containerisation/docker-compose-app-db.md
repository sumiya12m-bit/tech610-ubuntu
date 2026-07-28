# Docker Compose - Run TicTacToe App and MongoDB Together

---

## What is Docker Compose?

Docker Compose is a tool that lets you define and run multiple containers at the same time using a single configuration file called `docker-compose.yml`. Instead of running multiple `docker run` commands manually, you describe all your services in one file and start everything with one command:

```bash
docker compose up -d
```

### Why Use Docker Compose?

Without Docker Compose:
- Run MongoDB container manually
- Wait for it to start
- Run app container manually
- Set environment variables manually
- Remember to link them together

With Docker Compose:
- Write one docker-compose.yml file
- Run one command
- Everything starts automatically in the right order

---

## Folder Structure
```
tech610-docker/
└── docker-compose-app-db/
└── docker-compose.yml
```
---

## Step 1 - Create the Folder

```bash
mkdir ~/tech610-docker/docker-compose-app-db
cd ~/tech610-docker/docker-compose-app-db
```

---

## Step 2 - Create the docker-compose.yml

```bash
nano docker-compose.yml
```

---

## The docker-compose.yml File

### Version 1 - Basic (no automatic seeding)

```yaml
version: "3.8"

services:

  mongo:
    image: mongo:8.0
    container_name: mongo
    ports:
      - "27017:27017"
    volumes:
      - mongo-data:/data/db

  app:
    image: sumiya12m/tech610-tttapp:1.2.0
    container_name: ttt-app
    ports:
      - "3000:3000"
    environment:
      - MONGODB_URI=mongodb://mongo:27017/tic-tac-toe
    depends_on:
      - mongo

volumes:
  mongo-data:
```

### Version 2 — With Automatic Seeding

```yaml
version: "3.8"

services:

  mongo:
    image: mongo:8.0
    container_name: mongo
    ports:
      - "27017:27017"
    volumes:
      - mongo-data:/data/db

  app:
    image: sumiya12m/tech610-tttapp:1.2.0
    container_name: ttt-app
    ports:
      - "3000:3000"
    environment:
      - MONGODB_URI=mongodb://mongo:27017/tic-tac-toe
    depends_on:
      - mongo
    command: sh -c "node index.js & sleep 5 && node seeds/seed.js && wait"

volumes:
  mongo-data:
```

---

## docker-compose.yml Explained

### services

Defines all the containers you want to run. We have two services — mongo and app.

### mongo service

**image: mongo:8.0**
Uses the official MongoDB Docker image version 8.0. This matches the MongoDB version we used throughout the bootcamp (8.2.5). No need to install MongoDB manually - it comes pre-installed in this image.

**container_name: mongo**
Gives the container a fixed name. This is important because the app uses this name in the connection string - mongodb://mongo:27017. Docker uses container names as hostnames within the same network so the app can find the database by the name mongo.

**ports: "27017:27017"**
Maps port 27017 on your machine to port 27017 inside the container. This is the default MongoDB port.

**volumes: mongo-data:/data/db**
Creates a named volume called mongo-data that persists MongoDB data at /data/db inside the container. This means if you stop and restart the containers your data is still there - it doesn't get wiped.

### app service

**image: sumiya12m/tech610-tttapp:1.2.0**
Uses the TicTacToe app image we built and pushed to Docker Hub in the previous task. Docker pulls this automatically if it's not already local.

**container_name: ttt-app**
Gives the container a fixed name so we can reference it easily in docker exec commands.

**ports: "3000:3000"**
Maps port 3000 on your machine to port 3000 inside the container where the Node.js app runs.

**environment: MONGODB_URI**
Sets the environment variable the app needs to connect to MongoDB. Instead of using an IP address we use the container name mongo - Docker automatically resolves this to the MongoDB container's internal IP address.

```
mongodb://mongo:27017/tic-tac-toe
            │      │       │
        container  port   database name
        name
```

**depends_on: mongo**
Tells Docker Compose to start the mongo container before the app container. Without this the app might try to connect to MongoDB before it's ready.

**command (Version 2 only)**
```
sh -c "node index.js & sleep 5 && node seeds/seed.js && wait"
```
Breaking this down:
- node index.js & - starts the app in the background so the next commands can run
- sleep 5 - waits 5 seconds to give the app time to fully start and connect to MongoDB
- node seeds/seed.js - seeds the database with 10 records
- wait - keeps the shell alive so the container doesn't exit after seeding

### volumes

Defines named volumes that persist data. mongo-data is created automatically by Docker and survives container restarts.

---

## Step 3 - Run the Containers

```bash
docker compose up -d
```

- docker compose — the Docker Compose command
- up — start all services defined in docker-compose.yml
- -d — detached mode, runs in the background

You should see:
```
✔ Container mongo     Started
✔ Container ttt-app   Started
```
---

## Step 4 - Verify Both Containers Are Running

```bash
docker ps
```

You should see both mongo and ttt-app listed with status Up.

---

## Step 5 - Test the App

Visit in your browser:
```
http://localhost:3000
```
The TicTacToe app should load and be connected to MongoDB.

---

## Step 6 - Seed the Database

### Method 1 - Manually (using docker exec)

Docker exec lets you run a command inside a running container without SSHing into it:

```bash
docker exec -it ttt-app node seeds/seed.js
```

Breaking this down:
- docker exec — run a command in a running container
- -it — interactive terminal so you can see the output
- ttt-app — the name of the container to run the command in
- node seeds/seed.js — the command to run inside the container

You should see:
```
Seeded active app state via /api/seed (10 records).
```
Refresh http://localhost:3000 — you should see data populated.

### Method 2 - Automatically (using command in docker-compose.yml)

Update the app service in docker-compose.yml to add the command line:

```yaml
command: sh -c "node index.js & sleep 5 && node seeds/seed.js && wait"
```

Then restart:

```bash
docker compose down
docker compose up -d
```

The database seeds automatically every time the containers start — no manual step needed.

---

## Step 7 - Check MongoDB bindIp

With the official MongoDB Docker image you do NOT need to change the bindIp. Unlike when installing MongoDB on a VM where bindIp defaults to 127.0.0.1 (localhost only), the Docker image already accepts connections from any IP by default.

You can verify the MongoDB version inside the container:

```bash
docker exec -it mongo mongod --version
```

Note: The /etc/mongod.conf file does not exist in the Docker image - configuration is handled differently from a VM installation.

---

## Stopping and Starting the Containers

### Stop all containers
```bash
cd ~/tech610-docker/docker-compose-app-db
docker compose down
```

This stops and removes both containers but your MongoDB data is safe - it's stored in the mongo-data volume which persists even when containers are removed.

### Start everything back up again
```bash
cd ~/tech610-docker/docker-compose-app-db
docker compose up -d
```

One command brings everything back up exactly as it was - the app, the database, and the connection between them. Because of the volume your data is still there from before.

### The beauty of Docker Compose
```
docker compose up -d    ← everything starts
docker compose down     ← everything stops (data safe)
docker compose up -d    ← everything back up (data still there)
```
No manual steps, no remembering which containers to start in which order, no worrying about losing data. One command does it all.

---

## Useful Commands

| Command | What it does |
|---|---|
| docker compose up -d | Start all services in background |
| docker compose down | Stop and remove all containers |
| docker compose logs | View logs from all services |
| docker compose logs app | View logs from app service only |
| docker ps | List running containers |
| docker exec -it ttt-app sh | Open a shell inside the app container |
| docker exec -it mongo sh | Open a shell inside the mongo container |
| docker exec -it ttt-app node seeds/seed.js | Seed the database manually |

---

## Blocker - App Container Kept Stopping

### Problem
When using the automatic seeding command the app container kept stopping after seeding. docker ps only showed the mongo container running.

### Why it Happened
The command was:
```
sh -c "node index.js & sleep 5 && node seeds/seed.js"
```
After node seeds/seed.js finished the shell had nothing left to do and exited - taking the container with it. Even though node index.js was running in the background, when the shell exited Docker stopped the container.

### Fix
Added wait at the end to keep the shell alive:
```
sh -c "node index.js & sleep 5 && node seeds/seed.js && wait"
```
wait tells the shell to keep running until all background processes finish - since node index.js runs forever the container stays up.

---

## Key Lessons Learned

- Docker Compose manages multiple containers with one file and one command
- Container names act as hostnames within the same Docker network - use the container name in connection strings instead of IP addresses
- depends_on controls startup order - always start the database before the app
- Volumes persist data across container restarts - without a volume your database is wiped every time you run docker compose down
- docker exec lets you run commands inside containers without SSHing in
- The official MongoDB Docker image does not need bindIp configuration - it accepts connections from any IP by default
- wait is needed to keep a container alive when the main process runs in the background