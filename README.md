# BOX86/BOX64/WINEX86/STEAM TUTORIAL for ARM64 LINUX SYSTEMS


_Salvador Liébana (MicroLinux YT: https://www.youtube.com/channel/UCwFQAEj1lp3out4n7BeBatQ )_



## QUICK RECAP

- BOX86 is a linux x86 userspace emulator, it's ARMHF ONLY (ARM 32 bits); on ARM64 we need a multiarch system to run it. 
- BOX64 is a linux x86_64 userspace emualtor, it's ARM64 ONLY (ARM 64 bits); we need a 64 bit arm system.
- BOX32 is an on DEV linux x86 userspace emulator, it's ARM64 ONLY (ARM 64 bits) and targets legacy linux x86 apps without multiarch and handy on non multiarch supported distros like manjaro.
- WINE x86 it's of course x86 (x86 32 bits) but you can install wine x64 (x86_64 64 bits) if you want, I don't found it useful here (unless you have a proper AMD gpu).
- BOX86/64 will wrapper system libs to make it easier to run x86/x86_64 sofware without having to store a full set of x86/x86_64 libs and to produce a better performance
since those libs will not be emulated, just used the armhf/arm64 counterpart ones.
- Goldberg is an open source Steam Emulator https://gitlab.com/Mr_Goldberg/goldberg_emulator

### Latest wine development 
WINEHQ team is developing a SySwow64 system to execute x86 apps on pure x86_64 platforms without multiarch (on linux x86_64 they still need multiarch to run x86 apps),
Beucause of that, newer BOX64 developement will allow, alongside this wine development, to execute x86 windows apps without multiarch, neither box86, making the all thing a lot
simpler, but that's not ready today. It works currently on latest wine and latest box64, but it's buggy.

# PROCEDURE FOR WINE/BOX64/BOX86

We are going to use armbian ubuntu jammy on mainline on a panfrost mesa powered ARM64 system on this case since those are the systems I use. We are also going to use ubuntu because like Debian, they support multiarch, that means, having a 64 bit linux kernel (the OS core) and both 64 bit (ARM64/AARCH64) userspace libraries that are used by 64 bit programs like box64, and 32 bit (ARMHF) userspace libraries, used by ARMHF 32 bit software, like BOX86. So, a 64 bit core, and both 64 bit and 32 bit arm libraries. Windows used to do this not that far away in time to run x86 windows software. Programas doesn't run isolated, they use system (or third party) libraries to work, that's why we need them. Libraries make development and system complexity to be reduced. On windows libraries end on .dll and here on .so, so, shared objects. why shared? because they are or can be used by multiple software. 

1. We are going to setup a multiarch system adding armhf (AKA ARM 32 bits) before installing BOX86 (an armhf software only). This is not a complete list for the linux x86 stuff, it's
 just a bunch of packages that depends on another bunch of system libs that ultimately will do what we want, a full 32 bit arm userspace set of libraries sop we can run box86.

- If you dont have armhf added by default like on armbian/your linux distro, before installing the 32 bit armhf userspace libs you need to add armhf architecture first.

```
 sudo dpkg --add-architecture armhf &&  sudo apt update
```
Then, on a terminal we do..

```
 sudo apt install cmake cabextract p7zip-full libncurses6:armhf libc6:armhf libx11-6:armhf libgdk-pixbuf2.0-0:armhf \
 libgtk2.0-0:armhf libstdc++6:armhf libsdl2-2.0-0:armhf mesa-va-drivers:armhf libsdl-mixer1.2:armhf \
 libpng16-16:armhf libsdl2-net-2.0-0:armhf libopenal1:armhf libsdl2-image-2.0-0:armhf libjpeg62:armhf \
 libudev1:armhf libgl1-mesa-dev:armhf libx11-dev:armhf libsdl2-image-2.0-0:armhf libsdl2-mixer-2.0-0:armhf libvulkan1:armhf
```    

This will install a tonf of shit, check that doesnt remove anything please (that doesnt produce any conflict), if so, stop and remove whatever enter in conflict.


2. Now we can install BOX86/BOX64. For RK3588/S you need to use the special target for it, the generic will not gonna cut it bc rk3588 runs on a very odd kernel, not mainline.


So, we need to install BOX86 and BOX64 and we are going to use Ryan Fortner REPOS at https://github.com/ryanfortner/box86-debs and https://github.com/ryanfortner/box64-debs
Note that Ryan added specific platform target builds, but we are going to use the generic binaries since the performance impact it's not that high (if any), you can just use TAB after typing sudo apt install box86 to show all the variants or just apt search box86. The same applies to BOX64.

**IF YOU USE MODERN ARMBIAN, BOX86/BOX64 PACKAGES ARE AVAILABLE FROM ARMBIAN, YOU DON'T NEED RYAN REPOS THEN. AFTER AN UPDATE, DO "APT INSTALL BOX86 OR BOX64" AND PRESS TAB TO SEE THEM** 

**RK3588 on RK LINUX ONLY** 

```
sudo wget https://ryanfortner.github.io/box86-debs/box86.list -O /etc/apt/sources.list.d/box86.list \
&& sudo wget https://ryanfortner.github.io/box64-debs/box64.list -O /etc/apt/sources.list.d/box64.list \
&& wget -qO- https://ryanfortner.github.io/box86-debs/KEY.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/box86-debs-archive-keyring.gpg \
&& wget -qO- https://ryanfortner.github.io/box64-debs/KEY.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/box64-debs-archive-keyring.gpg \
&& sudo apt update \
&& sudo apt install box86-rk3588 box64-rk3588 -y
```


**ANY OTHER ARM64 MAINLINE LINUX PLATFORM** 

```
sudo wget https://ryanfortner.github.io/box86-debs/box86.list -O /etc/apt/sources.list.d/box86.list \
&& sudo wget https://ryanfortner.github.io/box64-debs/box64.list -O /etc/apt/sources.list.d/box64.list \
&& wget -qO- https://ryanfortner.github.io/box86-debs/KEY.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/box86-debs-archive-keyring.gpg \
&& wget -qO- https://ryanfortner.github.io/box64-debs/KEY.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/box64-debs-archive-keyring.gpg \
&& sudo apt update \
&& sudo apt install box86-generic-arm box64-generic-arm -y
```

3. Since you are on a Panfrost (MESA FOSS GPU driver) powered SBC on mainline (RPI4 also has mesa drivers but this only applies to panfrost and rk3588 uses a hacky panfrost while not on mainline), we will need OpenGL 3.3 for many games, so we should force it:

```
 sudo bash -c "echo 'PAN_MESA_DEBUG=gl3' >> /etc/environment"
```

 on RPI4 it should be the same to export these two variables: MESA_GL_VERSION_OVERRIDE=3.3 and MESA_GLSL_VERSION_OVERRIDE=330 on two different lines.


4. Reboot for now, not required but just to get the /etc/environment env vars working and to check that we still have a system.


5. **Note:** if you installed wine (arm64 or armhf) or winetricks with apt, remove them, wine ARM will not be usefull for mostly anything here since they arent that much arm64 windows apps, not even legally accesible outside windows on ARM most probably.

    - installing WINE x86 or x86_64 (that has both, x86 and x86_64). okay, download a copy from https://github.com/Kron4ek/Wine-Builds/releases ,I would recommend x86 stagging or stable, you can also get the proton variant from there. I would extremely recommend wine x86 stable 8.0 or orlder and wine64 only if you plan to only use box64 and clean wine64 (with 32 bit programs running on syswow64)
    - uncompress it, rename the folder "wine" and place it at your `/home/your_user/` directory.

I will give you two options for a quick setup:

wine 7.0 (recommended)

```
wget -O ~/wine-7.0-x86.tar.xz https://github.com/Kron4ek/Wine-Builds/releases/download/7.0/wine-7.0-x86.tar.xz \
&& tar -xf ~/wine-7.0-x86.tar.xz -C ~/ \
&& mv ~/wine-7.0-x86 ~/wine \
&& rm ~/wine-7.0-x86.tar.xz
```

wine 8.0 (there is a memory leak problem on this one)


```
wget -O ~/wine-8.0-x86.tar.xz https://github.com/Kron4ek/Wine-Builds/releases/download/8.0/wine-8.0-x86.tar.xz \
&& tar -xf ~/wine-8.0-x86.tar.xz -C ~/ \
&& mv ~/wine-8.0-x86 ~/wine \
&& rm ~/wine-8.0-x86.tar.xz
```



6. Ending wine setup..

    Every linux app (if not portable), and wine is a linux app, can be accesed by terminal like box86 and box64. We have our wine binaries on our user `/home` folder, so we need to link that to `/usr/local/bin` in order to the system to recognize it and be able to execute it, while x86 Wine, BOX86 will pick it and emulate it automatically thanks to the binfmt trick.

So we do the next thing from terminal to create those links:


```
sudo ln -s ~/wine/bin/wine /usr/local/bin/ \
&& sudo ln -s ~/wine/bin/winecfg /usr/local/bin/ \
&& sudo ln -s ~/wine/bin/wineserver /usr/local/bin/ \
&& sudo ln -s ~/wine/bin/wine64 /usr/local/bin/
```

Now we can launch wine to create the fake `c:` drive and the first setup, so type on terminal `winecfg` and install mono if it pop ups, etc, set xp for compat reasons and if you want to use a virtual windows, also set that.

7. installing winetricks and essential libs:
winetricks allow us to easily install some windows libraries that arent working perfectly on wine project reconstruction of those libraries, alonside other tricks.

So, we get winetricks from terminal like this: 

```
wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
&& sudo chmod +x winetricks \
&& sudo mv winetricks /usr/local/bin
```

NOTE: This winetricks thingy takes an hour to complete, you can just try to use proton wine that comes with some stuff already preinstalled
and then skipt this libraries instalation process.

Installing the essentials (I consider them like that) from terminal with:

```
 W_OPT_UNATTENDED=1 winetricks mfc42 vcrun6 vb6run xact d3drm d3dx9 d3dx9_43 d3dcompiler_43 msxml3 vcrun2003 vcrun2005 vcrun2008
```
  
It will take some time...specially from sdcard systems.

If you have a dxvk capable gpu, also install that one from winetricks.
  
```
 winetricks dxvk
```
  
You can list every possible instalable (unless it's 16 bit) software with winetricks with:
  
```
 winetricks list-all
```

8. Now you can test some windows x86 software with:

```
 wine explorer /desktop=1024x768 program.exe
```

To ensure that there is no display resolution problem. if your system doesnt have 1024x768 added on xrandr... it will crash even if it works. if you have the resolution added with xrandr and working.. you can skipt that advice and just "wine program.exe", the same if you already set a virtual desktip from winecfg.

9. performance: by default wine use on our gpus WINE3D wrappers that translate DirectX calls to OpenGL (remember that we dont have DirectX drivers, just OPENGL and VULKAN is used on Linux), its not fast and very cpu intensive! but it's what we have, opengl games should run considerably faster and use less CPU.

**Note:** RK3588 on RK Linux uses Panfork, a hacky mesa driver developed by Icecream95, DO NOT ATTEMPT TO USE OIBAF OR UPGRADE MESA ON RK3588 ON RK LINUX WITH PANFORK

GPU drivers upgrade: you can use oibaf launchpad repo, but latest mesa drivers may be problematic.

```
  sudo add-apt-repository ppa:oibaf/graphics-drivers
  sudo apt update && sudo apt upgrade 
```

or just the mesa packages (dpkg will list the packages that are upgradable after `sudo apt update`, it will warn you about new packages, so, not required to do full upgrade)


10. With oibaf mesa drivers repo, we can test Gallium nine because it's enabled by default. at point 8 I said we didnt have DirectX drivers, ding ding, I lied, we have "native" DX9 drivers and they are also possible to be used with wrappers on DX7 and DX8 games.

**Note:** nine and nine over panfrost it's on development, so, expect issues. You can make an apitrace (https://github.com/iXit/wine-nine-standalone/wiki/apitrace) and place a ticket at mesa.

Once we added oibaf, we install the gallium nine component on the driver with 

```
 sudo apt install libd3dadapter9-mesa:armhf
```

... and with winetricks we install gallium nine into wine with

```
 winetricks galliumnine
```

Now let's test if it works, do

```
 wine ninewinecfg
```

It should be working. then, every DX9 game should use Gallium nine instead of WINE3D.

To use NINE on DX8 games: we drag an x86 .dll copy of the dx8 to dx9 wrapper from here https://github.com/crosire/d3d8to9/releases, we place it on the game folder, probably overriting the original lib (you can jsut rename the original first) and from terminal we execute the game with:


```
  WINEDLLOVERRIDES=d3d8.dll=n wine thedx8game.exe
```

...or you can just set `d3d8.dll` as native on winecfg but I think it's best the other way.

On every ocassion, both dx9 or dx8 games with the wrapper, and if running from terminal, you will see gallium nine being used, if not, gallium nine isnt working for some reason and it's utilizing WINE3D.

**Note:** For STEAM WINDOWS GAMES I recommend the usage of Goldeberg emulator, and it works the same way as on linux games, you just need to use the goldberg windows x86 libs to replace the game
folder steam libraries to emulate steam. This isn't illegal at all! Goldberg only emulates the steam client, if you game has  DRM protection, you are on your own sadly...

## LINUX GAMES

For the linux games, it's super easy, remember that we need opengl 3.3 at least for most modern games, but some run just fine with 2.1 (and s3ct texture compression support), so that's why the env var we placed at /etc/environment (PAN_MESA_DEBUG=gl3), on RPI4 it should be the same to export these two variables: MESA_GL_VERSION_OVERRIDE=3.3 and MESA_GLSL_VERSION_OVERRIDE=330.

Just execute the game binaries from terminal like "./game.bin" , box86 or box64 will be automatically called.

First, if a game has a problem, launch it from terminal with BOX86_LOG=1 env var like "BOX86_LOG=1 box86 game.bin" then if there is a lib missing, it will say that a "native library isn't available" or that a "library is missing (then it's a non native lib that isn't wrapped on box86 or box64, so an x86 or x86_64 lib is required to run the game). 

If it's a native one, just install it from the repo (remember to use :armhf if box86) and if it's an x86 or x86_64 one, get it from the game folder and copy it to the binary executable OR set BOX64_LD_LIBRARY_PATH=/to_the_path_where_the_library_is. If the game folder doesn't has it, get it from debian repo browsing a bit..so, google "whatever.so debian", download it, unpack the deb, place the lib on the executable folder so box86/64 will pick it.


## GOLDBERG STEAM EMULATOR or REAL LINUX STEAM x86 CLIENT

For STEAM games, it's extremely recommended to use GOLDBERG steam emulator (https://gitlab.com/Mr_Goldberg/goldberg_emulator), since you dont need the steam client. grab your copy from steam for linux on any pc or use steamCMD from your pc or sbc... get a goldberg release, unpack it, drop goldberg libs alongside you game or wherever are the steam libs on your game. If an x86 linux game, x86 linux .so libs are the ones you need, if an x86_64 game linux x86_64 .so steam libs...same for windows dlls) then it should just launch like any game without DRM...

On the other hand, you can install the real steam client with an .sh provided by ptitiseb on from the repo of box86, clone the repo and execute it or just drag that sh from the github site itself and execute it. I will make a video on that later, but, the client uses more than 2 gigs of ram doing nothing, so, not a good idea.

example with SteamCMD: https://www.youtube.com/watch?v=KFgPwZ19eGQ

another example: https://www.youtube.com/watch?v=K9ITyZgGD5E&t=21s

 Good luck and remember this is a WIP! all the glory to ptitseb and mesa developers!
