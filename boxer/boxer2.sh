#!/bin/bash

# Check and install required packages
packages=("zenity" "glxinfo" "neofetch")
packages_to_install=()

for package in "${packages[@]}"; do
    if ! command -v "$package" &> /dev/null; then
        packages_to_install+=("$package")
    fi
done

if [ ${#packages_to_install[@]} -gt 0 ]; then
    echo "The following packages need to be installed: ${packages_to_install[@]}"
    echo "Installing..."
    sudo apt-get update
    sudo apt-get install -y "${packages_to_install[@]}"
fi


# Set the width and height of the Zenity window
width=600
height=400

# Display the introductory message using a text file
zenity --text-info \
       --title="Box86/Box64/Winex86 Installation Script" \
       --filename=<(echo -e "This script is a WIP for installing Box86/Box64/Winex86 on ARM Linux Debian/Ubuntu platforms that aren't RPI. It could be dangerous for your system to set up a multiarch platform (i.e., to add arm32 bits). Please beware: multiarch isn't a toy.\n\nIf you encounter any problems, please inform me at https://discord.com/invite/armbian.\n\nI am Microlinux (salva).") \
       --width=$width \
       --height=$height

# Confirm if the user wants to continue
zenity --question \
       --title="Confirmation" \
       --text="Do you want to proceed with the installation?" \
       --width=$width

# Check the return value of the Zenity dialog
if [ $? -eq 0 ]; then
    # User chose to proceed
    
    # Display a dialog to inform about the installation process
    zenity --info --text="We are going to set up a multiarch platform and install Box86 and Box64." --title="Installation Process"
    
else
    # User chose not to proceed
    zenity --warning --text="Installation process cancelled. Exiting..." --title="Installation Cancelled"
    exit 1
fi

# Gather system information
DISTRO=$(lsb_release -is 2>/dev/null)
ARCH=$(uname -m)
KERNEL=$(uname -r)
export BOX86_NOBANNER=1

# Check Internet Connection
if ! ping -c 1 google.com &> /dev/null; then
    zenity --error --text="No internet connection. Exiting..."
    exit 1
fi

# Check if the distro is Debian or Ubuntu
if [ "$DISTRO" != "Debian" ] && [ "$DISTRO" != "Ubuntu" ]; then
    zenity --error --text="This script only supports Debian and Ubuntu."
    exit 1
fi

# Check if the architecture is ARM64
if [ "$ARCH" != "aarch64" ]; then
    zenity --error --text="This script is intended for ARM64 platforms."
    exit 1
fi

# Check if the platform is "rk3588" or other RK linux device.
zenity --question --text="IMPORTANT: Are you using Rockchip Linux 5.10 on a Rockchip device(RK3588/RK3566/ETC)? if NO, then you are on MAINLINE LINUX"

# Check the user's response
if [ $? == 0 ]; then
    PLATFORM="rockchip-rk3588"
else
    PLATFORM="mainline"
fi


# Checking if Panfrost
if glxinfo -B | awk '/Device:/ { if (tolower($0) ~ /panfrost/) exit 0; else exit 1; }'; then
    echo "Panfrost driver detected."
else
    zenity --error --text="Panfrost driver not detected. Exiting..."
    exit 1
fi



# Check if armhf architecture is already added
dpkg --print-foreign-architectures | grep -q "armhf"
if [ $? -ne 0 ]; then
    echo -e "$Adding armhf architecture and updating...$"
    sudo dpkg --add-architecture armhf
    sudo apt -qq update
fi

# List of requi packages
PACKAGES=(
    cabextract
    p7zip-full
    libglu1-mesa:armhf
    libncurses6:armhf
    libc6:armhf
    libx11-6:armhf
    libgdk-pixbuf2.0-0:armhf
    libgtk2.0-0:armhf
    libstdc++6:armhf
    libsdl2-2.0-0:armhf
    mesa-va-drivers:armhf
    libsdl-mixer1.2:armhf
    libpng16-16:armhf
    libsdl2-net-2.0-0:armhf
    libopenal1:armhf
    libsdl2-image-2.0-0:armhf
    libjpeg62:armhf
    libudev1:armhf
    libgl1-mesa-dev:armhf
    libx11-dev:armhf
    libsdl2-image-2.0-0:armhf
    libsdl2-mixer-2.0-0:armhf
    libxpresent1:armhf
)

# Install required packages and handle conflicts
while [ ${#PACKAGES[@]} -gt 0 ]; do
    sudo apt install -y "${PACKAGES[@]}"
    if [ $? -ne 0 ]; then
        conflicting_package=$(sudo apt-get -s -o Debug::NoLocking=true install "${PACKAGES[@]}" 2>&1 | awk '/Conflicting packages/{print $NF}')
        if [ -n "$conflicting_package" ]; then
            echo -e "$Conflicting package detected: $conflicting_package. Removing from the list and retrying installation...$"
            PACKAGES=("${PACKAGES[@]/$conflicting_package}")
        else
            zenity --error --text="Installation failed due to other reasons. Exiting..."
            exit 1
        fi
    else
        break
    fi
done

# Check if Box86 and Box64 PPAs are already added
if ! grep -q "ryanfortner.github.io" /etc/apt/sources.list.d/box86.list /etc/apt/sources.list.d/box64.list; then
    echo -e "$Setting up for $PLATFORM platform...$"
    echo -e "$Installing Box86 and Box64...$"
    sudo wget https://ryanfortner.github.io/box86-debs/box86.list -O /etc/apt/sources.list.d/box86.list
    sudo wget https://ryanfortner.github.io/box64-debs/box64.list -O /etc/apt/sources.list.d/box64.list
    wget -qO- https://ryanfortner.github.io/box86-debs/KEY.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/box86-debs-archive-keyring.gpg
    wget -qO- https://ryanfortner.github.io/box64-debs/KEY.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/box64-debs-archive-keyring.gpg
    sudo apt -qq update
fi

if [ "$PLATFORM" == "rockchip-rk3588" ]; then
    sudo apt install box86-rk3588 box64-rk3588 -y
else
    sudo apt install box86-generic-arm box64-arm64 -y
fi

sleep 1

# Check if "box86" command produces output
output_box86=$(box86 2>&1)
if [ -z "$output_box86" ]; then
    zenity --error --text="Error: Box86 command not found or produced no output. Something happened, stopping here"
    exit 1
fi

# Check if "box64" command produces output
output_box64=$(box64 2>&1)
if [ -z "$output_box64" ]; then
    zenity --error --text="Error: Box64 command not found or produced no output. Something happened, stopping here"
    exit 1
fi

# Both "box86" and "box64" commands produced output
echo "Both 'box86' and 'box64' commands are working. Continuing"


# Set PAN_MESA_DEBUG for OpenGL 3.3 if not already set
if [[ -z $(grep "PAN_MESA_DEBUG=gl3" /etc/environment) ]]; then
    echo "Setting PAN_MESA_DEBUG environment variable..."
    echo "PAN_MESA_DEBUG=gl3" | sudo tee -a /etc/environment > /dev/null
else
    echo "PAN_MESA_DEBUG environment variable already set. Skipping."
fi


# Check if there's output from running Wine and if ~/wine directory exists
wine_output=$(wine --version 2>&1)
wine_directory=~/wine

if [[ -n "$wine_output" && -d "$wine_directory" ]]; then
    zenity --question \
           --title="Remove Existing Wine Installation" \
           --text="The current Wine installation in '$wine_directory' seems working.\nDo you want to remove it before continuing?" \
           --width=400

    case $? in
        0)
            echo "Removing existing Wine installation..."
            rm -rf "$wine_directory"
            ;;
        1)
            echo "Keeping existing Wine installation."
            exit 0
            ;;
    esac
fi

# Display Wine version selection dialog using zenity

wine_version=$(zenity --question \
    --title="Wine Version Selection" \
    --text="Choose Wine version to install:" \
    --ok-label="Wine 7.0" \
    --cancel-label="Wine 8.0" \
    --width=300)

if [ $? -eq 0 ]; then
    wine_version="7.0"
else
    wine_version="8.0"
fi

case $wine_version in
    "7.0")
        echo "Installing Wine 7.0 x86..."
        wget -q -O ~/wine-7.0-x86.tar.xz https://github.com/Kron4ek/Wine-Builds/releases/download/7.0/wine-7.0-x86.tar.xz
        tar -xf ~/wine-7.0-x86.tar.xz -C ~/
        mv ~/wine-7.0-x86 ~/wine
        rm ~/wine-7.0-x86.tar.xz
        
        # Create symbolic links for Wine binaries
        echo "Creating symbolic links for Wine binaries..."
        sudo ln -s ~/wine/bin/wine /usr/local/bin/
        sudo ln -s ~/wine/bin/winecfg /usr/local/bin/
        sudo ln -s ~/wine/bin/wineserver /usr/local/bin/
        sudo ln -s ~/wine/bin/wine64 /usr/local/bin/
        
        # Setup winetricks
        echo "Installing winetricks..."
        wget -q https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
        chmod +x winetricks
        sudo mv winetricks /usr/local/bin/
        ;;
        
    "8.0")
        echo "Installing Wine 8.0 x86..."
        wget -q -O ~/wine-8.0-x86.tar.xz https://github.com/Kron4ek/Wine-Builds/releases/download/8.0/wine-8.0-x86.tar.xz
        tar -xf ~/wine-8.0-x86.tar.xz -C ~/
        mv ~/wine-8.0-x86 ~/wine
        rm ~/wine-8.0-x86.tar.xz
        
        # Create symbolic links for Wine binaries
        echo "Creating symbolic links for Wine binaries..."
        sudo ln -s ~/wine/bin/wine /usr/local/bin/
        sudo ln -s ~/wine/bin/winecfg /usr/local/bin/
        sudo ln -s ~/wine/bin/wineserver /usr/local/bin/
        sudo ln -s ~/wine/bin/wine64 /usr/local/bin/
        
        # Setup winetricks
        echo "Installing winetricks..."
        wget -q https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
        chmod +x winetricks
        sudo mv winetricks /usr/local/bin/
        ;;
        
    *)
        echo "Exiting..."
        exit 0
        ;;
esac

# Verify Wine installation
if wine --version &>/dev/null; then
    echo "Wine installation seems successful. Continuing with the setup."
else
    error_message="Wine installation failed."
    zenity --error --text="$error_message"
    exit 1
fi

# Clone the GitHub repository for the shortcuts
echo -e "$Cloning the BOX86-BOX64-WINEx86-TUTORIAL repository...$"
git clone https://github.com/neofeo/BOX86-BOX64-WINEx86-TUTORIAL.git ~/boxer_repo

# Check if .icons folder exists, create it if not
if [ ! -d ~/.icons ]; then
    echo -e "$.icons folder doesn't exist, creating...$"
    mkdir -p ~/.icons
fi

# Copy icons from the cloned repository to ~/.icons
echo -e "$Copying icon files to .icons folder...$"
cp -r ~/boxer_repo/boxer/icons/* ~/.icons/

# Copy the desktop entries from the cloned repository to ~/.local/share/applications/
echo -e "$Copying the desktop entries...$"
cp -r ~/boxer_repo/boxer/shortcuts/* ~/.local/share/applications/
chmod +x ~/.local/share/applications/wine_launcher.sh

echo "Shortcuts were installed."

# Remove the cloned repository folder
echo -e "$Removing cloned repository folder...$"
rm -rf ~/boxer_repo

echo "Repository folder removed."

# Set up custom keyboard shortcut for killing Wine
echo -e "$Setting up custom keyboard shortcut for killing Wine...$"

desktop_environment=$(neofetch --stdout | awk '/DE:/ {print tolower($2)}')

if [ "$desktop_environment" == "gnome" ]; then
    echo "Setting up custom keyboard shortcut for killing Wine..."
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Kill Wine (wineserver -k)'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'wineserver -k'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Primary>q'
    zenity --info --text="You can now use the Left Ctrl + Q shortcut to quickly kill any Wine processes."

    # Set default application for .exe files to wine.desktop
    xdg-mime default wine.desktop application/x-ms-dos-executable
elif [ "$desktop_environment" == "xfce" ]; then
    echo "Setting up custom keyboard shortcut for killing Wine..."
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Primary>q" -n -t string -s "wineserver -k"
    zenity --info --text="You can now use the Left Ctrl + Q shortcut to quickly kill any Wine processes."
    # Set default application for .exe files to wine.desktop
    xdg-mime default wine.desktop application/x-ms-dos-executable
else
    echo -e "$Unsupported desktop environment. No custom keyboard shortcut set for killing Wine.$"
fi


# Download and install Wine Mono
echo "Downloading and installing Wine Mono..."
mkdir -p ~/.cache/wine/

file_path=~/.cache/wine/wine-mono-7.4.0-x86.msi
if [ ! -f "$file_path" ]; then
    wget https://dl.winehq.org/wine/wine-mono/7.4.0/wine-mono-7.4.0-x86.msi -P ~/.cache/wine/
    ~/wine/bin/wineboot > /dev/null 2>&1
else
    echo "Wine Mono file already exists. Skipping download but launching wineboot anyway."
    ~/wine/bin/wineboot > /dev/null 2>&1
fi


# Ask user if they want to install additional components with winetricks
zenity --question \
       --title="Winetricks Additional Components" \
       --text="Do you want to install additional components using winetricks?\nIt will take a while, approximately 15 minutes.\n\nComponents to be installed: mfc42 vcrun6 vb6run xact d3drm d3dx9 d3dx9_43 d3dcompiler_43 msxml3 vcrun2003 vcrun2005 vcrun2008" \
       --width=400

case $? in
    0)
        echo "Installing additional components using winetricks..."
        W_OPT_UNATTENDED=1 winetricks mfc42 vcrun6 vb6run xact d3drm d3dx9 d3dx9_43 d3dcompiler_43 msxml3 vcrun2003 vcrun2005 vcrun2008
        ;;
    1)
        echo "Skipping installation of additional components."
        ;;
esac

# Ask user if they want to upgrade Mesa drivers
if [ "$PLATFORM" != "rockchip-rk3588" ]; then
    zenity --question \
           --title="Upgrade Mesa Drivers" \
           --text="Do you want to upgrade Mesa drivers for the latest Panfrost (may be unstable)?" \
           --width=400

    case $? in
        0)
            echo "Upgrading Mesa drivers for Panfrost..."
            if [ "$DISTRO" == "Ubuntu" ]; then
                sudo add-apt-repository --yes ppa:oibaf/graphics-drivers
                sudo apt -qq update
                sudo apt -qq install mesa-va-drivers:armhf mesa-va-drivers libd3dadapter9-mesa:armhf -y
                zenity --info --text="After this, you can try galliumnine (Native Dx9) after installing 'nine' with 'winetricks galliumnine' and launching 'wine ninewinecfg' to check if it works."
            else
                echo -e "Unsupported distribution for Mesa driver upgrade."
            fi
            ;;
        1)
            echo "Skipping upgrade of Mesa drivers."
            ;;
    esac
fi


zenity --info --text="Hopefully everything works fine now. You should reboot just in case to get the Mesa environment variable working (so, OpenGL 3.3, mostly for the Linux x86_64 and x86 games)."

# Ask user if they want to reboot
zenity --question \
       --title="Reboot System" \
       --text="Do you want to reboot your system?" \
       --width=400

case $? in
    0)
        echo "Rebooting..."
        sudo reboot
        ;;
    1)
        echo "You can manually reboot your system later."
        ;;
esac


