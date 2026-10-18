# Standard OpenWrt source selection

DoorNet2-V0.1 uses official OpenWrt `v25.12.5`, commit
`f0a60eee2fe051741c643ea6118718aae1ef17fb`. GitHub's official release record
identifies this as a non-draft, non-prerelease release published on 2026-07-01.
The fixed line uses Linux `6.12.94` and includes the Rockchip `armv8` target.

The build workflow clones `https://github.com/openwrt/openwrt.git`, fetches
that exact commit, and rejects a mismatch. iStoreOS is not checked out,
configured as a feed, or used as an upgrade base.
