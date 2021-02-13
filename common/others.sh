 
#!/bin/bash

#
#   Timestamp function
#
function timestamp {
    date +%Y%m%d_%H%M%S
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