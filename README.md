# DoorNet2 Custom Firmware

`DoorNet2-V0.1` is a public, standard-OpenWrt firmware project for the
EmbedFire DoorNet2 (RK3399, owner-confirmed 1 GB DDR3L model).

## Build baseline

- Base system: signed upstream [OpenWrt v25.12.5](https://github.com/openwrt/openwrt/releases/tag/v25.12.5), pinned to `f0a60eee2fe051741c643ea6118718aae1ef17fb`
- Board support: DoorNet2 DTS, U-Boot integration and Rockchip image profile in this repository
- Application feed: independent [iStore](https://github.com/linkease/istore) `luci-app-store`, not iStoreOS
- Clean-install LAN: `192.168.100.1/24`
- Images: ext4 and squashfs sysupgrade disk images, with Rockchip loader/FIT structural checks

The GitHub workflow is named `DoorNet2-V0.1`, runs on GitHub-hosted runners,
and records the DoorNet2 and OpenWrt commits. No local compilation is accepted
as a release input.

## Current status

The repository has been migrated away from the iStoreOS base-system route.
The next result must be a new standard-OpenWrt cloud build; prior iStoreOS
cloud runs and local artifacts are historical audit evidence only. The
reference firmware was inspected read-only and is not copied or released.

PassWall, PassWall2, SmartDNS, AdGuard Home, ChinaDNS-NG, iStore, Argon and
WeChatDirect are configured as build inputs. Their real-device lifecycle,
DNS behavior, routing, OTA recovery, boot, Ethernet mapping, and DDR3L
training are **NOT TESTED**. A successful compile alone never authorizes
flashing or a release.

See [the build guide](docs/build.md), [hardware audit](docs/hardware-audit.md),
[reference-image audit](docs/reference-firmware-audit.md), and [test matrix](docs/test-matrix.md).
