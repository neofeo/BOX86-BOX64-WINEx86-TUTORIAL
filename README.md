# BOX86/BOX64/WINEX86 TUTORIAL for ARM64 LINUX SYSTEMS by SALVADOR LIÈBANA (MICROLINUX)

_Salvador Liébana_

- if you dont have armhf added by default like on armbian jammy, before installing the 32 bit armhf userspace libs you need to add armhf architecture first.

```
sudo dpkg --add-architecture armhf
sudo apt update
```

## QUICK RECAP

- BOX86 is a linux x86 userspace emulator, it's ARMHF ONLY (ARM 32 bits); on ARM64 we need a multiarch system to run it. 
- BOX64 is a linux x86_64 userspace emualtor, it's ARM64 ONLY (ARM 64 bits); we need a 64 bit arm system.
- BOX32 is an on DEV linux x86 userspace emulator, it's ARM64 ONLY (ARM 64 bits) and targets legacy linux x86 apps without multiarch and handy on non multiarch supported distros like manjaro.
- WINE x86 it's of course x86 (x86 32 bits) but you can install wine x64 (x86_64 64 bits) if you want, I don't found it usefull here.

### Latest wine development 
it's developing a SySwow64 system to execute x86 apps on pure x86_64 platforms without multiarch (on linux x86_64 they still need multiarch to run x86 apps),
Beucause of that, newer BOx64 developement will allow, alongside this wine development, to execute x86 windows apps without multiarch, neither box86, making the all thing a lot
simpler, but that's not ready today.

# STEPS

We are going to use ubuntu jammy on mainline on a panfrost mesa powered ARM64 system, because like Debian, they support multiarch, that means, having a 64 bit linux kernel (the OS core) and both 64 bit (ARM64/AARCH64) userspace libraries that use 64 bit programs like box64 and 32 bit (ARMHF) userspace libraries, used by ARMHF 32 bit software, like BOX86. a 64 bit core, and both 64 bit and 32 bit arm libraries. Windows used to do this not that far away in time.

1. First, we need to install BOX86 and BOX64 and we are going to use Ryan Fortner REPOS at https://github.com/ryanfortner/box86-debs and https://github.com/ryanfortner/box64-debs
    
    Note that Ryan added specific platform target builds, but we are going to use the rpi4 binaries since the performance impact it's not that high, you can just use TAB after typing sudo apt install box86 to show all the variants or just apt search box86. The same applies to BOX64

    **BOX86**
    
    ```
    sudo wget https://ryanfortner.github.io/box86-debs/box86.list -O /etc/apt/sources.list.d/box86.list
    wget -O- https://ryanfortner.github.io/box86-debs/KEY.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/box86-debs-archive-keyring.gpg
    sudo apt update && sudo apt install box86 -y
    ```

    **BOX64**
    
    ```sudo wget https://ryanfortner.github.io/box64-debs/box64.list -O /etc/apt/sources.list.d/box64.list
    wget -O- https://ryanfortner.github.io/box64-debs/KEY.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/box64-debs-archive-keyring.gpg 
    sudo apt update && sudo apt install box64 -y
    ```

2. since you are on Panfrost (RPI4 also has mesa drivers but this only applies to panfrost), we will need OpenGL 3.3 for many games, so we should force it:

    ```
    sudo nano /etc/environment and on a blank line just type "PAN_MESA_DEBUG=gl3" without quotes, save and close
    ```
    
3. Reboot for now, not required. check that box64 and box86 launch from terminal after that.

4. **Note:** if you install wine (arm64 or armhf) and winetricks with apt, remove them, wine ARM will not be usefull for mostly anything here since they arent that much arm64 windows apps, not even legally accesible outside windows on ARM most probably.

    - installing WINE x86. okay, download a copy from https://github.com/Kron4ek/Wine-Builds/releases , would recommend x86 stagging or stable.
    - uncompress it, rename the folder "wine" and place it at your `/home/your_user/` directory.

5. Until we finish with wine, we are going to setup a basic 32 bit ARMHF userspace to run both linux x86 and wine x86 stuff with box86, this is not complete for the linux x86 stuff. On a terminal we do..

    ```
    sudo apt install cmake cabextract 7zip libncurses6:armhf libc6:armhf libx11-6:armhf libgdk-pixbuf2.0-0:armhf \
      libgtk2.0-0:armhf libstdc++6:armhf libsdl2-2.0-0:armhf mesa-va-drivers:armhf libsdl-mixer1.2:armhf \
      libpng16-16:armhf libsdl2-net-2.0-0:armhf libopenal1:armhf libsdl2-image-2.0-0:armhf libjpeg62:armhf \
      libudev1:armhf libgl1-mesa-dev:armhf libx11-dev:armhf libsdl2-image-2.0-0:armhf libsdl2-mixer-2.0-0:armhf
    ```
    
    This will install a tonf of shit, check that doesnt remove anything please (that doesnt produce any conflict), if so, stop and remove whatever enter in conflict.

6. Ending wine setup..

    Every linux app (if on purpose, AKA not portable), and wine is a linux app, can be accesed by terminal like box86 and box64. we have our wine binaries on our user `/home` folder, so we need to link that to `/usr/local/bin` in order to the system to recognize it and be able to execute it, while x86, BOX86 will pick it and emulate it automatically.

      So we do the next thing from terminal to create those links:
    
    ```
    sudo ln -s /home/youruser/wine/bin/wine        /usr/local/bin/
    sudo ln -s /home/youruser/wine/bin/winecfg     /usr/local/bin/
    sudo ln -s /home/youruser/wine/bin/wineserver  /usr/local/bin/
    ```
    
    Only if you plan to use box64 and wine x86_64, then:
    
    ```
    sudo ln -s /home/youruser/wine/bin/wine64 /usr/local/bin/
    ```
    
    now we can launch wine to create the fake `c:` drive and the first setup, so type on terminal `winecfg` and install mono if it pop ups, etc, set xp for compat reasons and if you want to use a virtual windows, also set that.

7. installing winetricks and essential libs:

    winetricks allow us to easily install some windows libraries that arent working perfectly on wine project reconstruction of those libraries, alonside other tricks.

      so, we get winetricks from terminal like this: 
    
    ```
    wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
    ```

    then we enable it as executable with:
    
    ```
    sudo chmod +x winetricks
    ```
    
    and then we move it to `/usr/local/bin` with
    
    ```
    sudo mv winetricks /usr/local/bin
    ```

      installing the essentials (I consider them like that) from terminal with:
    
    ```
    W_OPT_UNATTENDED=1 winetricks mfc42 vcrun6 vcrun2003 xact d3drm d3dx9_43 d3dcompiler_43 \
      d3dx9 fontfix gdiplus dotnet20 msxml3 vcrun2005sp1 vcrun2008 fontsmooth=rgb
    ```
  
      it will take some time...

      if you have a dxvk capable gpu, also install that one from winetricks.
  
    ```
    winetricks dxvk
    ```
  
    you can list every possible instalable (unless it's 16 bit) software with winetricks with:
  
    ```
    winetricks list-all"
    ```
    
8. now you can test some windows x86 software with:

    ```
    wine explorer /desktop=name,1024x768 program.exe
    ```
    
  to ensure that there is no display resolution problem. if your system doesnt have 1024x768 added on xrandr... it will crash even if it works. if you have the resolution added with xrandr and working.. you can skipt that advice and just "wine program.exe", the same if you already set a virtual desktip from winecfg.

9. performance: by default wine use on our gpus WINE3D wrappers that translate DirectX calls to OpenGL (remember that we dont have DirectX drivers, just OPENGL and VULKAN is used on Linux), its not fast and very cpu intensive! but it's what we have, opengl games should run considerably faster and use less CPU.

    GPU drivers upgrade: you can use oibaf launchpad repo, but latest mesa drivers may be problematic.

    ```
    sudo add-apt-repository ppa:oibaf/graphics-drivers
    sudo apt update
    sudo apt upgrade 
    ```
    
    or just the mesa packages (dpkg will list the packages that are upgradable after  `sudo apt update`, it will warn you about new packages, so, not required to do full upgrade)


10. with oibaf mesa drivers, we can test Gallium nine because it's enable by default. at point 8 I said we didnt have DirectX drivers, ding ding, I lied, we have "native" DX9 drivers and they are also possible to be used with wrappers on DX7 and DX8 games.

    once we added oibaf, we install the gallium nine component on the driver with 
    
    ```
    sudo apt install libd3dadapter9-mesa:armhf
    ```
    
    and with winetricks we install gallium nine into wine with
    
    ```
    winetricks galliumnine
    ```

    now let's test if it works, do
    
    ```
    wine ninewinecfg
    ```
    
    it should be working. then, every DX9 game should use Gallium nine instead of WINE3D.

    to use it on DX8 games: we drag an x86 .dll copy of the dx8 to dx9 wrapper from here https://github.com/crosire/d3d8to9/releases, we place it on the game folder, probably overriting the original lib (you can jsut rename the original first)  and from terminal we execute the game with 
    
    ```
    WINEDLLOVERRIDES=d3d8.dll=n wine thedx8game.exe```
    
    or you can just set `dx3d.dll` as native on winecfg but I think it's best the other way.

on every ocassion, both dx9 or dx8 games with the wrapper, and if running from terminal, you will see gallium nine being used, if not, gallium nine isnt working for some reason and it's utilizing WINE3D