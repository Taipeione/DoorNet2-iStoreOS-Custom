# DoorNet2-V0.1

Status: draft only — no GitHub Release has been published.

This file reserves the exact formal title for the first DoorNet2 release. A formal release remains gated on a successful GitHub-hosted full build, verified cloud artifacts and checksums, and the required hardware/service/OTA acceptance evidence. Compilation alone is not release acceptance.

Planned target: EmbedFire DoorNet2 RK3399, based on pinned iStoreOS 24.10.8. Clean-install LAN: `192.168.100.1/24`.

Planned cloud artifacts must start with `DoorNet2-V0.1-`, including both ext4 and squashfs sysupgrade images, manifest, BuildInfo, and SHA256 file. This draft does not claim those artifacts have been produced or tested.

Not yet accepted: physical boot, eMMC/SD layout, plugin lifecycle, DNS runtime, WeChatDirect routing on-device, and OTA configuration retention on real hardware. These remain NOT TESTED until evidence is recorded in the test matrix.
