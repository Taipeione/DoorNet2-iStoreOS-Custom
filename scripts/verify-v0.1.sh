#!/bin/sh
set -eu

source_dir=${1:-${OPENWRT_SOURCE:-}}
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$repo_root/config/source.env"

[ -n "$source_dir" ] && [ -f "$source_dir/Makefile" ] || {
	printf '%s\n' 'usage: verify-v0.1.sh /path/to/openwrt-source' >&2
	exit 2
}

fail=0
check() {
	if "$@"; then printf 'PASS: %s\n' "$*"; else printf 'FAIL: %s\n' "$*" >&2; fail=1; fi
}
check_not() {
	if "$@"; then printf 'FAIL: not (%s)\n' "$*" >&2; fail=1; else printf 'PASS: not (%s)\n' "$*"; fi
}

check test "$(git -C "$source_dir" rev-parse HEAD)" = "$OPENWRT_COMMIT"
check test -f "$repo_root/board/doorNet2/kernel/rk3399-doornet2.dts"
check test -f "$repo_root/board/doorNet2/kernel/rk3399-doornet2.dtsi"
check test -f "$repo_root/board/doorNet2/kernel/999-add-doornet2-dtb-to-linux-6.12.patch"
check test -f "$repo_root/board/doorNet2/uboot/303-rockchip-rk3399-Add-support-for-EmbedFire-DoorNet2.patch"
check test -f "$repo_root/board/doorNet2/feeds/0001-openwrt-adguardhome-disabled-by-default.patch"
check test -f "$repo_root/package/doornet2-base/Makefile"
check rg -q '^name: DoorNet2-V0\.1$' "$repo_root/.github/workflows/doornet2-v0.1-cloud-build.yml"
check rg -q '^    name: DoorNet2-V0\.1$' "$repo_root/.github/workflows/doornet2-v0.1-cloud-build.yml"
check rg -q '^run-name: "DoorNet2-V0\.1 #\$\{\{ github\.run_number \}\}"$' "$repo_root/.github/workflows/doornet2-v0.1-cloud-build.yml"
check rg -q '^OPENWRT_VERSION=v25\.12\.5$' "$repo_root/config/source.env"
check rg -q '^OPENWRT_COMMIT=f0a60eee2fe051741c643ea6118718aae1ef17fb$' "$repo_root/config/source.env"
check_not rg -q 'ISTOREOS_(REPOSITORY|COMMIT)|istoreos/istoreos' "$repo_root/config" "$repo_root/scripts/build-v0.1.sh" "$repo_root/.github/workflows"
check rg -q 'src-git istore https://github.com/linkease/istore.git\^' "$repo_root/config/feeds.conf"
check_not rg -q 'openwrt-third|jjm2473/(packages|luci)' "$repo_root/config/feeds.conf"
check rg -q 'compatible = "embedfire,doornet2", "rockchip,rk3399"' "$repo_root/board/doorNet2/kernel/rk3399-doornet2.dts"
check rg -q '192\.168\.100\.1' "$repo_root/configs/doorNet2-v0.1.config"
check_not rg -q '192\.168\.50\.1' "$repo_root/configs/doorNet2-v0.1.config"
check rg -q 'CONFIG_VERSION_CODE="DoorNet2-V0\.1"' "$repo_root/configs/doorNet2-v0.1.config"
check rg -q 'CONFIG_PACKAGE_luci-app-store=y' "$repo_root/configs/doorNet2-v0.1.config"
check rg -q 'CONFIG_PACKAGE_luci-compat=y' "$repo_root/configs/doorNet2-v0.1.config"
check rg -q 'CONFIG_PACKAGE_luci-app-passwall=y' "$repo_root/configs/doorNet2-v0.1.config"
check rg -q 'CONFIG_PACKAGE_luci-app-passwall2=y' "$repo_root/configs/doorNet2-v0.1.config"
check rg -q 'CONFIG_PACKAGE_smartdns=y' "$repo_root/configs/doorNet2-v0.1.config"
check rg -q 'CONFIG_PACKAGE_adguardhome=y' "$repo_root/configs/doorNet2-v0.1.config"
check rg -q 'CONFIG_PACKAGE_chinadns-ng=y' "$repo_root/configs/doorNet2-v0.1.config"
check rg -F -q '#include "rk3399-sdram-ddr3-1866.dtsi"' "$repo_root/board/doorNet2/uboot/303-rockchip-rk3399-Add-support-for-EmbedFire-DoorNet2.patch"
check_not rg -F -q 'LPDDR4' "$repo_root/board/doorNet2/uboot/303-rockchip-rk3399-Add-support-for-EmbedFire-DoorNet2.patch"
check rg -F -q 'CONFIG_SPL_PAD_TO=0x7f8000' "$repo_root/board/doorNet2/uboot/303-rockchip-rk3399-Add-support-for-EmbedFire-DoorNet2.patch"
check rg -q 'TARGET_DEVICES \+= embedfire_doornet2' "$source_dir/target/linux/rockchip/image/armv8.mk"
check rg -q 'doornet2-rk3399' "$source_dir/package/boot/uboot-rockchip/Makefile"
check test -f "$source_dir/target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/rk3399-doornet2.dts"
check test -f "$source_dir/target/linux/rockchip/patches-6.12/999-add-doornet2-dtb.patch"
check test -f "$source_dir/package/boot/uboot-rockchip/patches/999-doornet2-rk3399.patch"
check rg -q "DISTRIB_DESCRIPTION='DoorNet2-V0\.1'" "$source_dir/package/base-files/files/etc/openwrt_release"
check rg -F -q '"version": "$(call json_quote,$(VERSION_CODE))",' "$source_dir/include/image-commands.mk"

duplicate_domains=$(awk '/^[[:space:]]*#/ || /^[[:space:]]*$/ { next } { count[$0]++ } END { for (domain in count) if (count[domain] > 1) duplicates++; print duplicates + 0 }' "$repo_root/package/doornet2-base/files/etc/doornet2/wechatdirect.domains")
check test "$duplicate_domains" = 0

[ "$fail" -eq 0 ] || exit 1
printf '%s\n' 'Static standard-OpenWrt V0.1 checks passed; this does not prove hardware behavior.'
