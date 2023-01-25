#!/bin/bash
###
### Age Encrypt/decrypt functions
###

function do_get_files_encrypt() {
  echo "- Pre-commit unencrypted secrets check:"

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
      # Check if the file contains "kind: Secret" and "stringData:" or "data:" but does not contain "sops:" and "encrypted_regex: ^(data|stringData)$"
      if grep -q "kind: Secret" "$file" && grep -q "stringData:" "$file" && grep -q "data:" "$file" && ! grep -q "sops:" "$file" && ! grep -q "encrypted_regex: ^(data|stringData)$" "$file"; then
        # Add the file to the result array
        FILES_ENCRYPT+=("$file")
        echo -e "  ${YELLOW}ADDING:${ENDCOLOR} $file"
        # Increment the result count
        export FILES_ENCRYPT_COUNT=$((FILES_ENCRYPT_COUNT + 1))
      fi
    fi
  done

  # Check to see if any files were found
  if [ -z "$FILES_ENCRYPT" ]; then
    echo -e "  ${GREEN}OK.${ENDCOLOR} - No files to encrypt"
    echo
    export EXIT_STATUS=0
  else
    # Announce the number of files to encrypt
    if [ "$FILES_ENCRYPT_COUNT" -eq 1 ]; then
      echo -e "  ${YELLOW}SUMMARY:${ENDCOLOR} There is $FILES_ENCRYPT_COUNT file to encrypt"
    else
      echo -e "  ${YELLOW}SUMMARY:${ENDCOLOR} There are $FILES_ENCRYPT_COUNT files to encrypt"
    fi
    export EXIT_STATUS=0
  fi
}

function do_encrypt_files() {
  # Start file encryption
  echo
  if [ "$FILES_ENCRYPT_COUNT" -eq 1 ]; then
    echo -e "- Encrypting file:"
  else
    echo -e "- Encrypting files:"
  fi

  # Iterate over ${FILES_ENCRYPT[@]} and encrypt each file
  for FILE in "${FILES_ENCRYPT[@]}"; do
    do_pretty_processing "sops --age=$KEY_AGE --encrypt --encrypted-regex ^(data|stringData)$ --in-place $FILE"
    #git add -f $FILE
  done

  # Commit the encrypted files
  #git commit -m "Encrypted files: ${FILES_ENCRYPT[@]}"

  EXIT_STATUS=0
}

function do_get_files_decrypt() {
  echo "- Post-commit encrypted secrets check:"

  # The directory to search
  SEARCH_DIR="."

  # The array to store the result files
  FILES_DECRYPT=()

  # The variable to store the number of result files
  FILES_DECRYPT_COUNT=0

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
      # Check if the file contains "sops:" and "encrypted_regex: ^(data|stringData)$" and "kind: Secret" and "stringData:""
      if grep -q "kind: Secret" "$file" && grep -q "stringData:" "$file" && grep -q "data:" "$file" && grep -q "sops:" "$file" && grep -q "encrypted_regex:" "$file"; then
        # Add the file to the result array
        FILES_DECRYPT+=("$file")
        echo -e "  ${YELLOW}ADDING:${ENDCOLOR} $file"
        # Increment the result count
        FILES_DECRYPT_COUNT=$((FILES_DECRYPT_COUNT + 1))
      fi
    fi
    export EXIT_STATUS=0
  done

  # Print the result array
  # echo "FILES_DECRYPT: ${FILES_DECRYPT[@]}"

  # Check to see if any files were found
  if [ -z "$FILES_DECRYPT" ]; then
    echo -e "  ${GREEN}OK.${ENDCOLOR} - No files to decrypt"
    export EXIT_STATUS=0
  else
    # Announce the number of files to decrypt
    if [ "$FILES_DECRYPT_COUNT" -eq 1 ]; then
      echo -e "  ${YELLOW}SUMMARY:${ENDCOLOR} There is $FILES_ENCRYPT_COUNT file to decrypt"
    else
      echo -e "  ${YELLOW}SUMMARY:${ENDCOLOR} There are $FILES_ENCRYPT_COUNT files to decrypt"
    fi
    export EXIT_STATUS=0
  fi
}


function do_decrypt_files() {
  echo
  if [ "$FILES_DECRYPT_COUNT" -eq 1 ]; then
    echo -e "- Decrypting file:"
  else
    echo -e "- Decrypting files:"
  fi

  # Iterate over ${FILES_DECRYPT[@]} and decrypt each file
  for FILE in "${FILES_DECRYPT[@]}"; do
    do_pretty_processing "sops --decrypt --encrypted-regex '^(data|stringData)$' --in-place $FILE"
    #git add -f $FILE
  done

  # Commit the decrypted files
  #git commit -m "Decrypted files: ${FILES_DECRYPT[@]}"

  EXIT_STATUS=0
  
  echo
  echo "- Decryption complete."
}