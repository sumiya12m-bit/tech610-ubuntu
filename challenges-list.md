# My Biggest Challenges on the Course

---

## Challenge 1 - File Paths and Directory Issues

**Status: Solved**

### The Challenge
Getting file paths wrong caused a lot of frustration throughout the course. The two biggest examples were:

- User Data scripts run from `/` (root) not `/home/ubuntu` — so `cd ~/app` would fail because the path didn't exist from root
- SCP commands failing because of backslashes instead of forward slashes on Windows, or because I wasn't in the right directory on my local machine

### What I've Tried / How I'm Solving It
- Learning the difference between absolute paths (`/home/ubuntu/app`) and relative paths (`~/app`) and when to use each one
- Always using absolute paths in User Data scripts because they run from `/` not from `/home/ubuntu`
- Running `pwd` to check where I am before running any file-based commands
- Running `ls` after SCP commands to verify files actually arrived on the VM before trying to run them

### What I've Learned
Always check where you are before running commands. A script that works perfectly when run manually from `/home/ubuntu` can fail completely in User Data because the starting directory is different. Using absolute paths in scripts removes this ambiguity entirely.

---

## Challenge 2 - Connecting Two VMs (2-Tier Architecture)

**Status: Solved**

### The Challenge
Setting up communication between the App VM and the DB VM was challenging because there were multiple things that all had to be correct at the same time for it to work:

- MongoDB had to be running on the DB VM
- The `bindIp` in MongoDB's config had to be set to `0.0.0.0`
- The DB VM security group had to have port 27017 open
- The `MONGODB_URI` environment variable had to have the correct private IP
- The environment variable had to be set before the app started

If any one of these was wrong, the app wouldn't connect to the database and the error messages weren't always clear about which one was the problem.

### What I've Tried / How I'm Solving It
- Working through a systematic troubleshooting checklist one step at a time rather than changing multiple things at once
- Using `sudo systemctl status mongod` to confirm MongoDB was actually running
- Using `sudo cat /etc/mongod.conf | grep bindIp` to verify the bindIp change had worked
- Using `pm2 env 0` to check the environment variable was picked up correctly before the app started
- Always using the **private IP** of the DB VM in the connection string rather than the public IP which changes on restart

### What I've Learned
Debugging a two-VM setup requires a systematic approach; check one thing at a time, starting with the most likely cause. The most common issues were either MongoDB not running, the wrong IP in the connection string, or port 27017 not being open in the security group. Having a checklist to work through made troubleshooting much faster.