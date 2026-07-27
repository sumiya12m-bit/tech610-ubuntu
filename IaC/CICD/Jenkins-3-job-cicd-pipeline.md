# Jenkins CI/CD Pipeline — TicTacToe App Documentation

---

## Table of Contents
- [Jenkins CI/CD Pipeline — TicTacToe App Documentation](#jenkins-cicd-pipeline--tictactoe-app-documentation)
  - [Table of Contents](#table-of-contents)
  - [What is CI/CD and Why We Set It Up This Way](#what-is-cicd-and-why-we-set-it-up-this-way)
    - [Without CI/CD](#without-cicd)
    - [With CI/CD](#with-cicd)
  - [Pipeline Diagram](#pipeline-diagram)
  - [Prerequisites](#prerequisites)
  - [Authentication and Security](#authentication-and-security)
    - [Jenkins to GitHub (SSH)](#jenkins-to-github-ssh)
    - [Jenkins to EC2 (SSH)](#jenkins-to-ec2-ssh)
    - [Why SSH Keys Instead of Passwords?](#why-ssh-keys-instead-of-passwords)
    - [Generating the SSH Key Pair for SCM](#generating-the-ssh-key-pair-for-scm)
  - [How the Webhook Works](#how-the-webhook-works)
    - [Setup Steps](#setup-steps)
    - [Trigger Flow](#trigger-flow)
  - [Job 1 — CI Test](#job-1--ci-test)
    - [Configuration](#configuration)
    - [Why npm ci Instead of npm install?](#why-npm-ci-instead-of-npm-install)
  - [Results and Screenshots](#results-and-screenshots)
    - [Pipeline Running Successfully](#pipeline-running-successfully)
    - [Change 1 — Front Page Updated](#change-1--front-page-updated)
    - [Change 2 — Front Page Updated Again](#change-2--front-page-updated-again)
  - [Blockers and How They Were Resolved](#blockers-and-how-they-were-resolved)
    - [Blocker 1 — Job 3 Had No SCM Configured](#blocker-1--job-3-had-no-scm-configured)
    - [Blocker 2 — Tests Failing After Front Page Change](#blocker-2--tests-failing-after-front-page-change)
    - [Blocker 3 — PM2 Serving Cached Old Code](#blocker-3--pm2-serving-cached-old-code)
    - [Blocker 4 — SSH Permission Denied on Local Machine](#blocker-4--ssh-permission-denied-on-local-machine)
  - [Benefits of This Pipeline](#benefits-of-this-pipeline)
    - [Benefits Seen During This Task](#benefits-seen-during-this-task)
    - [Benefits for an Organisation](#benefits-for-an-organisation)

---

## What is CI/CD and Why We Set It Up This Way

CI/CD stands for Continuous Integration and Continuous Deployment. It automates the process of taking code changes from a developer's laptop all the way to a live running application — automatically, reliably, and repeatedly.

### Without CI/CD
```
Developer writes code
│
▼
Manually runs tests (if they remember)
│
▼
Manually merges to main branch
│
▼
Manually deploys to server
│
▼
Hopes nothing breaks
```
### With CI/CD
```
Developer pushes code to dev branch
│
▼
Pipeline triggers automatically
│
├── Job 1: Run tests automatically
│
├── Job 2: Merge to main automatically
│
└── Job 3: Deploy to server automatically
```
Every time someone pushes code the same process runs automatically. No manual steps, no forgetting to test, no deployment errors.

---

## Pipeline Diagram
```
Developer
│
│  git push (dev branch)
▼
GitHub Repository (dev branch)
│
│  Webhook — POST request to Jenkins
▼
Jenkins (Controller / Master Node)
http://34.254.6.118:8080/
│
│  Pulls code using SSH private key
│  (sumiya-jenkins-2-gh-ttt-app)
▼
Agent Node (runs the jobs)
│
├──────────────────────────────────────────────────────┐
│                                                      │
▼                                                      │
Job 1 — CI Test                                           │
├── Clone repo from dev branch                            │
├── Install Node.js dependencies                          │
└── Run automated tests (111 tests)                       │
│                                                      │
├── FAIL → Pipeline stops ❌                           │
│                                                      │
└── PASS → triggers Job 2 ✅                           │
│                                      │
▼                                      │
Job 2 — CI Merge                              │
├── Pull dev branch                           │
└── Merge dev → main (Git Publisher)          │
│                                      │
├── FAIL → Pipeline stops ❌           │
│                                      │
└── PASS → triggers Job 3 ✅           │
│                      │
▼                      │
Job 3 — CD Deploy             │
├── rsync app/ to EC2         │
├── SSH into EC2              │
├── npm install               │
├── pm2 stop all              │
├── pm2 delete all            │
└── pm2 start index.js        │
│                      │
├── FAIL → stops ❌    │
│                      │
└── PASS ✅            │
│              │
▼              │
EC2 Instance ←────────┘
(app live at
http://34.241.30.177)
```
---

## Prerequisites

Before setting up the pipeline the following were already in place:

- Jenkins server running at `http://34.254.6.118:8080/`
- Agent node configured and connected to Jenkins master
- GitHub repo: `https://github.com/sumiya12m-bit/tech610-ttt-app-cicd-jenkins`
- App repo contains TicTacToe app version 1.2 with `app/` folder at the root
- EC2 instance running with app AMI (Node.js, nginx, PM2 pre-installed)
- Dev branch created on the GitHub repo

---

## Authentication and Security

### Jenkins to GitHub (SSH)

An Ed25519 SSH key pair was generated specifically for Jenkins to authenticate with GitHub:

```bash
ssh-keygen -t ed25519 -a 100 -C "jenkins@ttt-scm-3job-cicd"
# key name: sumiya-jenkins-2-gh-ttt-app
```

- **Public key** → added to GitHub repo under Settings → Deploy keys
- **Private key** → added to Jenkins under Manage Jenkins → Credentials
  - Kind: SSH Username with private key
  - ID: sumiya-jenkins-2-gh-ttt-app

This allows Jenkins to securely clone and pull from the GitHub repo without using a password.

### Jenkins to EC2 (SSH)

The existing AWS key pair (`sumiya-tech610-key`) was added to Jenkins credentials:

- Kind: SSH Username with private key
- Username: ubuntu
- Private key: contents of `sumiya-tech610-key.pem`

This allows Job 3 to SSH into the EC2 instance and deploy the updated code.

### Why SSH Keys Instead of Passwords?

- More secure — private keys are much harder to brute force than passwords
- Automated — no human needs to enter a password during the pipeline
- Auditable — you can see exactly which key has access to what

### Generating the SSH Key Pair for SCM

A dedicated SSH key pair was generated specifically for Jenkins to authenticate with GitHub SCM (Source Code Management). Using a separate key for Jenkins means your personal SSH key is never exposed to Jenkins.

Run this command on your local machine:

```bash
ssh-keygen -t ed25519 -a 100 -C "jenkins@ttt-scm-3job-cicd"
```

When prompted for a file name:
```
sumiya-jenkins-2-gh-ttt-app
```
Breaking down the command:
- `-t ed25519` — the key type. Ed25519 is a modern, more secure algorithm than the older RSA format
- `-a 100` — the number of rounds used to generate the key. Higher number means more secure but slower to generate. 100 is a good balance
- `-C "jenkins@ttt-scm-3job-cicd"` — a comment/label so you know what this key is for when you see it listed

This creates two files in your `~/.ssh/` folder:
- `sumiya-jenkins-2-gh-ttt-app` ← private key — added to Jenkins credentials
- `sumiya-jenkins-2-gh-ttt-app.pub` ← public key — added to GitHub repo deploy keys
---

## How the Webhook Works

A webhook is a POST request that GitHub sends to Jenkins every time code is pushed. It tells Jenkins something has changed so it can trigger the pipeline automatically.

### Setup Steps

1. Go to GitHub repo → Settings → Webhooks → Add webhook
2. Payload URL: `http://34.254.6.118:8080/github-webhook/`
3. Content type: `application/json`
4. Trigger: Just the push event
5. Click Add webhook

### Trigger Flow
```
Developer pushes to dev branch
│
▼
GitHub detects the push
│
▼
GitHub sends POST request (webhook) to Jenkins URL
│
▼
Jenkins receives webhook and triggers Job 1
│
▼
Pipeline runs automatically
```
Note: The webhook only triggers when pushing to the dev branch. Jenkins is configured on Job 1 to only respond to changes on the dev branch.

---

## Job 1 — CI Test

**Job name:** `sumiya-ttt-job1-ci-test`

**Purpose:** Automatically run all 111 automated tests against the code on the dev branch. If any test fails the pipeline stops immediately.

### Configuration

**General:**
- Discard old builds: keep last 3

**Source Code Management:**
- Git
- Repository URL: `git@github.com:sumiya12m-bit/tech610-ttt-app-cicd-jenkins`
- Credentials: `sumiya-jenkins-2-gh-ttt-app`
- Branch: `*/dev`

**Build Triggers:**
- GitHub hook trigger for GITScm polling ← this is what the webhook triggers

**Build Environment:**
- Provide Node & npm bin/ folder to PATH ← needed to run npm test

**Build Steps — Execute Shell:**
### Why npm ci Instead of npm install?

In Job 1 the execute shell uses `npm ci` instead of `npm install`:

```bash
cd app
npm ci
npm test
```

**npm install** — installs dependencies and can update the `package-lock.json` file if versions have changed. This means the installed packages might be slightly different each time which could cause inconsistent test results.

**npm ci** — stands for Clean Install. It does the following:
- Deletes the `node_modules` folder completely before installing
- Installs exact versions specified in `package-lock.json` — never updates it
- Faster than npm install in CI environments
- Guarantees the exact same dependencies every single time

This is why `npm ci` is the recommended command for CI/CD pipelines — you want your test environment to be identical every single run so you can trust the results. If the tests pass on one run they should pass on every run with the same code.
```

**Result:**
- 111 tests run
- All must pass for Job 2 to trigger
- If any test fails — pipeline stops and developer is notified

---

## Job 2 — CI Merge

**Job name:** `sumiya-ttt-job2-ci-merge`

**Purpose:** If Job 1 passes, automatically merge the tested code from the dev branch into the main branch using the Git Publisher plugin.

### Configuration

**General:**
- Discard old builds: keep last 3

**Source Code Management:**
- Git
- Repository URL: `git@github.com:sumiya12m-bit/tech610-ttt-app-cicd-jenkins`
- Credentials: `sumiya-jenkins-2-gh-ttt-app`
- Branch: `*/dev`

**Build Triggers:**
- Build after other projects are built
- Projects to watch: `sumiya-ttt-job1-ci-test`
- Trigger only if build is stable

**Post Build Actions — Git Publisher:**
- Merge Results: ✅ ticked
- Branch to push: `main`
- Target remote name: `origin`

**Why Git Publisher Instead of Execute Shell?**

Git Publisher is a Jenkins plugin specifically designed for Git operations. It is more reliable and maintainable than writing raw shell commands to do the same thing. It handles authentication automatically using the credentials already configured in the SCM section.

**Result:**
- dev branch is merged into main on GitHub
- main branch always contains tested, working code

---

## Job 3 — CD Deploy

**Job name:** `sumiya-ttt-job3-cd-deploy`

**Purpose:** If Job 2 passes, automatically copy the updated code to the EC2 instance and restart the app so the changes are live immediately.

### Configuration

**General:**
- Discard old builds: keep last 3

**Source Code Management:**
- Git
- Repository URL: `git@github.com:sumiya12m-bit/tech610-ttt-app-cicd-jenkins`
- Credentials: `sumiya-jenkins-2-gh-ttt-app`
- Branch: `*/main` ← deploys from main since Job 2 already merged

**Build Triggers:**
- Build after other projects are built
- Projects to watch: `sumiya-ttt-job2-ci-merge`
- Trigger only if build is stable

**Build Environment:**
- SSH Agent: `sumiya-tech610-key` ← EC2 SSH credentials

**Build Steps — Execute Shell:**
```bash
# copy updated app code from Jenkins workspace to EC2 instance
rsync -avz -e "ssh -o StrictHostKeyChecking=no" app/ ubuntu@34.241.30.177:/home/ubuntu/app/

# SSH into EC2 and restart the app
ssh -o StrictHostKeyChecking=no ubuntu@34.241.30.177 <<EOF
    cd /home/ubuntu/app
    npm install
    pm2 stop all
    pm2 delete all
    pm2 start index.js --name app
EOF
```

**Why rsync Instead of git clone?**

- rsync copies only the changed files — faster and more efficient
- git clone would pull the entire repo each time — unnecessary
- The task specifically says not to git clone from main and push to production

**Why pm2 stop, delete, start Instead of restart?**

Using `pm2 restart` sometimes serves cached old code. Doing a full stop, delete, and start ensures PM2 picks up the latest version of the files every single time.

**Result:**
- Updated code copied to EC2
- App restarted with new code
- Changes visible on front page immediately

---

## Results and Screenshots

### Pipeline Running Successfully

All 3 jobs complete with green ticks in Jenkins:

- ✅ sumiya-ttt-job1-ci-test
- ✅ sumiya-ttt-job2-ci-merge
- ✅ sumiya-ttt-job3-cd-deploy

### Change 1 — Front Page Updated

*(Add screenshot of Change 1 here — v1.2.0 27/07/2026 - Change 1)* ![first change to app homepage](../)

The version stamp at the bottom of the page shows:
```
v1.2.0 27/07/2026 - Change 1
```
### Change 2 — Front Page Updated Again

*(Add screenshot of Change 2 here — v1.2.0 | Updated: 27/07/2026 - 15:08)*

The version stamp updated to:
```
v1.2.0 | Updated: 27/07/2026 - 15:08
```
Both changes were deployed automatically within minutes of pushing to the dev branch — with zero manual steps.

---

## Blockers and How They Were Resolved

### Blocker 1 — Job 3 Had No SCM Configured
Job 3 failed with `No such file or directory` for the app folder because Jenkins had no code in its workspace.

Fix: Added SCM configuration to Job 3 pointing to the main branch so Jenkins clones the repo before running the deploy script.

### Blocker 2 — Tests Failing After Front Page Change
Changing the footer text caused test 99 to fail because the automated tests check for specific exact text in the footer.

Fix: Changed `server.js` line 100 instead — the `getFooterVersionStamp()` function — which adds a timestamp to the version stamp at the bottom of the page without affecting the text the tests check for.

### Blocker 3 — PM2 Serving Cached Old Code
After Job 3 ran successfully the front page wasn't showing the updated content because PM2 was still running the old version.

Fix: Updated the Job 3 shell script to use `pm2 stop all`, `pm2 delete all`, then `pm2 start` instead of `pm2 restart` — forcing a complete fresh start every deployment.

### Blocker 4 — SSH Permission Denied on Local Machine
When pushing from local machine using SSH git remote it failed with permission denied because Git Bash didn't know which key to use.

Fix: Created `~/.ssh/config` file specifying which key to use for github.com:
```
Host github.com
HostName github.com
User git
IdentityFile ~/.ssh/sumiya-jenkins-2-gh-ttt-app
```
---

## Benefits of This Pipeline

### Benefits Seen During This Task

- Every push to dev automatically runs 111 tests — catching bugs immediately
- The main branch always contains tested working code — never broken
- Deploying a change takes 2-3 minutes from push to live — compared to manual deployment which took much longer
- Zero manual steps once the pipeline is running — push the code and walk away

### Benefits for an Organisation

- **Speed** — developers can ship multiple changes per day safely
- **Reliability** — automated tests catch bugs before they reach production
- **Consistency** — every deployment follows exactly the same process every time
- **Reduced risk** — small frequent changes are easier to debug than large releases
- **Developer confidence** — developers know immediately if their code broke something
- **Time saving** — no manual deployment steps frees up engineers for more valuable work
- **Audit trail** — every build, test result and deployment is logged in Jenkins