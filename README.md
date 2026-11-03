# DoorNet2 Custom Firmware

`DoorNet2-V1.0.1` is the current main-line standard-OpenWrt firmware project
for the EmbedFire DoorNet2 (Rockchip RK3399, 1 GB DDR3L). The `DoorNet2-V0.1`
tag is retained as historical build-line evidence. iStore is integrated only
as an application store; the base system is official OpenWrt.

## Safety and status

- Clean-install LAN target: `192.168.100.1/24`.
- Formal builds run only on GitHub-hosted Actions.
- The project never flashes a real device as part of CI or development.
- V1.0.0 Run #4 is the last successful cloud artifact. V1.0.1 adds boot-source
  diagnostics and stricter static gates; hardware TF-first boot remains
  `NOT TESTED` until real-device evidence is collected.

Without USB-TTL, use the [LAN-only read-only plan](docs/lan-only-acceptance.md)
to determine whether the currently running system is reachable over SSH. Do
not use SSH to run `sysupgrade` or modify U-Boot/eMMC.

The Run #4 images have passed whole-disk TF-image structure checks. See the
[TF first-boot guide](docs/tf-first-boot.md) before writing a card. Physical TF
boot remains `NOT TESTED`; do not publish a Release based only on the cloud
artifact.

See [docs/source-selection.md](docs/source-selection.md),
[docs/hardware-audit.md](docs/hardware-audit.md), and
[docs/test-matrix.md](docs/test-matrix.md) and the
[TF-first failure audit](docs/tf-first-failure-audit.md). The actual cloud-run record is in
[docs/cloud-build-history.md](docs/cloud-build-history.md).

V1.0.1 build and installation details are in
[docs/V1.0.1-boot-fix-and-test.md](docs/V1.0.1-boot-fix-and-test.md).
