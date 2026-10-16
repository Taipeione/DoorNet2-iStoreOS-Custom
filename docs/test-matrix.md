# DoorNet2 V0.1 test matrix

Repository/static checks and pinned-feed resolution have passed. The complete image build is in progress; no complete image has passed acceptance yet. No real-device tests have been run. Build-time/static checks are deliberately separate from service runtime and hardware acceptance.

| Area | Required check | Status |
|---|---|---|
| Build | Static V0.1 checks and shell syntax | PASS |
| Build | Pinned feed update/install and `make defconfig` resolves DoorNet2 V0.1 selections | PASS |
| Build | ARM64 Go external bootstrap checksum and Go host toolchain compile | PASS |
| Build | RK3399 Linux target compile | PASS |
| Build | DoorNet2 U-Boot target compile, including SPL/TPL and DTB | PASS |
| Build | Complete DoorNet2 image and metadata | NOT TESTED |
| Build | Resolved config includes PassWall, PassWall2, SmartDNS, LuCI SmartDNS, AdGuard Home, ChinaDNS-NG | PASS |
| Defaults | PassWall and PassWall2 upstream defaults are disabled | PASS |
| Defaults | SmartDNS UCI default is disabled | PASS |
| Defaults | OTA keep list covers network and optional-service UCI/config/data paths | PASS |
| Defaults | WeChatDirect additive/idempotent policy logic and CN-shunt association | NOT TESTED |
| Boot | Cold boot from MicroSD | NOT TESTED |
| Boot | eMMC boot | NOT TESTED |
| Network | Clean-install LAN `192.168.100.1/24` | NOT TESTED |
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
