#!/bin/bash
###
### Dependency installer for git hooks
###

# Detect operating system
function detect_os_and_version() {
    # Detect the OS & Version
    echo "- Detecting OS and version..."
    OS=""
    OS_VERSION=""
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        export OS=$(cat /etc/os-release | (grep -v 'VERSION_ID=') | (grep -E 'ID=') | sort | sed 's/VERSION_ID=//;s/ID=//;s/"//g;')
        export OS_VERSION=$(cat /etc/os-release | grep -E 'VERSION_ID=' | cut -d'"' -f2)
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        export OS=$(sw_vers -productName)
        export OS_VERSION=$(sw_vers -productVersion)
    elif [[ "$OSTYPE" == "win32" ]]; then
        export OS="Windows"
    else
        echo -e "  ${BOLDRED}Unknown OS - exiting${ENDCOLOR}"
        exit 1
    fi

    # If both $OS and $OS_VERSION are defined, print the OS and version
    if [ -n "$OS" ] && [ -n "$OS_VERSION" ]; then
        echo -e "  ${BOLDBLUE}OS:${ENDCOLOR}       ${BLUE}$OS${ENDCOLOR}"
        echo -e "  ${BOLDBLUE}Version:${ENDCOLOR}  ${BLUE}$OS_VERSION${ENDCOLOR}"
        echo
    else
        echo -e " ${BOLDRED}Could not detect OS and version${ENDCOLOR}"
        exit 1
    fi
}

function do_install_homebrew() {
    # Check if Homebrew is installed first
    if command -v brew &>/dev/null; then
        echo -e " ${GREEN}Homebrew is already installed.${ENDCOLOR}"
    else
        echo -e " ${YELLOW}Homebrew is not installed. Installing...${ENDCOLOR}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

function do_configure_os_executables() {
    export python3=$(command -v python3)
    export pip=$(command -v pip3)
    export ts=$(command -v ts)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew=$(command -v brew)
    fi
}

function do_install_pip3_packages() {
    # Install the pip packages
    echo
    echo "- Checking required pip packages..."
    # pre-commit
    if ! command -v pre-commit &>/dev/null; then
        echo -e "  ${YELLOW}pre-commit could not be found, installing now${ENDCOLOR}"
        $(command -v pip3) install pre-commit
    fi

    # age
    if ! command -v age &>/dev/null; then
        echo -e "${YELLOW}age could not be found, installing now${ENDCOLOR}"
        $(command -v pip3) install age
    fi

    echo -e "  ${GREEN}OK.${ENDCOLOR}"
    echo
}

function os_ubuntu() {
    # Install dependencies for Ubuntu
    echo "- Installing dependencies for Ubuntu..."
    sudo apt-get install -y python3 python3-pip moreutils jq gnupg sops git age
    if $? -ne 0; then
        echo -e "  ${BOLDRED}Could not install dependencies${ENDCOLOR}"
        exit 1
    else
        echo -e "  ${GREEN}OK.${ENDCOLOR}"
    fi
}

function os_centos() {
    # Install dependencies for CentOS
    echo "- Installing dependencies for CentOS..."
    sudo yum install -y python3 python3-pip moreutils jq gnupg sops git age
    if $? -ne 0; then
        echo -e "  ${BOLDRED}Could not install dependencies${ENDCOLOR}"
        exit 1
    else
        echo -e "  ${GREEN}OK.${ENDCOLOR}"
    fi
}

function os_macos() {
    # Install dependencies for macOS
    echo "- Checking dependencies for macOS..."

    # Make sure homebrew is installed
    which -s brew || do_install_homebrew

    # Make sure that moreutils is installed
    which -s ts || brew install moreutils

    # Make sure that python3 is installed
    which -s python3 || brew install python3

    # Make sure that jq is installed
    which -s jq || brew install jq

    # Make sure that gnupg is installed
    which -s gpg || brew install gnupg

    # Make sure that sops is installed
    which -s sops || brew install sops

    # Make sure that pip3 is installed
    which -s pip3 || $(command -v python3) -m pip install --upgrade pip

    echo -e "  ${GREEN}OK.${ENDCOLOR}"
}

# Detect operating system
detect_os_and_version

# Install dependencies based on $OS
if [[ "$OS" == "ubuntu" ]]; then
    os_ubuntu
elif [[ "$OS" == "centos" ]]; then
    os_centos
elif [[ "$OS" == "macOS" ]]; then
    os_macos
else
    echo "Unknown OS. Please install dependencies manually."
    exit 1
fi

# Configure OS executable paths
do_configure_os_executables

# Install pip3 packages
do_install_pip3_packages
