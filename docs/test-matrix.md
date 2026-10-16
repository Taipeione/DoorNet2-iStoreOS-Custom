# DoorNet2 V0.1 test matrix

Repository/static checks, pinned-feed resolution, and full image construction have passed. No real-device tests have been run, so image construction is not hardware acceptance and does not authorize flashing. Build-time/static checks are deliberately separate from service runtime and hardware acceptance.

| Area | Required check | Status |
|---|---|---|
| Build | Static V0.1 checks and shell syntax | PASS |
| Build | Pinned feed update/install and `make defconfig` resolves DoorNet2 V0.1 selections | PASS |
| Build | ARM64 Go external bootstrap checksum and Go host toolchain compile | PASS |
| Build | RK3399 Linux target compile | PASS |
| Build | DoorNet2 U-Boot target compile, including SPL/TPL and DTB | PASS |
| Build | Complete DoorNet2 image and metadata (ext4 and squashfs sysupgrade artifacts) | PASS |
| Build | Image SHA256 matches generated `sha256sums` and `profiles.json` metadata | PASS |
| Build | Image target/profile/version: `embedfire,doornet2`, RK3399, DoorNet2 V0.1 | PASS |
| Build | Full-image package installation including dnsmasq-full, Argon, and selected optional services | PASS |
| Build | Latest full build log reviewed: no fatal make error; nonfatal feed/configuration warnings documented | PASS |
| Policy | Isolated built-rootfs UCI test: WeChatDirect merge, mapping preservation, disabled defaults, and repeat idempotence | PASS |
| Policy | Reconciler preserves user LAN value and PassWall/PassWall2 enabled/disabled toggles | PASS |
| Build | Resolved config includes PassWall, PassWall2, SmartDNS, LuCI SmartDNS, AdGuard Home, ChinaDNS-NG | PASS |
| Defaults | PassWall and PassWall2 shipped default configs set `enabled=0` | PASS |
| Defaults | SmartDNS shipped UCI default sets `enabled=0` | PASS |
| Defaults | AdGuard Home package config and init script are present; runtime activation behavior | NOT TESTED |
| Defaults | Built sysupgrade keep files cover network and optional-service UCI/config/data paths | PASS |
| Defaults | Built clean-install configuration sets LAN to `192.168.100.1/24`; no `192.168.50.1` target default | PASS |
| Policy | WeChatDirect additive/idempotent merge and CN-shunt association using the built UCI binary | PASS |
| Boot | Cold boot from MicroSD | NOT TESTED |
| Boot | eMMC boot | NOT TESTED |
| Network | Device applies clean-install LAN and is reachable at `192.168.100.1/24` | NOT TESTED |
| Management | LuCI and SSH | NOT TESTED |
| WAN | DHCP, PPPoE, IPv4, IPv6 | NOT TESTED |
| Services | DHCP, DNS ports `53`, `3053`, `6053`, `15353`, `15355`, firewall with optional services disabled | NOT TESTED |
| Hardware | Both physical Ethernet ports and LED mapping | NOT TESTED |
| Hardware | USB, eMMC, MicroSD, reset key, status/LAN/WAN LEDs | NOT TESTED |
| Lifecycle | PassWall and PassWall2 enable/disable/boot/reboot persistence | NOT TESTED |
| Lifecycle | SmartDNS and AdGuard Home enable/disable/boot/reboot persistence | NOT TESTED |
| DNS | SmartDNS/AdGuard Home dependency, startup, and port behavior | NOT TESTED |
| Routing | WeChatDirect in PassWall and PassWall2 | NOT TESTED |
| Upgrade | OTA configuration retention and idempotent merge on target | NOT TESTED |

No item may be changed to PASS without logs or other reproducible evidence.
