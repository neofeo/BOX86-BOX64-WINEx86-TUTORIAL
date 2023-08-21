#!/bin/bash

# Path to the configuration file
CONFIG_FILE="$HOME/.wine_launcher_config"

# Check if the configuration file exists, and create it if not
if [ ! -e "$CONFIG_FILE" ]; then
    touch "$CONFIG_FILE"
fi

# Load saved choices from the configuration file
saved_choice="$(grep "$1" "$CONFIG_FILE" | cut -d '=' -f2)"

# If no saved choice exists, show the selection dialog
if [ -z "$saved_choice" ]; then
    choice=$(zenity --list --title="Choose Wine Options" --text="Select an option:" --radiolist --column "Select" --column "Option" TRUE "Fullscreen" FALSE "Virtual Desktop")
    if zenity --question --text="Remember this choice for $1?"; then
        echo "$1=$choice" >> "$CONFIG_FILE"
    fi
fi

# Use the saved choice if available, or use the user's new choice
if [ -z "$saved_choice" ]; then
    selected_choice="$choice"
else
    selected_choice="$saved_choice"
fi

EXEC_DIR=$(dirname "$1")

if [ "$selected_choice" == "Fullscreen" ]; then
    cd "$EXEC_DIR"
    wine "$1"
elif [ "$selected_choice" == "Virtual Desktop" ]; then
    cd "$EXEC_DIR"
    wine explorer /desktop=1024x768 "$1"
fi
