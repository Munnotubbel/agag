#!/bin/bash

set -e

source "./fancy.sh"

load_and_execute() {
    local script=$1
    if [ -f "$script" ]; then
        print_fancy "Executing $script" "green" "🚀"
        source "$script"
    else
        print_fancy "Warning: $script not found" "yellow" "⚠️"
    fi
}

print_fancy "Starting setup process..." "green" "🔧"

load_and_execute "install_ansible.sh"

print_fancy "Installing required Ansible collections..." "yellow" "📦"
ansible-galaxy collection install community.docker
ansible-galaxy collection install community.general
ansible-galaxy collection install community.kubernetes
ansible-galaxy collection install community.library_inventory_filtering_v1
ansible-galaxy collection install kubernetes.core

print_fancy "Running Ansible playbook..." "yellow" "🎭"
ANSIBLE_STDOUT_CALLBACK=yaml ansible-playbook ../ansible/playbooks/site.yml -K

print_fancy "(>'-')> Setup completed! <('-'<)" "green" "🎉"