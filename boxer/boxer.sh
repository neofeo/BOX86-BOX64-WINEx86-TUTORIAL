#!/bin/bash

# Gather system information
DISTRO=$(lsb_release -is 2>/dev/null)
ARCH=$(uname -m)
KERNEL=$(uname -r)

# Check if the distro is Debian or Ubuntu
if [ "$DISTRO" != "Debian" ] && [ "$DISTRO" != "Ubuntu" ]; then
    echo "This script only supports Debian and Ubuntu."
    exit 1
fi

# Check if the architecture is ARM64
if [ "$ARCH" != "aarch64" ]; then
    echo "This script is intended for ARM64 platforms."
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
glxinfo -B | awk '/Device:/ { if (tolower($0) ~ /panfrost/) exit 0; else exit 1; }'
if [ $? -ne 0 ]; then
    echo "Panfrost driver not detected. Exiting..."
    exit 1
fi

echo "This script it's a WIP for installing Box86/Box64/Winex86 on ARM Linux Debian/Ubuntu platforms that aren't RPI. It could destroy your system, beware, multiarch isn't a toy"
echo "inform me of any problem at https://discord.com/invite/armbian , I am Microlinux(salva)."
echo "We are going to setup a multiarch platform and install Box86 and Box64, then you will be asked to install Wine or not."

# Add armhf architecture and update
echo "Adding armhf architecture and updating..."
sudo dpkg --add-architecture armhf && sudo apt update

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
echo "Installing essential 32-bit ARM packages for Box86..."
while [ ${#PACKAGES[@]} -gt 0 ]; do
    sudo apt install -y "${PACKAGES[@]}"
    if [ $? -ne 0 ]; then
        conflicting_package=$(sudo apt-get -s -o Debug::NoLocking=true install "${PACKAGES[@]}" 2>&1 | awk '/Conflicting packages/{print $NF}')
        if [ -n "$conflicting_package" ]; then
            echo "Conflicting package detected: $conflicting_package. Removing from the list and retrying installation..."
            PACKAGES=("${PACKAGES[@]/$conflicting_package}")
        else
            echo "Installation failed due to other reasons. Exiting..."
            exit 1
        fi
    else
        break
    fi
done

# Install Box86 and Box64
echo "Setting up for $PLATFORM platform..."
echo "Installing Box86 and Box64..."
sudo wget https://ryanfortner.github.io/box86-debs/box86.list -O /etc/apt/sources.list.d/box86.list
sudo wget https://ryanfortner.github.io/box64-debs/box64.list -O /etc/apt/sources.list.d/box64.list
wget -qO- https://ryanfortner.github.io/box86-debs/KEY.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/box86-debs-archive-keyring.gpg
wget -qO- https://ryanfortner.github.io/box64-debs/KEY.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/box64-debs-archive-keyring.gpg
sudo apt update

if [ "$PLATFORM" == "rockchip-rk3588" ]; then
    sudo apt install box86-rk3588 box64-rk3588 -y
else
    sudo apt install box86-generic-arm box64-generic-arm -y
fi

# Set PAN_MESA_DEBUG for OpenGL 3.3
echo "Setting PAN_MESA_DEBUG environment variable..."
sudo bash -c "echo 'PAN_MESA_DEBUG=gl3' >> /etc/environment"

# Prompt user for Wine version choice
echo "Do you want to install Wine x86 (32-bit) version 8.0 or 7.0? Wine x86_64 (amd64) is not the main focus for now, but may be added later."
"
select wine_version in "7.0" "8.0" "No"; do
    case $wine_version in
        7.0)
            echo "Installing Wine 7.0 x86..."
            wget -O ~/wine-7.0-x86.tar.xz https://github.com/Kron4ek/Wine-Builds/releases/download/7.0/wine-7.0-x86.tar.xz
            tar -xf ~/wine-7.0-x86.tar.xz -C ~/
            mv ~/wine-7.0-x86 ~/wine
            rm ~/wine-7.0-x86.tar.xz
            break
            ;;
        8.0)
            echo "Installing Wine 8.0 x86..."
            wget -O ~/wine-8.0-x86.tar.xz https://github.com/Kron4ek/Wine-Builds/releases/download/8.0/wine-8.0-x86.tar.xz
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
            echo "Invalid selection, please choose a valid option."
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
wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
sudo chmod +x winetricks \
sudo mv winetricks /usr/local/bin

# Verify Wine installation
if wine --version &>/dev/null; then
    echo "Wine installation seems successful. Continuing with the setup"
else
    echo "Wine installation failed."
    exit 1
fi

# Download and install wine.desktop and wine_launcher.sh
echo "Downloading and installing wine.desktop and wine_launcher.sh..."
wget https://raw.githubusercontent.com/neofeo/BOX86-BOX64-WINEx86-TUTORIAL/main/boxer/wine.desktop -O ~/.local/share/applications/wine.desktop
wget https://raw.githubusercontent.com/neofeo/BOX86-BOX64-WINEx86-TUTORIAL/main/boxer/wine_launcher.sh -O ~/wine_launcher.sh
chmod +x ~/wine_launcher.sh

echo "wine.desktop and wine_launcher.sh installed."

# Set up custom keyboard shortcut for killing Wine
if [ "$DESKTOP_ENV" == "GNOME" ]; then
    echo "Setting up custom keyboard shortcut for killing Wine..."
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Kill Wine (wineserver -k)'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'wineserver -k'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Primary>q'
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
    echo "You can now use the Left Ctrl + Q shortcut to quickly kill any Wine processes."
elif [ "$DESKTOP_ENV" == "XFCE" ]; then
    echo "Setting up custom keyboard shortcut for killing Wine..."
    xfconf-query -c xfce4-keyboard-shortcuts -p "/commands/custom/<Primary>q" -n -t string -s "wineserver -k"
    echo "You can now use the Left Ctrl + Q shortcut to quickly kill any Wine processes."
else
    echo "Unsupported desktop environment. No custom keyboard shortcut set for killing Wine."
fi


# Unattended setup of Mono
echo "Setting up Mono (unattended)..."
WINE_MONO=--unattended ~/wine/bin/wineboot

# Prompt user for installing components with winetricks
echo "Do you want to install additional components using winetricks?"
echo "Components to be installed: mfc42 vcrun6 vb6run xact d3drm d3dx9 d3dx9_43 d3dcompiler_43 msxml3 vcrun2003 vcrun2005 vcrun2008"
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
            echo "Invalid selection, please choose a valid option."
            ;;
    esac
done


# Ask user if they want to upgrade Mesa drivers
if [ "$PLATFORM" != "rockchip-rk3588" ]; then
    echo "Do you want to upgrade Mesa drivers for the latest Panfrost (may be unstable)?"
    select upgrade_mesa in "Yes" "No"; do
        case $upgrade_mesa in
            Yes)
                echo "Upgrading Mesa drivers for Panfrost..."
                if [ "$DISTRO" == "Ubuntu" ] || [ "$DISTRO" == "Debian" ]; then
                    sudo add-apt-repository --yes ppa:oibaf/graphics-drivers
                    sudo apt update
                    sudo apt install mesa-va-drivers:armhf mesa-va-drivers libd3dadapter9-mesa:armhf -y
                    echo "After this, you can try galliumnine (Native Dx9) after installing 'nine' with 'winetricks galliumnine' and launching 'wine ninewinecfg' to check if it works."
                else
                    echo "Unsupported distribution for Mesa driver upgrade."
                fi
                break
                ;;
            No)
                echo "Skipping upgrade of Mesa drivers."
                break
                ;;
            *)
                echo "Invalid selection, please choose a valid option."
                ;;
        esac
    done
fi


echo "Hopefully everything works fine now. You should reboot just in case to get the mesa env var working (so, OpenGL 3.3, mostly for the linux x86_64 and x86 games)"

# Ask user if they want to reboot
echo "Do you want to reboot your system?"
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
            echo "Invalid selection, please choose a valid option."
            ;;
    esac
done




