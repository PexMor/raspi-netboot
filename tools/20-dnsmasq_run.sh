#!/bin/bash

set -x
set -e

source ~/.config/raspi/netboot/config.inc

if [ $EUID -ne 0 ]; then
    echo "switching to root"
    sudo $0
fi
[ $EUID -eq 0 ] || exit

[ -d "${HOME}/.config/raspi/netboot/dhcp-hostdir" ] || mkdir -p "${HOME}/.config/raspi/netboot/dhcp-hostdir"
# MODE=--keep-in-foreground
MODE=--no-daemon

INTF=brinet

rm -f /tmp/dnsmasq-${IF_NAME}.log
dnsmasq \
  --conf-file=conf/dnsmasq-static.conf \
  $MODE \
  --log-facility=/tmp/dnsmasq-${IF_NAME}.log \
  --interface=${IF_NAME} \
  --tftp-root=${TFTP_ROOT} \
  --pid-file=${HOME}/.config/raspi/netboot/dnsmasq-${IF_NAME}.pid \
  --dhcp-hostsdir=${HOME}/.config/raspi/netboot/dhcp-hostdir
