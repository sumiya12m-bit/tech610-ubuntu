# Get app to connect to DB

1. DB VM running first
2. in the app folder:

export MONGODB_URI=mongodb://172.31.53.27:27017/tic-tac-toe

3. Run the app 
npm start 
pm2 start index.js

# Troubleshoot app not connecting to DB

* Environment variable - is it set correctly? does it have the right IP address? 
* DB security group rules?
* Does the app run without the database?
* BindIp - set correctly?
* Is the database actually running?

## Extra

### General troubleshooting advice

* Is it a systematic approach?
* What is the easiest thing to check?
* What is most likely thing it could be?
