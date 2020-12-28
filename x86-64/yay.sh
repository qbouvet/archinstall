#!/usr/bin/env bash


# ----- Prelude

# Usual bash flags
set -euo pipefail   # Exit on 1/ nonzero exit code 2/ unassigned variable 3/ pipe error
shopt -s nullglob   # Allow null globs
#set -o xtrace      # Show xtrace  
 
source $wd/config.sh
source $wd/utils/f.sh
source $wd/utils/trapstack.sh


# ----- Sudo workaround

uuid=$(cat /proc/sys/kernel/random/uuid)
uuid=${uuid:0:4}
uinstaller="installer_$uuid"
useradd -m "${uinstaller}"
f.append "/etc/sudoers" \
  "\n\n${uinstaller} ALL=(ALL) NOPASSWD:ALL"

trap.stack "
  userdel ${uinstaller};
  rm -rf /home/${uinstaller};
  f.comment '/etc/sudoers' '${uinstaller} ALL=(ALL) NOPASSWD:ALL';
"


# ----- Install yay

# Again, we'd ideally want a dir+uuid
# But this works well enough

if ! [[ -e /opt/build ]] 
then 
  mkdir -p /opt/build
  trap.stack "rm -rf /opt/build;"
fi 

chown "$uinstaller":"$uinstaller" /opt/build
pushd /opt/build
trap.stack "popd;"

sudo -u "$uinstaller" git clone https://aur.archlinux.org/yay.git
trap.stack "rm -rf ./yay;"

pushd yay; 
trap.stack "popd;"
pacman --noconfirm -S go 
sudo -u "$uinstaller" makepkg -s
pacman --noconfirm -U *.zst


# ----- Install packages

sudo -u "$uinstaller" yay -Syu --noconfirm --sudoloop --batchinstall \
  --removemake \
  --noredownload --norebuild \
  --answerdiff None --answerclean None --answeredit None --answerupgrade None \
  $packages


# ----- Cleanup

trap.all.run