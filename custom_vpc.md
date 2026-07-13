### VPC
VPC on AWS search bar

Your VPCs - create VPC 

VPC only 

Name tag - tech610-sumiya-2tier-first-vpc

IPv4 CIDR Manual block - 10.0.0.0/16

### Subnets 
Go to Subnets - create subnets

VPC ID - choose your VPC 

Subnet settings: 
- Subnet name - tech610-sumiya-public-subnet
- Availability Zone (AZ) - Zone A Europe (Ireland) - eu-west-1a
- IPv4 VPC CIDR block - default (10.0.0.0/16)
- IPv4 subnet CIDR block - 10.0.2.0/24

#### Add new subnet
- Subnet name - tech610-sumiya-private-subet
- AZ : Zone B 
- IPv4 VPC CIDR block: default (10.0.0.0/16)
- IPv4 subnet CIDR block - 10.0.3.0/24

### Create Internet gateway

- Go to internet gateway and create one
- Name - tech610-sumiya-2tier-first-vpc-ig

Once created, attach to your VPC via actions
check the state says `attached`

### Create public route table
- `The private route table is made by default so theres no need to create.`

Go to route tables and create one

Name - tech610-sumiya-2tier-first-vpc-public-rt
VPC - Select your vpc
Click create route table

In summary page, go to subnet associations
click edit subnet associations
- Choose your `public` subnet and press save
Next go to routes in the summary page
Click edit routes
click add route
- Destination - 0.0.0.0/0 (Anywhere)
- Target - Internet Gateway
- In the drop down for IG - you need to click on your internet gateway ID so its associated with it and save changes.

### Set up Database VM
- Create VM using your database AMI as we have all our dependancies installed. 
Launch instance from AMI 
Name - tech610-sumiya-in-2tier-vpc-ttt-db

Key Pair: sumiya-tech610-key


Click edit security groups
Choose your VPC 
Choose the private subnet
Create new security group 
Name - tech610-sumiya-2tier-vpc-allow-ssh-mongodb
SSH - 22 - Anywhere
Custom TPC - 27017 - Source (10.0.2.0/24)
click create instance

### Set up App VM
- Launch instance from AMI 
- Name - tech610-sumiya-in-2tier-vpc-ttt-app
- Key pair

Network settings: 
Edit security
Add VPC 
Choose PUBLIC SUBNET
Enable the auto-assign public ip 
create security group 
Name - tech610-sumiya-2tier-allow-ssh-http
port 80 HTTP - Anywhere 
port 20 SSH - Anywhere or your IP

User Data - Bash script tictactoe to connect to DB
```bash
#!/bin/bash

# ── Set MongoDB connection string
export MONGODB_URI=mongodb://10.0.3.212:27017/tic-tac-toe

# ── Start the app 
cd /tech610-tic-tac-toe/app

pm2 start index.js
```


### Cleaning up 
- Delete both VM's first (app and DB)
- Go to VPC and SELECT your VPC 
- Click actions and delete VPC 
This will also delete your subnets and route tables (you can choose to keep these)