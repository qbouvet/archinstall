#!/usr/bin/env bash
read -r -d '' usage_str << EOF

    Usage : $0 <options>

EOF


if [ $# -gt 0 ] && { [ "$1" == "-h" ] || [ "$1" == "--help" ] ;} ; then
    printf "$usage_str"
    return 0
fi

    # 
    #   Import & requires
    #
source /scripts/config.sh || exit 1
source /scripts/utils.sh || exit 1
require --exit tprint get_root_privilege 

    #
    #   Asset root access
    #
get_root_privilege "$0" "$@"

    #
    # Debug flags & bash magic
    #
set -o nounset      # exit on unassigned variable
set -o errexit      # exit on error
set -o pipefail     # exit on pipe fail
# set -o xtrace     # Display xtrace



########################################################################
#                       FUNCTIONS & VARS                               #
########################################################################

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


########################################################################
#                           EXECUTION                                  #
########################################################################

