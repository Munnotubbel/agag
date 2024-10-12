#!/bin/bash

source "fancy.sh"

install_git() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            # Debian-based systems (Ubuntu, Debian)
            print_fancy "Debian-based system detected. Installing Git..." "green" "🐧"
            sudo apt-get update
            sudo apt-get install -y git
        elif [ -f /etc/redhat-release ]; then
            # Red Hat-based systems (CentOS, Fedora, RHEL)
            print_fancy "Red Hat-based system detected. Installing Git..." "green" "🎩"
            sudo yum install -y git
        else
            print_fancy "Unknown Linux distribution. Please install Git manually." "red" "❌"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        print_fancy "macOS detected. Installing Git..." "green" "🍎"
        if ! command -v brew &> /dev/null; then
            print_fancy "Homebrew not found. Installing Homebrew..." "yellow" "🍺"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install git
    else
        print_fancy "Unsupported operating system. Please install Git manually." "red" "❌"
        exit 1
    fi
}

# Check if Git is already installed
if ! command -v git &> /dev/null; then
    print_fancy "Git is not installed. Starting installation..." "yellow" "🚀"
    install_git
else
    print_fancy "Git is already installed." "green" "✅"
    git --version
fi