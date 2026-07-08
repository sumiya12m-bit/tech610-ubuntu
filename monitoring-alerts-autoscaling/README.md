# Monitoring, alert management and auto scaling

### Under the performance testing that we will do

What is performance testing? 
* About asking: "Is the app working well generally?"

Performance testing includes:
* load testing
    * About asking: "Can the app handle the usual amount of traffic?"
* stress testing
    * About asking: "How much traffic can the app handle before it breaks and what happens when it does break?"

What we will do
* concentrating on load testing
* use a tool called Apache Bench (ab)
* taking note of what happens to the CPU usuage 

## Using Apache Bench to do load testing

### Installing Apache bench

```bash
sudo apt-get update -y
sudo apt-get install apache2-utils
```

### Doing the load testing

Format for `ab` command: 

```bash 
ab -n 1000 -c 100 http://yourwebsite.com/
```

Example of commands to run:

ab -n 1000 -c 100 http://34.242.250.13/

ab -n 10000 -c 200 http://34.242.250.13/

ab -n 20000 -c 300 http://34.242.250.13/

