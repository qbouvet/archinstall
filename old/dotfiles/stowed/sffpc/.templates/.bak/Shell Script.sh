#!/usr/bin/env bash

source /scripts/bashutils/usage.sh ''    # '' is important !! 
usage "\

    script.sh
    =========

  Does cool stuff. Has cool features: 
    - cool feature 1
    - cool feature 2

  Usage/Examples: 
    $ source script.sh
    $ script -o opt1
" $@


#======================================================================#
#                             GLOBALS                                  #
#======================================================================#

function initialize () {
    # Imports
    source /scripts/bashcfg/all.sh
    source /scripts/bashutils/kvstore.sh
    require --exit kv_namespace kv_set kv_get

    # Parameters 
    arg1="$1"; shift;   # Positionals
    parms["p1"]="v1"    # Keywords
    parms["p2"]="v2"
    aa_parse_args parms ${@:1};

    # Usual environment variables
    local _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local _name="$(basename ${BASH_SOURCE[0]})" 
}

function __not_implemented () {
    echo "Not Implemented"
    return 1
}


#======================================================================#
#                           EXECUTION                                  #
#======================================================================#

function script_sh () {
    echo "Running main()"
    echo "All done"
}

# Don't execute if source'd
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then 
    # Usual bash flags
    set -euo pipefail   # Exit on 1/ nonzero exit code 2/ unassigned variable 3/ pipe error
    shopt -s nullglob   # Allow null globs
    #set -o xtrace      # Show xtrace

    declare -A parms
    initialize $@
    script_sh $@
    exit 0
fi

return 0