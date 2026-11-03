# DoorNet2 Custom Firmware

`DoorNet2-V1.0.0` is the current main-line standard-OpenWrt firmware project
for the EmbedFire DoorNet2 (Rockchip RK3399, 1 GB DDR3L). The `DoorNet2-V0.1`
tag is retained as historical build-line evidence. iStore is integrated only
as an application store; the base system is official OpenWrt.

## Safety and status

- Clean-install LAN target: `192.168.100.1/24`.
- Formal builds run only on GitHub-hosted Actions.
- The project never flashes a real device as part of CI or development.
- V1.0.0 Run #4 produced and verified the cloud artifact; no formal Release
  exists yet because hardware acceptance and release approval are pending.
  The first TF attempt was performed, but the board still booted its original
  eMMC system; the failing boot stage is `NOT TESTED`. Network ports, plugin
  lifecycle, DNS routing, WeChatDirect behavior and OTA recovery remain
  `NOT TESTED`.

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
