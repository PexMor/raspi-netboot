#!/bin/bash

set -x
set -e

source ~/.config/raspi/netboot/config.inc

if [ $EUID -ne 0 ]; then
    echo "switching to root"
    sudo $0
fi
[ $EUID -eq 0 ] || exit

RMF=()
RMF+=(etc/rc2.d/S01dphys-swapfile)
RMF+=(etc/rc3.d/S01dphys-swapfile)
RMF+=(etc/rc4.d/S01dphys-swapfile)
RMF+=(etc/rc5.d/S01dphys-swapfile)
RMF+=(etc/rc3.d/S01resize2fs_once)
RMF+=(etc/rc2.d/K01ssh)
RMF+=(etc/systemd/system/multi-user.target.wants/dphys-swapfile.service)
# RMF+=(etc/systemd/system/multi-user.target.wants/regenerate_ssh_host_keys.service)
RMF+=(etc/systemd/system/multi-user.target.wants/userconfig.service)

: ${CLI_DIR:=client1}

ROOTFS=$NFS_ROOT/$CLI_DIR

# prevent wrong deletions !!!
[ -z "$ROOTFS" ] && exit -1

echo "Run the preparation script @ '$ROOT_FS'"
echo "To continue press ENTER"
read ENTER

for FN in "${RMF[@]}"; do
  echo "remove $FN"
  rm -rf ${ROOTFS}/$FN
done

sed -i 's/pi:[^:][^:]*:/pi:$y$j9T$SBXTP92AwBHv4p\/Xa3aAr.$fH4IgKj86SWjCUet771eojGrddd\/xzLwbeG3KTlPNbB:/' "$ROOTFS/etc/shadow"

cat >"${ROOTFS}/etc/fstab" <<DATA
proc            /proc           proc    defaults          0       0
100.64.0.1:/mnt/nvme/tftp /boot nfs defaults,vers=4.1,proto=tcp,ro 0 0
DATA

# copy orig
# rsync -av --info=progress2 --xattrs --acls /nfs/orig/. /nfs/client2/
# LC_ALL=C diff --brief --recursive --no-dereference orig/ client1/ | grep "Only in client1/"
# optional but reasonable

for RL in 2 3 4 5; do
  echo "start ssh"
  ln -sf ../init.d/ssh ${ROOTFS}/etc/rc${RL}.d/S01ssh
done

ln -sf /lib/systemd/system/multi-user.target ${ROOTFS}/etc/systemd/system/default.target
ln -sf /lib/systemd/system/ssh.service ${ROOTFS}/etc/systemd/system/multi-user.target.wants/ssh.service
ln -sf /lib/systemd/system/ssh.service ${ROOTFS}/etc/systemd/systemsshd.service
mkdir -p ${ROOTFS}/etc/systemd/system/getty.target.wants
ln -sf /lib/systemd/system/getty@.service ${ROOTFS}/etc/systemd/system/getty.target.wants/getty@tty1.service
