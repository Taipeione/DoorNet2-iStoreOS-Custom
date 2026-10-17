# DoorNet2 iStoreOS Custom Firmware

Public firmware project for EmbedFire DoorNet2, an RK3399-based device.

## DoorNet2-V0.1 target

- Base: iStoreOS 24.10.8
- Formal firmware identity: `DoorNet2-V0.1` (independent of the base distribution release)
- Clean-install LAN: `192.168.100.1/24`
- Hardware: DoorNet2 RK3399; board-specific DTS and U-Boot only
- Optional services: PassWall, PassWall2, SmartDNS, AdGuard Home, ChinaDNS-NG, and WeChatDirect are included in the pinned build inputs; runtime acceptance remains pending
- OTA: retain user configuration and service enablement state; merge new settings idempotently

## Status

All formal firmware compilation runs on GitHub-hosted Actions; no local Docker or local-machine build is accepted. Previous local Docker images are historical development artifacts only. Cloud attempts have not yet completed artifact verification; consult [`docs/cloud-build-history.md`](docs/cloud-build-history.md) and [`docs/test-matrix.md`](docs/test-matrix.md) for the actual run results. Device boot, plugin process lifecycle, DNS runtime, and OTA restore tests remain NOT TESTED. The build procedure is in [`docs/build.md`](docs/build.md). No formal release exists and no real DoorNet2 hardware test has been performed.

The audit found community DoorNet2 DTS/U-Boot material, but not enough verified information to claim hardware acceptance. Board variants and the exact production partition/boot image layout still require reconciliation. PassWall/PassWall2 and DNS runtime lifecycle tests remain open; the policy package deliberately does not start or stop optional services.

Do not flash eMMC or alter a real device without explicit confirmation. Hardware claims must remain `NOT TESTED` until backed by reproducible real-device evidence.

## Sources

- [EmbedFire DoorNet2 documentation](https://doc.embedfire.com/openwrt/user_manal/zh/latest/User_Manual/board_introduce/dn2_introduce.html)
- [EmbedFire product resource index](https://doc.embedfire.com/products_test/link/zh/latest/linux/ebf_doornet.html)
- [Community DoorNet2 build repository](https://github.com/bluedragon1988/DoorNet2)
- [Community Rockchip/OpenWrt source with DoorNet2 DTS](https://github.com/DHDAXCW/lede-rockchip)
