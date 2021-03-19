 #!/usr/bin/env bash

if [ $# -gt 0 ] && { [ "$1" == "-h" ] || [ "$1" == "--help" ] ;} ; then
printf "
    Install yay in an ugly way. 
    Necessary, because ARM systems have issues with the fakeroot binary. 
"
return 0
fi


# ----- Prelude

set -euo pipefail   # Exit on 1/ nonzero exit code 2/ unassigned variable 3/ pipe error
shopt -s nullglob   # Allow null globs
#set -o xtrace      # Show xtrace  


# ----- Imports

pushd /install/pi0/ 2>&1 >/dev/null
wd=$(pwd)   # Needed ? 

# Variables don't need to be re-sourced, but functions do ???
source "${wd}/config.sh"                     # <- This is not needed ? 
source "${wd}/../common/utils/f.sh"          # <- But this is ? 
source "${wd}/../common/utils/indent.sh"     # <- But this is ? 


# ----- Très brouillon

pacman --noprogressbar --noconfirm -S base base-devel git 

#
#   AUR installer. Automates downloading, extracting and calling makepkg.
#   Args : $1  AUR package name
#          $2+ passed to makepkg (e.g. if --skippgpcheck is needed)
#
function manual_aur_install () {
    _user="quentin"
    _package="$1"
    _builddir="/tmp/build"
    _gitlink="https://aur.archlinux.org/${_package}.git"
    [ ! -e "$_builddir" ] && mkdir -p "$_builddir"
    pushd "$_builddir"
    rm -rf "$_package"
    printf "\n\nCloning...\n"
    git clone "$_gitlink" | indent
    chmod 777 -R "$_builddir/$_package"
    cd "$_package"
    printf "\n\nBuilding...\n"
    sudo -u "$_user" makepkg -s "${@:2}"
    printf "\n\n... Installing\n"
    if [[ -x $(which pacinstall) ]]; then
        pacinstall --file "$_package"*.tar.xz \
          --resolve-conflicts=all --noconfirm 
    else 
        pacman -U "$_package"*.tar.xz --noconfirm
    fi
    printf "\n\nDone\n"
    popd
}

manual_aur_install yay


# I dont think we need it so far

function yay_packages () {
  # Temporarily need sudo without password  
    f_append "/etc/sudoers" "\n
        #  
        # Allow user to run all commands without password
        #
        $username ALL=(ALL) NOPASSWD: ALL"
  # Install AUR packages
    sudo -u "$username" yay --noconfirm -S "${aur_packages[@]}" 
  # Revert sudo without password
    f_comment "/etc/sudoers" "$username ALL=(ALL) NOPASSWD: ALL"
}










#
#   For reference
#
function yay_setup () { #   Requires sudo / pacman
  # Fakeroot doesn't work under qemu chroot
  # The alternative is takeroot-tcp, but you need fakeroot to build it from AUR
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