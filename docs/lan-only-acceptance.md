# DoorNet2 LAN-only read-only acceptance plan

This plan does not require a USB-TTL adapter and does not write the DoorNet2
eMMC, U-Boot, boot partition, or firmware. It is only applicable after the
device is already powered and connected to an isolated LAN. The running
system must be identified before any result is attributed to DoorNet2-V1.0.0.

## 1. LAN and SSH discovery

Do not guess a root password or reset credentials. Use only credentials that
the owner already has for the currently running system.

On a laptop connected directly to a DoorNet2 LAN port, first use a temporary
static address such as `192.168.100.2/24` with no gateway. Then perform only
these read-only probes:

```sh
ping -c 3 -W 1 192.168.100.1
nc -vz -w 3 192.168.100.1 22
nc -vz -w 3 192.168.100.1 80
nc -vz -w 3 192.168.100.1 443
```

If DHCP is expected, inspect the laptop's lease and neighbor table instead of
scanning or changing the router:

```sh
ip addr
ip route
ip neigh
```

If port 22 is reachable and existing credentials are available, use a
non-interactive read-only SSH session. Do not run `reboot` or any command that
changes UCI, packages, boot variables, partitions, or files:

```sh
ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new root@192.168.100.1 \
  'cat /etc/openwrt_release; cat /proc/cmdline; ubus call system board; lsblk -o NAME,SIZE,FSTYPE,PARTUUID,MOUNTPOINTS; blkid; ip -brief address; ip route; ip -6 route; uci -q show network; uci -q show firewall; uci -q show dhcp; if command -v ss >/dev/null 2>&1; then ss -lntup; else netstat -lntup 2>/dev/null || true; fi; /etc/init.d/dropbear enabled; /etc/init.d/uhttpd enabled; true'
```

The SSH probe itself is `NOT TESTED` until the user supplies a live result.
Failure to connect is not evidence that the firmware is unbootable: the
device may have another LAN address, disabled SSH, changed credentials, a
different current OS, or a disconnected port.

## 2. Read-only checks if SSH works

Record the outputs before considering any firmware test:

- `/etc/openwrt_release`, `ubus call system board`, and `/proc/cmdline`;
- current root filesystem, block devices, PARTUUIDs and mountpoints;
- current LAN/WAN interface names, IPv4/IPv6 routes and DHCP state;
- listening services and Dropbear/uhttpd enabled state;
- `uci show network`, `uci show firewall`, and `uci show dhcp` output.

These checks can establish the current system and recovery context. They do
not prove that the Run #4 image boots on the board.

## 3. Prohibited operations in this phase

Do not run any of the following without a separate explicit approval after a
recovery plan is recorded:

- `sysupgrade`, `firstboot`, `jffs2reset`, package installation or removal;
- `fw_setenv`, `fw_printenv -s`, `mtd write`, `flashcp`, `ubiformat`;
- `dd of=...`, `parted`, `fdisk` write mode, or any eMMC/boot-partition write;
- changing `/etc/config`, firewall rules, SSH credentials, or boot scripts;
- `reboot`, power cycling, or removing the current boot medium while the
  current recovery path is unknown.

## 4. Safe removable-TF test design

The only acceptable future boot experiment is a separately prepared removable
TF card using the verified Run #4 `squashfs` image, with the original eMMC and
its boot areas left untouched. Before that experiment, the current boot
medium, partition layout and recovery path must be captured read-only. The TF
card write and the physical boot attempt are not performed by CI and remain
`NOT TESTED`.

If the board does not boot the TF card, stop. Do not compensate by changing
U-Boot, eMMC sectors, or environment variables. Without serial output, the
failure mode cannot be distinguished between BootROM selection, DDR3L
training, U-Boot behavior, power, media, or Ethernet visibility.

## 5. Current evidence status

| Check | Status |
|---|---|
| Run #4 firmware/static boot-chain verification | PASS |
| LAN address of the physical device | NOT TESTED |
| SSH reachability and credentials | NOT TESTED |
| Current OS/U-Boot/boot medium/partitions | NOT TESTED |
| TF-only boot without eMMC modification | NOT TESTED |
| LuCI, iStore, DHCP/WAN, IPv4/IPv6 and DNS on hardware | NOT TESTED |
| Plugin lifecycle, WeChatDirect and OTA on hardware | NOT TESTED |
