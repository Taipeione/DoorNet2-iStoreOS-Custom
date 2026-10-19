# DoorNet2 RK3399 hardware audit

The user-provided `beggar-embedfire_doornet2-squashfs-sysupgrade.img.gz` is
available for read-only analysis. It is a gzip stream with appended structured
trailer data; `gzip -t` reports trailing data, so that message is not treated
as proof of corruption. It must never be renamed, flashed, copied into a
release, or used to overwrite DoorNet2 boot components.

Available evidence identifies an EmbedFire DoorNet2/RK3399 boot chain with
U-Boot 2022.07, SPL/TPL, FIT and an `embedfire_doornet2` DTB. This establishes
the board family but does not prove DDR3L timings, eMMC layout, port mapping,
or compatibility with an OpenWrt 6.12 build.

The project targets the owner-confirmed 1 GB DDR3L variant. Board DTS,
U-Boot/BL31 integration, SPL/TPL offsets and image layout must be introduced
only after their source and current-kernel compatibility are checked. Until a
cloud artifact and hardware test exist, all boot-compatibility claims are
`NOT TESTED`.
