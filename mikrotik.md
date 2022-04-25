# How to use Mikrotik for RPi boot

References:

* [2020/07/11 -PXE Boot Raspberry Pi4 with Mikrotik* DHCP and TFTP server.](https://blog.kroko.ro/2020/07/11/pxe-boot-raspberry-pi4-with-mikrotik-dhcp-and-tftp-server/)
* [DHCP option 43 and 66 @ Cisco](https://community.cisco.com/t5/wireless-mobility-documents/configuring-dhcp-option-43-and-option-60/ta-p/3143572)
* [DHCP option 43 and 66 @ Juniper](https://www.juniper.net/documentation/en_US/junose15.1/topics/concept/dhcp-relay-option-60-strings.html)
* [DHCP option 43, 66,67 @ Nokia](https://infocenter.nokia.com/public/7750SR217R1A/index.jsp?topic=%2Fcom.nokia.Basic_System_Configuration_Guide_21.7.R1%2Fdhcp_server_off-ai9emdyopr.html)
* [DHCP option 43 @ blog](http://blog.schertz.name/2012/05/understanding-dhcp-option-43/)
* [DHCP option 43 @ RPi forums](https://forums.raspberrypi.com/viewtopic.php?t=282316)
* [Ubuntu RPi 4B+](https://xunnanxu.github.io/2020/11/28/PXE-Boot-Diskless-Raspberry-Pi-4-With-Ubuntu-Ubiquiti-and-Synology-1-DHCP-Setup/)

DHCP Options:

| no | Name, usage                                                                                         |
|----|-----------------------------------------------------------------------------------------------------|
| 43 | vendor-specific aka service identification, client __might__ only boot with expected value received |
| 66 | next-server, IP of tftp server or URL for http boot server                                          |
| 67 | boot-file, filename for tftp to boot or URL for boot file                                           |

To get serial number of the RPi when you have it booted by other means:

```bash
cat /sys/firmware/devicetree/base/serial-number|tail -c 9
```

or you can wait for tftp read at the server to check this value.

```
#
# prepare DHCP options
# note: opt.43 for some older firmwares required 3 spaces added to the right
# the string "Raspberry Pi Boot" is 17 chars long
#

/ip dhcp-server option add name=pi-43 code=43 value="s'Raspberry Pi Boot'"

# might be optional, VCI = vendor class identifier (sent by client)

/ip dhcp-server option add name=pxe-client code=60 value="s'PXEClient'"

# address of the next-server (usually tftp server) - must match your settings

/ip dhcp-server option add name=tftp-server code=66 value="s'192.168.x.y'"

# to check the values, the raw value are the actually sent bytes (i.e. without the s'' which denotes string)
/ip dhcp-server option print
 # NAME                                       CODE VALUE                                       RAW-VALUE
 1 pi-43                                        43 s'Raspberry Pi Boot'                        52617370626572727920506920426f6f74
 2 tftp-server                                  66 s'192.168.x.y'                              3139322e3136382e...
 3 pxe-client                                   60 s'PXEClient'                                505845436c69656e74
```

# change ip and mac address with your PI data.

```
/ip dhcp-server lease add address=192.168.x.y dhcp-option=pi-43,pxe-client,tftp-server mac-address=b8:27:eb:xx:yy:zz server=<your-server>
```

# activate tftp (optional)

```
/ip tftp add real-filename=tftp/ req-filename=.*
```
