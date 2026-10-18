# DoorNet2-V0.1 test matrix

| Area | Required check | Status |
|---|---|---|
| Repository | New public repository and `main` branch | PASS |
| Base | Fixed official OpenWrt v25.12.5 commit | PASS |
| Base | No iStoreOS base system configured | PASS (source configuration) |
| Board | DoorNet2 RK3399 DTS/U-Boot/BL31 integration | NOT TESTED |
| Image | Full GitHub-hosted OpenWrt build and DoorNet2 artifacts | NOT TESTED |
| Defaults | Clean-install LAN `192.168.100.1/24` | PASS (configuration) |
| iStore | Pinned application feed/package compilation | NOT TESTED |
| Plugins | PassWall, PassWall2, SmartDNS, AdGuard Home, ChinaDNS-NG and Argon packaging | NOT TESTED |
| Lifecycle | Service enable/disable, autostart and reboot persistence | NOT TESTED |
| DNS | Port coexistence, IPv4/IPv6 and disabled-service baseline | NOT TESTED |
| WeChatDirect | Rule behavior on real traffic | NOT TESTED |
| Upgrade | Same-line configuration preservation and idempotent merge | NOT TESTED |
| Hardware | DDR3L training, MicroSD/eMMC boot, Ethernet, LEDs and reset key | NOT TESTED |

Only reproducible cloud logs or physical-device evidence may change a row to
`PASS`.
