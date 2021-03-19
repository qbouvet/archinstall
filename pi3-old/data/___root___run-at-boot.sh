#!/usr/bin/env bash

##  /run-at-boot.sh
##
##  This script is executed at startup by
##  /etc/systemd/system/run-at-boot.sh.service
##
##  It runs with root priviledge.
##


#
# Prelude
#

# Usual bash flags
set -euo pipefail   # Exit on 1/ nonzero exit code 2/ unassigned variable 3/ pipe error
shopt -s nullglob   # Allow null globs
#set -o xtrace      # Show xtrace

function stdio_to_logfile () {
    local logfile="$1"

    [[ -f "$logfile" ]] && rm "$logfile";
    echo "Redirecting stdio to log file"  >> "$logfile";
    echo "" >> "$logfile"
    date >> "$logfile";
    echo "" >> "$logfile";

    exec 1<&-;          # Close STDOUT file descriptor
    exec 2<&-;          # Close STDERR FD
    exec 1<>"$logfile"; # Open STDOUT as $log file for read and write.
    exec 2>&1;          # Redirect STDERR to STDOUT
}
stdio_to_logfile "/root/run-at-boot.log"

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
#source "$HOME"/.bashrc;


#
#   Test
#
printf "[Date] $(date)\n";

echo hello my dude

exit 0;
