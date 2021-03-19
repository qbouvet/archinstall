#!/bin/bash -i

##
##  ~/run-at-login.sh
##  This script is run at user login in an interactive shell 
##      ( bash -i in autostart-login.sh.service )
##


#
#   Prelude
#

# Usual bash flags
set -euo pipefail   # Exit on 1/ nonzero exit code 2/ unassigned variable 3/ pipe error
shopt -s nullglob   # Allow null globs
#set -o xtrace      # Show xtrace  

function stdio_to_logfile () {
    local logfile="$1"
    
    #rm $log;
    echo "" >> "$logfile"; 
    echo "Redirecting stdio to log file"  >> "$logfile";
    date >> "$logfile"; 
    echo "" >> "$logfile"; 
    
    exec 1<&-;          # Close STDOUT file descriptor
    exec 2<&-;          # Close STDERR FD
    exec 1<>"$__log";   # Open STDOUT as $log file for read and write.
    exec 2>&1;          # Redirect STDERR to STDOUT
}
stdio_to_logfile "~/run-at-login.log"

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
source "$HOME"/.bashrc;


#
#   Test
#
printf "\n\n [Date]";
date;

exit 0
