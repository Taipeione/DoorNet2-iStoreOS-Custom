#!/bin/sh
set -eu

# Formal firmware compilation is permitted only on GitHub-hosted Actions.
if [ "${GITHUB_ACTIONS:-}" != true ] || [ "${RUNNER_ENVIRONMENT:-}" != github-hosted ]; then
	printf '%s\n' 'Refusing firmware compilation: DoorNet2 builds must run on GitHub-hosted Actions.' >&2
	exit 2
fi
if [ "${GITHUB_REPOSITORY:-}" != Taipeione/DoorNet2-iStoreOS-Custom ]; then
	printf '%s\n' 'Refusing firmware compilation from an unexpected GitHub repository.' >&2
	exit 2
fi

source_dir=${1:-${OPENWRT_SOURCE:-}}
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$repo_root/config/source.env"

if [ -z "$source_dir" ] || [ ! -f "$source_dir/Makefile" ]; then
	printf '%s\n' 'usage: build-v0.1.sh /path/to/pinned/openwrt-source' >&2
	exit 2
fi
source_commit=$(git -C "$source_dir" rev-parse HEAD)
if [ "$source_commit" != "$OPENWRT_COMMIT" ]; then
	printf 'Refusing unpinned OpenWrt source: expected %s, got %s\n' "$OPENWRT_COMMIT" "$source_commit" >&2
	exit 1
fi

"$repo_root/scripts/apply-board-support.sh" "$source_dir"
cp "$repo_root/config/feeds.conf" "$source_dir/feeds.conf"
cp "$repo_root/configs/doorNet2-v0.1.config" "$source_dir/.config"

"$source_dir/scripts/feeds" update -a
patch -d "$source_dir" -p1 < "$repo_root/board/doorNet2/feeds/0001-openwrt-adguardhome-disabled-by-default.patch"
while read -r feed_type feed_name feed_source; do
	case "$feed_type" in ''|\#*) continue ;; src-git*) ;; *) echo "Unsupported feed declaration: $feed_type" >&2; exit 1 ;; esac
	expected_commit=${feed_source##*^}
	[ "$expected_commit" != "$feed_source" ] && [ "${#expected_commit}" -eq 40 ] || {
		echo "Feed $feed_name lacks a 40-character pin." >&2; exit 1; }
	actual_commit=$(git -C "$source_dir/feeds/$feed_name" rev-parse HEAD)
	[ "$actual_commit" = "$expected_commit" ] || {
		printf 'Feed %s pin mismatch: expected %s, got %s\n' "$feed_name" "$expected_commit" "$actual_commit" >&2; exit 1; }
done < "$repo_root/config/feeds.conf"

"$source_dir/scripts/feeds" install luci-compat luci-app-store luci-theme-argon luci-app-passwall luci-app-passwall2 smartdns luci-app-smartdns adguardhome chinadns-ng

make -C "$source_dir" defconfig
required_packages_file="$repo_root/config/required-packages-v0.1.txt"
while IFS= read -r package; do
	case "$package" in ''|\#*) continue ;; esac
	sed -i "/^CONFIG_PACKAGE_${package}=/d" "$source_dir/.config"
	printf 'CONFIG_PACKAGE_%s=y\n' "$package" >> "$source_dir/.config"
done < "$required_packages_file"

# These preparation steps fail early when the exact standard-OpenWrt source
# rejects the DoorNet2 DTS/U-Boot integration. They do not compile firmware.
make -C "$source_dir" target/linux/prepare
make -C "$source_dir" package/boot/uboot-rockchip/prepare
"$repo_root/scripts/verify-v0.1.sh" "$source_dir"

make -C "$source_dir" prepare-tmpinfo
perl "$repo_root/scripts/verify-package-closure-v0.1.pl" "$source_dir" "$source_dir/.config" "$required_packages_file"

jobs=${BUILD_JOBS:-2}
make -C "$source_dir" -j"$jobs" download
make -C "$source_dir" -j"$jobs" V="${BUILD_VERBOSE:-}"

output_dir=${BUILD_OUTPUT_DIR:-"$repo_root/work/build-output"}
mkdir -p "$output_dir"
cp -R "$source_dir/bin/targets/rockchip/armv8/." "$output_dir/"

# This is a cloud-only built-rootfs policy test, never a physical-device test.
rootfs=$(find "$source_dir/build_dir" -type d -path '*root-rockchip' -print -quit)
[ -n "$rootfs" ] || { echo 'Built DoorNet2 rootfs was not found.' >&2; exit 1; }
sudo "$repo_root/scripts/test-policy-v0.1.sh" "$rootfs"
