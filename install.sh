#!/bin/bash
###
### Install commit hooks for git - run this script from the root of the repo
###

# Find root of git repo:
REPO_ROOT=$(git rev-parse --show-toplevel)

# If we're not in a git repo, exit
if [[ ! -d $REPO_ROOT ]]; then
  echo "Error: Not in a git repo"
  exit 1
fi

# Move to the root of the repo
cd $REPO_ROOT

# Create the hooks directory if it doesn't exist
echo "Making sure that the hooks directory exists..."
echo
if [[ ! -d .git/hooks ]]; then
  mkdir .git/hooks
fi

# Install the pre-commit pip package if it isn't already installed
PC_INSTALLED=$(which pre-commit)
if [[ -z $PC_INSTALLED ]]; then
  echo "pre-commit not installed, installing..."
  echo
  pip install pre-commit
else
  echo "pre-commit already installed"
fi

# If .git/hooks/pre-commit doesn't exist, install pre-commit
PC_REPO_INSTALLED=$(grep -c "pre-commit" .git/hooks/pre-commit)
if [[ $PC_REPO_INSTALLED -eq 0 ]]; then
  echo "pre-commit not installed in repo, installing..."
  echo
  pre-commit install
else
  echo "pre-commit already installed in repo"
fi

# Make sure that an includes directory exists in the repo root
echo "Making sure that the includes directory exists..."
echo
cd $REPO_ROOT
if [[ ! -d includes ]]; then
  mkdir includes
fi

# Add git-hooks as a submodule in the repo includes directory if it isn't
# already there
echo "Making sure that the git_hooks submodule exists..."
echo
cd $REPO_ROOT/includes
if [[ ! -d git_hooks ]]; then
  git submodule add git@github.com:djh00t/git-hooks.git
  cd git-hooks
  git add .gitmodules git-hooks
  git commit -m "added git-hooks submodule"
  git push origin master
else
  echo "git_hooks submodule already exists"
fi

# Symlink the pre-commit hook
echo "Symlinking the pre-commit hook..."
echo
cd $REPO_ROOT
if [[ ! -f .git/hooks/pre-commit ]]; then
  ln -s includes/git_hooks/pre-commit .git/hooks/pre-commit
else
  echo "Error: A pre-commit hook already exists"
  exit 1
fi

# Symlink the post-commit hook
echo "Symlinking the post-commit hook..."
echo
cd $REPO_ROOT
if [[ ! -f .git/hooks/post-commit ]]; then
  ln -s includes/git_hooks/post-commit .git/hooks/post-commit
else
  echo "Error: A post-commit hook already exists"
  exit 1
fi
