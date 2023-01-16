#!/bin/bash
###
### Add color formatting variables to bash scripts
###

# Example use case:
#    echo '#'
#    echo -e "# ${RED}╔══════════════════════════════════════════════════════════════╗${ENDCOLOR}"
#    echo -e "# ${RED}║          ${BOLDYELLOW} !!! ERROR: Age private key not found !!!           ${ENDCOLOR}${RED}║${ENDCOLOR}"
#    echo -e "# ${RED}╠══════════════════════════════════════════════════════════════╣${ENDCOLOR}"
#    echo -e "# ${RED}║${ENDCOLOR} Please retrieve the age private key from the secrets manager ${ENDCOLOR}${RED}║${ENDCOLOR}"
#    echo -e "# ${RED}║${ENDCOLOR} and save it to ~/.config/sops/age/keys.txt                   ${ENDCOLOR}${RED}║${ENDCOLOR}"
#    echo -e "# ${RED}╚══════════════════════════════════════════════════════════════╝${ENDCOLOR}"
#    echo '#'

# Color formatting variables
export WHITE='\033[97m'
export RED='\033[31m'
export GREEN='\033[32m'
export YELLOW='\033[33m'
export BLUE='\033[34m'

export BOLDWHITE='\033[1;97m'
export BOLDRED='\033[1;31m'
export BOLDGREEN='\033[1;32m'
export BOLDYELLOW='\033[1;33m'
export BOLDBLUE='\033[1;34m'

export ENDCOLOR='\033[0m'


function do_pretty_processing(){
# Pretty processing function
  CMD=$1

  # Display pretty processing message
    echo -en "  ${YELLOW}PROCESSING:${ENDCOLOR} ${FILE[0]}"
    sleep 0.1
    echo -n "."
    sleep 0.1
    echo -ne "."
    sleep 0.1
    echo -ne "."
    sleep 0.1
    echo -ne "\t"
    sleep 0.1
    $CMD
    # Check if the command was successful
    if [[ $? -ne 0 ]]; then
      echo -ne "  ${BOLDRED}ERROR:${ENDCOLOR} while processing - Exiting\n"
      exit 1
    else
      echo -ne "  ${GREEN}OK.${ENDCOLOR}\n"
    fi
}

echo
echo -e "- ${BOLDRED}C${BOLDGREEN}o${BOLDYELLOW}l${BOLDBLUE}o${BOLDWHITE}u${BOLDRED}r ${GREEN}f${YELLOW}o${BLUE}r${WHITE}m${RED}a${GREEN}t${YELLOW}t${BLUE}i${WHITE}n${RED}g ${ENDCOLOR}variables configured."
echo