## AWS Auto-scaling Group Documentation

### Create Launch Template

1. Launch templates
- create launch template
- launch template name: tech610-sumiya-for-asg-ttt-app-lt
- template version description: for testing, ttt app

2. AMI - use your app image
My AMIs -> search image name

3. Instance type - t3.micro

4. Key pair - usual one you have

5. Network settings - use security group that you use for your app, port 80 and port 22 SSH (port 3000 in it too is okay)

6. Advanced details - USER DATA
- add in your short app script 

```bash
#!/bin/bash 

cd /tech610-tic-tac-toe/app

pm2 start index.js
```

Click create launch template

Launch instance from template
- will automatically choose or you choose the template that you are using
- everything will be automatically filled in 
- press launch instance and copy public IP
- Check that the app is up and running

Instance dont have a name? 
Our auto scaling groups is going to name the instances it creates

You can delete the instance just created as it was just to see if app is up and running 

### Create Auto Scaling Group

1. From your launch templates, click actions and create auto scaling group 
- Your launch template will be automatically selected
OR 
2. Go on auto scaling group tab and click on create auto scaling group 
- You will need to choose your launch template

3. Name - tech610-sumiya-ttt-app-asg 

Choose Instance Launch Options 
- Keep default VPC as the same
Availability zones and subnets 
- Select all of them(A, B & C) spread out VMs in one availability zone 
Availability zone distrubition 
- Balanced best effort

Integrate with other services
- Attach to a new load balancer 
- Application Load Balancer (HTTP, HTTPS)

Load balancer name: tech610-sumiya-ttt-app-asg-lb (add lb at end for load balancer)

Load balancer scheme: 
Internet facing 

Listeners and routing: 
Default routing (forward to): Create new target group
New target group name: add `-tg` at the end

Health Checks:
- Turn on Elastic load balancing health checks (replaces unhealthy instances with healthy ones)
- Health check grace period - 90 seconds

Configure group sizing: 
Desired capacity - 2 
Minimum desired capacity - 2
Maximum desired capacity - 3

Automatic scaling:
- Target tracking scaling policy

- Instance warm up: 90 seconds

Instance maintenance policy: 
- Choose no policy

Add Tags
Key: Name
Value: Tech610-sumiya-ttt-app-asg-HA-SC 


### Deleting what we created

Delete the load balancer
Delete the target group (if the load balancer is gone already it will sayNone associatedin theLoad balancercolumn)
Delete the ASG