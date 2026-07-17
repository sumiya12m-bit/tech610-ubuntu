# Terraform 2-Tier App Deployment Documentation

---

## Overview

This documents the process of using Terraform to deploy a 2-tier TicTacToe application on AWS. Rather than clicking through the AWS console manually, we wrote code that creates everything automatically with one command.

We built this in 3 parts, each adding more complexity:

| Part | What we built | Key learning |
|---|---|---|
| Part 1 | App VM only — front page working | How to use Terraform to create a security group and EC2 instance with User Data |
| Part 2 | App VM + DB VM connected | How Terraform automatically passes the DB private IP to the app — no manual copying |
| Part 3 | Full custom VPC with app and DB | How to create an entire network from scratch with Terraform including subnets, internet gateway and route tables |

---

## Why Use Terraform for This?

Before Terraform, deploying the 2-tier app required:
- Clicking through the AWS console to create a VPC
- Manually creating subnets, internet gateways and route tables
- Manually creating security groups with rules
- Launching VMs one by one
- Manually finding the DB private IP and adding it to the app

With Terraform all of this is done with one command:
```bash
terraform apply
```

And destroyed with:
```bash
terraform destroy
```

This means the entire infrastructure is reproducible, version controlled in GitHub, and can be rebuilt in minutes.

---

## Key Terraform Concepts Used Throughout

### Variables
Instead of hardcoding values like AMI IDs and instance types directly in the code, we store them in a `variables.tf` file and reference them with `var.variable_name`. This makes the code reusable and easier to update.

### Referencing Other Resources
```hcl
vpc_id = aws_vpc.main.id
```
Terraform connects resources together by referencing them using `resource_type.resource_name.attribute` syntax. You never have to manually copy IDs — Terraform figures out the correct order to create things automatically.

### Data Source — Fetching Your IP Automatically
```hcl
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}
```
Instead of hardcoding or manually entering your IP address for the SSH rule, Terraform fetches it automatically every time you run plan or apply.

### Heredoc — User Data
```hcl
user_data = <<-EOF
            #!/bin/bash
            cd /tech610-tic-tac-toe/app
            pm2 start index.js
            EOF
```
`<<-EOF` and `EOF` is called a heredoc — a way of writing a multi-line string in Terraform. Everything between them is treated as one block of text, exactly like pasting a bash script into the User Data box in the AWS console. The `-` means indentation is ignored so the code stays readable.

### ip_protocol = "-1"
The `-1` value means all protocols — TCP, UDP, ICMP, everything. Used on egress rules to allow all outbound traffic without restricting by protocol or port. When using `-1` you don't need `from_port` or `to_port` because ports don't apply when all protocols are allowed.

### Output Block
```hcl
output "app_public_ip" {
  value = aws_instance.app_vm.public_ip
}
```
Outputs print important values to the terminal after `terraform apply` completes — so you get the public IP immediately without having to go into the AWS console.

---

## Folder Structure

```
tech610-terraform/
├── create-ec2-no-vars/     ← first attempt, no variables
├── create-ec2-with-vars/   ← added variables and security group
├── 2-tier-deploy/          ← Part 1 and Part 2
└── 2-tier-vpc/             ← Part 3 with custom VPC
```
---

## Part 1 — Deploy the App VM

### What We Built
```
Internet
│
▼
App VM (default VPC)
├── Security group: ports 22, 80, 3000
├── Key pair attached for SSH
└── User Data starts the TicTacToe app automatically
```
### Why No Database Yet?
In Part 1 the app runs in local mode — it works without a database. This lets us verify the app is deploying correctly before adding the complexity of a database connection.

### variables.tf
```hcl
variable "region" {
  description = "AWS region"
  default     = "eu-west-1"
}

variable "app_ami_id" {
  description = "AMI ID for the app VM — uses our custom app AMI with everything pre-installed"
  default     = "YOUR-APP-AMI-ID"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the key pair to use with EC2"
  default     = "sumiya-tech610-key"
}

variable "app_instance_name" {
  description = "Name tag for the app VM"
  default     = "tech610-sumiya-tf-ttt-app"
}

variable "app_sg_name" {
  description = "Name of the app security group"
  default     = "tech610-sumiya-tf-app-sg"
}
```

### main.tf
```hcl
# use aws provider
provider "aws" {
  region = var.region
}

# fetch current public IP automatically — used for SSH rule
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

# create the security group shell — rules are added separately below
resource "aws_security_group" "app_sg" {
  name        = var.app_sg_name
  description = "Security group for TicTacToe app VM"

  tags = {
    Name = var.app_sg_name
  }
}

# allow SSH from my IP only — /32 means a single specific IP address
resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.app_sg.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "${chomp(data.http.my_ip.response_body)}/32"
}

# allow port 80 — nginx reverse proxy
resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.app_sg.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# allow port 3000 — Node.js app
resource "aws_vpc_security_group_ingress_rule" "allow_3000" {
  security_group_id = aws_security_group.app_sg.id
  from_port         = 3000
  to_port           = 3000
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# allow all outbound traffic — standard practice, restrict inbound not outbound
resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.app_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# create app VM from our custom AMI
# key_name attaches the SSH key so we can connect to the VM
# user_data runs automatically on first boot — starts the app
resource "aws_instance" "app_vm" {
  ami                    = var.app_ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              cd /tech610-tic-tac-toe/app
              pm2 start index.js
              EOF

  tags = {
    Name = var.app_instance_name
  }
}

# print the public IP after apply so we can visit the app immediately
output "app_public_ip" {
  value = aws_instance.app_vm.public_ip
}
```

### How to Run
```bash
terraform init    # download required providers
terraform plan    # preview what will be created
terraform apply   # create the infrastructure
terraform destroy # destroy when done to avoid charges
```

### Result
```
Outputs:
app_public_ip = "x.x.x.x"
```
App accessible at `http://<app_public_ip>` ✅

### Deliverable
> "Terraform deployed app"

---

## Part 2 — Deploy App and Database VM

### What We Built
```
Internet
│
▼
App VM (default VPC)
├── Security group: ports 22, 80, 3000
└── MONGODB_URI → automatically set to DB VM private IP
│
│ private network
▼
DB VM (default VPC)
└── Security group: ports 22, 27017
```
### The Key Improvement — Automatic Private IP

The most important thing in Part 2 is that Terraform passes the DB VM's private IP into the app VM's User Data automatically:

```hcl
user_data = <<-EOF
            #!/bin/bash
            export MONGODB_URI=mongodb://${aws_instance.db_vm.private_ip}:27017/tic-tac-toe
            cd /tech610-tic-tac-toe/app
            pm2 start index.js
            EOF
```

`${aws_instance.db_vm.private_ip}` tells Terraform to get the private IP of the DB VM and insert it here. Terraform creates the DB VM first, gets its IP, then passes it into the app VM's User Data — all automatically. This is one of the most powerful features of Terraform.

### Why Does the DB VM Have No User Data?
Because we use a custom DB AMI that already has MongoDB installed and configured. The AMI was created from a working DB VM so MongoDB starts automatically on boot — no extra setup needed.

### Additional variables added
```hcl
variable "db_ami_id" {
  description = "AMI ID for the DB VM — MongoDB pre-installed"
  default     = "ami-078903b8bb1f83e91"
}

variable "db_instance_name" {
  description = "Name tag for the DB VM"
  default     = "tech610-sumiya-tf-ttt-db"
}

variable "db_sg_name" {
  description = "Name of the DB security group"
  default     = "tech610-sumiya-tf-db-sg"
}
```

### Additional resources added to main.tf
```hcl
# create DB security group
resource "aws_security_group" "db_sg" {
  name        = var.db_sg_name
  description = "Security group for TicTacToe DB VM"

  tags = {
    Name = var.db_sg_name
  }
}

# allow SSH from my IP only
resource "aws_vpc_security_group_ingress_rule" "db_allow_ssh" {
  security_group_id = aws_security_group.db_sg.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "${chomp(data.http.my_ip.response_body)}/32"
}

# allow MongoDB port from anywhere
# note: in Part 3 this is restricted to the public subnet only for better security
resource "aws_vpc_security_group_ingress_rule" "db_allow_mongodb" {
  security_group_id = aws_security_group.db_sg.id
  from_port         = 27017
  to_port           = 27017
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "db_allow_all_outbound" {
  security_group_id = aws_security_group.db_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# create DB VM — no user data needed as MongoDB starts automatically from the AMI
resource "aws_instance" "db_vm" {
  ami                    = var.db_ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  tags = {
    Name = var.db_instance_name
  }
}
```

### Updated app VM user data
```hcl
# MONGODB_URI is automatically set using the DB VM's private IP
# Terraform creates the DB VM first, gets its IP, then injects it here
user_data = <<-EOF
            #!/bin/bash
            export MONGODB_URI=mongodb://${aws_instance.db_vm.private_ip}:27017/tic-tac-toe
            cd /tech610-tic-tac-toe/app
            pm2 start index.js
            EOF
```

### Result
```
Outputs:
app_public_ip = "x.x.x.x"
db_private_ip = "172.31.x.x"
```
App connected to MongoDB ✅

### Deliverable
> "Terraform deployed app & database"

---

## Part 3 — Deploy App and Database in Custom VPC

### What We Built
```
Internet
│
▼
Internet Gateway
│
▼
Public Route Table (0.0.0.0/0 → IGW)
│
▼
VPC (10.0.0.0/16)
├── Public Subnet (10.0.2.0/24) — eu-west-1a
│     └── App VM
│           ├── Security group: ports 22, 80, 3000
│           └── MONGODB_URI → DB private IP
│
└── Private Subnet (10.0.3.0/24) — eu-west-1b
└── DB VM
├── Security group: port 22 + 27017 from public subnet only
└── No public IP — completely hidden from internet
```
### Why a Custom VPC?

The default VPC works but offers no control over networking. A custom VPC lets us:
- Put the DB in a **private subnet** with no public IP — it's completely unreachable from the internet
- Restrict MongoDB access to the **public subnet CIDR only** — only the app VM can connect, not random external traffic
- Control exactly how traffic flows between resources

### New Resources Explained

**aws_vpc** — creates your own private network inside AWS with a defined IP range (CIDR block). The `10.0.0.0/16` gives us 65,536 private IP addresses to use.

**aws_subnet** — divides the VPC into smaller sections. We created two:
- Public subnet `10.0.2.0/24` in eu-west-1a — has internet access
- Private subnet `10.0.3.0/24` in eu-west-1b — no internet access

**map_public_ip_on_launch = true** — this is set on the public subnet only. It means any VM launched in the public subnet automatically gets a public IP without having to configure it separately.

**aws_internet_gateway** — connects the VPC to the internet. Without this nothing inside the VPC can communicate with the outside world — not even the public subnet.

**aws_route_table** — contains rules for directing network traffic. We created a public route table with one rule: send all internet-bound traffic (`0.0.0.0/0`) through the internet gateway. The private subnet uses the default route table which has no such rule — so the DB VM has no internet access at all.

**aws_route_table_association** — links the public route table to the public subnet. Without this the subnet wouldn't know which route table to use.

**subnet_id on EC2** — this is new in Part 3. We now specify exactly which subnet each VM goes into:
- App VM → `aws_subnet.public_subnet.id`
- DB VM → `aws_subnet.private_subnet.id`

**vpc_id on security groups** — security groups in a custom VPC must be associated with that VPC. Without this they'd be created in the default VPC instead.

### Security Improvement vs Part 2

In Part 2 MongoDB port 27017 was open to `0.0.0.0/0` — anywhere on the internet could theoretically try to connect. In Part 3 it is restricted to the public subnet CIDR only:

```hcl
# Part 2 — less secure
cidr_ipv4 = "0.0.0.0/0"

# Part 3 — more secure
cidr_ipv4 = var.public_subnet_cidr  # 10.0.2.0/24
```

This means only instances in the public subnet (our app VM) can reach MongoDB. Combined with the DB having no public IP, the database is completely protected from the internet.

### variables.tf
```hcl
variable "region" {
  description = "AWS region"
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  default     = "10.0.2.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  default     = "10.0.3.0/24"
}

variable "app_ami_id" {
  description = "AMI ID for the app VM"
  default     = "YOUR-APP-AMI-ID"
}

variable "db_ami_id" {
  description = "AMI ID for the DB VM"
  default     = "ami-078903b8bb1f83e91"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the key pair"
  default     = "sumiya-tech610-key"
}

variable "app_instance_name" {
  description = "Name tag for the app VM"
  default     = "tech610-sumiya-tf-vpc-ttt-app"
}

variable "db_instance_name" {
  description = "Name tag for the DB VM"
  default     = "tech610-sumiya-tf-vpc-ttt-db"
}

variable "vpc_name" {
  description = "Name tag for the VPC"
  default     = "tech610-sumiya-tf-2tier-vpc"
}
```

### main.tf
```hcl
# use aws provider
provider "aws" {
  region = var.region
}

# fetch current public IP automatically
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

# ── VPC ──────────────────────────────────────────────
# creates our own private network inside AWS
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = var.vpc_name
  }
}

# ── SUBNETS ───────────────────────────────────────────
# public subnet — app VM lives here, has internet access
# map_public_ip_on_launch means VMs here get a public IP automatically
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "tech610-sumiya-tf-public-subnet"
  }
}

# private subnet — DB VM lives here, no internet access
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "eu-west-1b"

  tags = {
    Name = "tech610-sumiya-tf-private-subnet"
  }
}

# ── INTERNET GATEWAY ──────────────────────────────────
# connects the VPC to the internet
# without this nothing in the VPC can reach the outside world
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "tech610-sumiya-tf-igw"
  }
}

# ── PUBLIC ROUTE TABLE ────────────────────────────────
# rules for directing traffic — send internet traffic through the IGW
# private subnet uses default route table which has no internet route
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "tech610-sumiya-tf-public-rt"
  }
}

# link the public route table to the public subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ── APP SECURITY GROUP ────────────────────────────────
# vpc_id links this security group to our custom VPC
resource "aws_security_group" "app_sg" {
  name        = "tech610-sumiya-tf-vpc-app-sg"
  description = "Security group for app VM in custom VPC"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "tech610-sumiya-tf-vpc-app-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_allow_ssh" {
  security_group_id = aws_security_group.app_sg.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "${chomp(data.http.my_ip.response_body)}/32"
}

resource "aws_vpc_security_group_ingress_rule" "app_allow_http" {
  security_group_id = aws_security_group.app_sg.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "app_allow_3000" {
  security_group_id = aws_security_group.app_sg.id
  from_port         = 3000
  to_port           = 3000
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "app_allow_outbound" {
  security_group_id = aws_security_group.app_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ── DB SECURITY GROUP ─────────────────────────────────
resource "aws_security_group" "db_sg" {
  name        = "tech610-sumiya-tf-vpc-db-sg"
  description = "Security group for DB VM in custom VPC"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "tech610-sumiya-tf-vpc-db-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_allow_ssh" {
  security_group_id = aws_security_group.db_sg.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "${chomp(data.http.my_ip.response_body)}/32"
}

# restrict MongoDB to public subnet only — not open to the whole internet
resource "aws_vpc_security_group_ingress_rule" "db_allow_mongodb" {
  security_group_id = aws_security_group.db_sg.id
  from_port         = 27017
  to_port           = 27017
  ip_protocol       = "tcp"
  cidr_ipv4         = var.public_subnet_cidr
}

resource "aws_vpc_security_group_egress_rule" "db_allow_outbound" {
  security_group_id = aws_security_group.db_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ── DB VM ─────────────────────────────────────────────
# subnet_id places this VM in the private subnet — no public IP
# no user_data needed — MongoDB starts automatically from the AMI
resource "aws_instance" "db_vm" {
  ami                    = var.db_ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  tags = {
    Name = var.db_instance_name
  }
}

# ── APP VM ────────────────────────────────────────────
# subnet_id places this VM in the public subnet — gets a public IP
# Terraform automatically injects the DB VM private IP into user_data
resource "aws_instance" "app_vm" {
  ami                    = var.app_ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              export MONGODB_URI=mongodb://${aws_instance.db_vm.private_ip}:27017/tic-tac-toe
              cd /tech610-tic-tac-toe/app
              pm2 start index.js
              EOF

  tags = {
    Name = var.app_instance_name
  }
}

# ── OUTPUTS ───────────────────────────────────────────
output "app_public_ip" {
  value = aws_instance.app_vm.public_ip
}

output "db_private_ip" {
  value = aws_instance.db_vm.private_ip
}
```

### Result
```
Outputs:
app_public_ip = "x.x.x.x"
db_private_ip = "10.0.3.x"
```
Full 2-tier deployment in custom VPC ✅

### Deliverable
> "Terraform deployed app & database in custom VPC"

---

## Progression Summary

| | Part 1 | Part 2 | Part 3 |
|---|---|---|---|
| App VM | ✅ | ✅ | ✅ |
| DB VM | ❌ | ✅ | ✅ |
| Custom VPC | ❌ | ❌ | ✅ |
| Private subnet for DB | ❌ | ❌ | ✅ |
| DB hidden from internet | ❌ | ❌ | ✅ |
| MongoDB restricted to app subnet | ❌ | ❌ | ✅ |
| Auto DB private IP in app | ❌ | ✅ | ✅ |

---

## Key Lessons Learned

- Terraform automatically resolves dependencies — it creates the DB VM first because the app VM references its private IP, without you having to specify the order
- Use `output` blocks to print important values like public IPs after apply — no need to go into the AWS console
- Reference other resources using `resource_type.resource_name.attribute` — no manual copying of IDs needed
- The `data "http"` source fetches your current IP automatically — no hardcoding or manual input
- `map_public_ip_on_launch = true` on a subnet means VMs get public IPs automatically without extra configuration
- Security groups in a custom VPC must have `vpc_id` specified — otherwise they're created in the default VPC
- Restricting MongoDB to the public subnet CIDR rather than `0.0.0.0/0` is a simple but important security improvement
- The private subnet has no internet route by default — this is what keeps the DB VM hidden from the internet
- Always run `terraform destroy` after testing to avoid unnecessary AWS charges

---

## Terraform Commands Reference

| Command | What it does |
|---|---|
| `terraform init` | Downloads required providers |
| `terraform plan` | Previews what will be created changed or destroyed |
| `terraform apply` | Creates or updates the infrastructure |
| `terraform destroy` | Destroys all resources managed by the current configuration |