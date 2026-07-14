# Manipulate AWS S3 Storage

---
- [Manipulate AWS S3 Storage](#manipulate-aws-s3-storage)
  - [What is S3 Storage?](#what-is-s3-storage)
  - [Installing AWS CLI on Ubuntu 24.04 LTS](#installing-aws-cli-on-ubuntu-2404-lts)
    - [Authenticate with AWS CLI](#authenticate-with-aws-cli)
  - [AWS CLI Commands to Manipulate S3 Storage](#aws-cli-commands-to-manipulate-s3-storage)
    - [Useful Help Commands](#useful-help-commands)
    - [List all buckets](#list-all-buckets)
    - [Create a bucket](#create-a-bucket)
    - [List contents of a bucket](#list-contents-of-a-bucket)
    - [Create and upload a file](#create-and-upload-a-file)
    - [Download files from a bucket](#download-files-from-a-bucket)
    - [Delete a file from a bucket](#delete-a-file-from-a-bucket)
    - [Delete all files from a bucket](#delete-all-files-from-a-bucket)
    - [Delete a bucket](#delete-a-bucket)
    - [Reusing commands from history](#reusing-commands-from-history)
  - [Python Boto3 — Manipulate S3 with Python](#python-boto3--manipulate-s3-with-python)
    - [What is Boto3?](#what-is-boto3)
    - [Install Dependencies](#install-dependencies)
    - [Create a folder for your scripts](#create-a-folder-for-your-scripts)
    - [Script 1 — List All S3 Buckets](#script-1--list-all-s3-buckets)
    - [Script 2 — Create an S3 Bucket](#script-2--create-an-s3-bucket)
    - [Script 3 — Upload a File to S3](#script-3--upload-a-file-to-s3)
    - [Script 4 — Download a File from S3](#script-4--download-a-file-from-s3)
    - [Script 5 — Delete a File from S3](#script-5--delete-a-file-from-s3)
    - [Script 6 — Delete a Bucket](#script-6--delete-a-bucket)
  - [AWS CLI vs Python Boto3 — When to Use Which](#aws-cli-vs-python-boto3--when-to-use-which)
  - [Summary of All Scripts](#summary-of-all-scripts)
---

## What is S3 Storage?

- Simple Storage Service
- Used to store and retrieve any amount of data, at any time, from anywhere
- Can be easily used to host a static website on the cloud
- Provides built-in redundancy by default
  - 3 copies — each one stored across the AZs in the region
- We can access it from AWS Console, AWS CLI, and Python Boto3
- Often the resources from an application/website are stored in S3 e.g. images, log files
- Default is files you put there are private — you need to configure to make public

---

## Installing AWS CLI on Ubuntu 24.04 LTS

```bash
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt install unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

### Authenticate with AWS CLI

```bash
aws configure
```

You will be prompted to enter:
1. AWS Access Key ID
2. AWS Secret Access Key
3. Default region: `eu-west-1`
4. Default output format: `json`

> Use `clear` to clear your terminal and `history` to see past commands

---

## AWS CLI Commands to Manipulate S3 Storage

### Useful Help Commands

```bash
aws help          # general help
aws s3 help       # S3 specific help (press q to exit)
```

### List all buckets

```bash
aws s3 ls
```

### Create a bucket

```bash
aws s3 mb s3://tech610-sumiya-first-bucket
```

### List contents of a bucket

```bash
aws s3 ls s3://tech610-sumiya-first-bucket
```

### Create and upload a file

```bash
# Create a test file
echo this is the first line in a test file > test.txt
cat test.txt

# Copy the file into your bucket
aws s3 cp test.txt s3://tech610-sumiya-first-bucket
```

### Download files from a bucket

```bash
# Make a downloads folder
mkdir downloads
cd downloads/

# Sync all files from bucket to current folder
aws s3 sync s3://tech610-sumiya-first-bucket .
```

### Delete a file from a bucket

> Dangerous — deletes immediately without confirmation

```bash
aws s3 rm s3://tech610-sumiya-first-bucket/test.txt
```

### Delete all files from a bucket

> Dangerous — deletes immediately without confirmation

```bash
aws s3 rm s3://tech610-sumiya-first-bucket --recursive
```

### Delete a bucket

Empty bucket only:
```bash
aws s3 rb s3://tech610-sumiya-first-bucket
```

Bucket with files inside:
```bash
aws s3 rb s3://tech610-sumiya-first-bucket --force
```

### Reusing commands from history

```bash
history    # shows all past commands with line numbers
!22        # reruns command number 22
```

---

## Python Boto3 — Manipulate S3 with Python

### What is Boto3?

Boto3 is the official AWS Python library. It lets you interact with AWS services like S3 using Python scripts instead of the command line. This is useful for automation — for example automatically uploading files to S3 as part of a deployment pipeline.

Boto3 uses the same credentials you set up with `aws configure` — no extra authentication needed.

### Install Dependencies

```bash
sudo apt-get install python3-pip -y
pip3 install boto3 --break-system-packages
```

### Create a folder for your scripts

```bash
mkdir ~/s3-boto3-scripts
cd ~/s3-boto3-scripts
```

---

### Script 1 — List All S3 Buckets

Save as `list_buckets.py`
```
nano list_buckets.py
```
```python
import boto3

s3 = boto3.client('s3')

response = s3.list_buckets()

for bucket in response['Buckets']:
    print(bucket['Name'])
```
`ctl + X , Y and Enter`

What it does:
- Creates an S3 client using boto3
- Calls list_buckets() to get all buckets in your AWS account
- Loops through and prints each bucket name

Run it:
```bash
python3 list_buckets.py
```

---

### Script 2 — Create an S3 Bucket

Save as `create_bucket.py`
```
nano create_bucket.py
```
```python
import boto3

s3 = boto3.client('s3', region_name='eu-west-1')

s3.create_bucket(
    Bucket='tech610-sumiya-test-boto3',
    CreateBucketConfiguration={'LocationConstraint': 'eu-west-1'}
)

print("Bucket created successfully")
```
`ctl + X , Y and Enter`

What it does:
- Creates an S3 client in eu-west-1 region
- Creates a new bucket called tech610-sumiya-test-boto3
- The LocationConstraint is required for any region that is not us-east-1

Run it:
```bash
python3 create_bucket.py
```

---

### Script 3 — Upload a File to S3

First create a test file to upload:
```bash
echo "this is a test file for boto3" > test.txt
```

Save as `upload_file.py`
```
nano upload_file.py
```
```python
import boto3

s3 = boto3.client('s3')

s3.upload_file('test.txt', 'tech610-sumiya-test-boto3', 'test.txt')

print("File uploaded successfully")
```
`ctl + X , Y and Enter`

What it does:
- Takes a local file called test.txt
- Uploads it to the bucket tech610-sumiya-test-boto3
- The third argument is the name it will have inside the bucket

Run it:
```bash
python3 upload_file.py
```

Verify it uploaded:
```bash
aws s3 ls s3://tech610-sumiya-test-boto3
```

---

### Script 4 — Download a File from S3

Save as `download_file.py`
```bash
nano download_file.py
```
```python
import boto3

s3 = boto3.client('s3')

s3.download_file('tech610-sumiya-test-boto3', 'test.txt', 'downloaded_test.txt')

print("File downloaded successfully")
```
`ctl + X , Y and Enter`

What it does:
- Downloads test.txt from the bucket tech610-sumiya-test-boto3
- Saves it locally as downloaded_test.txt
- Arguments are: bucket name, file name in bucket, local file name to save as

Run it:
```bash
python3 download_file.py
```

Verify it downloaded:
```bash
ls
cat downloaded_test.txt
```

---

### Script 5 — Delete a File from S3

Save as `delete_file.py`
```
nano delete_file.py
```
```python
import boto3

s3 = boto3.client('s3')

s3.delete_object(Bucket='tech610-sumiya-test-boto3', Key='test.txt')

print("File deleted successfully")
```
`ctl + X , Y and Enter`

What it does:
- Deletes the object called test.txt from the bucket
- Key refers to the name of the file inside the bucket
- Deletes immediately with no confirmation

Run it:
```bash
python3 delete_file.py
```

Verify the file is gone:
```bash
aws s3 ls s3://tech610-sumiya-test-boto3
```

The bucket should be empty.

---

### Script 6 — Delete a Bucket

Save as `delete_bucket.py`
```
nano delete_bucket.py
```
```python
import boto3

s3 = boto3.resource('s3')

bucket = s3.Bucket('tech610-sumiya-test-boto3')

bucket.objects.all().delete()

bucket.delete()

print("Bucket deleted successfully")
```
`ctl + X , Y and Enter`

What it does:
- Uses boto3.resource instead of boto3.client for higher level operations
- Gets the bucket object
- Deletes all objects inside the bucket first (bucket must be empty before it can be deleted)
- Then deletes the bucket itself

Run it:
```bash
python3 delete_bucket.py
```

Verify the bucket is gone:
```bash
aws s3 ls
```

---

## AWS CLI vs Python Boto3 — When to Use Which

| | AWS CLI | Python Boto3 |
|---|---|---|
| Best for | Quick manual tasks | Automation and scripting |
| How you use it | Terminal commands | Python scripts |
| Example use | Quickly check what's in a bucket | Automatically upload files as part of a deployment |
| Learning curve | Easy — simple commands | Requires Python knowledge |
| Part of DevOps | Ad hoc tasks and testing | CI/CD pipelines and automation |

---

## Summary of All Scripts

| Script | What it does |
|---|---|
| list_buckets.py | Lists all S3 buckets in your AWS account |
| create_bucket.py | Creates a new S3 bucket |
| upload_file.py | Uploads a file to an S3 bucket |
| download_file.py | Downloads a file from an S3 bucket |
| delete_file.py | Deletes a file from an S3 bucket |
| delete_bucket.py | Deletes all files then deletes the bucket |