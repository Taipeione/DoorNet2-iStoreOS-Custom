# DoorNet2-V0.1 standard-OpenWrt cloud build

Formal compilation is restricted to GitHub-hosted Actions. Local development
may inspect sources and perform static checks, but never produces a release
candidate.

The `DoorNet2-V0.1` workflow and job have the formal name
`DoorNet2-V0.1`; each run is named `DoorNet2-V0.1 #<run number>`. The workflow
checks out the exact DoorNet2 commit and the fixed, signed upstream OpenWrt
`v25.12.5` commit `f0a60eee2fe051741c643ea6118718aae1ef17fb`.

The workflow then:

1. applies the repository's DoorNet2 RK3399 DTS, U-Boot and image-profile
   integration to the standard OpenWrt tree;
2. loads only upstream OpenWrt feeds plus independently pinned iStore, Argon,
   PassWall and PassWall2 application feeds;
3. performs source-pin, board, version, LAN and U-Boot preparation checks;
4. performs one complete cloud build; and
5. verifies ext4/squashfs sysupgrade images, fwtool metadata, MBR/FIT offsets,
   required package manifest, SHA256 and cloud provenance.

The clean-install address is `192.168.100.1/24`, supplied through the standard
OpenWrt preinit/board-config mechanism. Existing configuration is preserved by
normal compatible sysupgrade behavior and the idempotent DoorNet2 policy
package. Direct online configuration migration from iStoreOS to this new
standard-OpenWrt line is explicitly unsupported until tested.

Successful artifact names, BuildInfo, Version, test matrix and checksum files
start with `DoorNet2-V0.1`. A passing cloud build is not hardware acceptance:
boot, DDR3L training, Ethernet mapping, plugin lifecycle, DNS routing,
WeChatDirect behavior and OTA recovery remain `NOT TESTED` until real-device
evidence exists. No workflow writes eMMC or flashes a device.
