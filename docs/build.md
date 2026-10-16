# Reproducible V0.1 build

V0.1 is based on the iStoreOS 24.10.8 release line at commit `a405f0378aef729f0f250c94b18a34a09b7d8890`, using Linux 6.6.144. The source pin is recorded in [`config/source.env`](../config/source.env).

On macOS, [`scripts/build-v0.1.sh`](../scripts/build-v0.1.sh) runs the build inside Docker and copies the source into a Linux case-sensitive named volume. This is required by OpenWrt/iStoreOS and avoids compiling in the macOS native filesystem.

After a successful full build, the script copies `bin/targets/rockchip/armv8` artifacts from the build volume to `work/build-output` by default. Set `BUILD_OUTPUT_DIR` to choose another output directory.

The local builder image is used only as a Linux build environment. No R76S board files, DTS, U-Boot configuration, partition layout, or network mapping are used by DoorNet2.

The build script applies the reviewed board files, adds the DoorNet2 image/device definition, adds the U-Boot patch, installs the `doornet2-base` policy package and required pinned-feed packages (including Argon), sets the clean-install LAN to `192.168.100.1/24`, runs static checks, then compiles the kernel, DoorNet2 U-Boot, and full image. It explicitly excludes the mutually conflicting default `dnsmasq` package in favor of `dnsmasq-full`, selected by PassWall2. The DoorNet2 U-Boot target is built through its native `arch/arm/dts` path because the board DTS has not yet been independently verified as an upstream U-Boot DTS.

`doornet2-base` is intentionally conservative: its UCI defaults are additive, its upgrade keep list preserves network and service configuration, and its policy init script never starts or stops optional proxy/DNS services. When a PassWall or PassWall2 config is present, it adds the missing `WeChatDirect` shunt entry and only the missing domains/link; repeated reconciliation is idempotent. PassWall/PassWall2, SmartDNS, and AdGuard Home must only be enabled after their exact iStoreOS feed revisions are pinned and their lifecycle is tested.

The build uses the pinned feed revisions in [`config/feeds.conf`](../config/feeds.conf), including the iStoreOS feeds and the PassWall/PassWall2 source feeds. Package sources are fetched inside the Linux build environment; the macOS feed-index attempt is not used because OpenWrt host tools and a case-sensitive filesystem are required. U-Boot is compiled only with `BUILD_VARIANT=doornet2-rk3399`, not the unrelated Rockchip variants. Full ext4 and squashfs sysupgrade images now build and their generated hashes/profile metadata verify; boot, partition compatibility, service lifecycle, OTA restore, and hardware acceptance remain open.

On an ARM64 Linux builder, the pinned Go feed cannot build its default Go 1.4 bootstrap. The build script therefore downloads the [official Go 1.20.14 Linux ARM64 archive](https://go.dev/dl/) as the external bootstrap and verifies SHA-256 `2096507509a98782850d1f0669786c09727053e9fe3c92b03c0d96f48700282b` before use. The Go toolchain still gets built from the feed's pinned Go source for the firmware build.

The pinned PassWall packages currently request geoview 0.2.6 (Go 1.25), newer than the pinned iStoreOS Go 1.23.12 source. The build applies [`0001-geoview-go123-compatible.patch`](../board/doorNet2/feeds/0001-geoview-go123-compatible.patch), pinning only geoview to 0.1.10 (Go 1.21) with a fixed source-archive hash. This keeps the PassWall2 geoview dependency enabled while retaining the rest of the pinned feeds.
