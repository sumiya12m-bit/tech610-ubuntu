# Manipulate AWS S3 storage 

- [Manipulate AWS S3 storage](#manipulate-aws-s3-storage)
    - [What is S3 storage?](#what-is-s3-storage)
  - [Installing AWS CLI on Ubuntu 24.04 LTS](#installing-aws-cli-on-ubuntu-2404-lts)
    - [AWS CLI commands to manipulate s3 storage](#aws-cli-commands-to-manipulate-s3-storage)
  - [To delete entire bucket with and without files inside](#to-delete-entire-bucket-with-and-without-files-inside)


### What is S3 storage?

- Simple Storage Service 
- Used to storage and retrieve any amount, at any time, from anywhere
- Can be easily be used to host a static website on the cloud
- Provides built-in redundancy by default
  - 3 copies - each one stored across the AZs in region
- We will see we can access from AWS Console, AWS CLI, Python Boto3
- Often the resources from an application/website are stored in S3 e.g. images, log files
- Default is files you put there are private, you need to configure to make public

## Installing AWS CLI on Ubuntu 24.04 LTS

```bash
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt install unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

aws --version
aws configure
```

1. enter ID
2. enter secret
3. eu-west-1
4. json

- you can use "clear" to clear your terminal
- you can use "history" to see your past commands

List buckets in AWS S3: 

```bash
aws s3 ls 
```
To get help: 
```bash
aws help
```
Get help for AWS S3 specifically:
```bash
aws help s3
```
`press q to exit`

to make a s3 bucket:
```bash
aws s3 mb s3://tech610-firstname-first-bucket
```

### AWS CLI commands to manipulate s3 storage
---
```bash
aws s3 mb s3://tech610-sumiya-first-bucket
aws s3 ls s3://tech610-sumiya-first-bucket
```
adding a test file to bucket:

```bash
echo this is the first line in a test file > test.txt

cat test.txt
```
copy the file into your bucket:

```bash
aws s3 cp test.txt s3://tech610-sumiya-first-bucket
```
making a folder: 
```
mkdir downloads
cd downloads/
```

to move files: 
```bash
aws s3 sync s3://<name of bucket> <path where you want the files downloaded>

aws s3 sync s3://tech610-sumiya-first-bucket .
```

to delete file from bucket: 

`(dangerous as it will delete files immediately without confirmation)`
```bash
aws s3 rm s3://tech610-sumiya-first-bucket/test.txt
```

to delete all files from bucket: 

`(dangerous as it will delete files immediately without confirmation)`
```bash
aws s3 rm help

aws s3 rm s3://tech610-sumiya-first-bucket --recursive
```

## To delete entire bucket with and without files inside

this would only delete buckets with empty files:

```bash
aws s3 rb s3://tech610-sumiya-first-bucket
```
to remove bucket with files inside: 

```bash
aws s3 rb s3://tech610-sumiya-first-bucket --force
```
To reuse commands, you can go up and down or when you are in history you check the line number for the command you want to use.
For example:
```bash 
!22
```

