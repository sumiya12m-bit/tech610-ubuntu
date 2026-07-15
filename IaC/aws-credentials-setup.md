# AWS Access Keys — Environment Variables Setup
- [AWS Access Keys — Environment Variables Setup](#aws-access-keys--environment-variables-setup)
  - [Why We Need This](#why-we-need-this)
  - [Why User Variables Not System Variables](#why-user-variables-not-system-variables)
  - [Steps](#steps)
    - [Step 1 - Open Environment Variables](#step-1---open-environment-variables)
    - [Step 2 - Add the Two Variables](#step-2---add-the-two-variables)
    - [Step 3 - Verify in a New Terminal](#step-3---verify-in-a-new-terminal)
  - [Important Notes](#important-notes)

---

## Why We Need This

Terraform needs AWS credentials to be able to create and manage resources on AWS. Instead of hardcoding the keys directly in Terraform code (which would be a security risk if pushed to GitHub), we store them as environment variables on our local machine. Terraform automatically looks for these specific environment variable names when it needs to authenticate with AWS.

---

## Why User Variables Not System Variables

We used User variables rather than System variables because:
- User variables only apply to your user account - more secure
- System variables apply to all users on the machine
- For AWS credentials which are personal and sensitive, user variables are the safer choice

---

## Steps

### Step 1 - Open Environment Variables

1. Press Windows key → search "Environment Variables"
2. Click "Edit the system environment variables"
3. Click "Environment Variables" button at the bottom

### Step 2 - Add the Two Variables

Under User variables (top section) click New for each one:

First variable:
- Variable name: AWS_ACCESS_KEY_ID
- Variable value: (value from CSV file - not documented here for security)

Second variable:
- Variable name: AWS_SECRET_ACCESS_KEY
- Variable value: (value from CSV file — not documented here for security)

Click OK on all windows to save.

### Step 3 - Verify in a New Terminal

Opened a brand new Git Bash terminal then ran:

```bash
printenv | grep AWS
```

Output confirmed both variables are set correctly:
```bash
AWS_ACCESS_KEY_ID=***************
AWS_SECRET_ACCESS_KEY=***************
```
Note: Values are not shown here for security reasons.

---

## Important Notes

- Never hardcode AWS access keys in any file that gets pushed to GitHub
- Always use the exact variable names AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY - one character wrong and Terraform won't find them
- Always open a new terminal after setting environment variables - existing terminals won't pick them up
- These variables are stored permanently so they survive laptop restarts