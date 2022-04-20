#!/bin/bash

VER=4.2
mkdir -p /run/{lower,merged,rw}

umount /run/merged
umount /run/lower
umount /run/rw

mount -t nfs -o defaults,vers=${VER},proto=tcp,ro 100.64.0.1:/nfs/client2 /run/lower
mount -t nfs -o defaults,vers=${VER},proto=tcp,rw 100.64.0.1:/nfs/client2o /run/rw
mkdir -p /run/rw/{upper,work}
mount -t overlay -o rw,lowerdir=/run/lower,upperdir=/run/rw/upper,workdir=/run/rw/work none /run/merged

# was reporting when there was no /run/rw common ancestor
#[ 1693.084207] overlayfs: workdir and upperdir must reside under the same mount
# when run at raspberry pi 3b+
#[ 1910.784898] overlayfs: upper fs does not support tmpfile.
#[ 1910.798927] overlayfs: upper fs does not support RENAME_WHITEOUT.
#[ 1910.798961] overlayfs: upper fs missing required features.
