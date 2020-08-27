#!/usr/bin/env bash
read -r -d '' usage_str << EOF

    Usage : $0 <options>

EOF


if [ $# -gt 0 ] && { [ "$1" == "-h" ] || [ "$1" == "--help" ] ;} ; then
    printf "$usage_str"
    exit 0
fi



## Debug flags & bash magic
set -o nounset      # exit on unassigned variable
set -o errexit      # exit on error
set -o pipefail     # exit on pipe fail
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# set -o xtrace     # Display xtrace



########################################################################
######################      FUNCTIONS      #############################
########################################################################


########################################################################
######################      EXECUTION      #############################
########################################################################

