#!/bin/bash

if [ $EUID -ne 0 ]; then
    echo "switching to root"
    sudo $0
fi
[ $EUID -eq 0 ] || exit

VER=4.2
BASE=/nfs
PFX=$BASE/client3

umount $PFX/merged
mkdir -p $PFX/{merged,upper,work}

mount -t overlay -o rw,lowerdir=$BASE/client2,upperdir=$PFX/upper,workdir=$PFX/work none $PFX/merged
