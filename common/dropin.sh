  #!/usr/bin/env bash
if [ $# -gt 0 ] && { [ "$1" == "-h" ] || [ "$1" == "--help" ] ;} ; then
printf '

  Example: 
    $ di_setsrcdir "./drop-ins"
    $ di_drop "does-not-exist" /path/to/some/root
    > "Error: drop-in "does-not-exist" does not exist"
    $ di_drop "exists" /path/to/some/root
    > "exists/{...} copied to /path/to/some/root"
'
exit 0
fi

# Don't execute if source'd
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then 
    echo "This file ($0) should be sourced, not executed"
fi

#
#   Drop-in files helper
#
dropin_srcdir="/tmp/dropins"

function __remove_trailing_slashes () {
    local str="${1}"
    echo "$str" | sed 's:/*$::'
}

function di_setsrcdir () {
    local new_dropin_srcdir="$(__remove_trailing_slashes $1)"
    printf "Drop-in: New srcdir: ${new_dropin_srcdir}\n"
    dropin_srcdir="${new_dropin_srcdir}"
}

function di_drop () {
    local dropin_prefix="$(__remove_trailing_slashes $1)"
    local dropin_target="$(__remove_trailing_slashes $2)"
#    printf "\n  dropin_prefix=$dropin_prefix"
#    printf "\n  dropin_target=$dropin_target"
    if ! [[ -d "${dropin_srcdir}/${dropin_prefix}" ]]
    then
    printf "\n  dropin_prefix=$dropin_prefix"
        printf "\nDropin prefix does not exist: no such file or directory: ${dropin_srcdir}/${dropin_prefix}"
        exit 1
    fi
    for filename in "${dropin_srcdir}/${dropin_prefix}"/*
    do
#        printf "\n    -> $filename"
        local __filename=$(basename $filename)
#        printf "\n    -> $__filename"
        if [ "${__filename:0:3}" != "___" ]
        then
            printf "\nInvalid argument: not an absolute path: ${__filename}"
            exit 1
        fi 
        newpath=${__filename/___/}      # remove the first '___'
        newpath=${newpath//___/\/}    # replace all subsequent '___' by '/'
        mkdir -p "$(dirname "${dropin_target}/${newpath}")"
        cp "${dropin_srcdir}/${dropin_prefix}/${__filename}" "${dropin_target}/${newpath}"
        printf "\n-> ${dropin_target}/${newpath}"
    done
    printf "\n"
}
