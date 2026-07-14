# AWS Custom VPC - 2-Tier Deployment Documentation

---

## What is a VPC?

A VPC (Virtual Private Cloud) is your own private, isolated network inside AWS. Think of AWS as a large office building shared by thousands of companies - your VPC is your company's private floor with its own rules about who can come in and out.

By default AWS gives you one VPC per region. In this task we created our own **custom VPC** so we have full control over the network configuration, subnets, and security.

---

## Understanding the Default VPC vs Custom VPC
```bash
AWS (the building — shared with everyone using AWS)
└── Our Sparta Account on AWS
├── Default VPC ("apartment") for Ireland region
│     ├── Default Subnet A ← linked to AZ eu-west-1a
│     ├── Default Subnet B ← linked to AZ eu-west-1b
│     └── Default Subnet C ← linked to AZ eu-west-1c
│
└── Our Custom VPC (what we built in this task)
├── Public Subnet A  (10.0.2.0/24) ← App VM lives here
└── Private Subnet B (10.0.3.0/24) ← DB VM lives here
```
A, B and C refer to different Availability Zones — physically separate data centres within the Ireland region.

---

## Architecture Diagram

```
Internet (HTTP)
                          │
                          ▼
                ┌──────────────────┐
                │   Public IP /    │
                │ Internet Gateway │ ← Step 3: created and attached to VPC
                └────────┬─────────┘
                         │
    ┌────────────────────▼──────────────────────────────────┐
    │              VPC 10.0.0.0/16  ← Step 1               │
    │                                                        │
    │  ┌─────────────────────────┐  ┌─────────────────────┐ │
    │  │   Public Subnet         │  │   Private Subnet    │ │
    │  │   10.0.2.0/24 ← Step 2 │  │   10.0.3.0/24       │ │
    │  │                         │  │                     │ │
    │  │  Public Route Table     │  │  Default Route      │ │
    │  │  (Step 4) uses IGW      │  │  Table (auto made)  │ │
    │  │         │               │  │         │           │ │
    │  │  ┌──────▼──────┐        │  │  ┌──────▼──────┐   │ │
    │  │  │  SG: port   │        │  │  │  SG: port   │   │ │
    │  │  │  80 + 22    │        │  │  │  22 + 27017 │   │ │
    │  │  └──────┬──────┘        │  │  └──────┬──────┘   │ │
    │  │         │               │  │         │           │ │
    │  │  ┌──────▼──────┐        │  │  ┌──────▼──────┐   │ │
    │  │  │   App VM    │ Step 6 │  │  │    DB VM    │   │ │
    │  │  │  (TicTacToe)│───────────────▶  (MongoDB) │   │ │
    │  │  └─────────────┘        │  │  └─────────────┘   │ │
    │  └─────────────────────────┘  └─────────────────────┘ │
    └───────────────────────────────────────────────────────-┘
```
The numbered steps on the diagram match the order we built things:
1. Create the VPC
2. Create public and private subnets
3. Create and attach the Internet Gateway
4. Create the public route table and associate with public subnet
5. Launch the DB VM in the private subnet
6. Launch the App VM in the public subnet with User Data to connect to DB

---

## Why Do We Need a Public and Private Subnet?

| | Public Subnet | Private Subnet |
|---|---|---|
| Internet access | Yes |  No |
| Has public IP |  Yes |  No |
| What lives here | App VM | DB VM |
| Why | Users need to reach the app | DB should never be exposed to internet |
| Extra security | Security group controls ports | No public IP = completely hidden |

Putting the DB in a private subnet means even if someone finds the IP, they can't reach it from the internet — it's only accessible from within the VPC.

---

## Step 1 - Create the VPC

1. Go to AWS Console → search **VPC** in the search bar
2. Click **Your VPCs → Create VPC**
3. Fill in:
   - Select: **VPC only**
   - Name tag: `tech610-sumiya-2tier-first-vpc`
   - IPv4 CIDR block: `10.0.0.0/16`
4. Click **Create VPC**

> The CIDR block `10.0.0.0/16` gives us 65,536 private IP addresses to use across all our subnets.

---

## Step 2 - Create Subnets

We need two subnets — one public for the app and one private for the database.

1. Go to **Subnets → Create subnet**
2. VPC ID — select your VPC `tech610-sumiya-2tier-first-vpc`

### Public Subnet
- Subnet name: `tech610-sumiya-public-subnet`
- Availability Zone: **eu-west-1a** (Zone A — Europe Ireland)
- IPv4 VPC CIDR block: default (10.0.0.0/16)
- IPv4 subnet CIDR block: `10.0.2.0/24`

### Add New Subnet - Private Subnet
Click **Add new subnet** and fill in:
- Subnet name: `tech610-sumiya-private-subnet`
- Availability Zone: **eu-west-1b** (Zone B)
- IPv4 VPC CIDR block: default (10.0.0.0/16)
- IPv4 subnet CIDR block: `10.0.3.0/24`

Click **Create subnet**

> Each subnet gets its own CIDR block - a smaller range of IPs carved out of the VPC's range. 10.0.2.0/24 gives 256 IPs for the public subnet and 10.0.3.0/24 gives 256 for the private subnet.

---

## Step 3 - Create and Attach the Internet Gateway

An Internet Gateway is what connects your VPC to the internet. Without it, nothing inside the VPC can communicate with the outside world.

1. Go to **Internet Gateways → Create internet gateway**
2. Name: `tech610-sumiya-2tier-first-vpc-ig`
3. Click **Create internet gateway**
4. Once created - click **Actions → Attach to VPC**
5. Select your VPC and click **Attach internet gateway**
6. Confirm the state shows **Attached** 

---

## Step 4 - Create the Public Route Table

A route table contains rules (routes) that determine where network traffic is directed. The private route table is created automatically by AWS when you create the VPC - you only need to create the public one.

1. Go to **Route Tables → Create route table**
2. Fill in:
   - Name: `tech610-sumiya-2tier-first-vpc-public-rt`
   - VPC: select your VPC
3. Click **Create route table**

### Associate with Public Subnet
1. In the summary page go to **Subnet associations**
2. Click **Edit subnet associations**
3. Select your **public subnet** and click **Save associations**

### Add Route to Internet
1. Go to **Routes** in the summary page
2. Click **Edit routes → Add route**
3. Fill in:
   - Destination: `0.0.0.0/0` (anywhere on the internet)
   - Target: **Internet Gateway** → select your IGW from the dropdown
4. Click **Save changes**

> This route tells AWS: any traffic trying to reach an address outside the VPC (0.0.0.0/0) should go through the Internet Gateway. Without this the public subnet has no internet access even with the IGW attached.

---

## Step 5 - Launch the DB VM

We use our existing DB AMI so MongoDB is already installed and configured — no need to run scripts from scratch.

1. Go to **EC2 → AMIs → My AMIs**
2. Find your DB AMI and click **Launch instance from AMI**
3. Fill in:
   - Name: `tech610-sumiya-in-2tier-vpc-ttt-db`
   - Key pair: `sumiya-tech610-key`

4. Under **Network settings → Edit**:
   - VPC: select your custom VPC
   - Subnet: select **private subnet**
   - Auto-assign public IP: **Disable** ← DB should have no public IP
   - Create new security group:
     - Name: `tech610-sumiya-2tier-vpc-allow-ssh-mongodb`

| Port | Protocol | Source | Purpose |
|---|---|---|---|
| 22 | SSH | Anywhere | Terminal access |
| 27017 | Custom TCP | 10.0.2.0/24 | Only allow app subnet to connect to MongoDB |

> Setting the MongoDB source to `10.0.2.0/24` (the public subnet CIDR) means only instances in the public subnet can reach MongoDB — not the open internet.

5. Click **Launch instance**

---

## Step 6 — Launch the App VM

1. Go to **EC2 → AMIs → My AMIs**
2. Find your App AMI and click **Launch instance from AMI**
3. Fill in:
   - Name: `tech610-sumiya-in-2tier-vpc-ttt-app`
   - Key pair: `sumiya-tech610-key`

4. Under **Network settings → Edit**:
   - VPC: select your custom VPC
   - Subnet: select **public subnet**
   - Auto-assign public IP: **Enable** ← App needs a public IP for users to reach it
   - Create new security group:
     - Name: `tech610-sumiya-2tier-allow-ssh-http`

| Port | Protocol | Source | Purpose |
|---|---|---|---|
| 80 | HTTP | 0.0.0.0/0 | Users visit the app |
| 22 | SSH | Anywhere (or My IP) | Terminal access |

5. Under **Advanced details → User Data** paste:

```bash
#!/bin/bash

# ── Set MongoDB connection string
export MONGODB_URI=mongodb://10.0.3.212:27017/tic-tac-toe

# ── Start the app
cd /tech610-tic-tac-toe/app
pm2 start index.js
```

> The MONGODB_URI uses the **private IP of the DB VM** (10.0.3.212) — not the public IP. VMs within the same VPC communicate using private IPs.

6. Click **Launch instance**

---

## Step 7 - Test it's Working

Once both VMs are running:

1. Copy the **public IP** of the App VM from the AWS console
2. Visit in your browser:
```
http://<app-vm-public-ip>
```
The TicTacToe app should load and be connected to MongoDB 

---

## Security Group Summary

| Security Group | VM | Ports | Purpose |
|---|---|---|---|
| tech610-sumiya-2tier-allow-ssh-http | App VM | 22, 80 | SSH access and web traffic |
| tech610-sumiya-2tier-vpc-allow-ssh-mongodb | DB VM | 22, 27017 | SSH access and MongoDB from app subnet only |

---

## Cleaning Up

Always delete resources in the correct order to avoid dependency errors.

### Step 1 — Terminate both VMs
1. EC2 → Instances
2. Select App VM → Instance state → Terminate
3. Select DB VM → Instance state → Terminate
4. Wait for both to show **Terminated**

### Step 2 — Delete the VPC
1. Go to **VPC → Your VPCs**
2. Select your VPC `tech610-sumiya-2tier-first-vpc`
3. Click **Actions → Delete VPC**
4. This automatically deletes:
   - Your subnets
   - Your route tables
   - Your internet gateway association
5. Type **delete** to confirm

> You can choose to keep subnets and route tables if you plan to reuse them — but for a clean teardown deleting the VPC handles everything.

---

## Key Concepts Summary

| Concept | What it is | Why we need it |
|---|---|---|
| VPC | Your private network inside AWS | Isolates your resources from other AWS customers |
| Public Subnet | Subnet with internet access | Where the app VM lives so users can reach it |
| Private Subnet | Subnet with no internet access | Where the DB lives so it's hidden from the internet |
| Internet Gateway | Connects VPC to the internet | Without it nothing in the VPC can reach the internet |
| Route Table | Rules for directing network traffic | Tells public subnet traffic to go through the IGW |
| Security Group | Virtual firewall for each VM | Controls exactly which ports and sources can connect |
| CIDR Block | IP address range | Defines how many IPs are available in the VPC or subnet |
| Private IP | Internal IP within the VPC | Used for VM to VM communication inside the VPC |
| Public IP | External IP visible to internet | Used by users to reach the app VM |
