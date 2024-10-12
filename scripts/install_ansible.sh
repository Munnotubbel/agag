#!/bin/bash

source "fancy.sh"

check_ansible() {
    if command -v ansible &> /dev/null; then
        print_fancy "Ansible is already installed." "green" "✅"
        return 0
    else
        return 1
    fi
}

install_ansible() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/redhat-release ]; then
            print_fancy "Installing Ansible on Red Hat-based system..." "yellow" "🎩"
            if ! check_ansible; then
                sudo dnf install -y epel-release
                sudo dnf install -y ansible
            fi
        elif [ -f /etc/debian_version ]; then
            print_fancy "Installing Ansible on Debian-based system..." "yellow" "🐧"
            if ! check_ansible; then
                sudo apt-get update
                sudo apt-get install -y software-properties-common
                sudo apt-add-repository --yes --update ppa:ansible/ansible
                sudo apt-get install -y ansible
            fi
        else
            print_fancy "Unsupported Linux distribution. Please install Ansible manually." "red" "❌"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        print_fancy "Checking Ansible on macOS..." "yellow" "🍎"
        if ! check_ansible; then
            print_fancy "Installing Ansible on macOS..." "yellow" "🍎"
            if ! command -v brew &> /dev/null; then
                print_fancy "Homebrew not found. Installing Homebrew..." "yellow" "🍺"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install ansible
        fi
    else
        print_fancy "Unsupported operating system. Please install Ansible manually." "red" "❌"
        exit 1
    fi
}

# Main execution
install_ansible

# Verify installation
if check_ansible; then
    print_fancy "Ansible installation verified." "green" "✅"
else
    print_fancy "Ansible installation failed or not found." "red" "❌"
    exit 1
fi