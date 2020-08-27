#!/bin/bash -i


## Run me as root
##
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@";


## Paths & variables
##
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # module parameters
    # https://wiki.archlinux.org/index.php/zswap#Maximum_pool_size
max_pool_percent="30"
zpool="zbud"    # z3fold doesn't work for some reason
compressor="lzo"    


## Usage
##
if [ $# -lt 1 ] || [ "$1" == "-h" ] ; then
    printf"\
    Usage : zswap_conf <on/off/install>
";
    exit 0
fi


## Enable until next reboot
##
if [ $# -ge 1 ] && [ "$1" == "on" ] ; then
        # enable
    echo 1 > /sys/module/zswap/parameters/enabled;
        # params
    echo "$max_pool_percent" > /sys/module/zswap/parameters/max_pool_percent
    echo "$zpool" > /sys/module/zswap/parameters/zpool
    echo "$compressor" > /sys/module/zswap/parameters/compressor
        # feedback
    echo "zswap enabled. Parameters : ";
    grep -R . /sys/module/zswap/parameters;
    exit
fi


## Disable
##
if [ $# -ge 1 ] && [ "$1" == "off" ] ; then
    echo "Not implemented";
    exit
fi


## Enable indefinitely
##
if [ $# -ge 1 ] && [ "$1" == "off" ] ; then
    # Note : Kernel parameters
    # https://archlinuxarm.org/forum/viewtopic.php?f=47&t=7077
    echo "Not implemented";
    exit
fi

