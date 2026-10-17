# DoorNet2 Custom Firmware

This public repository builds DoorNet2 RK3399 firmware from **standard
OpenWrt**, not iStoreOS. The formal project version is exactly
`DoorNet2-V0.1`; later versions are `DoorNet2-V0.2`, `DoorNet2-V0.3`, and so
on.

## Permanent rules

- Keep `Taipeione/DoorNet2-iStoreOS-Custom` public on `main`.
- A clean installation must use LAN `192.168.100.1/24`. Upgrades must preserve
  an existing user LAN configuration.
- DoorNet2 is an RK3399 board with 1 GB DDR3L. Never use R76S/RK3576 files or
  claim support for DoorNet2's distinct LPDDR4 variant.
- The fixed base source is the signed OpenWrt `v25.12.5` commit recorded in
  `config/source.env`. iStore is only a separately pinned application feed.
- Retain the DoorNet2 DTS/U-Boot, but do not copy the reference firmware's
  partitions or boot binaries. Hardware-facing changes require evidence.
- PassWall, PassWall2, SmartDNS, AdGuard Home and ChinaDNS-NG default to a
  non-disruptive state. The policy layer must not override service enablement.
- OTA preserves user configuration within the same compatible firmware line.
  Cross-system iStoreOS-to-standard-OpenWrt migration is unsupported until
  explicitly tested.
- Never write a real device's eMMC, partitions, or bootloader without a
  separate user authorization.

## Build and release

All formal firmware compilation runs only on a GitHub-hosted Actions runner.
Local work is limited to source editing, static checks, and cloud artifact/log
inspection. Workflow and job names must both be `DoorNet2-V0.1`; the run name
must be `DoorNet2-V0.1 #${{ github.run_number }}`. Formal artifacts and the
release title use the `DoorNet2-V0.1` prefix exactly.

Before pushing, inspect the diff for secrets and unintended changes, run
applicable YAML/shell/static checks, and update the test matrix honestly.
Cloud compilation is not device acceptance: boot, DDR3L training, Ethernet,
service lifecycle, DNS, WeChatDirect routing and OTA recovery remain
`NOT TESTED` until proven on hardware.
