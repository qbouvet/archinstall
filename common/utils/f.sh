#!/usr/bin/env bash
if [ $# -gt 0 ] && { [ "$1" == "-h" ] || [ "$1" == "--help" ] ;} ; then
printf '

  Example: 
    $ source f.sh
    $ f_overwrite /etc/locale.conf "LANG=en_US.UTF-8"
    $ f_uncomment /etc/locale.gen  "en_US.UTF-8"
    $ f_append    /etc/sudoers     "\n\n%wheel ALL=(ALL) ALL"
'
exit 0
fi

# Don't execute if source'd
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then 
    echo "This file ($0) should be sourced, not executed"
fi


#
#    Overwrite the content of a file
#
function f_overwrite () {
    _file="$1"
    _text="$2"
    printf "$_text" | sed 's:    ::g' > "$_file"
}

#
#   Append to the last line (!: No new line)
#
function f_append () {
    # https://unix.stackexchange.com/questions/20573/sed-insert-text-after-the-last-line
    _file="$1"
    shift
    for _text in "$@" # !! '"' on "$@"" are very important
    do 
        sed "\$s|\$|$_text|" -i "$_file"
        shift
    done
}

#
#   Find and comment all instances
#
function f_comment () {
    _file="$1"
    _text1="$2"
    _text2="#$2"
    sed "s|${_text1}|${_text2}|g" -i "$_file"
}

#
#   Find and uncomment all instances
#
function f_uncomment () {
    # Find and uncomment all instances
    _file="$1"
    _text1="#$2"
    _text2="$2"
    sed "s|${_text1}|${_text2}|g" -i "$_file"
}

#
#   Replace all lines containing the pattern in $2 by 
#   the raw text line in $3
#
function f_replaceLine () {
    _file="$1"
    _text1="$2"
    _text2="$3"
    sed "s|^.*${_text1}.*$|${_text2}|g" -i "$_file"
}

#
#   Deprecated
#
#   Append as new line at the end of a file
#
function f_newlineAppend () {
    _file="$1"
    _text="$2"
    printf "$_text" | sed 's:    ::g' >> "$_file"
}
