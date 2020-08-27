#!/usr/bin/env bash

  #
  #   Initial setup, imports, requires
  #
function prepare () {
    set -o nounset      # exit on unassigned variable
    set -o errexit      # exit on error
    set -o pipefail     # exit on pipe fail
  # Set execution directory
    export __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
    pushd "$__dir";
  # Source variables
    source "${__dir}/0-config.sh"
  # Report
    report="REPORT:"
}
# Acquire root
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@";
prepare



  # Parameters
  #
function parameters () {
    user="quentin"
    packages=(python python-tornado)
    packages_aur=(python-picamera python-raspberry-gpio)
}
parameters



  # Install dependancies
  #
function dependancies () {
    pacman -S "${packages[@]}" --noconfirm
    sudo -u "$user" aurman -S "${packages_aur[@]}" \
      --noconfirm --skip_news --skip_new_locations;
}
ask_go "Install dependancies" dependancies



  # Clone repo
  #
function git_install () {
    pushd /opt
    git clone https://github.com/sgPepper/watchbot-dev.git
    [ -e watchbot ] && rm watchbot
    ln -s watchbot-dev watchbot
    popd
}
ask_go "Clone repository" git_install



  # autostart-boot.sh - doesn't work
  #
function autostart {
    overwrite "/etc/systemd/system/watchbot.service" "\
        # /etc/systemd/system/watchbot.service
        \n[Unit]
        Description=Watchbot at boot
        \n[Service]
        Type=forking
        ExecStart=python /opt/watchbot/main.py
        TimeoutSec=0
        RemainAfterExit=yes
        \n[Install]
        WantedBy=multi-user.target
    "
    chmod 744 /etc/systemd/system/watchbot.service;
    systemctl enable watchbot.service;
}
ask_go "enable autostart" autostart



  # Exit
  #
report="${report}\n\n    Script:
      1.  Watchbot has been installed
"
printf "\n\n${report}"
popd
exit 0
