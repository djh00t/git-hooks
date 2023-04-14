#!/bin/bash
###
### Age Encrypt/decrypt functions
###

# Find files that are already encrypted and add them to $FILES_IGNORE
function do_find_pre_enc_files() {
  # Set the number of encrypted files to 0
  FILES_ENCRYPTED_COUNT=0

  # Find all yaml files in the search directory
  for file in $(find "$SEARCH_DIR" -name "*.yaml" -o -name "*.yml"); do

    # Check if the file contains "sops:" and "encrypted_regex: ^(data|stringData)$" and "kind: Secret" and "stringData:"
    if grep -q -E '(^kind: (Secret|ConfigMap)$)' "$file" && grep -q -E '(^sops:$)' "$file" && grep -q -E '(^    encrypted_regex:)' "$file"; then

      # Add the file to the FILES_IGNORE array
      FILES_IGNORE+=("$file")

      # Add 1 to the count of encrypted files
      FILES_ENCRYPTED_COUNT=$((FILES_ENCRYPTED_COUNT + 1))
    fi
  done

  # Export the ${FILES_IGNORE[@]} array so other functions can use it
  export FILES_IGNORE

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

  # Get root of current git repo and set as SEARCH_DIR
  SEARCH_DIR=$(git rev-parse --show-toplevel)

  # Find candidate files in $SEARCH_DIR that have a yaml or yml file extension, contain "data:" or "stringData:" and add them to the FILES_CAND array
  for file in $(find "$SEARCH_DIR" -name "*.yaml" -o -name "*.yml"); do
    if grep -q -E '(^kind: (Secret|ConfigMap)$)' "$file" && grep -q -E '(^data:|^stringData:)' "$file"; then
      FILES_CAND+=("$file")
    fi
  done

  # Echo the number of candidate files
  echo -e "        There are ${#FILES_CAND[@]} candidate files in your repo."

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

  # Remove ${FILES_IGNORE[@]} from ${FILES_CAND[@]}
  for FILE in "${FILES_IGNORE[@]}"; do
    # Echo the file being removed from the FILES_CAND array
    echo -e "  ${YELLOW}IGNORING:${ENDCOLOR} $FILE"
    # Remove the file from the FILES_CAND array
    FILES_CAND=("${FILES_CAND[@]/$FILE/}")
  done

  # Add the remaining files to the FILES_ENCRYPT array, ignoring any blank or empty records
  for FILE in "${FILES_CAND[@]}"; do
    if [ -n "$FILE" ]; then
      FILES_ENCRYPT+=("$FILE")
    fi
  done

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

  # Set FILES_DECRYPT_COUNT to 0
  FILES_DECRYPT_COUNT=0

  # Find candidate files in $SEARCH_DIR that have a yaml or yml file extension, contain "sops:" and "encrypted_regex: ^(data|stringData)$" and "kind: Secret" and "stringData: and add them to the FILES_DECRYPT array
  for file in $(find "$SEARCH_DIR" -name "*.yaml" -o -name "*.yml"); do
    if grep -q "kind: Secret" "$file" && grep -q "stringData:" "$file" && grep -q "data:" "$file" && grep -q "sops:" "$file" && grep -q "encrypted_regex:" "$file"; then
      echo -e "  ${YELLOW}ADDING:${ENDCOLOR} $file"
      FILES_DECRYPT+=("$file")
      # Increment the result count
      FILES_DECRYPT_COUNT=$((FILES_DECRYPT_COUNT + 1))
    fi
    export EXIT_STATUS=0
  done

  # Echo the number of candidate files
  echo -e "        There are ${#FILES_DECRYPT[@]} candidate files in your repo."

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
