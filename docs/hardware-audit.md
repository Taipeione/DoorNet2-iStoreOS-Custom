# DoorNet2 RK3399 board-support audit

Audit started 2026-10-16. This is an evidence record, not a hardware acceptance report.

## Evidence found

| Area | Evidence | Result |
|---|---|---|
| Board | EmbedFire documents RK3399, two Gigabit ports, 8 GB eMMC, MicroSD, two USB 3.0 ports, optional USB Wi-Fi, Flash/Reset keys and LEDs. | Vendor identity confirmed. |
| Linux DTS | DoorNet2 RK3399 DTS and SoC includes are integrated into the pinned iStoreOS Linux 6.6.144 source. | NOT TESTED in the current GitHub Actions builds; compile/runtime evidence remains open. |
| U-Boot | DoorNet2 U-Boot package integration is present for the pinned iStoreOS U-Boot 2024.10 source. | NOT TESTED in the current GitHub Actions builds; boot behavior and SDRAM variant selection remain untested. |
| Owner's RAM variant | The owner confirmed the target device is the 1 GB DDR3L DoorNet2. Vendor selection material also lists a separate 4 GB LPDDR4 variant. | The former U-Boot patch requested an LPDDR4-specific option and included multiple SDRAM parameter sets, so it cannot be accepted as proven compatible with this target. The pending correction selects only RK3399 DDR3 SDRAM data; electrical/timing suitability still requires real-device boot evidence. |
| RK3399 loader layout | Upstream U-Boot 2024.10 RK3399 EVB sets `CONFIG_SPL_PAD_TO=0x7f8000`. The former DoorNet2 defconfig omitted it; a historical local image had no U-Boot FIT magic at sector `0x4000`. | A cloud image must now contain a nonempty loader at sector 64 and FIT magic at sector `0x4000`, or artifact verification fails. This checks structure, not boot success. |
| Firmware | Full ext4 and squashfs sysupgrade image generation is configured for profile `embedfire_doornet2`. | NOT TESTED in an accepted cloud run; no cloud artifact has passed verification. |
| Boot media | U-Boot maps `mmc0` to `sdmmc`, `mmc1` to `sdhci`, and declares SPL boot order `same-as-spl`, SD, eMMC. The community README documents MicroSD and eMMC workflows. | Boot intent known; production image offsets/layout unverified. |
| Storage | Sources enable 8-bit non-removable eMMC and 4-bit removable MicroSD with card-detect/power GPIOs. | Source-level evidence only. |
| Ethernet | Sources describe the SoC GMAC path and a PCIe Realtek path; one source uses `realtek,r8168`, another models an RTL8211F GMAC PHY. | Mapping/PHY/port labels require confirmation. |
| LEDs/key | Sources map system, LAN, WAN LEDs and reset GPIOs. | Source-level evidence only. |
| iStoreOS | Official repository has an active `istoreos-24.10` line. `DoorNet2-V0.1` is pinned to commit `a405f0378aef729f0f250c94b18a34a09b7d8890` (24.10.8 release line); code search found no DoorNet2 support in the official tree. | Base pin recorded; DoorNet2 integration is in this repository. Full cloud image construction has not passed. |

## Open items

1. The intended hardware is specifically 1 GB DDR3L. The firmware must not be described as suitable for the separate LPDDR4 variant. DDR3 training timings and real boot remain unverified.
2. Community DTS revisions differ in PHY modeling and PCIe link parameters; they cannot be merged blindly.
3. The generic Rockchip image recipe uses an MBR and fixed loader positions; vendor stock-image compatibility and production partition details remain unverified. Image structural checks cannot substitute for a boot test.
4. Physical WAN/LAN naming must come from the actual board and boot logs, not LED labels alone.
5. No real-device serial log, target-kernel `dtc` result, boot test, network test, or eMMC/TF test exists yet.

## Decision

Do not claim `DoorNet2-V0.1` readiness or create a formal release yet. Earlier in-flight cloud runs use an ambiguous U-Boot memory configuration and lack the new loader-layout gate; the corrected DDR3L/SPL layout has not passed a full cloud build or real boot test. Even a successful structural image check is not real-device acceptance. Partition and bootloader behavior, physical-device startup, service lifecycles, and OTA retention remain open. Do not write the image to eMMC or alter partitions without separate user confirmation.

## References

- https://doc.embedfire.com/openwrt/user_manal/zh/latest/User_Manual/board_introduce/dn2_introduce.html
- https://github.com/bluedragon1988/DoorNet2
- https://github.com/DHDAXCW/lede-rockchip/tree/b9d5e7f19e9b831c2247577f529c0d6a4fc4a169
- https://github.com/Boos4721/openwrt/blob/84684c4a071dbb87d3a056e6cd3286fefd63fc47/package/boot/uboot-rockchip/patches/303-rockchip-rk3399-Add-support-for-EmbedFire-DoorNet2.patch
