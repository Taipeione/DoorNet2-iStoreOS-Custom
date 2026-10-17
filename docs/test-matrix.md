# DoorNet2-V0.1 test matrix

This matrix distinguishes source checks from cloud compilation and hardware acceptance. The ext4/squashfs images previously found in ignored `work/build-output` were built locally with Docker. They are historical artifacts, not GitHub Actions results, and do not satisfy the permanent cloud-build requirement. Until a matching Actions run and artifact are verified, cloud build rows remain NOT TESTED. No real-device tests have been run.

| Area | Required check | Status |
|---|---|---|
| Build | Static V0.1 checks and shell syntax | PASS |
| Build | GitHub-hosted runner checked out and recorded exact DoorNet2 repository commit | PASS (run 38993536280) |
| Build | Cloud static Precheck | FAIL (run 38993536280: runner lacked `ripgrep`; fixed in follow-up commit; compilation not reached) |
| Build | Full cloud compile after naming corrections | FAIL (run 38994612587 re-enabled RK3528 U-Boot; run 38995074665 exposed RK3568 defaults; run 38995399526 reached Linux compile but lacked host `m4`; targeted U-Boot default opt-outs and explicit `tools/install` are committed for retest) |
| Build | Pinned feeds update and each checked-out HEAD matches the configured 40-character revision | PASS (run 38994050512) |
| Build | Final `make defconfig` is in sync after DoorNet2 package exclusions | FAIL (run 38994050512 warned configuration was out of sync; second defconfig and resolved-option assertions added) |
| Build | RK3399 Linux target compile in GitHub Actions | FAIL (run 38994050512: target step exited with `.config` out-of-sync warning; no image produced) |
| Build | DoorNet2 U-Boot target compile, including SPL/TPL and DTB, in GitHub Actions | NOT TESTED |
| Build | Complete cloud DoorNet2 image and metadata (ext4 and squashfs sysupgrade artifacts) | NOT TESTED |
| Build | Cloud image SHA256 matches generated `sha256sums` and `profiles.json` metadata | NOT TESTED |
| Build | Cloud image target/profile/version: `embedfire,doornet2`, RK3399, `DoorNet2-V0.1` | NOT TESTED |
| Version | Firmware `/etc/openwrt_release` display, OTA UCI version metadata, artifact/BuildInfo/checksum prefixes all exactly `DoorNet2-V0.1` | NOT TESTED (naming changes await successful cloud artifact verification) |
| Build | Cloud full-image package installation including dnsmasq-full, Argon, and selected optional services | NOT TESTED |
| Build | Cloud build logs reviewed; failures and warnings classified and retained | PASS (runs 38993536280, 38993725481, 38994050512) |
| Policy | Cloud built-rootfs UCI test: WeChatDirect merge, mapping preservation, disabled defaults, and repeat idempotence | NOT TESTED |
| Policy | Cloud reconciler test preserves user LAN value and PassWall/PassWall2 toggles | NOT TESTED |
| Historical | Previous local Docker image build and policy test (not a cloud result; excluded from acceptance) | PASS (LOCAL ONLY) |
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
