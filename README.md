# DoorNet2 Custom Firmware

`DoorNet2-V0.1` is a public standard-OpenWrt firmware project for the
EmbedFire DoorNet2 (Rockchip RK3399, 1 GB DDR3L). iStore is integrated only as
an application store; the base system is official OpenWrt.

## Safety and status

- Clean-install LAN target: `192.168.100.1/24`.
- Formal builds run only on GitHub-hosted Actions.
- The project never flashes a real device as part of CI or development.
- No release exists until a cloud build produces and verifies a DoorNet2
  image. Hardware boot, network ports, plugin lifecycle, DNS routing,
  WeChatDirect behavior and OTA recovery are `NOT TESTED` until tested on the
  physical board.

See [docs/source-selection.md](docs/source-selection.md),
[docs/hardware-audit.md](docs/hardware-audit.md), and
[docs/test-matrix.md](docs/test-matrix.md). The actual cloud-run record is in
[docs/cloud-build-history.md](docs/cloud-build-history.md).
