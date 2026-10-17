# DoorNet2-V0.1 test matrix

The standard-OpenWrt migration supersedes iStoreOS build results. Historical
iStoreOS failures and artifacts remain in the audit record but are not release
evidence for this line. No real device has been written or flashed.

| Area | Required check | Status |
|---|---|---|
| Base | Fixed signed OpenWrt v25.12.5 commit `f0a60eee…` selected | PASS |
| Base | Old iStoreOS source, feeds and formal workflow entry removed | PASS (static migration audit) |
| Board | Official OpenWrt has no `embedfire_doornet2` profile; repository integration is required | PASS (source audit) |
| Board | DoorNet2 RK3399 DTS overlay and Linux 6.12 DTB Makefile patch apply to fixed source | PASS (static source check) |
| Board | 1 GB DDR3L U-Boot configuration includes DDR3 and excludes LPDDR4 | PASS (static source check) |
| Image | Standard-OpenWrt DoorNet2 profile builds a complete cloud image | NOT TESTED |
| Image | ext4 and squashfs sysupgrade artifacts, fwtool metadata, MBR/FIT offsets and SHA256 | NOT TESTED |
| Defaults | Clean-install LAN `192.168.100.1/24`; no R76S address | PASS (configuration/static source check) |
| iStore | Pinned independent iStore `luci-app-store` feed and `luci-compat` selected | PASS (source audit) |
| iStore | iStore loads and resolves application dependencies on the target | NOT TESTED |
| Plugins | PassWall, PassWall2, SmartDNS, AdGuard Home, ChinaDNS-NG and Argon selected | PASS (configuration check) |
| Policy | WeChatDirect additive merge and service-enable preservation in built rootfs | NOT TESTED |
| Lifecycle | Plugin enable/disable, autostart and reboot persistence on hardware | NOT TESTED |
| DNS | Disabled-service baseline and all DNS port interactions on hardware | NOT TESTED |
| Boot | MicroSD/eMMC boot, DDR3L training, Ethernet mapping, LEDs and reset key | NOT TESTED |
| Management | LAN reachability, LuCI, SSH, DHCP, PPPoE, IPv4 and IPv6 | NOT TESTED |
| Upgrade | Same-line OTA retention/idempotent merge on hardware | NOT TESTED |
| Upgrade | iStoreOS-to-standard-OpenWrt configuration-preserving OTA | NOT SUPPORTED / NOT TESTED |

Only reproducible logs or real-device evidence may change a row to `PASS`.
