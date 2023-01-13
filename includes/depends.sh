#!/bin/bash
###
### Post-commit hook that encrypts files containing age encrypted kubernetes secrets
### File should be .git/hooks/post-commit and executable

# Add dependencies and includes
# Add color include if $ENDCOLOR is not defined
if [ -z "$ENDCOLOR" ]; then
  source includes/color.sh
fi

# Add dependencies and includes if $pip isn't defined
if [ -z "$pip" ]; then
  source includes/depends.sh
fi

# Setup EXIT_STATUS variable
export EXIT_STATUS=0

# Check if .k8s_password_hooks exists
if [ ! -r '.k8s_password_hooks' ]; then
  export EXIT_STATUS=0
fi

function do_check_age_prv_key() {
  # Ensure that age private key exists

  # The current user
  USER=$(whoami)

  # The path for linux
  LINUX_PATH="~/.config/sops/age/keys.txt"

  # The path for MacOS
  MACOS_PATH="/Users/$USER/.config/sops/age/keys.txt"

  if [ -f "$LINUX_PATH" ]; then
    echo '#'
    echo -e "# ${GREEN}Age keys.txt found in $LINUX_PATH...${ENDCOLOR}"
    echo '#'
  elif [ -f "$MACOS_PATH" ]; then
    echo '#'
    echo -e "# ${GREEN}Age keys.txt found in $MACOS_PATH...${ENDCOLOR}"
    echo '#'
  else
    echo '#'
    echo -e "# ${RED}╔══════════════════════════════════════════════════════════════╗${ENDCOLOR}"
    echo -e "# ${RED}║          ${BOLDYELLOW} !!! ERROR: Age private key not found !!!           ${ENDCOLOR}${RED}║${ENDCOLOR}"
    echo -e "# ${RED}╠══════════════════════════════════════════════════════════════╣${ENDCOLOR}"
    echo -e "# ${RED}║${ENDCOLOR} Please retrieve the age private key from the secrets manager ${ENDCOLOR}${RED}║${ENDCOLOR}"
    echo -e "# ${RED}║${ENDCOLOR} and save it to ~/.config/sops/age/keys.txt                   ${ENDCOLOR}${RED}║${ENDCOLOR}"
    echo -e "# ${RED}╚══════════════════════════════════════════════════════════════╝${ENDCOLOR}"
    echo '#'
    sleep 3
    export EXIT_STATUS=1
  fi

}

function do_check_age_pub_key() {
  # Ensure that age public key exists
 
  PUB_AGE=".age.pub"

  if [ -f "$PUB_AGE" ]; then
    echo '#'
    echo -e "# ${GREEN}Age $PUB_AGE found in repo...${ENDCOLOR}"
    echo '#'
  else
    echo '#'
    echo -e "# ${RED}╔══════════════════════════════════════════════════════════════╗${ENDCOLOR}"
    echo -e "# ${RED}║          ${BOLDYELLOW} !!! ERROR: Age public key not found !!!           ${ENDCOLOR}${RED}║${ENDCOLOR}"
    echo -e "# ${RED}╠══════════════════════════════════════════════════════════════╣${ENDCOLOR}"
    echo -e "# ${RED}║${ENDCOLOR} Please retrieve the age public key from the secrets manager ${ENDCOLOR}${RED}║${ENDCOLOR}"
    echo -e "# ${RED}║${ENDCOLOR} and save it to .age.pub in the root of your repo.           ${ENDCOLOR}${RED}║${ENDCOLOR}"
    echo -e "# ${RED}╚══════════════════════════════════════════════════════════════╝${ENDCOLOR}"
    echo '#'
    sleep 3
    export EXIT_STATUS=1
  fi

}

function do_get_files_encrypt() {
  echo '#'
  echo '# PRE-COMMIT ENCRYPTION CHECK'
  echo '#'

  # The directory to search
  SEARCH_DIR="."

  # The array to store the result files
  FILES_ENCRYPT=()

  # The variable to store the number of result files
  FILES_ENCRYPT_COUNT=0

  # Check if the ignore file exists
  if [ -f "$SEARCH_DIR/.k8s_password_hooks_ignore" ]; then
    # Read the ignore file and create an array of ignored files
    IGNORE_FILES=($(cat "$SEARCH_DIR/.k8s_password_hooks_ignore"))
  else
    # Create an empty array of ignored files
    IGNORE_FILES=()
  fi

  # Find all yaml files in the search directory
  for file in $(find "$SEARCH_DIR" -name "*.yaml" -o -name "*.yml"); do
    # Check if the file is in the ignore list
    if [[ ! " ${IGNORE_FILES[@]} " =~ " ${file} " ]]; then
      # Check if the file contains "kind: Secret" and "stringData:" but does not contain "sops:" and "encrypted_regex: ^(data|stringData)$"
      if grep -q "kind: Secret" "$file" && grep -q "stringData:" "$file" && ! grep -q "sops:" "$file" && ! grep -q "encrypted_regex: ^(data|stringData)$" "$file"; then
        # Add the file to the result array
        FILES_ENCRYPT+=("$file")
        echo "# Adding $file"
        # Increment the result count
        FILES_ENCRYPT_COUNT=$((FILES_ENCRYPT_COUNT + 1))
      fi
    fi
  done

  # Check to see if any files were found
  if [ -z "$FILES_ENCRYPT" ]; then
    echo "# No files to encrypt"
    echo '#'
    export EXIT_STATUS=0
  else
    # Announce the number of files to encrypt
    echo '#'
    echo "# There are $FILES_ENCRYPT_COUNT files to encrypt"
  fi
}

function do_encrypt_files() {
  # Start file encryption
  echo '#'
  echo "# Encrypting files..."
  echo '#'

  # Import public key
  export KEY_AGE=$(cat .age.pub)

  # Iterate over ${FILES_ENCRYPT[@]} and encrypt each file
  for FILE in "${FILES_ENCRYPT[@]}"; do
    echo "# Encrypting $FILE"

    # Encrypt the file
    sops --age=$KEY_AGE --encrypt --encrypted-regex '^(data|stringData)$' --in-place $FILE

    # Add decrypted file to next git commit to reduce IDE weirdness
    git add $FILE

    # Check if the encryption was successful
    if [[ $? -ne 0 ]]; then
      echo "Error encrypting $FILE - Exiting"
      exit 1
    else
      # Add encrypted file to next git commit
      git add $FILE
      echo '#'
    fi
  done

  echo "# Encryption complete"
  
  # Commit the encrypted files
  git commit -m "Encrypted files: ${FILES_ENCRYPT[@]}"
  
  EXIT_STATUS=0
}

# Ensure that age private key is configured
if [ $EXIT_STATUS = 0 ]; then
  do_check_age_prv_key
  do_check_age_pub_key
fi

# Get list of files to encrypt
if [ $EXIT_STATUS = 0 ]; then
  do_get_files_encrypt
fi

# Encrypt files
# If $FILES_ENCRYPT_COUNT is greater than 0 run do_encrypt_files
if [ $EXIT_STATUS = 0 ] && [ $FILES_ENCRYPT_COUNT -gt 0 ]; then
  do_encrypt_files
fi

###
### Run pre-commit hooks
###
INSTALL_PYTHON=$(which python3)
ARGS=(hook-impl --config=.pre-commit-config.yaml --hook-type=pre-commit)
pre-commit "${ARGS[@]}"


HERE="$(cd "$(dirname "$0")" && pwd)"
ARGS+=(--hook-dir "$HERE" -- "$@")

if [ -x "$INSTALL_PYTHON" ]; then
  exec "$INSTALL_PYTHON" -mpre_commit "${ARGS[@]}"
elif command -v pre-commit >/dev/null; then
  exec pre-commit "${ARGS[@]}"
else
  echo '`pre-commit` not found.  Did you forget to activate your virtualenv?' 1>&2
  export EXIT_STATUS=1
fi

exit $EXIT_STATUS
