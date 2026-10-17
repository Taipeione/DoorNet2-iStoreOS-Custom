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

source_dir=${1:-${ISTOREOS_SOURCE:-}}
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$repo_root/config/source.env"

if [ -z "$source_dir" ] || [ ! -f "$source_dir/Makefile" ]; then
	printf '%s\n' 'usage: build-v0.1.sh /path/to/pinned/istoreos-source' >&2
	exit 2
fi
source_commit=$(git -C "$source_dir" rev-parse HEAD)
if [ "$source_commit" != "$ISTOREOS_COMMIT" ]; then
	printf 'Refusing unpinned iStoreOS source: expected %s, got %s\n' "$ISTOREOS_COMMIT" "$source_commit" >&2
	exit 1
fi

"$repo_root/scripts/apply-board-support.sh" "$source_dir"
"$repo_root/scripts/verify-v0.1.sh" "$source_dir"
cp "$repo_root/config/feeds.conf" "$source_dir/feeds.conf"
cp "$repo_root/configs/doorNet2-v0.1.config" "$source_dir/.config"

jobs=${BUILD_JOBS:-2}
"$source_dir/scripts/feeds" update -a
while read -r feed_type feed_name feed_source; do
	case "$feed_type" in
		''|\#*) continue ;;
		src-git*) ;;
		*) printf 'Unsupported feed declaration: %s\n' "$feed_type" >&2; exit 1 ;;
	esac
	expected_commit=${feed_source##*^}
	if [ "$expected_commit" = "$feed_source" ] || [ "${#expected_commit}" -ne 40 ]; then
		printf 'Feed %s does not have a full 40-character pinned commit.\n' "$feed_name" >&2
		exit 1
	fi
	actual_commit=$(git -C "$source_dir/feeds/$feed_name" rev-parse HEAD)
	if [ "$actual_commit" != "$expected_commit" ]; then
		printf 'Feed %s pin mismatch: expected %s, got %s\n' "$feed_name" "$expected_commit" "$actual_commit" >&2
		exit 1
	fi
done < "$repo_root/config/feeds.conf"
if grep -q '^PKG_VERSION:=0.2.6$' "$source_dir/feeds/passwall_packages/geoview/Makefile"; then
	patch -d "$source_dir" -p1 < "$repo_root/board/doorNet2/feeds/0001-geoview-go123-compatible.patch"
elif ! grep -q '^PKG_VERSION:=0.1.10$' "$source_dir/feeds/passwall_packages/geoview/Makefile" || \
	! grep -q '^PKG_HASH:=9221df928df68030893125a60bdf6d8a1fef2b199fa58ed80772cb3c17225fc5$' "$source_dir/feeds/passwall_packages/geoview/Makefile"; then
	echo 'Unexpected geoview feed version or hash; refusing an unpinned build.' >&2
	exit 1
fi
# Upstream AdGuard Home's interface-up trigger restarts the daemon without an
# enable guard. Ship it disabled and make explicit UCI enablement persistent.
patch -d "$source_dir" -p1 < "$repo_root/board/doorNet2/feeds/0002-adguardhome-disabled-by-default.patch"
"$source_dir/scripts/feeds" install luci-theme-argon luci-app-passwall luci-app-passwall2 smartdns luci-app-smartdns adguardhome chinadns-ng

sed -i -e '/^CONFIG_GDB=/d' -e '/^# CONFIG_GDB is not set/d' "$source_dir/.config"
printf '%s\n' '# CONFIG_GDB is not set' >> "$source_dir/.config"
make -C "$source_dir" defconfig
sed -i '/^CONFIG_PACKAGE_dnsmasq=/d' "$source_dir/.config"
printf '%s\n' '# CONFIG_PACKAGE_dnsmasq is not set' >> "$source_dir/.config"
for package in u-boot-easepi-rk3528 u-boot-easepi-rk3576 u-boot-easepi-rk3568 u-boot-easepi-rk3568-rk809 u-boot-easepi-rk3588; do
	sed -i "/^CONFIG_PACKAGE_${package}=/d" "$source_dir/.config"
	printf '# CONFIG_PACKAGE_%s is not set\n' "$package" >> "$source_dir/.config"
done
make -C "$source_dir" defconfig
if grep -q '^CONFIG_PACKAGE_dnsmasq=y$' "$source_dir/.config"; then
	echo 'defconfig re-enabled conflicting dnsmasq; refusing an ambiguous configuration.' >&2
	exit 1
fi
for package in u-boot-easepi-rk3528 u-boot-easepi-rk3568 u-boot-easepi-rk3568-rk809 u-boot-easepi-rk3576 u-boot-easepi-rk3588; do
	if grep -q "^CONFIG_PACKAGE_${package}=y$" "$source_dir/.config"; then
		printf 'defconfig re-enabled unrelated U-Boot package %s; refusing an ambiguous configuration.\n' "$package" >&2
		exit 1
	fi
done

make -C "$source_dir" -j"$jobs" download
# target/linux/compile is invoked explicitly for early board/kernel diagnostics;
# prepare OpenWrt host tools and the ARM64 cross toolchain first.
make -C "$source_dir" -j"$jobs" tools/install
make -C "$source_dir" -j"$jobs" toolchain/install
make -C "$source_dir" -j"$jobs" V="${BUILD_VERBOSE:-}" target/linux/compile
make -C "$source_dir" -j"$jobs" V="${BUILD_VERBOSE:-}" package/boot/uboot-rockchip/compile BUILD_VARIANT=doornet2-rk3399
make -C "$source_dir" -j"$jobs" V="${BUILD_VERBOSE:-}"

output_dir=${BUILD_OUTPUT_DIR:-"$repo_root/work/build-output"}
mkdir -p "$output_dir"
cp -R "$source_dir/bin/targets/rockchip/armv8/." "$output_dir/"

# This test executes target ARM64 UCI in a chroot and therefore uses runner sudo.
sudo "$repo_root/scripts/test-policy-v0.1.sh" "$source_dir/build_dir/target-aarch64_generic_musl/root-rockchip"
