#!/bin/sh
set -eu

source_dir=${1:-${ISTOREOS_SOURCE:-}}
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if [ -z "$source_dir" ] || [ ! -f "$source_dir/Makefile" ]; then
	printf '%s\n' 'usage: apply-board-support.sh /path/to/istoreos-source' >&2
	exit 2
fi

kernel_dts="$source_dir/target/linux/rockchip/dts/rk3399"
uboot_patches="$source_dir/package/boot/uboot-rockchip/patches"
policy_package="$source_dir/package/doornet2-base"
mkdir -p "$kernel_dts" "$uboot_patches" "$policy_package"
rm -f "$source_dir/target/linux/rockchip/patches-6.6/822-add-rk3399-doornet2-dtb.patch"

install -m 0644 "$repo_root/board/doorNet2/kernel/rk3399-doornet2.dtsi" "$kernel_dts/rk3399-doornet2.dtsi"
install -m 0644 "$repo_root/board/doorNet2/kernel/rk3399-doornet2.dts" "$kernel_dts/rk3399-doornet2.dts"
install -m 0644 "$repo_root/board/doorNet2/uboot/303-rockchip-rk3399-Add-support-for-EmbedFire-DoorNet2.patch" "$uboot_patches/303-rockchip-rk3399-Add-support-for-EmbedFire-DoorNet2.patch"
cp -R "$repo_root/package/doornet2-base/." "$policy_package/"

python3 - "$source_dir" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1])

def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text()
    if new in text:
        return
    if old not in text:
        raise SystemExit(f"anchor not found: {path}: {old!r}")
    path.write_text(text.replace(old, new, 1))

image = source / "target/linux/rockchip/image/armv8.mk"
device = """define Device/embedfire_doornet2
  DEVICE_VENDOR := EmbedFire
  DEVICE_MODEL := DoorNet2
  DEVICE_VARIANT := RK3399
  SOC := rk3399
  UBOOT_DEVICE_NAME := doornet2-rk3399
  DEVICE_DTS_DIR := ../dts
  DEVICE_DTS = rk3399/rk3399-doornet2
  DEVICE_PACKAGES := kmod-r8169
  KERNEL = kernel-bin | lzma | fit lzma $$(KDIR)/image-rk3399-doornet2.dtb
endef
TARGET_DEVICES += embedfire_doornet2

"""
replace_once(image, "define Device/friendlyarm_nanopi-r2c\n", device + "define Device/friendlyarm_nanopi-r2c\n")

release_template = source / "package/base-files/files/etc/openwrt_release"
replace_once(
    release_template,
    "DISTRIB_DESCRIPTION='%D %V %C'\n",
    "DISTRIB_DESCRIPTION='DoorNet2-V0.1'\n",
)

# This package is a default-y choice for RK3528/RK3576 boards, unrelated to
# DoorNet2's RK3399 boot chain. Prevent its generic default from pulling either
# firmware into this target's package set; device-specific selection can still
# explicitly opt in when required by a different board.
rk35xx_uboot = source / "package/boot/uboot-rk35xx/Makefile"
replace_once(
    rk35xx_uboot,
    "define U-Boot/Default\n  BUILD_TARGET:=rockchip\n  UENV:=default\n  HIDDEN:=1\n  BUILD_SUBTARGET:=armv8\n  DEFAULT:=y\n",
    "define U-Boot/Default\n  BUILD_TARGET:=rockchip\n  UENV:=default\n  HIDDEN:=1\n  BUILD_SUBTARGET:=armv8\n  DEFAULT:=n\n",
)

# The pinned uboot-rockchip feed also marks generic RK3568/RK3588 EasePi
# variants default-y. Keep them available for their own devices, but do not
# select them while building this RK3399 DoorNet2 image.
rk_uboot = source / "package/boot/uboot-rockchip/Makefile"
for board in ("easepi-rk3568", "easepi-rk3568-rk809", "easepi-rk3588"):
    old = f"define U-Boot/{board}\n  $(U-Boot/"
    start = rk_uboot.read_text().find(old)
    if start < 0:
        raise SystemExit(f"anchor not found: {rk_uboot}: {board}")
    block_end = rk_uboot.read_text().find("endef\n", start)
    block = rk_uboot.read_text()[start:block_end]
    if "  DEFAULT:=y\n" in block:
        replace_once(rk_uboot, block, block.replace("  DEFAULT:=y\n", "  DEFAULT:=n\n", 1))
    elif "  DEFAULT:=n\n" not in block:
        raise SystemExit(f"default selector missing: {rk_uboot}: {board}")

for relative in (
    "target/linux/rockchip/armv8/base-files/etc/board.d/01_leds",
    "target/linux/rockchip/armv8/base-files/etc/board.d/02_network",
):
    path = source / relative
    text = path.read_text()
    if "embedfire,doornet2|" not in text:
        for anchor in ("embedfire,doornet1|\\\n", "friendlyarm,nanopi-r2c|\\\n"):
            if anchor in text:
                text = text.replace(anchor, anchor + "embedfire,doornet2|\\\n", 1)
                break
        else:
            raise SystemExit(f"board list anchor not found: {path}")
        path.write_text(text)

network = source / "target/linux/rockchip/armv8/base-files/etc/board.d/02_network"
mac_block = """embedfire,doornet2)
        wan_mac=$(generate_mac_from_mmc_cid)
        lan_mac=$(macaddr_add \"$wan_mac\" +1)
        ;;
"""
mac_start = network.read_text()
if "embedfire,doornet2)" not in mac_start:
    marker = 'rockchip_setup_macs()'
    start = mac_start.index(marker)
    case_pos = mac_start.index('case "$board" in', start) + len('case "$board" in\n')
    mac_start = mac_start[:case_pos] + mac_block + mac_start[case_pos:]
    network.write_text(mac_start)

uboot = source / "package/boot/uboot-rockchip/Makefile"
uboot_block = """define U-Boot/doornet2-rk3399
  $(U-Boot/rk3399/Default)
  NAME:=DoorNet2
  BUILD_DEVICES:= \\
    embedfire_doornet2
endef

"""
replace_once(uboot, "define U-Boot/nanopc-t4-rk3399\n", uboot_block + "define U-Boot/nanopc-t4-rk3399\n")
replace_once(uboot, "UBOOT_TARGETS := \\\n", "UBOOT_TARGETS := \\\n  doornet2-rk3399 \\\n")
PY

printf '%s\n' "Applied DoorNet2 board support to $source_dir"
