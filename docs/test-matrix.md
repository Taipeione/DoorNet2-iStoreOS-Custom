# DoorNet2 test matrix

| Area | Required check | Status |
|---|---|---|
| Repository | New public repository and `main` branch | PASS |
| Base | Fixed official OpenWrt v25.12.5 commit | PASS |
| Base | No iStoreOS base system configured | PASS (source configuration) |
| Board | DoorNet2 RK3399 DTS/U-Boot/BL31 integration | NOT TESTED |
| Image | Full GitHub-hosted OpenWrt build and DoorNet2 artifacts | PASS — V1.0.0 Run #4; hardware boot remains NOT TESTED |
| TF image | Whole-disk partition/SPL/FIT/rootfs/TF-first structure for independent TF boot | PASS — Run #4 ext4 and squashfs; physical boot NOT TESTED |
| Defaults | Clean-install LAN `192.168.100.1/24` | PASS (configuration) |
| LAN/SSH | Read-only discovery of current device system over existing LAN | NOT TESTED — no device connection evidence |
| iStore | Pinned application feed/package compilation | CLOUD BUILD PASS; runtime NOT TESTED |
| Configuration | Required package roots and complete selected-package dependency closure after final Kconfig normalization | PASS — V1.0.0 Run #4 |
| Plugins | PassWall, PassWall2, SmartDNS, AdGuard Home, ChinaDNS-NG and Argon packaging | CLOUD BUILD PASS; runtime NOT TESTED |
| Lifecycle | Service enable/disable, autostart and reboot persistence | NOT TESTED |
| DNS | Port coexistence, IPv4/IPv6 and disabled-service baseline | NOT TESTED |
| WeChatDirect | Rule behavior on real traffic | NOT TESTED |
| Upgrade | Same-line configuration preservation and idempotent merge | NOT TESTED |
| Hardware | DDR3L training, MicroSD/eMMC boot, Ethernet, LEDs and reset key | NOT TESTED |

Only reproducible cloud logs or physical-device evidence may change a row to
`PASS`.
