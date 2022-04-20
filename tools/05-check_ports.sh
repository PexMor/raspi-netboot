#!/bin/bash

echo "EUID = $EUID"

[ $EUID -eq 0 ] || sudo $0
[ $EUID -eq 0 ] || exit

echo "...systemctl stop tftpd-hpa.service"
echo "...UDP/TFTP(69):"
lsof -P -n -i :69
echo RC=$?

echo "...UDP/DHCP(68):"
lsof -P -n -i :68
echo RC=$?

echo "...UDP/RPC-portmapper(111):"
lsof -P -n -i :111
echo RC=$?

echo "...UDP/NFS(2049):"
lsof -P -n -i :2049
echo RC=$?
