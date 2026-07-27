## Intro to Ansible

### What is Ansible

- A configuration management tool
- Red Hat leads development, guaranteeing quality open-source code
- Written in Python
- Started off with a few core modules for managing and configuring Linux servers
- Main use cases:
  - Can manage infrastructure
  - Best known for config management (keep software and software settings in the desired and consistent state)
  - Application deployment

- Works with almost any system. Examples:
  - Linux and Windows servers
  - routers and switches
  - cloud services



#### How does Ansible work

- It's like having recipes that your robot (Ansible) can follow to automate the software setup of other computers/devices
- The robot (Ansible) can login and control/change/setup/configure other computers/devices
- Recipes (or the actions/tasks/instructions) are written in YAML called "playbooks"
- Use *Ansible Control Node* (a controller computer/host) to tell the *Target Nodes* (computer/host which receives the action) what to do
- 'Playbooks' and 'Inventory' are saved on the controller computer
Unique attributes:
  - Module-based architecture
  - Agentless
    - No need to install ansible on *Target Nodes*
    - Instead, Ansible controller will SSH into *Target Nodes* computers to run commands
    - A Python interpreter is required on a Linux target nodes





#### Who is using IaC and Ansible in the industry

- A wide range of organisations from many industries, from starts to large enterprises
- Some examples include NASA, Spotify, Twitter