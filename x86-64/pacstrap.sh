#!/usr/bin/env bash

strapdir=/mnt

pacstrap ${strapdir} $($wd/pkgs.sh pacstrap)

genfstab -U -p ${strapdir} >> ${strapdir}/etc/fstab

# Copy over install scripts for chrooting
mkdir -p ${strapdir}${wd}
cp -a $wd/* ${strapdir}${wd}