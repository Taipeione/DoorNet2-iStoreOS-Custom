# DoorNet2 iStoreOS Custom Firmware

This public repository is the DoorNet2 RK3399 firmware project. The project version is `V0.1`; do not use the R76S `R76S-V1.4.6` version scheme.

## Permanent rules

- DoorNet2 is an independent RK3399 target. Never copy R76S RK3576 board files, U-Boot, partitions, boot configuration, or Ethernet mappings.
- A clean install must default to LAN `192.168.100.1/24` (`255.255.255.0`). `192.168.50.1` is forbidden for DoorNet2.
- Configuration-preserving OTA must retain LAN, WAN, PPPoE, IPv4, IPv6, DHCP, DNS, firewall, proxy nodes, subscriptions, rules, custom settings, and service enablement state.
- New configuration must be idempotent and incremental: preserve existing user values and do not duplicate entries on repeated upgrades.
- PassWall and PassWall2 are preinstalled but disabled by default. Their enable/disable state and lifecycle are independent and persistent.
- WeChatDirect is a separate direct-connection rule set supported by both PassWall and PassWall2; do not fold it into ordinary proxy rules.
- DNS must still work when all optional services are disabled. Audit ports `53`, `3053`, `6053`, `15353`, and `15355` for IPv4 and IPv6.
- Never write to a real DoorNet2 eMMC, alter real-device partitions or bootloader, or perform a dangerous flash operation without explicit user confirmation.
- Do not claim hardware acceptance until the feature is tested on real DoorNet2 hardware.

## Build and review

**Permanent build rule:** Every DoorNet2 firmware compilation must run in GitHub Actions on a GitHub-hosted runner. Do not compile firmware on the Mac, local Linux, or local Docker. The repository is intentionally public; do not change its visibility. Use the independent DoorNet2 `V0.1`, `V0.2`, `V0.3` version sequence. The formal build script must refuse execution outside the authorized GitHub-hosted Actions repository context. Local work is limited to development, static checks, GitHub operations, and inspection of cloud logs/artifacts.

Every change must be checked against the target iStoreOS/kernel/U-Boot versions, DTS compilation, image layout, default LAN, platform name, DTB, boot files, and SHA256 metadata. Review `git diff` for secrets, debug residue, and unintended files; commit reliable stages with descriptive messages and push `origin/main`.

Release names, firmware filenames, build metadata, OTA metadata, and documentation must identify the same DoorNet2 version (`V0.1`, then `V0.2`, etc.). If memory variant, PHY, partition map, or bootloader behavior is uncertain, document it and stop the related hardware change instead of guessing.
