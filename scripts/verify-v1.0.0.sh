#!/bin/sh
set -eu

source_dir=${1:-}
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$repo_root/config/source.env"

[ -n "$source_dir" ] && [ -f "$source_dir/Makefile" ] || { echo 'OpenWrt source path required' >&2; exit 2; }
fail=0
check() { if "$@"; then echo "PASS: $*"; else echo "FAIL: $*" >&2; fail=1; fi; }
check_not() { if "$@"; then echo "FAIL: not ($*)" >&2; fail=1; else echo "PASS: not ($*)"; fi; }

check test "$(git -C "$source_dir" rev-parse HEAD)" = "$OPENWRT_COMMIT"
check rg -q '^name: DoorNet2-V1\.0\.0$' "$repo_root/.github/workflows/doornet2-v1.0.0.yml"
check rg -q '^run-name: "DoorNet2-V1\.0\.0 #\$\{\{ github\.run_number \}\}"$' "$repo_root/.github/workflows/doornet2-v1.0.0.yml"
check rg -q '^    name: DoorNet2-V1\.0\.0$' "$repo_root/.github/workflows/doornet2-v1.0.0.yml"
check_not rg -q 'istoreos/istoreos|ISTOREOS_' "$repo_root/config" "$repo_root/scripts/build-v1.0.0.sh" "$repo_root/.github"
check rg -q '192\.168\.100\.1' "$repo_root/configs/doorNet2-v1.0.0.config"
check_not rg -q '192\.168\.50\.1' "$repo_root/configs/doorNet2-v1.0.0.config"
check rg -q 'CONFIG_VERSION_CODE="DoorNet2-V1\.0\.0"' "$repo_root/configs/doorNet2-v1.0.0.config"
check rg -F -q '#include "rk3399.dtsi"' "$repo_root/patches/kernel/rk3399-doornet2.dtsi"
check_not rg -q 'rk3399-opp\.dtsi|rockchip/rk3399\.dtsi' "$repo_root/patches/kernel/rk3399-doornet2.dtsi"
check_not rg -q 'rk3399-opp\.dtsi' "$repo_root/patches/uboot/999-doornet2-rk3399.patch"
check git apply --numstat "$repo_root/patches/uboot/998-doornet2-tf-first.patch"
check git apply --numstat "$repo_root/patches/uboot/999-doornet2-rk3399.patch"
check test -f "$source_dir/target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/rk3399-doornet2.dts"
check test -f "$source_dir/package/boot/uboot-rockchip/patches/998-doornet2-tf-first.patch"
check test -f "$source_dir/package/boot/uboot-rockchip/patches/999-doornet2-rk3399.patch"
check rg -q '^\+CONFIG_ENV_IS_NOWHERE=y' "$repo_root/patches/uboot/999-doornet2-rk3399.patch"
check_not rg -q '^\+CONFIG_ENV_IS_IN_MMC=y|^\+CONFIG_SYS_MMC_ENV_DEV=1' "$repo_root/patches/uboot/999-doornet2-rk3399.patch"
check rg -q 'doornet2-mbr' "$source_dir/target/linux/rockchip/image/armv8.mk"
check rg -q '0xD0021000' "$source_dir/include/image-commands.mk"
check rg -F -q 'part uuid mmc ${devnum}:2 uuid' "$source_dir/target/linux/rockchip/image/mmc.bootscript"
[ "$fail" -eq 0 ] || exit 1
echo 'Static DoorNet2-V1.0.0 checks passed; this is not hardware acceptance.'
