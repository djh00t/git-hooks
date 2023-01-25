#!/bin/bash
###
### Age Encrypt/decrypt functions
###

# Find files that are already encrypted
function do_find_pre_enc_files() {
  # Find files that are already encrypted and add them to $FILES_IGNORE
  FILES_ENCRYPTED_COUNT=0
  for file in $(find "$SEARCH_DIR" -name "*.yaml" -o -name "*.yml"); do
    if grep -q -E '(^kind: (Secret|ConfigMap)$)' "$file" && grep -q -E '(^sops:$)' "$file" && grep -q -E '(^    encrypted_regex:)' "$file"; then
      export FILES_IGNORE+=("$file")
      # Add 1 to the count of ecncrypted files
      FILES_ENCRYPTED_COUNT=$((FILES_ENCRYPTED_COUNT + 1))
    fi
  done

  # Announce the number of encrypted files found
  if [ "$FILES_ENCRYPTED_COUNT" -eq 0 ]; then
    echo -e "        There are $FILES_ENCRYPTED_COUNT encrypted files in your repo."
  elif [ "$FILES_ENCRYPTED_COUNT" -eq 1 ]; then
    echo -e "        There is $FILES_ENCRYPTED_COUNT encrypted file in your repo, adding it to the ignore list."
  else
    echo -e "        There are $FILES_ENCRYPTED_COUNT encrypted files in your repo, adding them to the ignore list."
  fi
}

function do_get_files_encrypt() {
  echo "- Pre-commit unencrypted secrets check:"

  # The directory to search
  SEARCH_DIR="."

  # Create array to store candidate files
  FILES_CAND=()

  # Create array to store the result files
  FILES_ENCRYPT=()

  # Create variable to store the number of result files
  FILES_ENCRYPT_COUNT=0

  # Check if the ignore file exists
  if [ -f "$SEARCH_DIR/.k8s_password_hooks_ignore" ]; then
    # Read the ignore file and create an array of ignored files
    FILES_IGNORE=($(cat "$SEARCH_DIR/.k8s_password_hooks_ignore"))
    echo -e "  ${YELLOW}INFO:${ENDCOLOR} Found $SEARCH_DIR/.k8s_password_hooks_ignore"
    echo -e "        There are ${#FILES_IGNORE[@]} files in your ignore file."
    do_find_pre_enc_files
    echo -e "        There are ${#FILES_IGNORE[@]} files being ignored in total."
  else
    # Create an empty array of ignored files
    FILES_IGNORE=()
    # Find files that are already encrypted and add them to $FILES_IGNORE
    do_find_pre_enc_files
  fi

  # Get candidate files to encrypt
  export FILES_CAND=($(find $SEARCH_DIR \( -name "*.yml" -o -name "*.yaml" \) -exec grep -lE '^(data:|stringData:)$' {} \; | xargs grep -EL '((config|values)\.(yml|yaml):)'))
  echo -e "        There are ${#FILES_CAND[@]} candidate files"

  # Remove ${FILES_IGNORE[@]} from ${FILES_CAND[@]}
  for CAND_FILE in "${FILES_CAND[@]}"; do
    IGNORE=0

    for IGNORE_FILE in "${FILES_IGNORE[@]}"; do
      if [ "${CAND_FILE}" = "${IGNORE_FILE}" ]; then
        IGNORE=1
      fi
    done

    # only add to encrypted array if wasnt ignored
    if [ "${IGNORE}" -eq 0 ]; then
      FILES_ENCRYPT+=("${CAND_FILE}")
    fi

  done


  if [ ${#FILES_ENCRYPT[@]} -ne 0 ]; then
    echo -e "        There are ${#FILES_ENCRYPT[@]} files to encrypt"
  fi
  echo
  
  # List the files to ignore
  if [ ${#FILES_IGNORE[@]} -ne 0 ]; then
    for FILE in "${FILES_IGNORE[@]}"; do
      echo -e "  ${YELLOW}IGNORING:${ENDCOLOR} $FILE"
    done
    echo
  fi

  # List the files to encrypt
  if [ ${#FILES_ENCRYPT[@]} -ne 0 ]; then
    for FILE in "${FILES_ENCRYPT[@]}"; do
      echo -e "  ${YELLOW}ADDING:${ENDCOLOR} $FILE"
    done
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
    FILES_IGNORE=($(cat "$SEARCH_DIR/.k8s_password_hooks_ignore"))
  else
    # Create an empty array of ignored files
    FILES_IGNORE=()
  fi

  # Find all yaml files in the search directory
  for file in $(find "$SEARCH_DIR" -name "*.yaml" -o -name "*.yml"); do
    # Check if the file is in the ignore list
    if [[ ! " ${FILES_IGNORE[@]} " =~ " ${file} " ]]; then
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
