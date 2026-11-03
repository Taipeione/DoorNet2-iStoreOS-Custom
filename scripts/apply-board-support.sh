#!/bin/sh
set -eu

source_dir=${1:-${OPENWRT_SOURCE:-}}
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
version_code=${DOORNET2_VERSION_CODE:-DoorNet2-V1.0.0}

if [ -z "$source_dir" ] || [ ! -f "$source_dir/Makefile" ]; then
	printf '%s\n' 'usage: apply-board-support.sh /path/to/pinned/openwrt-source' >&2
	exit 2
fi

# The kernel DTS files are copied through OpenWrt's documented target files
# overlay. The accompanying 6.12 patch adds the DTB to the upstream makefile.
kernel_files="$source_dir/target/linux/rockchip/files/arch/arm64/boot/dts/rockchip"
kernel_patches="$source_dir/target/linux/rockchip/patches-6.12"
uboot_patches="$source_dir/package/boot/uboot-rockchip/patches"
policy_package="$source_dir/package/doornet2-base"
mkdir -p "$kernel_files" "$kernel_patches" "$uboot_patches" "$policy_package"
install -m 0644 "$repo_root/patches/kernel/rk3399-doornet2.dts" "$kernel_files/rk3399-doornet2.dts"
install -m 0644 "$repo_root/patches/kernel/rk3399-doornet2.dtsi" "$kernel_files/rk3399-doornet2.dtsi"
install -m 0644 "$repo_root/patches/kernel/999-add-doornet2-dtb.patch" "$kernel_patches/999-add-doornet2-dtb.patch"
install -m 0644 "$repo_root/patches/uboot/998-doornet2-tf-first.patch" "$uboot_patches/998-doornet2-tf-first.patch"
install -m 0644 "$repo_root/patches/uboot/999-doornet2-rk3399.patch" "$uboot_patches/999-doornet2-rk3399.patch"
install -m 0755 "$repo_root/scripts/doornet2-set-mbr-signature.py" "$source_dir/scripts/doornet2-set-mbr-signature.py"
cp -R "$repo_root/package/doornet2-base/." "$policy_package/"
sed -i "s/DoorNet2-VERSION/$version_code/g" "$policy_package/files/90-doornet2-policy"

DOORNET2_VERSION_CODE="$version_code" python3 - "$source_dir" <<'PY'
from pathlib import Path
import os
import sys

source = Path(sys.argv[1])
version_code = os.environ["DOORNET2_VERSION_CODE"]

def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text()
    if new in text:
        return
    if old not in text:
        raise SystemExit(f"anchor not found: {path}: {old!r}")
    path.write_text(text.replace(old, new, 1))

image = source / "target/linux/rockchip/image/armv8.mk"
device = """define Device/embedfire_doornet2
  $(Device/rk3399)
  DEVICE_VENDOR := EmbedFire
  DEVICE_MODEL := DoorNet2
  DEVICE_VARIANT := RK3399 1GB DDR3L
  DEVICE_DTS := rk3399-doornet2
  UBOOT_DEVICE_NAME := doornet2-rk3399
  DEVICE_PACKAGES := kmod-r8169
  SUPPORTED_DEVICES := embedfire,doornet2
endef
TARGET_DEVICES += embedfire_doornet2

"""
replace_once(image, "define Device/friendlyarm_nanopc-t4\n", device + "define Device/friendlyarm_nanopc-t4\n")

release_template = source / "package/base-files/files/etc/openwrt_release"
replace_once(release_template, "DISTRIB_DESCRIPTION='%D %V %C'\n", f"DISTRIB_DESCRIPTION='{version_code}'\n")

image_commands = source / "include/image-commands.mk"
replace_once(image_commands, '"version": "$(call json_quote,$(VERSION_NUMBER))",', '"version": "$(call json_quote,$(VERSION_CODE))",')

network = source / "target/linux/rockchip/armv8/base-files/etc/board.d/02_network"
text = network.read_text()
if "embedfire,doornet2|\\\n" not in text:
    anchor = "friendlyarm,nanopi-r2c|\\\n"
    if anchor not in text:
        raise SystemExit(f"network board-list anchor not found: {network}")
    network.write_text(text.replace(anchor, "embedfire,doornet2|\\\n" + anchor, 1))

leds = source / "target/linux/rockchip/armv8/base-files/etc/board.d/01_leds"
text = leds.read_text()
if "embedfire,doornet2|\\\n" not in text:
    anchor = "friendlyarm,nanopi-r2c|\\\n"
    if anchor not in text:
        raise SystemExit(f"LED board-list anchor not found: {leds}")
    leds.write_text(text.replace(anchor, "embedfire,doornet2|\\\n" + anchor, 1))

image_makefile = source / "target/linux/rockchip/image/Makefile"
replace_once(
    image_makefile,
    '\tdd if="$(STAGING_DIR_IMAGE)"/$(UBOOT_DEVICE_NAME)-u-boot-rockchip.bin of="$@" seek=64 conv=notrunc\n',
    '\tpython3 "$(TOPDIR)/scripts/doornet2-set-mbr-signature.py" "$@" --signature 0xD0021000\n'
    '\tdd if="$(STAGING_DIR_IMAGE)"/$(UBOOT_DEVICE_NAME)-u-boot-rockchip.bin of="$@" seek=64 conv=notrunc\n',
)

bootscript = source / "target/linux/rockchip/image/default.bootscript"
replace_once(
    bootscript,
    "part uuid ${devtype} ${devnum}:2 uuid\n",
    "part uuid ${devtype} ${devnum}:2 uuid\n"
    "echo \"DoorNet2: boot source ${devtype} ${devnum}, root PARTUUID=${uuid}\"\n",
)

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

printf '%s\n' "Applied standard-OpenWrt DoorNet2 RK3399 support to $source_dir"
