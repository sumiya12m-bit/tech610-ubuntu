# Infrastructure as Code

## What problems need solving?

- At the moment, still manually having provision servers

What does it mean by "provision"?
- Setting up & configuring servers

## What have we automated?

VMs
- Creation of the VMs? No
- Creation of the infrastructure they live in? No 
- Setup & configuring of software on the VMs? Yes, how?
  - Bash script
  - User data
  - Images (AMI)

## Solving the problem

IaC -> can automate all of it
How? codify our requirements
* do not always define the steps (imperative) in the code
* Instead can be declarative (declare what you want)
  
## What is IaC?

- a way to manage and provision resources (often computers) through a machine-readable definition of the infrastrcture

## Benefits of IaC?

- speed & simplicity
- consistency & accuracy 
- version control
- scalability

## When/where to use IaC

- Return of investment? Is it worth it?
- 

## What are the tools available for IaC?

2 types: 
- Configuration management (software configuration)
  - Chef
  - Puppet
  - Ansible
- Orchestration (managing infrastructure)
  - Terraform (cloud-agnostic)
  - Cloud-specific:
    - Azure - Arm/Bicep templates
    - AWS - CloudFormation

## What is provisioning of infrastructure? Do CM tools do it?

## What is configuration management (CM)?