# DoorNet2 V0.1 test matrix

Static repository checks have passed. The kernel target and DoorNet2 U-Boot package have compiled in the Linux builder. The complete image and all real-device/service tests remain pending. No real-device tests have been run. Every hardware or service item is `NOT TESTED` unless a future report adds reproducible evidence.

| Area | Required check | Status |
|---|---|---|
| Build | Static V0.1 checks and shell syntax | PASS |
| Build | RK3399 Linux target compile | PASS |
| Build | DoorNet2 U-Boot target compile, including SPL/TPL and DTB | PASS |
| Build | Complete DoorNet2 image and metadata | NOT TESTED |
| Boot | Cold boot from MicroSD | NOT TESTED |
| Boot | eMMC boot | NOT TESTED |
| Network | Clean-install LAN `192.168.100.1/24` | NOT TESTED |
| Management | LuCI and SSH | NOT TESTED |
| WAN | DHCP, PPPoE, IPv4, IPv6 | NOT TESTED |
| Services | DHCP, DNS, firewall with optional services disabled | NOT TESTED |
| Hardware | Both physical Ethernet ports and LED mapping | NOT TESTED |
| Hardware | USB, eMMC, MicroSD, reset key, status/LAN/WAN LEDs | NOT TESTED |
| Lifecycle | PassWall and PassWall2 enable/disable/reboot persistence | NOT TESTED |
| DNS | SmartDNS and AdGuard Home dependency/port behavior | NOT TESTED |
| Routing | WeChatDirect in PassWall and PassWall2 | NOT TESTED |
| Upgrade | OTA configuration retention and idempotent merge | NOT TESTED |

No item may be changed to PASS without logs or other reproducible evidence.
