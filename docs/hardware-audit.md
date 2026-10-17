# DoorNet2 RK3399 board-support audit

This is evidence for source integration, not a hardware acceptance report.
The current line is standard OpenWrt `v25.12.5` (Linux 6.12.94), pinned in
`config/source.env`.

| Area | Evidence | Result |
|---|---|---|
| Board identity | EmbedFire documentation and the supplied reference image identify `embedfire,doornet2`, RK3399, eMMC and MicroSD. | PASS (source evidence) |
| Upstream support | Official OpenWrt `v25.12.5` has Rockchip/RK3399 support but no `embedfire_doornet2` profile or DTS. | PASS (source audit; custom board integration required) |
| Linux board support | Repository DTS is installed through OpenWrt's Rockchip target-files overlay and its Linux 6.12 patch adds `rk3399-doornet2.dtb`. | PASS (static integration check) |
| U-Boot | Repository patch defines `doornet2-rk3399`, DDR3-1866 SDRAM inclusion and `CONFIG_SPL_PAD_TO=0x7f8000`. | PASS (static integration check) |
| RAM variant | Owner confirmed 1 GB DDR3L. The board patch excludes LPDDR4-specific configuration. | PASS (static selection only) |
| Boot layout | OpenWrt Rockchip image flow places loader at sector 64 and expects FIT at sector `0x4000`; image verification checks those offsets. | NOT TESTED in a new cloud artifact / hardware |
| Network mapping | Reference firmware's board script maps LAN `eth1`, WAN `eth0`; the standard-OpenWrt integration uses that mapping. | Source evidence only; physical ports NOT TESTED |
| Reference partitions | Reference image uses a different 32 MiB/96 MiB MBR layout. It is recorded only, not copied to this project. | PASS (non-reuse decision) |

## Known limits

The exact production partition/bootloader compatibility, DDR3L training,
MicroSD/eMMC boot, PHY behavior, Ethernet labels, LEDs, reset key and storage
operation require real-device evidence. A cloud artifact can verify structure
but cannot establish these facts. No image may be described as hardware
accepted, and no release may be made, until the relevant risk is resolved.

The complete read-only forensic record for the user-provided image is in
[`reference-firmware-audit.md`](reference-firmware-audit.md). No binary,
partition table, DTS or bootloader was copied from that image.
