#!/bin/bash

print_fancy() {
    local message="$1"
    local color="$2"
    local prefix="$3"

    case "$color" in
        "green") color_code="\033[0;32m" ;;
        "yellow") color_code="\033[0;33m" ;;
        "red") color_code="\033[0;31m" ;;
        *) color_code="\033[0m" ;;
    esac

    echo -e "${color_code}${prefix} ${message}\033[0m"
}