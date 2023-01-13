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

# Symlink the pre-commit hook
echo "Symlinking the pre-commit hook..."
echo
if [[ ! -f .git/hooks/pre-commit ]]; then
  ln -s ../../bash_includes/git_hooks/pre-commit .git/hooks/pre-commit
fi

# Symlink the post-commit hook
echo "Symlinking the post-commit hook..."
echo
if [[ ! -f .git/hooks/post-commit ]]; then
  ln -s ../../bash_includes/git_hooks/post-commit .git/hooks/post-commit
fi
