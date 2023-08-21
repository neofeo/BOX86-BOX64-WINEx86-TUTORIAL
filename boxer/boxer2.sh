#!/bin/bash

RED='\033[0;31m'
NC='\033[0m' # No Color

# Gather system information
DISTRO=$(lsb_release -is 2>/dev/null)
ARCH=$(uname -m)
KERNEL=$(uname -r)
export BOX86_NOBANNER=1

# Check if the distro is Debian or Ubuntu
if [ "$DISTRO" != "Debian" ] && [ "$DISTRO" != "Ubuntu" ]; then
    echo -e "${RED}This script only supports Debian and Ubuntu.${NC}"
    exit 1
fi

# Check if the architecture is ARM64
if [ "$ARCH" != "aarch64" ]; then
    echo -e "${RED}This script is intended for ARM64 platforms.${NC}"
    exit 1
fi

# Check if the kernel is specific to Rockchip RK3588
if [[ "$KERNEL" == *"rockchip-rk3588"* ]]; then
    PLATFORM="rockchip-rk3588"
else
    PLATFORM="mainline"
fi

# Panfrost check
echo "Checking for Panfrost driver..."
sudo apt install -qq -y mesa-utils neofetch
glxinfo -B | awk '/Device:/ { if (tolower($0) ~ /panfrost/) exit 0; else exit 1; }'
if [ $? -ne 0 ]; then
    echo -e "${RED}Panfrost driver not detected. Exiting...${NC}"
    exit 1
fi

echo -e "${RED}This script is a WIP for installing Box86/Box64/Winex86 on ARM Linux Debian/Ubuntu platforms that aren't RPI. It could destroy your system, beware; multiarch isn't a toy.${NC}"
echo -e "${RED}If you encounter any problems, inform me at https://discord.com/invite/armbian. I am Microlinux (salva).${NC}"
echo -e "${RED}We are going to set up a multiarch platform and install Box86 and Box64, then you will be asked to install Wine or not.${NC}"

# Check if armhf architecture is already added
dpkg --print-foreign-architectures | grep -q "armhf"
if [ $? -ne 0 ]; then
    echo -e "${RED}Adding armhf architecture and updating...${NC}"
    sudo dpkg --add-architecture armhf
    sudo apt -qq update
fi

# List of required packages
PACKAGES=(
    cmake
    cabextract
    p7zip-full
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
echo -e "${RED}Installing essential 32-bit ARM packages for Box86...${NC}"
while [ ${#PACKAGES[@]} -gt 0 ]; do
    sudo apt install -qq -y "${PACKAGES[@]}"
    if [ $? -ne 0 ]; then
        conflicting_package=$(sudo apt-get -s -o Debug::NoLocking=true install "${PACKAGES[@]}" 2>&1 | awk '/Conflicting packages/{print $NF}')
        if [ -n "$conflicting_package" ]; then
            echo -e "${RED}Conflicting package detected: $conflicting_package. Removing from the list and retrying installation...${NC}"
            PACKAGES=("${PACKAGES[@]/$conflicting_package}")
        else
            echo -e "${RED}Installation failed due to other reasons. Exiting...${NC}"
            exit 1
        fi
    else
        break
    fi
done

# Check if Box86 and Box64 PPAs are already added
if ! grep -q "ryanfortner.github.io" /etc/apt/sources.list.d/box86.list /etc/apt/sources.list.d/box64.list; then
    echo -e "${RED}Setting up for $PLATFORM platform...${NC}"
    echo -e "${RED}Installing Box86 and Box64...${NC}"
    sudo wget https://ryanfortner.github.io/box86-debs/box86.list -O /etc/apt/sources.list.d/box86.list
    sudo wget https://ryanfortner.github.io/box64-debs/box64.list -O /etc/apt/sources.list.d/box64.list
    wget -qO- https://ryanfortner.github.io/box86-debs/KEY.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/box86-debs-archive-keyring.gpg
    wget -qO- https://ryanfortner.github.io/box64-debs/KEY.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/box64-debs-archive-keyring.gpg
    sudo apt -qq update
fi

if [ "$PLATFORM" == "rockchip-rk3588" ]; then
    sudo apt install box86-rk3588 box64-rk3588 -y
else
    sudo apt install box86-generic-arm box64-generic-arm -y
fi


# Set PAN_MESA_DEBUG for OpenGL 3.3 if not already set
if [[ -z $(grep "PAN_MESA_DEBUG=gl3" /etc/environment) ]]; then
    echo "Setting PAN_MESA_DEBUG environment variable..."
    echo "PAN_MESA_DEBUG=gl3" | sudo tee -a /etc/environment > /dev/null
else
    echo "PAN_MESA_DEBUG environment variable already set. Skipping."
fi

# Prompt user for Wine version choice
echo -e "${RED}Do you want to install Wine x86 (32-bit) version 8.0 or 7.0? Wine x86_64 (amd64) is not the main focus for now, but may be added later.${NC}"
select wine_version in "7.0" "8.0" "No"; do
    case $wine_version in
        7.0)
            echo "Installing Wine 7.0 x86..."
            wget -q -O ~/wine-7.0-x86.tar.xz https://github.com/Kron4ek/Wine-Builds/releases/download/7.0/wine-7.0-x86.tar.xz
            tar -xf ~/wine-7.0-x86.tar.xz -C ~/
            mv ~/wine-7.0-x86 ~/wine
            rm ~/wine-7.0-x86.tar.xz
            break
            ;;
        8.0)
            echo "Installing Wine 8.0 x86..."
            wget -q -O ~/wine-8.0-x86.tar.xz https://github.com/Kron4ek/Wine-Builds/releases/download/8.0/wine-8.0-x86.tar.xz
            tar -xf ~/wine-8.0-x86.tar.xz -C ~/
            mv ~/wine-8.0-x86 ~/wine
            rm ~/wine-8.0-x86.tar.xz
            break
            ;;
        No)
            echo "Skipping Wine installation."
            break
            ;;
        *)
            echo -e "${RED}Invalid selection, please choose a valid option.${NC}"
            ;;
    esac
done

# Create symbolic links for Wine binaries
echo "Creating symbolic links for Wine binaries..."
sudo ln -s ~/wine/bin/wine /usr/local/bin/
sudo ln -s ~/wine/bin/winecfg /usr/local/bin/
sudo ln -s ~/wine/bin/wineserver /usr/local/bin/
sudo ln -s ~/wine/bin/wine64 /usr/local/bin/

# setup winetricks
echo "Installing winetricks..."
wget -q https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
sudo chmod +x winetricks
sudo mv winetricks /usr/local/bin

# Verify Wine installation
if wine --version &>/dev/null; then
    echo "Wine installation seems successful. Continuing with the setup."
else
    echo -e "${RED}Wine installation failed.${NC}"
    exit 1
fi

# Clone the GitHub repository for the shortcuts.
echo -e "${RED}Cloning the BOX86-BOX64-WINEx86-TUTORIAL repository...${NC}"
git clone https://github.com/neofeo/BOX86-BOX64-WINEx86-TUTORIAL.git ~/boxer

# Check if .icons folder exists, create it if not
if [ ! -d ~/.icons ]; then
    echo -e "${RED}.icons folder doesn't exist, creating...${NC}"
    mkdir -p ~/.icons
fi

# Copy icons from the cloned repository to ~/.icons
echo -e "${RED}Copying icon files to .icons folder...${NC}"
cp -r ~/boxer/icons/* ~/.icons/

# Copy the desktop entries from the cloned repository to ~/.local/share/applications/
echo -e "${RED}Copying the desktop entries...${NC}"
cp -r ~/boxer/shortcuts/* ~/.local/share/applications/
chmod +x ~/.local/share/applications/wine_launcher.sh

echo "wine.desktop and wine_launcher.sh installed."

# Set up custom keyboard shortcut for killing Wine
echo -e "${RED}Setting up custom keyboard shortcut for killing Wine...${NC}"

desktop_environment=$(neofetch --stdout | awk '/DE:/ {print tolower($2)}')

if [ "$desktop_environment" == "gnome" ]; then
    echo "Setting up custom keyboard shortcut for killing Wine on Xorg..."
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Kill Wine (wineserver -k)'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'wineserver -k'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Primary>q'
    echo "You can now use the Left Ctrl + Q shortcut to quickly kill any Wine processes."
elif [ "$desktop_environment" == "xfce" ]; then
    echo "Setting up custom keyboard shortcut for killing Wine..."
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Primary>q" -n -t string -s "wineserver -k"
    echo "You can now use the Left Ctrl + Q shortcut to quickly kill any Wine processes."
else
    echo -e "${RED}Unsupported desktop environment. No custom keyboard shortcut set for killing Wine.${NC}"
fi

# Download and install Wine Mono 8.0
echo -e "${RED}Downloading and installing Wine Mono 8.0...${NC}"
mkdir -p ~/wine/share/wine/mono/
wget https://dl.winehq.org/wine/wine-mono/8.0.0/wine-mono-8.0.0-x86.msi -P ~/wine/share/wine/mono/
WINEPREFIX=~/wine ~/wine/bin/wine msiexec /i ~/wine/share/wine/mono/wine-mono-8.0.0-x86.msi

# Unattended setup of Mono
echo -e "${RED}Setting up Mono (unattended)...${NC}"
WINE_MONO=--unattended WINEPREFIX=~/wine ~/wine/bin/wineboot


# Ask user if they want to install additional components with winetricks
echo -e "${RED}Do you want to install additional components using winetricks? It will take a while, 15 mins aprox.${NC}"
echo -e "${RED}Components to be installed: mfc42 vcrun6 vb6run xact d3drm d3dx9 d3dx9_43 d3dcompiler_43 msxml3 vcrun2003 vcrun2005 vcrun2008${NC}"
select install_winetricks in "Yes" "No"; do
    case $install_winetricks in
        Yes)
            echo "Installing additional components using winetricks..."
            W_OPT_UNATTENDED=1 winetricks mfc42 vcrun6 vb6run xact d3drm d3dx9 d3dx9_43 d3dcompiler_43 msxml3 vcrun2003 vcrun2005 vcrun2008
            break
            ;;
        No)
            echo "Skipping installation of additional components."
            break
            ;;
        *)
            echo -e "${RED}Invalid selection, please choose a valid option.${NC}"
            ;;
    esac
done

# Ask user if they want to upgrade Mesa drivers
if [ "$PLATFORM" != "rockchip-rk3588" ]; then
    echo -e "${RED}Do you want to upgrade Mesa drivers for the latest Panfrost (may be unstable)?${NC}"
    select upgrade_mesa in "Yes" "No"; do
        case $upgrade_mesa in
            Yes)
                echo "Upgrading Mesa drivers for Panfrost..."
                if [ "$DISTRO" == "Ubuntu" ] || [ "$DISTRO" == "Debian" ]; then
                    sudo add-apt-repository --yes ppa:oibaf/graphics-drivers
                    sudo apt -qq update
                    sudo apt -qq install mesa-va-drivers:armhf mesa-va-drivers libd3dadapter9-mesa:armhf -y
                    echo -e "${RED}After this, you can try galliumnine (Native Dx9) after installing 'nine' with 'winetricks galliumnine' and launching 'wine ninewinecfg' to check if it works.${NC}"
                else
                    echo -e "${RED}Unsupported distribution for Mesa driver upgrade.${NC}"
                fi
                break
                ;;
            No)
                echo "Skipping upgrade of Mesa drivers."
                break
                ;;
            *)
                echo -e "${RED}Invalid selection, please choose a valid option.${NC}"
                ;;
        esac
    done
fi

echo -e "${RED}Hopefully everything works fine now. You should reboot just in case to get the mesa env var working (so, OpenGL 3.3, mostly for the Linux x86_64 and x86 games).${NC}"

# Ask user if they want to reboot
echo -e "${RED}Do you want to reboot your system?${NC}"
select reboot_choice in "Yes" "No"; do
    case $reboot_choice in
        Yes)
            echo "Rebooting..."
            sudo reboot
            break
            ;;
        No)
            echo "You can manually reboot your system later."
            break
            ;;
        *)
            echo -e "${RED}Invalid selection, please choose a valid option.${NC}"
            ;;
    esac
done




