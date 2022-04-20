#!/bin/bash

source ~/.config/raspi/netboot/config.inc

if [ $EUID -ne 0 ]; then
    echo "switching to root"
    sudo $0
fi
[ $EUID -eq 0 ] || exit

: ${CLI_DIR:=client1}
: ${ORIG_DIR:=orig}

SRC_FS=$NFS_ROOT/$ORIG_DIR
DST_FS=$NFS_ROOT/$CLI_DIR

rsync -av --info=progress2 --xattrs --acls "${SRC_FS}/." "${DST_FS}/"
