# DoorNet2-V0.1

Status: draft only — no GitHub Release has been published.

Planned base: standard OpenWrt `v25.12.5` / commit
`f0a60eee2fe051741c643ea6118718aae1ef17fb`, with independently integrated
iStore `luci-app-store` for arm64. The target is EmbedFire DoorNet2 RK3399,
owner-confirmed 1 GB DDR3L, with clean-install LAN `192.168.100.1/24`.

The future stable release must contain only artifacts created by a passing
GitHub-hosted workflow for this standard-OpenWrt source: `DoorNet2-V0.1-*`
ext4 and squashfs sysupgrade images, SHA256SUMS, BuildInfo, Version, test
matrix and build record. Prior iStoreOS runs and reference-image binaries are
not release inputs.

The following remain NOT TESTED: physical boot, DDR3L training, eMMC/MicroSD
behavior, Ethernet, LuCI/SSH, service lifecycle, DNS/WeChatDirect routing and
same-line OTA recovery. Direct iStoreOS-to-standard-OpenWrt configuration
migration is unsupported. No release may claim these tests passed or instruct
users to write a bootloader/eMMC without separate authorization.
