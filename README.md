# git-hooks
These git hooks have been written to simplify working with K8S and other devopsish activities.

PR's and feature requests welcomed. 

## Installer
The installer is written for and intended to run on both MacOS and Linux.

To install run:
``` curl -s https://raw.githubusercontent.com/djh00t/git-hooks/main/install.sh | bash```

The installer must be run from the root of a git repo and will install a git submodule into  includes/git-hooks in the root of your repo. To update the submodule us the following commands:
  - git submodule update --init --recursive
  - git submodule update --remote

**Note:** *The installer will not overwrite other hooks if you already have them configured. I will probably convert this to a pre-commit plugin at some stage in the future but for now this is it.*

## Current hooks:
- **pre-commit:**
  - Checks to make sure you have age and other dependencies installed
  - Checks to make sure you have an age private key
  - Finds unencrypted K8S secrets, ignoring files in .k8s_password_hooks_ignore
  - Age encrypts all K8S secrets in the repo using .age.pub which you need to put in the root of the repo and .gitignore
  - git add's all newly encrypted files
  - restarts the git commit process with secrets encrypted
  - Runs pre-commit lint checks
- **post-commit:**
  - Age decrypts all K8S secrets in the repo to make it easier to work on them
