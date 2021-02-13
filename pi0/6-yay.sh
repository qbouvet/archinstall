 #!/usr/bin/env bash

if [ $# -gt 0 ] && { [ "$1" == "-h" ] || [ "$1" == "--help" ] ;} ; then
printf "
    Download and cache the Arch Linux ARM ISO
"
return 0
fi


# ----- Prelude

set -euo pipefail   # Exit on 1/ nonzero exit code 2/ unassigned variable 3/ pipe error
shopt -s nullglob   # Allow null globs
#set -o xtrace      # Show xtrace  


# ----- 

function yay_setup () { #   Requires sudo / pacman
  # Fakeroot doesn't work under qemu chroot
    # https://archlinuxarm.org/forum/viewtopic.php?f=57&t=14466
    # https://aur.archlinux.org/packages/fakeroot-tcp/
    # https://www.reddit.com/r/archlinux/fComments/7rycmu/cannot_build_fakeroottcp_without_fakeroot/
  # Compile fakeroot-tcp from source
    wget http://ftp.debian.org/debian/pool/main/f/fakeroot/fakeroot_1.23.orig.tar.xz
    tar xvf fakeroot_1.23.orig.tar.xz
    cd fakeroot-1.23/
    ./bootstrap
    ./configure --prefix=/opt/fakeroot-tcp \
      --libdir=/opt/fakeroot-tcp/libs \
      --disable-static \
     --with-ipc=tcp
    make 
    make install 
  # compile "package-manager" fakeroot-tcp using "from-source" fakeroot-tcp
    PATH="/opt/fakeroot-tcp/bin/:${PATH}" manual_aur_install fakeroot-tcp \
      && rm -rf /opt/fakeroot-tcp
  # Arch building system should now work 
    manual_aur_install yay
}

function yay_packages () {
  # Temporarily need sudo without password  
    fAppend "/etc/sudoers" "\n
        #  
        # Allow user to run all commands without password
        #
        $username ALL=(ALL) NOPASSWD: ALL"
  # Install AUR packages
    sudo -u "$username" yay --noconfirm -S "${aur_packages[@]}" 
  # Revert sudo without password
    fComment "/etc/sudoers" "$username ALL=(ALL) NOPASSWD: ALL"
}