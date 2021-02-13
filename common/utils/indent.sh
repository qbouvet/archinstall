#!/usr/bin/env bash
if [ $# -gt 0 ] && { [ "$1" == "-h" ] || [ "$1" == "--help" ] ;} ; then
printf '

  Example: 
    $ echo "hello" | indent 4
    >     hello
'
exit 0
fi

# Don't execute if source'd
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then 
    echo "This file ($0) should be sourced, not executed"
fi

function indent () {
    amount="${1:-4}"
    prefix=""
    IFS=''
    while [ "$amount" -gt 0 ]
    do
      prefix="${prefix} "
      amount=$((amount-1))
    done
    while read -r line ; do
      #printf "${prefix}${line}\n"
      echo "${prefix}${line}"
    done < /dev/stdin
}