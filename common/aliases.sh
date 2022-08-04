function PACMAN () {
    pacman --noprogressbar --noconfirm ${@}
}

function YAY () {
    yay --removemake --sudoloop --norebuild --noredownload ${@}
}