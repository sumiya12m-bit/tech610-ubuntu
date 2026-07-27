first go into .ssh folder
```
cd ~/.ssh
```


ssh-keygen -t ed25519 -a 100 -C "sumiya-mohamed@tech610-work-laptop"

name for key: tech610-sumiya-gh-key

Add public key, register in github account settings
```
eval `ssh-agent -s`

ssh-add tech610-sumiya-gh-key

ssh -T git@github.com
```