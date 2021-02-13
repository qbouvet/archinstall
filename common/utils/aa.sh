#!/usr/bin/env bash
if [ $# -gt 0 ] && { [ "$1" == "-h" ] || [ "$1" == "--help" ] ;} ; then
printf "
    aa.sh
    =====

  Example: 
    $ source aa.sh
    $ declare -A params
    $ params[quality]=24
    $ params[encoder]=x265
    $ aa.argparse params \${@:1}
    $ echo ${params[quality]}
    >>> 24
    $ aa.contains params quality
    >>> true
    $ aa.contains params something_else
    >>> true
    $ aa.pprint params
    >>> ...
"
exit 0
fi

# Don't execute if source'd
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then 
    echo "This file ($0) should be sourced, not executed"
fi


#   Parse parameters into the associative array
#   Arguments : 
#       $1          associative array
#       ${@:1}      CLI parameters
#   Example : 
#       aa.argparse params ${@:1}
#
# Bash caveat: This name must not collide in caller or called function namespaces
function aa.argparse() {
    declare -n aa_parse_args_array="$1" 
    itr=2
    while [ $itr -le $# ]; do
        argname="${!itr}"; 
        # remove '--' and transform '-' -> '_'
        pname=$(echo "$argname" | sed 's/--//g' | sed 's/-/_/g');
        itr=$((itr+1)) 		# In any case, we'll skip to the next parameter
        #echo "parsing parameter $pname"
        # Check parameter exists in 'params'
        if ! $(aa.contains aa_parse_args_array "$pname"); then
            printf "\nError : Argument not recognized : %s\n" "$pname"
            return 1
        # nothing afterwards -> necessarily boolean flag
        elif [ $itr -gt $# ]; then 
            if [ ${aa_parse_args_array["$pname"]} != "true" ] && [ ${aa_parse_args_array["$pname"]} != "false" ]  ; then
                printf "Parameter doesnt seem to be a boolean flag : $pname\n";
            else 
                aa_parse_args_array["$pname"]="true";
            fi
        # pname is a recognized parameter AND we've got something afterwards
        else
            nextarg="${!itr}"; 
            # If the next string is an option, then we have a boolean flag
            if [ "${nextarg:0:2}" == "--" ]; then
                if [ ${aa_parse_args_array["$pname"]} != "true" ] && [ ${aa_parse_args_array["$pname"]} != "false" ]  ; then
                    printf "Parameter doesnt seem to be a boolean flag : $pname\n\n";
                else 
                    aa_parse_args_array["$pname"]="true";
                fi
            # Otherwise, we have a valued parameter
            else 
                aa_parse_args_array["$pname"]="${!itr}";
                itr=$((itr+1));	    # skip value
            fi
        fi
    done
}


#   Check key existence in associative array. For use inside [ ].
#   https://stackoverflow.com/questions/13219634/easiest-way-to-check-for-an-index-or-a-key-in-an-array
#   Arguments
#       $1  associative array passed by reference
#       $2  key
#   Returns : 
#       "true" if true
#       <emtpy string> if false, for usability in if clauses
#
function aa.contains() {
    declare -n aa_contains_array="$1"
    [[ "${aa_contains_array[$2]+someDefaultString}" ]]
}


#   Pretty-print an associative array.
#   Arguments : 
#       $1      assoc array passed by reference 
#               (i.e. pass the array name without $) 
#       $2      Optional header 
#       $3      Optional display key length
#
function aa.pprint() {
    declare -n aa_pprint_array="$1"
    [[ "$#" -lt 2 ]] \
      && printf "\n%s\n" "$1" \
      || printf "\n%s\n" "$2"
    keylen=${3:-20}
    for key in "${!aa_pprint_array[@]}"; do
        printf "  + %-${keylen}s	: %s \n" "$key" ${aa_pprint_array["$key"]}
    done
    echo '----'; echo '';
}