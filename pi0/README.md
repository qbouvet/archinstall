 
# Install scripts for rapsberry pi zero W

How to use ? 
 -> Insert SD card into computer
 -> Read and adapt config.sh 
 -> Run ./main.sh 
 (/tmp/install-arch/$hostname will be used as work directory)
 -> Put SD into raspberry pi and start it
 
How do I login ? 
 -> Option 1: Usb-gadget-ethernet is configured. 
    Plug your pi via the data usb port and share your computer connection
 -> Option 2: Multiple wireless networks are configured and connect automatically at boot
    Configure yours via ./drop-in/netctl-wlan0-profiles

    
TODO
 * Configure yay 
 * Configure pacman hooks (clean pkg cache, ...)
 * Debug scheduled scripts functionality
 * Configure swap with systemd swap
 * Use ZFS instead of ext4
