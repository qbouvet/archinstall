#!/usr/bin/env bash


## Setup
##
    # Error codes
set -o nounset      # exit on unassigned variable
set -o errexit      # exit on error
set -o pipefail     # exit on pipe fail

    # Acquire root
#[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@";

    # Set execution director
export __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
pushd $__dir;

    # Source variables
source 0-config.sh







########################################################################
#########################    EXECUTION    ##############################
########################################################################



## Clear alarm user
##
function rem_alarm {
    sudo userdel alarm;
    sudo rm -rf /home/alarm;
}
ask_go "[remove alarm user]" rem_alarm




## autostart-login.sh
## 
function autostart_login_sh {
        # Put autostart.sh in user directory
    cp data-autostart-login.sh "$HOME"/autostart-login.sh
    chmod +x "$HOME"/autostart-login.sh;
        # Systemd service to start it up
    mkdir -p "$HOME"/.config/systemd/user/;
    echo '
    # ~/.config/systemd/user/autostart-login.sh.service
    [Unit]
    Description=$USER - autostart-login.sh

    [Service]
    Type=forking
    ExecStart=/bin/bash -i %h/autostart-login.sh
    RemainAfterExit=yes

    [Install]
    WantedBy=default.target
    ' | sed 's|    ||g' >"$HOME"/.config/systemd/user/autostart-login.service
    chmod 744 "$HOME"/.config/systemd/user/autostart-login.service;
        # enable service
    systemctl --user enable autostart-login;
}
ask_go "[autostart-login.sh]" autostart_login_sh


exit 0 ;










########################################################################
#######################    LEGACY CODE    ##############################
########################################################################
## For reference later
echo "You've reached deprecated code"; exit 1;


## Variables
##
export ssh_key_name="sshkey_pi_quentin";
export git_mail="quentin.bouvet@hotmail.fr";
export git_user="quentin";
export git_remote="git@github.com:sgPepper/rbpi.git";
export rbpi_git_dir="$HOME"/rbpi-git;   # source from bashrc



## ssh-agent setup
##
ask_go "\n\n [ssh-agent setup]\n"
if [ "$ask_go_go" == "true" ] ; then 
    echo "BROKEN"
        # "Remember keys" setting
    mkdir -p /home/"$USER"/.ssh/;
    echo "AddKeysToAgent yes" > "$HOME"/.ssh/config;
        # Service : cf arch wiki
    mkdir -p "$HOME"/.config/systemd/user/;
    printf "
        [Unit]
        Description=SSH key agent

        [Service]
        Type=simple
        Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
        ExecStart=/usr/bin/ssh-agent -D -a \$SSH_AUTH_SOCK

        [Install]
        WantedBy=default.target
    " | sed 's|    ||g' >"$HOME"/.config/systemd/user/ssh-agent.service
    echo 'SSH_AUTH_SOCK DEFAULT="${XDG_RUNTIME_DIR}/ssh-agent.socket"' >> "$HOME"/.pam_environment;
    export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.socket"; # use without rebooting
    chmod 744 "$HOME"/.config/systemd/user/ssh-agent.service;
        # Enable / start
    systemctl --user enable ssh-agent;
    systemctl --user start ssh-agent;
        # Add key & do first git commit so that key is remembered
    sudo cp "$__data"/"$ssh_key_name" "$__data"/"$ssh_key_name".pub "$HOME"/.ssh;
    sudo chown -R "$USER":users "$HOME"/.ssh;
    ssh-add "$HOME"/.ssh/"$ssh_key_name";
fi



## Git / github repo setup
##
ask_go "\n\n [Github repo setup]\n";
if [ "$ask_go_go" == "true" ] ; then 
        # Global git config
    git config --global user.email "$git_mail";
    git config --global user.name "$git_user";
        # repo setup
    mkdir -p "$rbpi_git_dir";
    pushd "$rbpi_git_dir";
    git init;
    git remote add origin "$git_remote";
    echo "  The 'Permission denied (publickey)' can be ignored if the subsequent commit completes";
    ssh -o StrictHostKeyChecking=no github.com 1h;
    git pull origin master;
        # One commit to make sure
    print_ip > ip;
    git add ip;
    git commit -m "ip autocomit";
    git push -u origin master;
    popd;
fi


