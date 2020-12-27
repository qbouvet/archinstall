#!/usr/bin/env bash

if [ $# -gt 0 ] && { [ "$1" == "-h" ] || [ "$1" == "--help" ] ;} ; then
printf '

  Example: 
    $ source trapstack.sh
    $ ...
    $ trap trap.all.run   <---| (?)

  Inspired from:
    https://stackoverflow.com/questions/3338030/multiple-bash-traps-for-the-same-signal  

  Would provide more features with an array datastructure. TODO. 

  Uses optional function arguments: 
    https://unix.stackexchange.com/questions/122845/using-a-b-for-variable-assignment-in-scripts/122878

'
exit 0
fi

# Don't execute, only source
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then 
    echo "This file ($0) should be sourced, not executed"
fi


#
#   Backing stack data structure
#
# For more features, this should be an array
__trapstack_trap_string=""


#
#   Add instructions to the trap stack
#
function trap.stack {
  local to_add=$1
  if [[ -z "$__trapstack_trap_string" ]]
  then
    __trapstack_trap_string=""
  fi
  __trapstack_trap_string="
${to_add}
${__trapstack_trap_string}"
}

function trap.all.pprint {
  printf "
trap.all: 
"
  printf "$__trapstack_trap_string"
  printf "\n"
}

#
#   Run all instruction "last-in-first-out"
#
function trap.all.run {
    set +o errexit              # Disable exit on error while trapped
    my___trapstack_trap_string="$__trapstack_trap_string"     # "Acquire exclusively" the trap string
    __trapstack_trap_string=""
    eval "$my___trapstack_trap_string"
    set -o errexit              # Re-enable exit
}

#
#   Discard all trapped instructions
#
function trap.all.del {
    __trapstack_trap_string=""
}

#
#   Discard one or more instruction "last-in-first-out"
#
function trap.top.del {
    echo "$0: not implemented"
    return 1
    local count=${$1:-1}
}

#
#   Run one or more instruction "last-in-first-out"
#
function trap.top.run {
    echo "$0: not implemented"
    return 1
    local count=${$1:-1}
}