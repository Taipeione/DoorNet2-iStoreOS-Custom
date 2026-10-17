# External DoorNet2 reference firmware audit

This is a read-only forensic audit of the user-supplied
`beggar-embedfire_doornet2-squashfs-sysupgrade.img.gz`. It is reference
evidence only; it is not a DoorNet2-V0.1 build or a release input. The source
file was not copied into this repository because its provenance and license
are not independently established.

## File and compression

| Check | Observed result |
|---|---|
| Source SHA256 | `5ebe80bec999aafcdea9da3c528d66068b8a595cc0ec1f180758cf57b994200e` |
| gzip members | One member, not a multi-member gzip |
| gzip member | 162,832,338 bytes compressed; 1,174,405,120 bytes decompressed |
| gzip trailing data | 805 bytes after the member: eight zero bytes followed by a fwtool JSON metadata block and `FWx0`/ucert signature records |
| gzip test | The member decompressed and CRC-checked successfully. GNU gzip returned 2 only because it reported the expected fwtool trailing data as “trailing garbage”. |

The member footer contains the correct little-endian ISIZE for 1,174,405,120
bytes. Tools that read the last four bytes of the whole file instead of the
gzip member footer can therefore report an incorrect original size. The tail
is structured firmware metadata and signing material, not evidence of a
truncated or corrupt gzip stream.

The fwtool JSON identifies:

```text
dist=OpenWrt
version=SNAPSHOT
revision=r4932-aed268398
target=rockchip/armv8
board=embedfire_doornet2
supported_devices=embedfire,doornet2
```

## Raw image and boot chain

The decompressed image is exactly 1,174,405,120 bytes (1120 MiB) and has a
DOS/MBR partition table with signature `55 aa`:

| Entry | Type | Start sector | Sector count | Size | Evidence |
|---|---:|---:|---:|---:|---|
| 1 | `0x83`, bootable | 65,536 (32 MiB) | 65,536 | 32 MiB | Linux ext2/ext4-compatible filesystem, label `kernel` |
| 2 | `0x83` | 196,608 (96 MiB) | 2,097,152 | 1 GiB | SquashFS root filesystem |

The first partition contains `boot.scr` and `kernel.img`. Its boot script
loads `kernel.img` from `mmc ${devnum}:1` and boots it; the kernel command line
uses `root=PARTUUID=${uuid}`. The raw image contains Rockchip loader material
before the partitions and an ARM64 FIT at offset `0x800000` (8 MiB).

Actual strings in the loader/FIT include:

```text
U-Boot TPL 2022.07-OpenWrt-r4932-aed268398
U-Boot SPL 2022.07-OpenWrt-r4932-aed268398
ARM64 OpenWrt FIT (Flattened Image Tree)
ARM64 OpenWrt Linux-6.1.50
ARM64 OpenWrt embedfire_doornet2 device tree blob
rk3399-doornet2.dtb
embedfire,doornet2
rockchip,rk3399
```

The second partition is SquashFS 4.0, little-endian, XZ-compressed, with a
1 MiB block size and 156,797,736 bytes of compressed filesystem data. The
local SquashFS 4.7.5 extractor warned about stored XZ options and stopped on
a duplicate module path during full extraction, but its superblock, directory
listing, targeted file reads, and kernel/rootfs signatures were valid. This is
an extractor compatibility limitation, not a conclusion that the image is
damaged.

## Root filesystem behavior

- The squashfs does not contain `/etc/config/network`; the first-boot
  `config_generate` path creates it.
- Its `02_network` board script maps `embedfire,doornet2` to LAN `eth1` and
  WAN `eth0` and derives MAC addresses from the MMC CID.
- The generic `bin/config_generate` fallback sets a static LAN default of
  `192.168.11.1/255.255.255.0`. This is not adopted by DoorNet2-V0.1, whose
  required clean-install default is `192.168.100.1/24`.
- Package status contains PassWall, PassWall2, SmartDNS, AdGuard Home,
  ChinaDNS-NG, mosdns, and dnsmasq-full. PassWall and PassWall2 default
  configs set `enabled '0'`; SmartDNS, AdGuard Home, and mosdns also ship
  disabled UCI defaults. Boot symlinks and init scripts exist, but this image
  does not contain the DoorNet2-V0.1 WeChatDirect policy package.
- `lib/upgrade/platform.sh` uses the MBR partition map to decide whether to
  write a full image or update partitions and restores the standard
  `/sysupgrade.tgz` backup. This is useful upgrade-flow evidence, but it does
  not prove DoorNet2-V0.1's required idempotent configuration retention.

## Comparison and reuse decision

The reference confirms the board identity, RK3399 boot media, serial console
(`ttyS2` at 1500000 baud), `rk3399-doornet2` DTB naming, and the presence of a
Rockchip TPL/SPL plus FIT boot chain. This matches the board family and the
current DoorNet2-specific DTS/U-Boot integration; it does not prove the
selected 1 GB DDR3L memory capacity or electrical timing by itself.

The reference must not be copied into the current project: it has a different
OpenWrt revision, Linux/U-Boot versions, rootfs layout, boot partition offsets,
LAN default, package set, and upgrade implementation. In particular, the
reference's 32 MiB partition start and 96 MiB rootfs start are recorded for
comparison only. The retired iStoreOS image recipe is not a migration input;
the new standard-OpenWrt image must verify its own layout before any change is
considered. No source DTS, U-Boot patch, binary, or partition-table change was
justified by this audit.

The next safe action is a GitHub-hosted DoorNet2-V0.1 full build and structural
artifact verification. Physical boot, memory training, Ethernet mapping,
plugin lifecycle, DNS behavior, WeChatDirect routing, and OTA restoration
remain `NOT TESTED`.
