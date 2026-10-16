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
check test -f "$repo_root/package/doornet2-base/Makefile"
check test -f "$repo_root/package/doornet2-base/files/etc/doornet2/wechatdirect.domains"
check rg -q 'compatible = "embedfire,doornet2", "rockchip,rk3399"' "$repo_root/board/doorNet2/kernel/rk3399-doornet2.dts"
check rg -q '192\.168\.100\.1' "$repo_root/configs/doorNet2-v0.1.config"
check_not rg -q '192\.168\.50\.1' "$repo_root/configs/doorNet2-v0.1.config"
check rg -q '192\.168\.50\.1' "$repo_root/AGENTS.md"
check rg -q 'CONFIG_PACKAGE_doornet2-base=y' "$repo_root/configs/doorNet2-v0.1.config"
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
