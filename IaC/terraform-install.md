# Terraform Installation Documentation

---
- [Terraform Installation Documentation](#terraform-installation-documentation)
  - [What is Terraform?](#what-is-terraform)
  - [What is IaC (Infrastructure as Code)?](#what-is-iac-infrastructure-as-code)
  - [Step 1 — Create IaC Folder in Your Repo](#step-1--create-iac-folder-in-your-repo)
  - [Step 2 — Download Terraform](#step-2--download-terraform)
  - [Step 3 — Move terraform.exe to a Logical Location](#step-3--move-terraformexe-to-a-logical-location)
  - [Step 6 — Install HashiCorp Terraform VS Code Extension](#step-6--install-hashicorp-terraform-vs-code-extension)
  - [Folder Structure](#folder-structure)

## What is Terraform?

Terraform is an open source Infrastructure as Code (IaC) tool created by HashiCorp. It allows you to define and provision cloud infrastructure using configuration files rather than clicking through a cloud console manually.

Instead of manually creating EC2 instances, VPCs, security groups and subnets through the AWS console, you write code that describes what infrastructure you want and Terraform creates it for you automatically.

This is important for DevOps because:
- Infrastructure is version controlled in Git just like application code
- You can recreate entire environments consistently with one command
- Changes are tracked, reviewed and auditable
- You can destroy and recreate infrastructure easily

---

## What is IaC (Infrastructure as Code)?

Infrastructure as Code means managing and provisioning infrastructure through code and configuration files rather than through manual processes. Instead of SSHing into a server and running commands manually, or clicking through a cloud console, you write files that describe your desired infrastructure and a tool like Terraform makes it happen.

---

## Step 1 — Create IaC Folder in Your Repo

Created a new folder in the tech610 repo for all Infrastructure as Code documentation:

```bash
cd ~/tech610
mkdir IaC
cd IaC
```

This folder will hold all Terraform and Ansible documentation and configuration files.

---

## Step 2 — Download Terraform

1. Go to https://developer.hashicorp.com/terraform/install
2. Click the Windows tab
3. Download the AMD64 version (.zip file)
4. Extract the zip file to get terraform.exe

---

## Step 3 — Move terraform.exe to a Logical Location

Created a dedicated folder for command line tools on the C drive and moved terraform.exe there:
```
Terraform v1.15.8
on windows_amd64
```
Terraform is successfully installed and accessible from anywhere ✅

Note: You must open a completely new terminal after adding to PATH — existing terminals won't pick up the new PATH variable.

---

## Step 6 — Install HashiCorp Terraform VS Code Extension

1. Open VS Code
2. Press Ctrl+Shift+X to open Extensions
3. Search for "Terraform"
4. Install the official one by HashiCorp (look for the HashiCorp logo)
5. Click Install

The extension provides:
- Syntax highlighting for .tf files
- Auto-completion for Terraform commands and resources
- Error highlighting
- Code formatting

---

## Folder Structure
```
tech610/
└── IaC/
└── terraform-install.md  ← this file
```
Future Terraform configuration files and Ansible documentation will also live in this IaC folder.