# DoorNet2 iStoreOS Custom Firmware

Private firmware project for EmbedFire DoorNet2, an RK3399-based device.

## V0.1 target

- Base: iStoreOS 24.10.8
- Firmware identity: DoorNet2 V0.1 (independent of the base distribution release)
- Clean-install LAN: `192.168.100.1/24`
- Hardware: DoorNet2 RK3399; board-specific DTS and U-Boot only
- Optional services: PassWall, PassWall2, SmartDNS, AdGuard Home, ChinaDNS-NG, and WeChatDirect are included in the pinned build inputs; runtime acceptance remains pending
- OTA: retain user configuration and service enablement state; merge new settings idempotently

## Status

The repository contains the board integration, pinned feed inputs, a reproducible Linux-container build path, and the `doornet2-base` policy package. The RK3399 Linux target and DoorNet2-specific U-Boot variant compile have passed in the Linux builder. The complete image is still being built and has not passed acceptance. The audit is in [`docs/hardware-audit.md`](docs/hardware-audit.md), the build procedure is in [`docs/build.md`](docs/build.md), and the V0.1 test matrix is in [`docs/test-matrix.md`](docs/test-matrix.md). No release exists and no real DoorNet2 hardware test has been performed.

The audit found community DoorNet2 DTS/U-Boot material, but not enough verified information to claim hardware acceptance. Board variants and the exact production partition/boot image layout still require reconciliation. PassWall/PassWall2 and DNS runtime lifecycle tests remain open; the policy package deliberately does not start or stop optional services.

Do not flash eMMC or alter a real device without explicit confirmation. Hardware claims must remain `NOT TESTED` until backed by reproducible real-device evidence.

## Sources

- [EmbedFire DoorNet2 documentation](https://doc.embedfire.com/openwrt/user_manal/zh/latest/User_Manual/board_introduce/dn2_introduce.html)
- [EmbedFire product resource index](https://doc.embedfire.com/products_test/link/zh/latest/linux/ebf_doornet.html)
- [Community DoorNet2 build repository](https://github.com/bluedragon1988/DoorNet2)
- [Community Rockchip/OpenWrt source with DoorNet2 DTS](https://github.com/DHDAXCW/lede-rockchip)
