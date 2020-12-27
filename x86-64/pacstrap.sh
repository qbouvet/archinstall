#!/usr/bin/env bash


# ----- Prelude

# Usual bash flags
set -euo pipefail   # Exit on 1/ nonzero exit code 2/ unassigned variable 3/ pipe error
shopt -s nullglob   # Allow null globs
#set -o xtrace      # Show xtrace  

source $wd/config.sh


# ----- Pacstrap

strapdir=/mnt

pacstrap ${strapdir} $($wd/pkgs.sh pacstrap)

genfstab -U -p ${strapdir} >> ${strapdir}/etc/fstab

# Copy over install scripts for chrooting
mkdir -p ${strapdir}${wd}
cp -a $wd/* ${strapdir}${wd}