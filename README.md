# DoorNet2 iStoreOS Custom Firmware

Public firmware project for EmbedFire DoorNet2, an RK3399-based device.

## V0.1 target

- Base: iStoreOS 24.10.8
- Clean-install LAN: `192.168.100.1/24`
- Hardware: DoorNet2 RK3399; board-specific DTS and U-Boot only
- Optional services: PassWall, PassWall2, SmartDNS, and AdGuard Home, with safe disabled defaults
- OTA: retain user configuration and service enablement state; merge new settings idempotently

## Status

The repository is initialized with the first board integration and source audit. The audit is in [`docs/hardware-audit.md`](docs/hardware-audit.md), the build procedure is in [`docs/build.md`](docs/build.md), and the V0.1 test matrix is in [`docs/test-matrix.md`](docs/test-matrix.md). No release exists and no real DoorNet2 hardware test has been performed.

The audit found community DoorNet2 DTS/U-Boot material, but not enough verified information to claim a complete iStoreOS 24.10.8 image. Board variants and the exact production partition/boot image layout still require reconciliation.

Do not flash eMMC or alter a real device without explicit confirmation. Hardware claims must remain `NOT TESTED` until backed by reproducible real-device evidence.

## Sources

- [EmbedFire DoorNet2 documentation](https://doc.embedfire.com/openwrt/user_manal/zh/latest/User_Manual/board_introduce/dn2_introduce.html)
- [EmbedFire product resource index](https://doc.embedfire.com/products_test/link/zh/latest/linux/ebf_doornet.html)
- [Community DoorNet2 build repository](https://github.com/bluedragon1988/DoorNet2)
- [Community Rockchip/OpenWrt source with DoorNet2 DTS](https://github.com/DHDAXCW/lede-rockchip)
