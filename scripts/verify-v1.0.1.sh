#!/bin/sh
set -eu

source_dir=${1:-}
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$repo_root/config/source.env"

[ -n "$source_dir" ] && [ -f "$source_dir/Makefile" ] || {
	echo 'OpenWrt source path required' >&2
	exit 2
}
fail=0
check() { if "$@"; then echo "PASS: $*"; else echo "FAIL: $*" >&2; fail=1; fi; }
check_not() { if "$@"; then echo "FAIL: not ($*)" >&2; fail=1; else echo "PASS: not ($*)"; fi; }

check test "$(git -C "$source_dir" rev-parse HEAD)" = "$OPENWRT_COMMIT"
check test -f "$repo_root/configs/doornet2-v1.0.1.config"
check rg -q '^name: DoorNet2-V1\.0\.1$' "$repo_root/.github/workflows/doornet2-v1.0.1.yml"
check rg -q '^run-name: "DoorNet2-V1\.0\.1 #\$\{\{ github\.run_number \}\}"$' "$repo_root/.github/workflows/doornet2-v1.0.1.yml"
check rg -q '^    name: DoorNet2-V1\.0\.1$' "$repo_root/.github/workflows/doornet2-v1.0.1.yml"
check_not rg -q 'istoreos/istoreos|ISTOREOS_' "$repo_root/config" "$repo_root/scripts/build-v1.0.1.sh" "$repo_root/.github"
check rg -q '192\.168\.100\.1' "$repo_root/configs/doornet2-v1.0.1.config"
check_not rg -q '192\.168\.50\.1' "$repo_root/configs/doornet2-v1.0.1.config"
check rg -q 'CONFIG_VERSION_CODE="DoorNet2-V1\.0\.1"' "$repo_root/configs/doornet2-v1.0.1.config"
check git apply --numstat "$repo_root/patches/uboot/998-doornet2-tf-first.patch"
check git apply --numstat "$repo_root/patches/uboot/999-doornet2-rk3399.patch"
check test -f "$source_dir/target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/rk3399-doornet2.dts"
check test -f "$source_dir/package/boot/uboot-rockchip/patches/998-doornet2-tf-first.patch"
check test -f "$source_dir/package/boot/uboot-rockchip/patches/999-doornet2-rk3399.patch"
check test -x "$source_dir/scripts/doornet2-set-mbr-signature.py"
check rg -q '^\+CONFIG_ENV_IS_NOWHERE=y' "$repo_root/patches/uboot/999-doornet2-rk3399.patch"
check_not rg -q '^\+CONFIG_ENV_IS_IN_MMC=y|^\+CONFIG_SYS_MMC_ENV_DEV=1' "$repo_root/patches/uboot/999-doornet2-rk3399.patch"
check rg -F -q 'u-boot,spl-boot-order = "same-as-spl", &sdmmc, &sdhci;' "$repo_root/patches/uboot/999-doornet2-rk3399.patch"
check rg -F -q 'DoorNet2: boot source ${devtype} ${devnum}, root PARTUUID=${uuid}' "$source_dir/target/linux/rockchip/image/default.bootscript"
check rg -F -q 'doornet2-boot-report' "$repo_root/package/doornet2-base/Makefile"
check rg -F -q 'DOORNET2_BOOT_REPORT=V1.0.1' "$repo_root/package/doornet2-base/files/usr/sbin/doornet2-boot-report"
check rg -F -q 'doornet2-set-mbr-signature.py' "$source_dir/target/linux/rockchip/image/Makefile"
check rg -F -q '0xD0021000' "$source_dir/target/linux/rockchip/image/Makefile"
check rg -F -q 'part uuid ${devtype} ${devnum}:2 uuid' "$source_dir/target/linux/rockchip/image/default.bootscript"
[ "$fail" -eq 0 ] || exit 1
echo 'Static DoorNet2-V1.0.1 checks passed; this is not hardware acceptance.'
