# git-hooks
These git hooks have been written to simplify working with K8S and other devopsish activities.

PR's and feature requests welcomed. 

## Installer
The installer is written for and intended to run on both MacOS and Linux.
The installer must be run from the root of a git repo.
**Note:** *The installer will not overwrite other hooks if you already have them configured. Adding includes/plugins that would allow others to be included may be added in future.*

## Current hooks:
   - **pre-commit:**
     - Age encrypts all K8S secrets in the repo
     - git add's all newly encrypted files
     - restarts the git commit process with secrets encrypted
     - Runs pre-commit lint checks
   - **post-commit:**
     - Age decrypts all K8S secrets in the repo to make it easier to work on them
