#!/bin/sh
set -eu

source_dir=${1:-${ISTOREOS_SOURCE:-}}
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if [ -z "$source_dir" ] || [ ! -f "$source_dir/Makefile" ]; then
	printf '%s\n' 'usage: verify-v0.1.sh /path/to/istoreos-source' >&2
	exit 2
fi

fail=0
check() {
	if "$@"; then
		printf 'PASS: %s\n' "$*"
	else
		printf 'FAIL: %s\n' "$*"
		fail=1
	fi
}

check_not() {
	if "$@"; then
		printf 'FAIL: not (%s)\n' "$*"
		fail=1
	else
		printf 'PASS: not (%s)\n' "$*"
	fi
}

check test -f "$repo_root/AGENTS.md"
check test -f "$repo_root/board/doorNet2/kernel/rk3399-doornet2.dts"
check test -f "$repo_root/board/doorNet2/kernel/rk3399-doornet2.dtsi"
check test -f "$repo_root/board/doorNet2/uboot/303-rockchip-rk3399-Add-support-for-EmbedFire-DoorNet2.patch"
check test -f "$repo_root/board/doorNet2/feeds/0001-geoview-go123-compatible.patch"
check test -f "$repo_root/board/doorNet2/feeds/0002-adguardhome-disabled-by-default.patch"
check test -f "$repo_root/package/doornet2-base/Makefile"
check rg -q '^name: DoorNet2-V0\.1$' "$repo_root/.github/workflows/doornet2-v0.1-cloud-build.yml"
check rg -q '^run-name: "DoorNet2-V0\.1 #\$\{\{ github\.run_number \}\}"$' "$repo_root/.github/workflows/doornet2-v0.1-cloud-build.yml"
check test -f "$repo_root/package/doornet2-base/files/etc/doornet2/wechatdirect.domains"
check rg -q "option version 'DoorNet2-V0.1'" "$repo_root/package/doornet2-base/files/etc/config/doornet2"
check rg -q 'compatible = "embedfire,doornet2", "rockchip,rk3399"' "$repo_root/board/doorNet2/kernel/rk3399-doornet2.dts"
check rg -q '192\.168\.100\.1' "$repo_root/configs/doorNet2-v0.1.config"
check rg -q 'CONFIG_VERSION_DIST="DoorNet2"' "$repo_root/configs/doorNet2-v0.1.config"
check rg -q 'CONFIG_VERSION_NUMBER="V0.1"' "$repo_root/configs/doorNet2-v0.1.config"
check rg -q 'CONFIG_VERSION_CODE="DoorNet2-V0.1"' "$repo_root/configs/doorNet2-v0.1.config"
check rg -q 'CONFIG_VERSION_PRODUCT="DoorNet2-V0.1"' "$repo_root/configs/doorNet2-v0.1.config"
check rg -q "DISTRIB_DESCRIPTION='DoorNet2-V0.1'" "$source_dir/package/base-files/files/etc/openwrt_release"
check rg -F -q '"version": "$(call json_quote,$(VERSION_CODE))",' "$source_dir/include/image-commands.mk"
check rg -q 'DEFAULT:=n' "$source_dir/package/boot/uboot-rk35xx/Makefile"
check rg -q 'CONFIG_PACKAGE_luci-app-passwall=y' "$repo_root/configs/doorNet2-v0.1.config"
check rg -q 'CONFIG_PACKAGE_luci-app-passwall2=y' "$repo_root/configs/doorNet2-v0.1.config"
check rg -q 'CONFIG_PACKAGE_smartdns=y' "$repo_root/configs/doorNet2-v0.1.config"
check rg -q 'CONFIG_PACKAGE_luci-app-smartdns=y' "$repo_root/configs/doorNet2-v0.1.config"
check rg -q 'CONFIG_PACKAGE_adguardhome=y' "$repo_root/configs/doorNet2-v0.1.config"
check rg -q 'CONFIG_PACKAGE_chinadns-ng=y' "$repo_root/configs/doorNet2-v0.1.config"
check rg -q 'PKG_VERSION:=0\.1\.10' "$repo_root/board/doorNet2/feeds/0001-geoview-go123-compatible.patch"
check rg -q '9221df928df68030893125a60bdf6d8a1fef2b199fa58ed80772cb3c17225fc5' "$repo_root/board/doorNet2/feeds/0001-geoview-go123-compatible.patch"
check_not rg -q '192\.168\.50\.1' "$repo_root/configs/doorNet2-v0.1.config"
check rg -q '192\.168\.50\.1' "$repo_root/AGENTS.md"
check rg -q 'CONFIG_PACKAGE_doornet2-base=y' "$repo_root/configs/doorNet2-v0.1.config"
check rg -q 'CONFIG_PACKAGE_trusted-firmware-a-rk3399=y' "$repo_root/configs/doorNet2-v0.1.config"
check rg -q 'CONFIG_PACKAGE_u-boot-doornet2-rk3399=y' "$repo_root/configs/doorNet2-v0.1.config"
for unrelated in u-boot-easepi-rk3528 u-boot-easepi-rk3576 u-boot-easepi-rk3568 u-boot-easepi-rk3568-rk809 u-boot-easepi-rk3588; do
	check_not rg -q "CONFIG_PACKAGE_${unrelated}=y" "$repo_root/configs/doorNet2-v0.1.config"
done
check rg -q 'CONFIG_DEFAULT_DEVICE_TREE="rk3399-doornet2"' "$repo_root/board/doorNet2/uboot/303-rockchip-rk3399-Add-support-for-EmbedFire-DoorNet2.patch"
check rg -q 'CONFIG_DEFAULT_FDT_FILE="rk3399-doornet2.dtb"' "$repo_root/board/doorNet2/uboot/303-rockchip-rk3399-Add-support-for-EmbedFire-DoorNet2.patch"
check rg -F -q 'CONFIG_SPL_PAD_TO=0x7f8000' "$repo_root/board/doorNet2/uboot/303-rockchip-rk3399-Add-support-for-EmbedFire-DoorNet2.patch"
check rg -F -q '#include "rk3399-sdram-ddr3-1866.dtsi"' "$repo_root/board/doorNet2/uboot/303-rockchip-rk3399-Add-support-for-EmbedFire-DoorNet2.patch"
check_not rg -F -q 'CONFIG_RAM_RK3399_LPDDR4=y' "$repo_root/board/doorNet2/uboot/303-rockchip-rk3399-Add-support-for-EmbedFire-DoorNet2.patch"
check_not rg -F -q 'rk3399-sdram-lpddr4' "$repo_root/board/doorNet2/uboot/303-rockchip-rk3399-Add-support-for-EmbedFire-DoorNet2.patch"
check rg -q '# CONFIG_OF_UPSTREAM is not set' "$repo_root/board/doorNet2/uboot/303-rockchip-rk3399-Add-support-for-EmbedFire-DoorNet2.patch"
check rg -q 'TARGET_DEVICES \+= embedfire_doornet2' "$source_dir/target/linux/rockchip/image/armv8.mk"
check rg -q 'doornet2-rk3399' "$source_dir/package/boot/uboot-rockchip/Makefile"
check_not test -e "$source_dir/target/linux/rockchip/patches-6.6/822-add-rk3399-doornet2-dtb.patch"

duplicate_domains=$(awk '
  /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
  { count[$0]++ }
  END { for (domain in count) if (count[domain] > 1) duplicates++ ; print duplicates + 0 }
' "$repo_root/package/doornet2-base/files/etc/doornet2/wechatdirect.domains")
check test "$duplicate_domains" = 0

if [ "$fail" -ne 0 ]; then
	exit 1
fi
printf '%s\n' 'Static V0.1 checks passed; this does not prove hardware behavior.'
