# Docker — Run TicTacToe App in a Container

---

## Aim

Run the Sparta TicTacToe Node.js app inside a Docker container and push the image to Docker Hub so anyone can run it with one command.

---

## Repo

- Docker learning repo: https://github.com/sumiya12m-bit/tech610-docker
- Folder: docker-run-sparta-app

---

## Folder Structure
```
tech610-docker/
└── docker-run-sparta-app/
├── Dockerfile
└── app/
├── index.js
├── server.js
├── package.json
├── package-lock.json
├── app.js
├── logger.js
├── metrics.js
├── styles.css
├── public/
├── seeds/
└── test/
```
---

## The Dockerfile

```dockerfile
# FROM which image
FROM node:20-alpine

# set working dir to "app" folder in container
WORKDIR /app

# COPY everything first — needed before npm ci
# because package.json contains a postinstall script
# that runs seeds/seed.js which must exist first
COPY app/ .

# run npm ci for production
RUN npm ci --omit=dev

# use "node" user for security
USER node

# expose app on port 3000
EXPOSE 3000

# run the node app using index.js
CMD ["node", "index.js"]
```

---

## Dockerfile Explained Line by Line

**FROM node:20-alpine**
Uses the official Node.js 20 image based on Alpine Linux as the base. Alpine is a very lightweight Linux distribution — it keeps the image size small which means faster builds and pulls.

**WORKDIR /app**
Sets the working directory inside the container to /app. All subsequent commands run from this location. If the folder doesn't exist Docker creates it automatically.

**COPY app/ .**
Copies everything from the local app folder into the container's working directory (/app). This must happen before npm ci because the package.json contains a postinstall script that runs seeds/seed.js — if only package.json is copied first the seeds folder won't exist and npm ci will fail.

**RUN npm ci --omit=dev**
Installs dependencies using npm ci (Clean Install):
- Deletes node_modules and reinstalls from scratch
- Uses exact versions from package-lock.json — never updates it
- --omit=dev skips development dependencies — keeps the image smaller and more secure
- Guarantees identical dependencies every build

**USER node**
Switches from the root user to the built-in node user. Running as root inside a container is a security risk — if someone exploits the app they'd have root access to the container. Using the node user limits what they can do.

**EXPOSE 3000**
Documents that the app listens on port 3000. This doesn't actually publish the port — that's done with -p when running the container. It's documentation for anyone reading the Dockerfile.

**CMD ["node", "index.js"]**
The command that runs when the container starts. Uses node to run index.js which is the entry point of the TicTacToe app.

---

## Commands Used

### Build the image
```bash
docker build -t sumiya12m/tech610-tttapp:1.2.0 .
```

Breaking down the command:
- docker build — build an image from the Dockerfile
- -t sumiya12m/tech610-tttapp:1.2.0 — tag the image with dockerhub-username/image-name:version
- . — use the Dockerfile in the current directory

### Run the container
```bash
docker run -d -p 3000:3000 sumiya12m/tech610-tttapp:1.2.0
```

Breaking down the command:
- -d — run in detached mode (background)
- -p 3000:3000 — map port 3000 on your machine to port 3000 inside the container

### Verify it's running
```bash
docker ps
```

Visit in browser: http://localhost:3000

### Push to Docker Hub
```bash
docker push sumiya12m/tech610-tttapp:1.2.0
```

### Run command to share with anyone
```bash
docker run -d -p 3000:3000 sumiya12m/tech610-tttapp:1.2.0
```

---

## Blocker — npm ci Failing During Build

### Problem
The initial Dockerfile copied only package.json and package-lock.json before running npm ci:

```dockerfile
COPY app/package.json app/package-lock.json ./
RUN npm ci --omit=dev
```

This caused the following error:
```
npm error command sh -c node seeds/seed.js
npm error code 1
npm error command failed
```
### Why it Failed
The package.json contains a postinstall script:

```json
"postinstall": "node seeds/seed.js"
```

This script runs automatically after npm ci completes. It needs seeds/seed.js to exist — but because only package.json and package-lock.json had been copied at that point, the seeds folder didn't exist yet and the script failed.

### Fix
Copy all app files first before running npm ci so the seeds folder is available:

```dockerfile
COPY app/ .
RUN npm ci --omit=dev
```

This ensures everything the postinstall script needs is already in the container before npm ci runs.

---

## Key Lessons Learned

- Always copy files your scripts need before running npm ci or npm install
- node:20-alpine keeps the image small — use Alpine-based images where possible
- USER node is a security best practice — never run Node.js apps as root in production
- --omit=dev excludes development dependencies — keeps production images lean and secure
- EXPOSE is documentation only — actual port publishing happens with -p at runtime
- npm ci is preferred over npm install in Docker builds — it's faster and guarantees identical installs every time