# Terraform Documentation

---
- [Terraform Documentation](#terraform-documentation)
  - [What is Terraform?](#what-is-terraform)
    - [Key Concepts](#key-concepts)
  - [Terraform Commands](#terraform-commands)
  - [Task 1 — Create a New Repo for Terraform Code](#task-1--create-a-new-repo-for-terraform-code)
  - [Task 2 — Create a .gitignore for Terraform](#task-2--create-a-gitignore-for-terraform)
    - [How We Created the .gitignore](#how-we-created-the-gitignore)
  - [Task 3 — Create an EC2 Instance with Terraform (No Variables)](#task-3--create-an-ec2-instance-with-terraform-no-variables)
    - [Folder: create-ec2-no-vars](#folder-create-ec2-no-vars)
    - [main.tf](#maintf)
    - [What Each Part Does](#what-each-part-does)
    - [Steps to Run](#steps-to-run)
  - [Task 4 — Create an EC2 Instance with Variables](#task-4--create-an-ec2-instance-with-variables)
    - [Folder: create-ec2-with-vars](#folder-create-ec2-with-vars)
    - [Why Use Variables?](#why-use-variables)
    - [variables.tf](#variablestf)
    - [main.tf](#maintf-1)
  - [Task 5 — Create a Security Group and Attach to EC2](#task-5--create-a-security-group-and-attach-to-ec2)
    - [Folder: create-ec2-with-vars](#folder-create-ec2-with-vars-1)
    - [What is a Security Group in Terraform?](#what-is-a-security-group-in-terraform)
    - [Updated variables.tf](#updated-variablestf)
    - [Updated main.tf](#updated-maintf)
    - [What Each New Part Does](#what-each-new-part-does)
    - [Security Group Rules Summary](#security-group-rules-summary)
    - [Blockers and Fixes](#blockers-and-fixes)
    - [Result](#result)
  - [Key Lessons Learned](#key-lessons-learned)
  - [Links](#links)
---
## What is Terraform?

Terraform is an open source Infrastructure as Code (IaC) tool created by HashiCorp. It allows you to define and provision cloud infrastructure using configuration files rather than manually clicking through a cloud console.

Instead of manually creating EC2 instances, security groups, and VPCs through the AWS console, you write code that describes what you want and Terraform creates it automatically.

### Key Concepts

**Declarative** — you describe what you want, not how to do it. Terraform figures out the steps.

**Idempotent** — you can run the same code multiple times and Terraform only makes changes if something is different from the desired state.

**State** — Terraform keeps track of what it has created in a state file (terraform.tfstate). This is how it knows what exists and what needs to change.

---

## Terraform Commands

| Command | What it does |
|---|---|
| `terraform init` | Initialises the working directory and downloads required providers |
| `terraform plan` | Shows what Terraform will create, change or destroy without doing it |
| `terraform apply` | Creates or updates the infrastructure |
| `terraform destroy` | Destroys all resources managed by the current configuration |

---

## Task 1 — Create a New Repo for Terraform Code

Created a new private GitHub repo specifically for Terraform code — separate from the main tech610 notes repo because this repo will contain live infrastructure code that we run commands from.

- Repo name: `tech610-terraform`
- Visibility: Private
- Trainer added as collaborator

Folder structure:
```
tech610-terraform/
├── .gitignore
├── README.md
├── create-ec2-no-vars/
│     └── main.tf
└── create-ec2-with-vars/
├── main.tf
├── variables.tf
└── .terraform.lock.hcl
```
---

## Task 2 — Create a .gitignore for Terraform

Terraform generates several files automatically that should not be pushed to GitHub:

- `terraform.tfstate` — contains sensitive information about your infrastructure including IDs and sometimes secrets
- `terraform.tfstate.backup` — backup of the state file
- `.terraform/` — contains downloaded provider plugins (large files, not needed in repo)

### How We Created the .gitignore

Used a curl command to download the official GitHub Terraform .gitignore template:

```bash
curl -s https://raw.githubusercontent.com/github/gitignore/main/Terraform.gitignore -o .gitignore
```

Then added a comment to also ignore the variables file to keep variable values private:

```bash
# Stored variables and their initial values
variables.tf
```
This means `variables.tf` will never be pushed to GitHub — protecting any sensitive values stored there such as IP addresses or resource names.

---

## Task 3 — Create an EC2 Instance with Terraform (No Variables)

### Folder: create-ec2-no-vars

First attempt at using Terraform to create an EC2 instance — hardcoding all values directly in the code.

### main.tf

```hcl
# use aws provider
provider "aws" {
  region = "eu-west-1"
}

# create ec2 instance
resource "aws_instance" "test_vm" {
  ami           = "ami-0c1c30571d2dae5c9"
  instance_type = "t3.micro"

  tags = {
    Name        = "tech610-sumiya-tf-first-vm"
    Environment = "test"
  }
}
```

### What Each Part Does

**provider "aws"** — tells Terraform to use the AWS provider and which region to create resources in. Terraform uses your AWS environment variables (AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY) to authenticate.

**resource "aws_instance" "test_vm"** — defines an EC2 instance resource. The first string is the resource type and the second is the local name used to reference it within Terraform.

**ami** — the Amazon Machine Image ID. This is the operating system template — we used Ubuntu 22.04 LTS.

**instance_type** — the size of the VM. t3.micro is free tier eligible.

**tags** — metadata attached to the resource in AWS for identification.

### Steps to Run

```bash
# initialise the working directory
terraform init

# preview what will be created
terraform plan

# create the resources
terraform apply

# destroy when done to avoid charges
terraform destroy
```

---

## Task 4 — Create an EC2 Instance with Variables

### Folder: create-ec2-with-vars

Improved version using variables so values can be reused and changed easily without editing the main code file.

### Why Use Variables?

- Avoids hardcoding values that might change
- Makes code reusable across different environments
- Keeps sensitive values out of the main code file
- Follows best practice for maintainable Terraform code

### variables.tf

```hcl
variable "test_vm_ami_id" {
  description = "AMI ID for the EC2 instance"
  default     = "ami-0c1c30571d2dae5c9"
}
```

Variables are defined with:
- **description** — explains what the variable is for
- **default** — the value used if no other value is provided

### main.tf

```hcl
# use aws provider
provider "aws" {
  region = "eu-west-1"
}

# create ec2 instance
resource "aws_instance" "test_vm" {
  ami           = var.test_vm_ami_id
  instance_type = "t3.micro"

  tags = {
    Name        = "tech610-sumiya-tf-first-vm"
    Environment = "test"
  }
}
```

Variables are referenced using `var.variable_name` syntax. So `var.test_vm_ami_id` pulls the value from the variables file.

---

## Task 5 — Create a Security Group and Attach to EC2

### Folder: create-ec2-with-vars

Added a security group resource to Terraform and attached it to the EC2 instance along with a key pair.

### What is a Security Group in Terraform?

A security group is a virtual firewall. In Terraform we define the security group and its rules as separate resources using the newer AWS provider approach:

- `aws_security_group` — creates the security group
- `aws_vpc_security_group_ingress_rule` — defines each inbound rule
- `aws_vpc_security_group_egress_rule` — defines each outbound rule

### Updated variables.tf

```hcl
variable "test_vm_ami_id" {
  description = "AMI ID for the EC2 instance"
  default     = "ami-0c1c30571d2dae5c9"
}

variable "my_ip" {
  description = "My local machine IP address for SSH access"
}

variable "key_name" {
  description = "Name of the key pair to use with EC2"
  default     = "sumiya-tech610-key"
}
```

Note: `my_ip` has no default value — Terraform will prompt you to enter it when you run plan or apply. This is intentional so the IP is never hardcoded or stored in the code.

### Updated main.tf

```hcl
# use aws provider
provider "aws" {
  region = "eu-west-1"
}

# create security group
resource "aws_security_group" "tech610_sumiya_tf_sg" {
  name        = "tech610-sumiya-tf-allow-port-22-3000-80"
  description = "Security group created by Terraform"

  tags = {
    Name = "tech610-sumiya-tf-allow-port-22-3000-80"
  }
}

# allow port 22 from my IP only
resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.tech610_sumiya_tf_sg.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "${var.my_ip}/32"
}

# allow port 3000 from all
resource "aws_vpc_security_group_ingress_rule" "allow_3000" {
  security_group_id = aws_security_group.tech610_sumiya_tf_sg.id
  from_port         = 3000
  to_port           = 3000
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# allow port 80 from all
resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.tech610_sumiya_tf_sg.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.tech610_sumiya_tf_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# create ec2 instance
resource "aws_instance" "test_vm" {
  ami                    = var.test_vm_ami_id
  instance_type          = "t3.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.tech610_sumiya_tf_sg.id]

  tags = {
    Name        = "tech610-sumiya-tf-first-vm"
    Environment = "test"
  }
}
```

### What Each New Part Does

**aws_security_group** — creates the security group in AWS with a name and description.

**aws_vpc_security_group_ingress_rule** — creates an inbound rule. Each rule is a separate resource in the newer AWS provider version. Key arguments:
- `security_group_id` — references the security group this rule belongs to using `aws_security_group.tech610_sumiya_tf_sg.id`
- `from_port` and `to_port` — the port range
- `ip_protocol` — the protocol (tcp, udp, or -1 for all)
- `cidr_ipv4` — the IP range allowed. `/32` means a single IP address

**aws_vpc_security_group_egress_rule** — creates an outbound rule. Using `ip_protocol = "-1"` with no ports means allow all outbound traffic.

**vpc_security_group_ids** — attaches the security group to the EC2 instance by referencing its ID.

**key_name** — attaches the key pair to the EC2 instance so you can SSH into it.

### Security Group Rules Summary

| Port | Protocol | Source | Purpose |
|---|---|---|---|
| 22 | TCP | My IP only (/32) | SSH terminal access |
| 3000 | TCP | 0.0.0.0/0 | Node.js app traffic |
| 80 | TCP | 0.0.0.0/0 | HTTP web traffic |
| All | All | 0.0.0.0/0 | All outbound traffic |

### Blockers and Fixes

**Blocker 1 — ingress blocks not supported**

Initially used ingress and egress blocks inside the aws_security_group resource. The newer AWS Terraform provider (v6+) no longer supports this syntax.

Fix: Used separate `aws_vpc_security_group_ingress_rule` and `aws_vpc_security_group_egress_rule` resources instead.

**Blocker 2 — typo in vpc_security_group_ids**

Had `vpc_security_groups_ids` (extra s) and `.ID` (uppercase) which caused an error.

Fix: Corrected to `vpc_security_group_ids` and `.id` (lowercase).

### Result
```
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.
```
6 resources created:
- ✅ aws_instance.test_vm
- ✅ aws_security_group.tech610_sumiya_tf_sg
- ✅ aws_vpc_security_group_ingress_rule.allow_ssh
- ✅ aws_vpc_security_group_ingress_rule.allow_3000
- ✅ aws_vpc_security_group_ingress_rule.allow_http
- ✅ aws_vpc_security_group_egress_rule.allow_all_outbound

---

## Key Lessons Learned

- Terraform uses a declarative approach — you describe what you want, not how to build it
- Always run `terraform plan` before `terraform apply` to preview changes
- Always run `terraform destroy` after testing to avoid unnecessary AWS charges
- Never push `terraform.tfstate` to GitHub — it contains sensitive infrastructure details
- Never push `variables.tf` to GitHub if it contains sensitive values like IP addresses
- Variables make code reusable and keep sensitive values out of the main code
- The AWS Terraform provider version affects the syntax available — always check the official documentation for the version you are using
- Reference other resources using `resource_type.resource_name.attribute` syntax e.g. `aws_security_group.tech610_sumiya_tf_sg.id`

---

## Links

- Terraform code: https://github.com/sumiya12m-bit/tech610-terraform/tree/main/create-ec2-with-vars
- Terraform documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs