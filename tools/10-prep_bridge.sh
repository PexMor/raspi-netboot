#!/bin/bash

set -x
set -e

source ~/.config/raspi/netboot/config.inc

if [ $EUID -ne 0 ]; then
    echo "switching to root"
    sudo $0
fi
[ $EUID -eq 0 ] || exit

# test script to:
# add the physical interface into the bridge to enable use with veth pairs
# the veth pair can be used either in netns or container (docker via inject trick)
brctl addif ${IF_NAME} ${IF_VLAN}
