## Intro to Terraform

### What is Terraform? What is it used for?

* IaC type of tool: orchestration
* infrastructure provisioning tool
* manage cloud resources
* originally inspired by AWS CloudFormation
* different to configuration management tools like Ansible which deploy software onto existing servers
* sees infrastructure as immutable (disposable)
* uses code written in HCL (Hashicorp Configuration Language) - aims to be a good balance between human and machine readable
  * HCL can be converted 1:1 to JSON and vice versa

### Why use Terraform? The benefits?
* declarative - say what you want, not how to do it
* easy to use
* sort of open-source
  
  In 2023, started using Business Source License (BSL). This means...
  * Terraform can't be used to create a competing commerical product
  * Some organisations have started using OpenTofu instead
    * OpenTofu aims to be a drop-in replacement
* Cloud-agnostic - deploy to any cloud provider
  * use different providers (like a plugin) to interface with different cloud providers
  * each cloud vendor maintains its own provider
* Expressive (refering to the language) and extendable (refering to being able to use different providers to manage different resources)

### Alternatives to Terraform

* Pulumi (not declarative)
* AWS CloudFormation, Azure ARM/Bicep templates, GCP Deployment Manager

### Who is using Terraform in the industry?

Some examples:
* Tech Companies and Startups: Uber, Spotify, Airbnb, Coinbase
* Financial Institutions (regulated industry): JPMorgan Chase, Goldman Sachs, Capital One
* Cloud Providers and SaaS Platforms: AWS, Google Cloud, Salesforce
* Media and Entertainment: The New York Times, Netflix
* Healthcare (regulated industry) and Life Sciences: Philips, Cerner
* Telecommunications: Verizon, T-Mobile
* Retail and E-Commerce: Walmart, Target
* Gaming Industry: Electronic Arts (EA), Riot Games (they make/run League of Legends)
* Government and Public Sector: UK Government Digital Service (GDS), NASA
* Consulting and Cloud Services: Accenture, Deloitte
* Education and Research Institutions: Harvard University, MIT

<br>

### In IaC, what is orchestration?

* Process of automating and managing the entire lifecycle of infrastructure resources

### How does Terraform act as "orchestrator"?
 
* Co-ordinating the piece of instructure to work together
* Includes
  * setting things up/destroying in the right order
  * makes sure things are connected together properly

To do this, it relies on understanding the dependencies between resources

### Give access to Terraform to use your cloud provider

#### (🟠 AWS) Best practice supplying AWS credentials to Terraform

What is order in which Terraform looks up AWS credentials (which ways take precedence/priority)?
1. Env variables: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY (Mediocre unless you temporarily set them such as through a key vault to retrieve them when needed)
2. Terraform variables (Worst in terms of security)

   Example:
   
   provider "aws" {
     access_key = "your_access_key"
     secret_key = "your_secret_key"
   }
   
   💥Danger! Never do this! Always avoid hard-coding credentials

3. AWS CLI shared credentials file (saved here when you do `aws configure` command) (Mediocre in terms of security)

4. If using Terraform through an EC2 instance, set IAM role permissions (Best)

<br>

#### (🌐 Azure) Give Terraform access to Azure

If you need to give access from your workstation, the quickest and easiest way:
1. Install Azure CLI
2. Login to Azure using command `az login`

Hint:
* Make sure you only try to create Terraform resources inside of the resource group you've been using
  * e.g. If you try to create your own resource group you will get a permissions error

<br>

#### (🌈 GCP) Give Terraform access to GCP

If you need to give access from your workstation, the quickest and easiest way:
1. Install Google Cloud (gcloud) CLI
2. Login to Azure using command `gcloud init`
3. Create Application Default Credentials (ADC): `gcloud auth application-default login`

Hint:
* There is no need to specify any credentials file when using ADC - Terraform will automatically pickup the credentials

<br>

### Why use Terraform for different environments (e.g. production, testing, etc)

* Production
  * Easily create a larger-scale or more scalable version of infrastructure

* Dev and Testing environments
  * Easily spin up infrastructure for testing/dev that mirrors production
  * Easily tear it down when not needed