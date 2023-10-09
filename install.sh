#!/bin/bash
###
### Install commit hooks for git - run this script from the root of the repo
###

# Make sure we're in the root of a git repo
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Error: this script must be run from the root of a git repository"
  exit 1
fi

# Create the hooks directory if it doesn't exist
echo "Making sure that the hooks directory exists..."
echo
if [[ ! -d .git/hooks ]]; then
  mkdir .git/hooks
fi

# Install the pre-commit pip package if it isn't already installed
echo "Installing the pre-commit pip package..."
echo
if [[ ! -d .git/hooks ]]; then
  pip install pre-commit
fi

# Install precommit into this repo if it isn't already installed
echo "Installing pre-commit into this repo..."
echo
if [[ ! -d .git/hooks ]]; then
  pre-commit install
fi

# Make sure that an includes directory exists in the repo root
echo "Making sure that the includes directory exists..."
echo
if [[ ! -d includes ]]; then
  mkdir includes
fi

# Add git-hooks as a submodule in the repo includes directory
cd includes
echo "Adding git-hooks as a submodule..."
git submodule add git@github.com:djh00t/git-hooks.git
cd git-hooks
git add .gitmodules git-hooks
git commit -m "added git-hooks submodule"

# Symlink the pre-commit hook
echo "Symlinking the pre-commit hook..."
echo
if [[ ! -f .git/hooks/pre-commit ]]; then
  ln -s includes/git_hooks/pre-commit .git/hooks/pre-commit
else
  echo "Error: A pre-commit hook already exists"
  exit 1
fi

# Symlink the post-commit hook
echo "Symlinking the post-commit hook..."
echo
if [[ ! -f .git/hooks/post-commit ]]; then
  ln -s includes/git_hooks/post-commit .git/hooks/post-commit
else
  echo "Error: A post-commit hook already exists"
  exit 1
fi
