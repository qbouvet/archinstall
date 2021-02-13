 #!/usr/bin/env bash

if [ $# -gt 0 ] && { [ "$1" == "-h" ] || [ "$1" == "--help" ] ;} ; then
printf "
    Help menu
"
return 0
fi


# ----- Prelude

set -euo pipefail   # Exit on 1/ nonzero exit code 2/ unassigned variable 3/ pipe error
shopt -s nullglob   # Allow null globs
#set -o xtrace      # Show xtrace  


# ----- Run as root

[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@";


# ----- Imports

# Set working directory
export wd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${wd}/config.sh"

source "${wd}/../common/utils/aa.sh"            # Associative arrays
source "${wd}/../common/utils/f.sh"             # File operations helpers
source "${wd}/../common/utils/trapstack.sh"     # Stack data structure for bash TRAP

source "${wd}/../common/others.sh"              # ???


# ----- CLI parameters

declare -A params

params["stage"]="iso"
params["unattended"]="false"
params["reportfile"]="$wd/report.txt"
params["check_blockdev"]="false"

aa.argparse params ${@:1}


# ----- Sanity checks 

# Check for qemu
if ! [ -x $(which qemu-arm-static) ] # qemu-arm-static, qemu-aarch64-static
then 
    echo "Qemu required, but not found."
    echo "See: "
    echo "  * https://lexruee.ch/customizing-an-arch-arm-image-using-qemu.html "
    echo "  * https://wiki.archlinux.org/index.php/QEMU#Chrooting_into_arm/arm64_environment_from_x86_64"
    echo "exiting"
    exit 1
fi 


# ----- Copy files to device, needed for chroot steps

# Copy scripts to chroot
if [[ -d "${rootmnt}/install" ]]
then 
  mkdir -p              ${rootmnt}/install/
  cp -a ${wd}/../common ${rootmnt}/install/
  mkdir -p              ${rootmnt}/install/pi0
  cp -a ${wd}/*         ${rootmnt}/install/pi0
fi


# ----- Dispatch stage

# User interaction
aa.pprint params
if ! [[ ${params["unattended"]} == "true" ]]
then 
  echo "[enter] to proceed"
  read
fi

# Dispatch 
# Some stages run in a qemu chroot. See
#   * https://wiki.archlinux.org/index.php/QEMU#Chrooting_into_arm/arm64_environment_from_x86_64
#   * https://lexruee.ch/customizing-an-arch-arm-image-using-qemu.html   
case ${params["stage"]} 
in 
    ("iso") \
        ${wd}/1-iso.sh 
        next="partition"
        ;;
    ("partition") \
        ${wd}/2-partition.sh
        next="extract"
        ;;
    ("extract") \
        ${wd}/3-extract.sh
        next="base"
        ;;
    ("pacstrap") \
        ${wd}/4-pacstrap.sh
        next="finish"
        ;;
    ("base") \
        arch-chroot "${rootmnt}" /install/pi0/5-base.sh  # Absolute path, in chroot dir !!!
        next="finish"
        ;;
    ("yay") \
        arch-chroot "${rootmnt}" /install/pi0/6-yay.sh   # Absolute path, in chroot dir !!!
        next="finish"
        ;;
    (*) \
        printf "Stage: ${params["stage"]}, exiting normally\n"
        exit 0
        ;;
esac

# Recursively call next stage
${0} --stage "${next}" --unattended ${params["unattended"]} --reportfile ${params["reportfile"]}




# Bind mount for report file in chroot: 
#
function chain_in_chroot () { 
    aa.pprint params
  # Remount if skipped previous step
    printf "  Remount...\n"
    remount | indent 2
    printf "  Done\n\n"
  # Copy the installation scripts into the rootfs for reference  
    mkdir -p "${rootmnt}/install"
    cp ./*.sh "${rootmnt}/install/"
  # Bind-mount file for reporting  
    touch "$rootmnt"/report.txt
    mount --bind "${params[reportfile]}" "$rootmnt"/report.txt
  # Chroot and call script again  
    arch-chroot "${rootmnt}" "./install/$0" \
      --stage configure \
      --reportfile "/report.txt" \
      --reportclear "false" \
      --skip-bd-check "${params[skip_bd_check]}" \
      --noconfirm "${params[noconfirm]}"
  # Unbind the reporting file, else mnt/ "target is busy"
    umount "$rootmnt"/report.txt
}
