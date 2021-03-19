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


# ----- Get image

if [ -f "${workdir}/$alarm_archive" ] ; then
  printf "Linux image found \n\n"
else
  printf "Linux image not found\n"
  printf "downloading... \n\n"
  wget \
    --output-document="${workdir}/${alarm_archive}.md5" \
    "$alarm_archive_md5"
  wget \
    --output-document="${workdir}/${alarm_archive}" \
    "$alarm_archive_url"
fi


# ----- Verify image

pushd ${workdir} 2>&1 >/dev/null
if ! md5sum --status -c "${workdir}/${alarm_archive}.md5" ; then
  popd 2>&1 >/dev/null
  printf "Checksum mismatch\n"
  printf "Exiting\n\n"
  exit 1
else
  popd 2>&1 >/dev/null
  printf "Checksum OK\n\n"
fi