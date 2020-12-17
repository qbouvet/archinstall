#!/usr/bin/env bash
read -r -d '' usage_str << EOF
.
    Usage : $0 <options>
.
EOF

if [ $# -gt 0 ] && { [ "$1" == "-h" ] || [ "$1" == "--help" ] ;} ; then
    printf "$usage_str"
    return 0
fi

    #
    # Debug flags & bash magic
    #
set -o nounset      # exit on unassigned variable
set -o errexit      # exit on error
set -o pipefail     # exit on pipe fail
# set -o xtrace     # Display xtrace

    # 
    #   Imports & requires
    #
source /scripts/config.sh || exit 1
source /scripts/utils.sh  || exit 1
require --exit obtain_root 

    #
    #   Some initial setup
    #
obtain_root "$0" "$@"



#======================================================================#
                                                           # Variables #
                                                           #===========#
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

logfile="/scripts/var/bashscript-log"



#======================================================================#
                                                           # Functions #
                                                           #===========#

function log () {
    
}

function prepare () {
    
}

function cleanup () {
    
}



#======================================================================#
                                                           # Execution #
                                                           #===========#
    
    #
    # redirect stderr / stdout
    #
exec 3>&1 4>&2 >"$logfile" 2>&1
printf "\n [Output redirected]\n\n";

# prepare 
# trap cleanup

