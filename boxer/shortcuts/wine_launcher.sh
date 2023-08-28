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

# Launch Wine with the chosen option and monitor loading
if [ "$selected_choice" == "Fullscreen" ]; then
    cd "$EXEC_DIR"
    wine "$1" &
elif [ "$selected_choice" == "Virtual Desktop" ]; then
    cd "$EXEC_DIR"
    wine explorer /desktop=1024x768 "$1" &
fi

# Check if wine is running
is_wine_running() {
    pgrep wine >/dev/null
}

# Display Wine loading message using Zenity
loading_popup=$(zenity --info --text="Wine is loading. Please wait..." --title="Wine Loading" --timeout 5 --width=250 --height=100)

# Start a loop to monitor Wine loading
while is_wine_running; do
    # Check if a Wine window has been created
    wine_window_id=$(xprop -root | grep -i '_NET_ACTIVE_WINDOW(WINDOW)' | awk '{print $NF}')
    
    if [ -n "$wine_window_id" ]; then
        echo "Wine program has opened a window."
        break
    else
        echo "Wine program is loading..."
    fi
    
    sleep 1  # Adjust the sleep duration if needed
done

# Close the loading pop-up if it's still open
if [ -n "$loading_popup" ]; then
    kill "$loading_popup" >/dev/null 2>&1
fi
