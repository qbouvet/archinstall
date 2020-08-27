#!/usr/bin/env bash

[[ $# -gt 0 ]] && [[ "$1" =~ ^-h$|^-help$|^--help$ ]] && printf "\

    mkTrees.sh
    ==========
    
  Print the files tree for each stowed package/directory.

" && exit 0

function main() {    
    # Usual bash prelude
    set -euo pipefail   # Exit on 1/ nonzero exit code 2/ unassigned variable 3/ pipe error
    shopt -s nullglob   # Allow null globs
    local _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local _name="$(basename ${BASH_SOURCE[0]})" 
    
    for f in "$_dir"/*
    do
        if [[ -d "$f" ]] 
        then 
            echo "Processing $f"
            tree -a -I .git -o "$f.tree" "$f"
        else 
            echo "skipping non-directory $f"
        fi
    done
}

# Don't execute if source'd
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then 
    main $@; 
    exit 0
fi
return 0
