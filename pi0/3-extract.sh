 #!/usr/bin/env bash

if [ $# -gt 0 ] && { [ "$1" == "-h" ] || [ "$1" == "--help" ] ;} ; then
printf "
    Extract the Arch Linux ARM ISO to SD card.
    Since it is extracted directly to SD card, no need for pacstrap.
"
return 0
fi


# ----- Prelude

set -euo pipefail   # Exit on 1/ nonzero exit code 2/ unassigned variable 3/ pipe error
shopt -s nullglob   # Allow null globs
#set -o xtrace      # Show xtrace  


# ----- Imports

# Variables don't need to ba re-sources, but functions do ???
source "${wd}/config.sh"              # <- This is not needed ? 
source "${wd}/../common/utils/indent.sh"     # <- But this is ? 


# -----  Extract root file system

if [ ! -f "${workdir}/$alarm_archive" ] ; then
    echo "Arch linux ARM archive not found, exiting"; 
    exit 1
fi

printf "\n[$(date +%H:%M:%S)] Extracting root file system...\n"
pushd "$rootmnt" > /dev/null 2>&1;
# redirect stderr to allow grep to filter error messages
tar -xf "${workdir}/${alarm_archive}" 2>&1 | grep -v 'SCHILY.fflags' | indent 2
popd > /dev/null 2>&1

# flush before return
printf "\n[$(date +%H:%M:%S)] Flushing... \n"
sync

# Feedback  
printf "\n[$(date +%H:%M:%S)] Extraction complete\n"


# -----  Create directory for receiving chroot install scripts

mkdir -p ${rootmnt}/install





# -----  Keep that for later // drop-ins

function cp_files () { 
    pushd "${__dir}/data" > /dev/null
    report.append "The following arbitrary files have been copied over:\n"
    for filename in *
    do
        if [ "${filename:0:3}" == "___" ]
        then
          newpath=${filename/___/}      # remove the first '___'
          newpath=${newpath//___/\/}    # replace all subsequent '___' by '/'
          mkdir -p "$(dirname "${rootmnt}/${newpath}")"
          cp "$filename" "${rootmnt}/${newpath}"
          report.append "  - $newpath\n"
        else
          printf "    Skipping $filename\n"
        fi
    done
    popd > /dev/null
    sync
}