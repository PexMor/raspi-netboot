#!/bin/bash

if [ $EUID -ne 0 ]; then
    echo "switching to root"
    sudo $0
fi
[ $EUID -eq 0 ] || exit

# mount --bind /mnt/nvme/nfs /nfs

systemctl restart nfs-server
