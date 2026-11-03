# DoorNet2 RK3399 hardware audit

The V1.0.0 Run #4 artifact contains verified whole-disk
`DoorNet2-V1.0.0-ext4.img.gz` and `DoorNet2-V1.0.0-squashfs.img.gz`
images. Both contain the MBR, SPL/idbloader, U-Boot FIT, OpenWrt boot
partition, and root filesystem needed for a TF-card image. They also carry the
normal OpenWrt fwtool trailer after the gzip member; the cloud verifier
validates and strips that trailer in a disposable copy before strict gzip
testing.

The old user-provided `beggar-embedfire_doornet2-squashfs-sysupgrade.img.gz`
is historical evidence only and is not the V1.0.0 TF image. It must not be
mixed with the Run #4 checksums or installation procedure.

The Run #4 image includes the DoorNet2 U-Boot 2025.10 integration with
SPL/TPL, FIT and an `embedfire_doornet2` DTB. This establishes static
RK3399/DDR3L-targeted integration but does not prove BootROM selection,
DDR3L training, eMMC layout, port mapping, or physical compatibility with
OpenWrt 6.12.

The project targets the owner-confirmed 1 GB DDR3L variant. The successful
Run #4 cloud artifact proves source-level integration, image layout and
static boot-chain checks, but not physical boot compatibility. ROM boot order,
DDR3L training, SPL/TPL execution, eMMC interaction, port mapping and current
kernel behavior remain `NOT TESTED` until a real device supplies logs or
screenshots. No eMMC or U-Boot write is part of the TF-first procedure.
