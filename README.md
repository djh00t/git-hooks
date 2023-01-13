# git-hooks
These git hooks have been written to simplify working with K8S and other devopsish activities.

PR's and feature requests welcomed. 

## Current hooks:
   - **pre-commit:**
     - Age encrypts all K8S secrets in the repo
     - git add's all newly encrypted files
     - restarts the git commit process with secrets encrypted
     - Runs pre-commit lint checks
   - **post-commit:**
     - Age decrypts all K8S secrets in the repo to make it easier to work on them
