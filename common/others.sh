 
#!/bin/bash

#
#   Timestamp function
#
function timestamp {
    date +%Y%m%d_%H%M%S
}


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