#!/bin/bash


## Init
##
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -f "$__dir"/variables.sh ]; then 
    echo "0-config.sh not found, exiting"; 
fi
set -o nounset      # exit on unassigned variable
set -o errexit      # exit on error
source "$__dir"/0-config.sh
loadkeys fr_CH
pushd "$__dir"



function sshd_setup {
        # sshd config
    sudo printf "\n\n\n    # Personal config\n#" >> /etc/ssh/sshd_config
    sudo printf "\n\n\nPermitRootLogin no \n#" >> /etc/ssh/sshd_config
    sudo printf "\nAllowUsers    $username" >> /etc/ssh/sshd_config
    sudo printf "\nX11Forwarding yes" >> /etc/ssh/sshd_config
	# systemd socket setting
    mkdir -p /etc/systemd/system/sshd.socket.d/
    sudo printf "[Socket]\nListenStream=\nListenStream=${sshport}\n" > /etc/systemd/system/sshd.socket.d/override.conf
        # start daemon
    sudo systemctl enable sshd.socket
    sudo systemctl start sshd.socket
}
ask_go "[ssh daemon (sshd) settings]" sshd_setup



function vnc_setup {
    sudo pacman -S tigervnc
    vncserver
    
}
ask_go "[VNC server setup]" vnc_setup


function samba_setup {
    useradd --no-create-home -G storage "$samba_user"
    usermod --shell /usr/bin/nologin --lock "$samba_user"
    smbpasswd -a "$samba_user"
}


popd;
printf "\n\n\tDone ! \n\n\tDon't forget to configure correctly the NAT/PAT/port forwarding on your router ;)\n\n"


