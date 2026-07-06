# Deploying Apps

1. Create the instance
    - What type of instance?
    - Key pairs
    - Configure a security group
        - SSH on isolated IP address
        - HTTP (80) all?
        - Other ports? *
2. Copy across source code (e.g. using `scp`) and deployment script(s) maybe?
3. SSH into the VM
4. (Change permissions on script if needed)
5. Run the deployment script!
    1. Check for updates and install them
    2. Install any dependencies
        - Packages needed for other steps in the automation
        - Packages / software needed to run the app
    3. Start / launch the application
    4. Configure nginx as a reverse proxy / port forwarding
    5. Restart nginx