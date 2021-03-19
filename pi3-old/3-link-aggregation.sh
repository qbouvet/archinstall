#!/usr/bin/env bash

if [ $# -gt 0 ] && { [ "$1" == "-h" ] || [ "$1" == "--help" ] ;} ; then
printf "\

    3-link-aggregation.sh
    =====================

  !! DRAFT !! 
  
  See: 
    * https://wiki.linuxfoundation.org/networking/bonding#Bonding_Driver_Options
    * https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/networking_guide/sec-network_bonding_using_the_networkmanager_command_line_tool_nmcli
    * https://serverfault.com/questions/382224/linux-bonding-802-3ad-lacp-vs-balance-alb-mode
    
  Alternatively, for netctl, see: 
    * https://wiki.archlinux.org/index.php/netctl#Bonding  

"
exit 0
fi


#======================================================================#
#                             GLOBALS                                  #
#======================================================================#


function initialize() {
    # Usual environment variables
    local _dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local _name="$(basename ${BASH_SOURCE[0]})" 
    # Imports
    source "$_dir/0-utils.sh" 
}

function packages() {
    pacman --noprogressbar --noconfirm -S networkmanager
}

function services() { 
    # ???
    # See 2-wifi-ap.sh
    #
}

function config() {
    # Current connections: 
    echo "Existing connections:"
    nmcli connection show
    
    # Wired connections 
    nmcli connection add \
      con-name "eth-over-usb-0" \
      type "ethernet" \
      ifname "usb0" \
      autoconnect "no"
    nmcli connection add \
      con-name "eth-over-usb-1" \
      type "ethernet" \
      ifname "usb1" \
      autoconnect "no"
    nmcli connection add \
      con-name "eth-over-usb-2" \
      type "ethernet" \
      ifname "usb2" \
      autoconnect "no"
    nmcli connection add \
      con-name "eth-over-usb-3" \
      type "ethernet" \
      ifname "usb3" \
      autoconnect "no"
      
    # Remove old connections
    nmcli connection delete "Wired connection 1"
    nmcli connection delete "Wired connection 2"
    nmcli connection delete "Wired connection 3"
    nmcli connection delete "Wired connection 4"
    
    # Rond-robin
    master="bond-rr"
    mode="balance-rr"
    nmcli connection add \
      con-name "$master" \
      type "bond" \
      ifname "$master" \
      bond.options "mode=$mode" \
      autoconnect "no"
    nmcli connection add \
      con-name "$master-usb0" \
      type "ethernet" \
      ifname "usb0" \
      master "$master" \
      autoconnect "no"
    nmcli connection add \
      con-name "$master-eth1" \
      type "ethernet" \
      ifname "eth1" \
      master "$master" \
      autoconnect "no"
    
    # XOR
    master="bond-xor"
    mode="balance-xor"
    nmcli connection add \
      con-name "$master" \
      type "bond" \
      ifname "$master" \
      bond.options "mode=$mode" \
      autoconnect "no"
    nmcli connection add \
      con-name "$master-usb0" \
      type "ethernet" \
      ifname "usb0" \
      master "$master" \
      autoconnect "no"
    nmcli connection add \
      con-name "$master-eth1" \
      type "ethernet" \
      ifname "eth1" \
      master "$master" \
      autoconnect "no"
    
    # ALB = TLB + Receiving load balancing
    master="bond-alb"
    mode="balance-alb"
    nmcli connection add \
      con-name "$master" \
      type "bond" \
      ifname "$master" \
      bond.options "mode=$mode" \
      autoconnect "no"
    nmcli connection add \
      con-name "$master-usb0" \
      type "ethernet" \
      ifname "usb0" \
      master "$master" \
      autoconnect "no"
    nmcli connection add \
      con-name "$master-eth1" \
      type "ethernet" \
      ifname "eth1" \
      master "$master" \
      autoconnect "no"
    
    # TLB
    master="bond-tlb"
    mode="balance-tlb"
    nmcli connection add \
      con-name "$master" \
      type "bond" \
      ifname "$master" \
      bond.options "mode=$mode" \
      autoconnect "no"
    nmcli connection add \
      con-name "$master-usb0" \
      type "ethernet" \
      ifname "usb0" \
      master "$master" \
      autoconnect "no"
    nmcli connection add \
      con-name "$master-eth1" \
      type "ethernet" \
      ifname "eth1" \
      master "$master" \
      autoconnect "no"
    
    # Dynamic 802.3ad
    master="bond-dyn"
    mode="4"
    nmcli connection add \
      con-name "$master" \
      type "bond" \
      ifname "$master" \
      bond.options "mode=$mode" \
      autoconnect "no"
    nmcli connection add \
      con-name "$master-usb0" \
      type "ethernet" \
      ifname "usb0" \
      master "$master" \
      autoconnect "no"
    nmcli connection add \
      con-name "$master-eth1" \
      type "ethernet" \
      ifname "eth1" \
      master "$master" \
      autoconnect "no"
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
