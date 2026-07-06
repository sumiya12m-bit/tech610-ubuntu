## TICTACTOE App

Security Group:
- SSH from my IP on Port 22
- All traffic on Port 3000

ssh -i ~/.ssh/sumiya-tech610-key.pem ubuntu@3.250.16.49

## VM Set UP

```Bash
sudo apt update -y
sudo apt upgrade -y

# Install Node 35 v20

curl -sL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh

sudo bash nodesource_setup.sh

sudo apt install nodejs -y

to check if you have node: node -v
```

## Get Source on to the VM

Options:

- Git
- Copy (scp)

scp -i KEY SOURCE TARGET

scp -i ~/.ssh/sumiya-tech610-key.pem ~/Downloads/nodejs20-sparta-tictactoe-v1-2.zip ubuntu@3.250.16.49:/home/ubuntu/

```bash
sudo apt install unzip -y

unzip nodejs20-sparta-tictactoe-v1-2.zip

```
# Going into the app

``` BASH
ls
ls app 

cd app
npm install
npm start 

## PM2

```bash 
sudo npm install pm2 -g

pm2 start index.js 

# list running apps
pm2 list 

# kill all running apps 
pm2 kill 