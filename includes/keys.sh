#!/bin/bash
###
### Age key related functions
###

# Import public key
export KEY_AGE=$(cat .age.pub)
export KEY_AGE_PRV=$(cat ~/.config/sops/age/keys.txt)

function do_check_age_prv_key() {
  # Ensure that age private key exists
  echo "- Checking for age private key..."

  # The current user
  USER=$(whoami)

  # The path for linux
  LINUX_PATH="~/.config/sops/age/keys.txt"

  # The path for MacOS
  MACOS_PATH="/Users/$USER/.config/sops/age/keys.txt"

  if [ -f "$LINUX_PATH" ]; then
    echo -e "  ${GREEN}OK.${ENDCOLOR}"
    echo
  elif [ -f "$MACOS_PATH" ]; then
    echo -e "  ${GREEN}OK.${ENDCOLOR}"
    echo
  else
    echo
    echo -e "  ${RED}╔══════════════════════════════════════════════════════════════╗${ENDCOLOR}"
    echo -e "  ${RED}║          ${BOLDYELLOW} !!! ERROR: Age private key not found !!!           ${ENDCOLOR}${RED}║${ENDCOLOR}"
    echo -e "  ${RED}╠══════════════════════════════════════════════════════════════╣${ENDCOLOR}"
    echo -e "  ${RED}║${ENDCOLOR} Please retrieve the age private key from the secrets manager ${ENDCOLOR}${RED}║${ENDCOLOR}"
    echo -e "  ${RED}║${ENDCOLOR} and save it to ~/.config/sops/age/keys.txt                   ${ENDCOLOR}${RED}║${ENDCOLOR}"
    echo -e "  ${RED}╚══════════════════════════════════════════════════════════════╝${ENDCOLOR}"
    echo
    sleep 3
    export EXIT_STATUS=1
  fi

}

function do_check_age_pub_key() {
  # Ensure that age public key exists
  echo "- Checking for age public key..."

  PUB_AGE=".age.pub"

  if [ -f "$PUB_AGE" ]; then
    echo -e "  ${GREEN}OK.${ENDCOLOR}"
    echo
  else
    echo
    echo -e "  ${RED}╔══════════════════════════════════════════════════════════════╗${ENDCOLOR}"
    echo -e "  ${RED}║          ${BOLDYELLOW} !!! ERROR: Age public key not found !!!            ${ENDCOLOR}${RED}║${ENDCOLOR}"
    echo -e "  ${RED}╠══════════════════════════════════════════════════════════════╣${ENDCOLOR}"
    echo -e "  ${RED}║${ENDCOLOR} Please retrieve the age public key from the secrets manager  ${ENDCOLOR}${RED}║${ENDCOLOR}"
    echo -e "  ${RED}║${ENDCOLOR} and save it to .age.pub in the root of your repo.            ${ENDCOLOR}${RED}║${ENDCOLOR}"
    echo -e "  ${RED}╚══════════════════════════════════════════════════════════════╝${ENDCOLOR}"
    echo
    sleep 3
    export EXIT_STATUS=1
  fi

}

# Ensure that age private and public key is configured
if [ !-z $EXIT_STATUS = 0 ]; then
  do_check_age_prv_key
  do_check_age_pub_key
fi
