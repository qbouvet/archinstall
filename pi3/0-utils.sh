#!/bin/bash

#  
#   User interaction
#
function ask_go {
    if [ "$#" -lt 0 ] ; then
        echo "Error: Missing argument"
        return
    fi
    ask="===> $1"; shift;
    passedFunction=${@}
    [ -x "$(command -v notify-send)" ] && notify-send --icon=terminator "$ask";
    printf "\n\n$ask";
    input=''
    while [ "true" ] ; do
        printf "\n===> [ go | skip | stop ] \n===> " ; read input
        case "$input" in
        ("go")      echo ""
                    $passedFunction
                    echo "Done !"
                    return 0;;
        ("skip")    echo "Skipping"
                    return 0;;
        ("stop")    echo "Exiting"
                    exit 0;;
        (*)         echo " ? ($input) ";;
        esac
    done
}

#
#   Indent stdin
#
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

#
#   AUR installer. Automates downloading, extracting and calling makepkg.
#   Args : $1  AUR package name
#          $2+ passed to makepkg (e.g. if --skippgpcheck is needed)
#
function manual_aur_install () {
    _user="quentin"
    _package="$1"
    _builddir="/tmp/build"
    _gitlink="https://aur.archlinux.org/${_package}.git"
    [ ! -e "$_builddir" ] && mkdir -p "$_builddir"
    pushd "$_builddir"
    rm -rf "$_package"
    printf "\n\nCloning...\n"
    git clone "$_gitlink" | indent
    chmod 777 -R "$_builddir/$_package"
    cd "$_package"
    printf "\n\nBuilding...\n"
    sudo -u "$_user" makepkg "${@:2}"
    printf "\n\n... Installing\n"
    if [[ -x $(which pacinstall) ]]; then
        pacinstall --file "$_package"*.tar.xz \
          --resolve-conflicts=all --noconfirm 
    else 
        pacman -U "$_package"*.tar.xz --noconfirm
    fi
    printf "\n\nDone\n"
    popd
}


#
#  Reporting helper
#
report_file="/tmp/report.txt"
function report.into () {
    local new_report_file="$1"
    printf "Report.into $new_report_file\n"
    report_file="$new_report_file"
}
function report.append () {
    local content="$1"
    mkdir -p "$(dirname report_file)"; touch "$report_file"
    printf "$1" >> "$report_file"
}
function report.clear () {
    mkdir -p "$(dirname report_file)"; touch "$report_file"
    printf "" > "$report_file"
}
function report.produce () {
    mkdir -p "$(dirname report_file)"; touch "$report_file"
    cat "$report_file"
    report.clear
}


#
#  Arguments parsing into associative array
#
function aa.argparse() {
    #   Parse parameters into the associative array
    #   Arguments : 
    #       $1          associative array
    #       ${@:1}      CLI parameters
    #   Example : 
    #       aa.argparse params ${@:1}
    #
    # Bash caveat: This name must not collide in caller or called function namespaces
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
function aa.contains() {
    #   Check key existence in associative array. For use inside [ ].
    #   https://stackoverflow.com/questions/13219634/easiest-way-to-check-for-an-index-or-a-key-in-an-array
    #   Arguments
    #       $1  associative array passed by reference
    #       $2  key
    #   Returns : 
    #       "true" if true
    #       <emtpy string> if false, for usability in if clauses
    #
    declare -n aa_contains_array="$1"
    [[ "${aa_contains_array[$2]+someDefaultString}" ]]
}
function aa.pprint() {
    #   Pretty-print an associative array.
    #   Arguments : 
    #       $1      assoc array passed by reference 
    #               (i.e. pass the array name without $) 
    #       $2      Optional header 
    #       $3      Optional display key length
    #
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


#
#  Misc helpers for readability
#
function timestamp {
    date +%Y%m%d_%H%M%S
}
function fOverwrite () {
    # overwrite the content of a file
    _file="$1"
    _text="$2"
    printf "$_text" | sed 's:    ::g' > "$_file"
}
function fAppend () {
    # Append as new line at the end of a file
    _file="$1"
    _text="$2"
    printf "$_text" | sed 's:    ::g' >> "$_file"
}
function fLineAppend () {
    # Append to the last line (!: No new line)
    _file="$1"
    _text="$2"
    sed "\$s/\$/${_text}/" -i "$_file"
}
function fComment () {
    # Find and comment all instances
    _file="$1"
    _text1="$2"
    _text2="#$2"
    sed "s|${_text1}|${_text2}|g" -i "$_file"
}
function fUncomment () {
    # Find and uncomment all instances
    _file="$1"
    _text1="#$2"
    _text2="$2"
    sed "s|${_text1}|${_text2}|g" -i "$_file"
}
