#!/usr/bin/env bash

if [ $# -gt 0 ] && { [ "$1" == "-h" ] || [ "$1" == "--help" ] ;} ; then
printf "\

    pi3-wifi-ap.sh
    ==============

  Configure a rasberry pi to act as a wifi access point. Especially 
  great with 3g/4g routers or USB sticks.
  
  See https://unix.stackexchange.com/questions/234552/create-wireless-access-point-and-share-internet-connection-with-nmcli

"
exit 0
fi


#======================================================================#
#                             GLOBALS                                  #
#======================================================================#

ssid="pi3.net" 
passwd="30275032"
interface="wlan0"

function initialize() {
    # Usual environment variables
    local _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local _name="$(basename ${BASH_SOURCE[0]})" 
    # Imports
    source "$_dir/0-utils.sh" 
}

function packages() {
    pacman --noprogressbar --noconfirm -S networkmanager modemmanager usb_modeswitch
}

function services() { 
    systemctl disable wpa_supplicant@"$interface" 
    systemctl disable systemd-networkd
    systemctl start NetworkManager
    
    systemctl stop systemd-networkd \
      && systemctl stop wpa_supplicant@"$interface" \
      && systemctl stop systemd-networkd \
      && systemctl enable NetworkManager
}

function config() {
    nmcli connection add \
      con-name "hotspot-$ssid" \
      type "wifi" \
      ifname "$interface" \
      ssid "$ssid" \
      mode "ap" \
      autoconnect "yes"
    nmcli connection modify "hotspot-$ssid" \
      802-11-wireless.mode "ap" \
      802-11-wireless-security.key-mgmt "wpa-psk" \
      802-11-wireless-security.psk "$passwd" \
      ipv4.method "shared"
    nmcli connection up "$ssid"
}


#======================================================================#
#                           EXECUTION                                  #
#======================================================================#

function script_sh () {
    printf "Installing packages\n" 
    packages | indent 2
    printf "Done\n\n" 
    printf "Preparing systemctl services\n" 
    services | indent 2
    printf "Done\n\n" 
    printf "Configuring application\n" 
    config | indent 2
    printf "Done\n\n" 
    
}

# Don't execute if source'd
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then 
    # Usual bash flags
    set -euo pipefail   # Exit on 1/ nonzero exit code 2/ unassigned variable 3/ pipe error
    #set -o xtrace      # Show xtrace
    shopt -s nullglob   # Allow null globs

    initialize $@
    script_sh $@
    exit 0
fi

return 0
