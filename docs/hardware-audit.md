# DoorNet2 RK3399 board-support audit

Audit started 2026-10-16. This is an evidence record, not a hardware acceptance report.

## Evidence found

| Area | Evidence | Result |
|---|---|---|
| Board | EmbedFire documents RK3399, two Gigabit ports, 8 GB eMMC, MicroSD, two USB 3.0 ports, optional USB Wi-Fi, Flash/Reset keys and LEDs. | Vendor identity confirmed. |
| Linux DTS | `DHDAXCW/lede-rockchip` commit `b9d5e7f19e9b831c2247577f529c0d6a4fc4a169` contains `rk3399-doornet2.dts` and `.dtsi`. | Community source; not yet validated against target iStoreOS kernel. |
| U-Boot | OpenWrt patch `303-rockchip-rk3399-Add-support-for-EmbedFire-DoorNet2.patch` adds the DTB, U-Boot DTS, and `configs/doornet2-rk3399_defconfig`. | Community source; not yet compiled against iStoreOS U-Boot. |
| Boot media | U-Boot maps `mmc0` to `sdmmc`, `mmc1` to `sdhci`, and declares SPL boot order `same-as-spl`, SD, eMMC. The community README documents MicroSD and eMMC workflows. | Boot intent known; production image offsets/layout unverified. |
| Storage | Sources enable 8-bit non-removable eMMC and 4-bit removable MicroSD with card-detect/power GPIOs. | Source-level evidence only. |
| Ethernet | Sources describe the SoC GMAC path and a PCIe Realtek path; one source uses `realtek,r8168`, another models an RTL8211F GMAC PHY. | Mapping/PHY/port labels require confirmation. |
| LEDs/key | Sources map system, LAN, WAN LEDs and reset GPIOs. | Source-level evidence only. |
| iStoreOS | Official repository has an active `istoreos-24.10` line. The V0.1 build is pinned to commit `a405f0378aef729f0f250c94b18a34a09b7d8890` (24.10.8 release line); code search found no DoorNet2 support in the official tree. | Base pin recorded; DoorNet2 integration is in this repository and still requires compile/hardware validation. |

## Open items

1. Public sources describe multiple memory variants, including DDR3/DDR3L and LPDDR4. U-Boot containing several SDRAM definitions does not prove one image covers all revisions.
2. Community DTS revisions differ in PHY modeling and PCIe link parameters; they cannot be merged blindly.
3. No complete production partition table, exact GPT/loader offsets, vendor bootloader provenance, or universal image format has been established.
4. Physical WAN/LAN naming must come from the actual board and boot logs, not LED labels alone.
5. No real-device serial log, target-kernel `dtc` result, boot test, network test, or eMMC/TF test exists yet.

## Decision

Do not claim V0.1 hardware readiness or create a flashable release yet. Next safe step: pin the iStoreOS 24.10.8 source/build revision, import reviewed DoorNet2 patches, and compile/static-check without touching a real device. Partition and bootloader changes remain gated on stronger evidence.

## References

- https://doc.embedfire.com/openwrt/user_manal/zh/latest/User_Manual/board_introduce/dn2_introduce.html
- https://github.com/bluedragon1988/DoorNet2
- https://github.com/DHDAXCW/lede-rockchip/tree/b9d5e7f19e9b831c2247577f529c0d6a4fc4a169
- https://github.com/Boos4721/openwrt/blob/84684c4a071dbb87d3a056e6cd3286fefd63fc47/package/boot/uboot-rockchip/patches/303-rockchip-rk3399-Add-support-for-EmbedFire-DoorNet2.patch
