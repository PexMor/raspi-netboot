# Netboot Raspi

This document gather some notes on how to setup booting a Raspberry Pi (3B+ and later) over network.
## The process

1. U-Boot on RPi waits 10s before trying the DHCP (?speedup by boot order?)
2. DHCP IP requests is sent over to DHCP server (target address is 255.255.255.255 - IPv4 broadcast, IPv6 is available starting RPi 4B+)
3. DHCP server reponds with IPv4 and few more options (43,66,67 - where only the `66`/next-server is required)
4. RPi using the option `66` requests `bootcode.bin`
5. The `bootcode.bin` is executed and extra files are requested from `TFTP` server
6. When all files are 

### Files requested on RPi 3B+

The following was recorded by `tftpd-hpa` daemon on Ubuntu 20.04. Some files are listed and requested __twice__ and not all files are present in `boot.tar.xz` or `BOOT`/FAT partition on your micro SD card or image.

> Note: the `<serial>` is placeholder for actuall serial number of your RPi.

The whole process spans across period of aprox. 3 seconds running on 1Gbps network (though RPi 3B+ has USB LAN chip capable of ~ 300Mbps).

For details see [#Boot folder](https://www.raspberrypi.com/documentation/computers/configuration.html#the-boot-folder) and/or [Raspberry Pi](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#raspberry-pi-4-boot-eeprom)

| filename                             | status        |
|--------------------------------------|---------------|
| `bootcode.bin`                       | ok            |
| `bootsig.bin`                        | not present   |
| `<serial>/start.elf`                 | ok            |
| `<serial>/start.elf`                 | ok#2          |
| `<serial>/autoboot.txt`              | not present   |
| `<serial>/config.txt`                | ok            |
| `<serial>/recovery.elf`              | not present#1 |
| `<serial>/start.elf`                 | ok#3          |
| `<serial>/fixup.dat`                 | ok            |
| `<serial>/recovery.elf`              | not present#2 |
| `<serial>/config.txt`                | ok#2          |
| `<serial>/config.txt`                | ok#3          |
| `<serial>/dt-blob.bin`               | not present   |
| `<serial>/recovery.elf`              | not present#3 |
| `<serial>/config.txt`                | ok#4          |
| `<serial>/config.txt`                | ok#5          |
| `<serial>/bootcfg.txt`               | not present   |
| `<serial>/bcm2710-rpi-3-b-plus.dtb`  | ok            |
| `<serial>/bcm2710-rpi-3-b-plus.dtb`  | ok#2          |
| `<serial>/overlays/overlay_map.dtb`  | not present   |
| `<serial>/overlays/overlay_map.dtb`  | not present#2 |
| `<serial>/config.txt`                | ok#6          |
| `<serial>/config.txt`                | ok#7          |
| `<serial>/overlays/vc4-kms-v3d.dtbo` | not present   |
| `<serial>/overlays/vc4-kms-v3d.dtbo` | not present#2 |
| `<serial>/cmdline.txt`               | ok            |
| `<serial>/cmdline.txt`               | ok#2          |
| `<serial>/recovery8.img`             | not present   |
| `<serial>/kernel8.img`               | ok            |
| `<serial>/kernel8.img`               | ok#2          |
| `<serial>/armstub8.bin`              | not present   |
| `<serial>/kernel8.img`               | ok#3          |
| `<serial>/kernel8.img`               | ok#4          |

Important files:

`cmdline.txt` - points to the NFS and sets the kernel options including `splash` and `quiet` (ref.[conf/cmdline.txt.sample](conf/cmdline.txt.sample)) which could look like:

`dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=/dev/nfs nfsroot=100.64.0.1:/nfs/client1,vers=4.2,proto=tcp rw ip=dhcp rootwait elevator=deadline quiet splash`

`config.txt` - the usual RPi config (as found on FAT `/boot` partition)

files present in `boot.tar.xz`:

```
bcm2710-rpi-cm3.dtb
bcm2710-rpi-zero-2.dtb
bcm2710-rpi-zero-2-w.dtb
bcm2710-rpi-2-b.dtb
bcm2710-rpi-3-b.dtb
bcm2710-rpi-3-b-plus.dtb
bcm2711-rpi-cm4.dtb
bcm2711-rpi-cm4s.dtb
bcm2711-rpi-4-b.dtb
bcm2711-rpi-400.dtb
cmdline.txt
config.txt
COPYING.linux
fixup_cd.dat
fixup.dat
fixup_db.dat
fixup_x.dat
fixup4cd.dat
fixup4.dat
fixup4db.dat
fixup4x.dat
issue.txt
kernel8.img
LICENCE.broadcom
overlays
start_cd.elf
start_db.elf
start.elf
start_x.elf
start4cd.elf
start4db.elf
start4.elf
start4x.elf
```

Some manapages (eventually search `man dnsmasq`):

* [man dnsmasq](https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html) to provide DHCP, TFTP and DNS
* [man rpcinfo](https://linux.die.net/man/8/rpcinfo) to list registered SUN RPC services
* [man exportfs](https://linux.die.net/man/8/exportfs) re-export `-r` as root and show `-v`
* [man tar](https://linux.die.net/man/1/tar)
* [man losetup](https://man7.org/linux/man-pages/man8/losetup.8.html)
* [man rsync](https://linux.die.net/man/1/rsync)

## Install packages

__Ubuntu server 20.04 LTS__

as __root__ (`sudo -i`):

```bash
apt install nfs-kernel-server dnsmasq tcpdump
```

```bash
cat >>/etc/exports <<DATA
/nfs *(rw,sync,no_subtree_check,no_root_squash)
/tftp *(rw,sync,no_subtree_check,no_root_squash)
DATA
```

To list available SUN RPC services on local computer `rpcinfo`.

Run the services:

* `dnsmasq` provides the DHCP(68), TFTP(69) and DNS(53) services (ports)
* `rpcbind` provides service 2 port mapping for SUN RPC
* `nfs-kernel-server` is the file service (use of NFS v4.2 over TCP is recommended)

```bash
#
systemctl enable dnsmasq
systemctl restart dnsmasq
#
systemctl enable rpcbind
systemctl restart rpcbind
#
systemctl enable nfs-kernel-server
systemctl restart nfs-kernel-server
#
systemctl enable nfs-server
systemctl restart nfs-server
```

* [prepare_pxetools.sh](https://datasheets.raspberrypi.com/soft/prepare_pxetools.sh)
* [pxetools.py](https://datasheets.raspberrypi.org/soft/pxetools.py)

To get serial number `cat /proc/cpuinfo` which is then used in TFTP boot or can be observed in `dnsmasq` logs when enabled as file request path `.../<serial-number>/start4.elf`

`${TFTP_ROOT}/bootcode.bin` is the bootcode downloaded by RPi __U-Boot__ from rom, which in turn loads the rest from `${TFTP_ROOT}/<serial-number>/...`

* [Main download space @ downloads.raspberrypi.org](https://downloads.raspberrypi.org)
* [raspios_lite_arm64/boot.tar.xz](https://downloads.raspberrypi.org/raspios_lite_arm64/boot.tar.xz) - extract to `${TFTP_ROOT}/orig`
* [raspios_lite_arm64/root.tar.xz](https://downloads.raspberrypi.org/raspios_lite_arm64/root.tar.xz) - extract to `${NFS_ROOT}/orig`

### To extract use tar with xattrs and acls

The boot partition of image [2022-04-04-raspios-bullseye-arm64-lite.img.xz](https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2022-04-07/2022-04-04-raspios-bullseye-arm64-lite.img.xz) to expand `unxz *.img.xz` and `kpartx -a *.img` to prepare loopbacks and which then can be mounted via `mount /dev/mapper/loopXpY` where __Y=1__ = `/boot` and __Y=2__ = `/`.

Or use the pre-prepared __tar.xz__ note use GNU tar (BSD does not have all options, also MacOS X)

[raspios_lite_arm64 @ RFP](https://downloads.raspberrypi.org/raspios_lite_arm64)/[boot.tar.cz](https://downloads.raspberrypi.org/raspios_lite_arm64/boot.tar.xz)

```bash
mkdir -p ${TFTP_ROOT}/orig
tar -xvJ --xattrs --acls -f boot.tar.xz --directory=${TFTP_ROOT}/orig
```

[raspios_lite_arm64 @ RFP](https://downloads.raspberrypi.org/raspios_lite_arm64)/[root.tar.cz](https://downloads.raspberrypi.org/raspios_lite_arm64/root.tar.xz)

```bash
mkdir -p ${NFS_ROOT}/orig
tar -xvJ --xattrs --acls -f root.tar.xz --directory=${NFS_ROOT}/orig
```

> Note: __x__ - extract, __v__ - verbose, __J__ - use `unxz`, __directory__ - extract to this directory/folder 

### TFTP bootcode.bin

Then copy `${TFTP_ROOT}/orig/bootcode.bin` to `${TFTP_ROOT}/bootcode.bin` to let the __U-Boot__ to find it.

### TFTP per RPi

The rest of `${TFTP_ROOT}/orig/.` should be copied to per RPi sub-folder like `${TFTP_ROOT}/<serial-number>/`.

Make a copy and __update__ `conf/cmdline.txt.sample` to `${TFTP_ROOT}/<serial-number>/` to __update__:

`nfsroot=100.64.0.1:/nfs/client1` to reflect the roof filesystem path on NFS server.

you might add `quiet` and `splash` and eventually ``

Install splash screen (plymouth) `sudo apt -y install rpd-plym-splash` (ref.`plymouth.ignore_serial_console` see [rpi/issue](https://github.com/raspberrypi/documentation/issues/1234))

* [RPi Chromium dashboard](https://gist.github.com/jordigg/30bf20eaa23f2746d9eb8eebd05fd546)
* [Pi Kiosk](https://reelyactive.github.io/diy/pi-kiosk/)
* [Web dashboard](https://fullstackcode.dev/2020/09/13/turn-your-raspberry-pi-into-web-dashboard/)
* [Another dashboard](https://yyjhao.com/posts/raspberry-pi-web-dashboard/)
* [RPi 4 wall dashboard](https://jonathanmh.com/raspberry-pi-4-kiosk-wall-display-dashboard/)
* [OctoDash](https://github.com/UnchartedBull/OctoDash)
* [Productivity dashboard](https://www.jlwinkler.com/2017-05-25/raspberry-pi-productivity-dashboard/)
* understand [cmdline.txt](https://forum.manjaro.org/t/understanding-cmdline-txt-on-raspberry-pi-4-minimal-fresh-install-vs-xfce/80385)
* [Raspberry Valley](https://raspberry-valley.azurewebsites.net/) - inspiration via [RPi Leds](https://raspberry-valley.azurewebsites.net/Raspberry-Pi-LEDs/)
### NFS root per RPi

The root filesystem should be copied by `11-replicate_nfs.sh` for each client `rsync -av --info=progress2 --xattrs --acls "${SRC_FS}/." "${DST_FS}/"`. Some experiments were done on using __overlayfs__ so far without success.

* [Pi Server](https://www.raspberrypi.com/news/piserver/)
* deprecated [Pi Net](http://pinet.org.uk)
* [LTSP](https://ltsp.org) - linux terminal server project
* Domoticz [OverlayFS](https://www.domoticz.com/wiki/Setting_up_overlayFS_on_Raspberry_Pi)
* [Extended Attrs in NFS](https://www.phoronix.com/scan.php?page=news_item&px=Linux-5.9-NFS-Server-User-Xattr)

## Extra info

__RPF__ = Raspberry Pi foundation

* [Leds on raspi](https://raspberry-valley.azurewebsites.net/Raspberry-Pi-LEDs/#act-green)
* [RPF docs on net boot](https://www.raspberrypi.com/documentation/computers/remote-access.html#network-boot-your-raspberry-pi)

## Other commands

### Configure NAT

```bash
source ~/.config/raspi/netboot/config.inc
iptables -I FORWARD -i ${IF_NAME} \! -o ${IF_NAME} -j ACCEPT
iptables -I FORWARD \! -i ${IF_NAME} -o ${IF_NAME} -j ACCEPT
iptables -t nat -I POSTROUTING -s ${SUBNET} \! -o ${IF_NAME} -j MASQUERADE
```

### Turn off swap

Swap does not make much sense when RPi is netbooted

```bash
# as root "sudo -i"
sync
swapoff -a
apt-get purge -y dphys-swapfile
rm /var/swap
sync
```

### Mount bind

```bash
sudo mount --bind /mnt/nvme/nfs /nfs
```

### Stop rpcbind

To stop all the `rpcbind` service to port mapper (locking, fileserver, ...)

```bash
#
systemctl stop rpcbind
systemctl disable rpcbind
systemctl mask rpcbind
#
systemctl stop rpcbind.socket
systemctl disable rpcbind.socket
#
systemctl status rpcbind
```

## Where are the ips

In general it is recomended to use DNS (as [It's Always DNS](https://teeherivar.com/product/its-always-dns-sysadmin/))

`address=/pi-server/192.168.x.y`

| path                      | IP/DNS | Usage                                               |
|---------------------------|--------|-----------------------------------------------------|
| DHCP server option `66`   | IP/DNS | next-server pointing to `TFTP server`               |
| tftp:`serial`/cmdline.txt | IP/DNS | NFS server IP or name, mount `/` aka root partition |
| rootfs`@`nfs/etc/fstab    | IP/DNS | NFS server IP or name, mount `/boot` partition      |

## DHCP proxy

[DHCP Proxy explainer @ FOG](https://wiki.fogproject.org/wiki/index.php?title=ProxyDHCP_with_dnsmasq#How_ProxyDHCP_works)