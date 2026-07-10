# AWS Auto Scaling Group Documentation

---

## What is Auto Scaling and Why Do We Need It?

Auto Scaling automatically adjusts the number of running instances based on demand. Instead of manually launching more VMs when traffic increases, AWS does it for you.

Without Auto Scaling:
```
High traffic → App slows down → Users have a bad experience
```

With Auto Scaling:

```
High traffic → AWS detects load → Launches more instances automatically → Users unaffected
Low traffic → AWS detects less load → Terminates extra instances → Saves money
```
---

## What is a Load Balancer and Why is it Needed?

A Load Balancer sits in front of your instances and distributes incoming traffic evenly across all of them. Without it, users would need to know which specific instance to connect to - which isn't practical when instances are being created and destroyed automatically.

```
Internet
                    │
                    ▼
          ┌─────────────────┐
          │  Load Balancer  │  ← single entry point for users
          └────────┬────────┘
       ┌───────────┼───────────┐
       ▼           ▼           ▼
  Instance 1   Instance 2   Instance 3
  (TicTacToe)  (TicTacToe)  (TicTacToe)

```

Key benefits of a Load Balancer:
- **Single URL** - users always visit the same address regardless of how many instances are running
- **Health checking** - automatically stops sending traffic to unhealthy instances
- **Even distribution** - spreads traffic so no single instance gets overloaded
- **High availability** - if one instance fails, traffic is rerouted to healthy ones instantly

---

## How Auto Scaling Works — Diagram

```
┌───────────────────────────────────────────────────  ─┐
│                    AWS Auto Scaling                  │
│                                                      │
│   Launch Template                                    │
│   (AMI + instance type + user data + security group) │
│              │                                       │
│              ▼                                       │
│   Auto Scaling Group                                 │
│   Min: 2  Desired: 2  Max: 3                         │
│              │                                       │
│    ┌─────────┴──────────┐                            │
│    ▼                    ▼                            │
│ Instance 1          Instance 2    (+ Instance 3      │
│ (AZ eu-west-1a)  (AZ eu-west-1b)   if needed)        │
│    │                    │                            │
└────┼────────────────────┼────────────────────────────┘
│                         │
└──────────┬────────     ─┘
           ▼
    Load Balancer
           │
           ▼
    Target Group
    (registered instances)
            │
            ▼
        Internet
        (users)
```
The key components and how they connect:
- **Launch Template** — the blueprint for each instance (what AMI, size, script to run)
- **Auto Scaling Group** — manages how many instances run and when to add/remove them
- **Load Balancer** — the single entry point that distributes traffic
- **Target Group** — the list of instances the load balancer sends traffic to

---

## Step 1 — Create a Launch Template

A Launch Template is the blueprint AWS uses every time it needs to launch a new instance. Think of it like a saved set of instructions.

1. Go to **EC2 → Launch Templates → Create launch template**
2. Fill in:
   - **Launch template name:** `tech610-sumiya-for-asg-ttt-app-lt`
   - **Template version description:** `for testing, ttt app`

3. **AMI** — use your app image:
   - Click **My AMIs** → search for your app image name
   - This is important — the AMI has everything pre-installed so instances launch quickly

4. **Instance type:** `t3.micro`

5. **Key pair:** your usual key pair

6. **Network settings:**
   - Use your existing app security group
   - Must include ports: **22** (SSH), **80** (HTTP), **3000** (app)

7. **Advanced details → User Data:**
   - This script runs automatically on every new instance the ASG launches
   - Because we're using an AMI that already has everything installed, we just need to start the app:

```bash
#!/bin/bash

cd /tech610-tic-tac-toe/app
pm2 start index.js
```

8. Click **Create launch template**

### Test the Launch Template

Before creating the ASG, test the template works by launching one instance from it:

1. From your launch template → **Actions → Launch instance from template**
2. Everything will be pre-filled automatically
3. Click **Launch instance** and copy the public IP
4. Visit `http://<public-ip>` and confirm the app loads
5. **Delete this test instance** once confirmed — the ASG will manage its own instances

> Instances launched by the ASG won't have a name by default — the ASG names them using the tag you set up later.

---

## Step 2 — Create the Auto Scaling Group

1. From your launch template → **Actions → Create Auto Scaling group**
   OR go to **EC2 → Auto Scaling Groups → Create Auto Scaling group**

2. **Name:** `tech610-sumiya-ttt-app-asg`

3. **Launch template:** automatically selected if coming from the template

### Choose Instance Launch Options

- **VPC:** keep the default VPC
- **Availability zones and subnets:** select **all of them (A, B and C)**
  - This spreads instances across multiple availability zones — if one zone goes down your app stays up
- **Availability zone distribution:** Balanced best effort

### Integrate with Other Services

- Select **Attach to a new load balancer**
- Load balancer type: **Application Load Balancer (HTTP/HTTPS)**
- **Load balancer name:** `tech610-sumiya-ttt-app-asg-lb`
- **Load balancer scheme:** Internet-facing
  - Internet-facing means it accepts traffic from the public internet
  - Internal would only accept traffic from within AWS
- **Listeners and routing:** Default routing → **Create new target group**
- **New target group name:** `tech610-sumiya-ttt-app-asg-lb-tg`

### Health Checks

-  Turn on **Elastic Load Balancing health checks**
  - This replaces unhealthy instances with new healthy ones automatically
- **Health check grace period:** 90 seconds
  - Gives new instances time to start up before being checked

### Configure Group Sizing

| Setting | Value | Why |
|---|---|---|
| Desired capacity | 2 | How many instances to run normally |
| Minimum capacity | 2 | Never go below 2 instances |
| Maximum capacity | 3 | Never exceed 3 instances |

### Automatic Scaling

- Select **Target tracking scaling policy**
  - Automatically adds instances when CPU goes above a threshold and removes them when it drops
- **Instance warm up:** 90 seconds
  - Time allowed for a new instance to be ready before receiving traffic

### Instance Maintenance Policy

- Select **No policy** for now

### Add Tags

| Key | Value |
|---|---|
| Name | Tech610-sumiya-ttt-app-asg-HA-SC |

This tag is what names every instance the ASG creates.

Click **Create Auto Scaling group**

---

## Step 3 — Verify it's Working

After creating the ASG, wait a few minutes then check:

1. Go to **EC2 → Instances** - you should see 2 new instances with the name tag you set
2. Go to **EC2 → Load Balancers** → select your load balancer → copy the **DNS name**
3. Visit the DNS name in your browser:
```
http://tech610-sumiya-ttt-app-asg-lb-xxxxxxxxx.eu-west-1.elb.amazonaws.com
```
You should see the TicTacToe app loading 

---

## Step 4 — How to SSH into an ASG Instance

ASG instances don't have a fixed IP — it changes every time a new one launches. To SSH in:

1. Go to **EC2 → Instances**
2. Find one of your ASG instances and copy its **public IP**
3. SSH in as normal:
```bash
ssh -i ~/.ssh/sumiya-tech610-key.pem ubuntu@<instance-public-ip>
```

> Note: If the instance gets replaced by the ASG, the IP will change. Always get the current IP from the console.

---

## Step 5 — Managing Instances (Healthy vs Unhealthy)

### What Healthy and Unhealthy Mean

The load balancer constantly checks each instance to make sure it's responding correctly. This is called a **health check**.

- **Healthy** — the instance is responding correctly to health check requests 
- **Unhealthy** — the instance is not responding or returning errors 

When an instance becomes unhealthy:
1. The load balancer stops sending traffic to it
2. The ASG detects it's unhealthy
3. The ASG terminates it and launches a replacement
4. The new instance goes through the warm up period
5. Once healthy, it starts receiving traffic

### How to Make an Instance Unhealthy (for testing)

This is useful for testing that the ASG correctly replaces failed instances:

**Method 1 — Stop the app:**
```bash
# SSH into the instance
ssh -i ~/.ssh/sumiya-tech610-key.pem ubuntu@<instance-ip>

# Stop PM2
pm2 stop index
```
The health check will now fail and the instance will be marked unhealthy.

**Method 2 — Stop the instance directly from AWS console:**
1. EC2 → Instances → select the instance
2. Instance state → Stop instance

**Method 3 — Mark as unhealthy manually:**
1. EC2 → Auto Scaling Groups → select your ASG
2. Instance management tab → select an instance
3. Actions → Set to unhealthy

### Why Instances Get Marked Unhealthy

| Reason | What Happens |
|---|---|
| App not running | Health check gets no response |
| Instance stopped or crashed | No response on port 80 |
| High CPU / out of memory | Slow or no response |
| Manually marked unhealthy | For testing purposes |

### Watching the ASG Replace an Instance

After making an instance unhealthy:
1. Go to **EC2 → Auto Scaling Groups → your ASG → Activity tab**
2. You should see entries showing the unhealthy instance being terminated and a new one launching
3. Go to **EC2 → Instances** to see the new instance appear

---

## Step 6 — Delete Everything

Always clean up to avoid unnecessary AWS charges. Delete in this order - if you delete out of order you may get dependency errors.

### 1 — Delete the Auto Scaling Group
1. EC2 → Auto Scaling Groups
2. Select your ASG `tech610-sumiya-ttt-app-asg`
3. Actions → Delete
4. Type **delete** to confirm
5. This will automatically terminate all instances managed by the ASG

### 2 — Delete the Load Balancer
1. EC2 → Load Balancers
2. Select `tech610-sumiya-ttt-app-asg-lb`
3. Actions → Delete load balancer
4. Confirm

### 3 — Delete the Target Group
1. EC2 → Target Groups
2. Select `tech610-sumiya-ttt-app-asg-lb-tg`
3. Actions → Delete
4. Confirm
5. Note: if the load balancer is already deleted it will show **None associated** in the Load balancer column - this is fine

### 4 — Delete the Launch Template (optional)
1. EC2 → Launch Templates
2. Select `tech610-sumiya-for-asg-ttt-app-lt`
3. Actions → Delete template
4. Confirm

> You may want to keep the launch template if you plan to recreate the ASG again.

---

## Adding a Database with Auto Scaling

If you want the TicTacToe app to use MongoDB while auto scaling, there are a few important things to consider:

### Key Principle
**You only auto scale the app VMs - NOT the database VM.** There is one single database VM that all app instances connect to.

```
Internet
                    │
                    ▼
          ┌─────────────────┐
          │  Load Balancer  │
          └────────┬────────┘
     ┌─────────────┼─────────────┐
     ▼             ▼             ▼
App Instance 1  App Instance 2  App Instance 3
     │             │             │
     └─────────────┼─────────────┘
                   │
                   ▼
          ┌─────────────────┐
          │   DB VM         │
          │   (MongoDB)     │
          │   Single VM     │
          └─────────────────┘
```

### What's Different When Adding a Database

| Without DB | With DB |
|---|---|
| User Data just starts the app | User Data sets MONGODB_URI then starts app |
| No env variable needed | Must export MONGODB_URI before pm2 start |
| Any instance works independently | All instances point to same DB private IP |

### Updated User Data Script with Database

```bash
#!/bin/bash

# Set MongoDB connection string
export MONGODB_URI=mongodb://<db-private-ip>:27017/tic-tac-toe

# Start the app
cd /tech610-tic-tac-toe/app
pm2 start index.js
```

### Important Considerations

- Use the DB VM's **private IP** in the connection string - not the public IP
- The DB VM must be running **before** the ASG launches instances
- If the DB VM goes down all app instances lose their database connection
- The DB VM is a **single point of failure** - in production you would use a managed database service like AWS RDS with replication for redundancy

---

## Summary

| Component | Purpose |
|---|---|
| Launch Template | Blueprint for every instance the ASG creates |
| Auto Scaling Group | Manages how many instances run and scales up/down |
| Load Balancer | Single entry point that distributes traffic across instances |
| Target Group | List of instances the load balancer sends traffic to |
| Health Checks | Detects and replaces unhealthy instances automatically |
| User Data | Script that runs on every new instance to start the app |