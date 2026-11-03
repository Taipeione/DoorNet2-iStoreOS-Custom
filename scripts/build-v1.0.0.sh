#!/bin/sh
set -eu

[ "${GITHUB_ACTIONS:-}" = true ] && [ "${RUNNER_ENVIRONMENT:-}" = github-hosted ] || {
	echo 'Refusing local firmware compilation; use GitHub-hosted Actions.' >&2
	exit 2
}
[ "${GITHUB_REPOSITORY:-}" = Taipeione/DoorNet2-iStoreOS-Custom ] || {
	echo 'Unexpected GitHub repository.' >&2
	exit 2
}

source_dir=${1:?OpenWrt source path required}
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$repo_root/config/source.env"
[ "$(git -C "$source_dir" rev-parse HEAD)" = "$OPENWRT_COMMIT" ] || { echo 'OpenWrt commit mismatch' >&2; exit 1; }

"$repo_root/scripts/apply-board-support.sh" "$source_dir"
cp "$repo_root/config/feeds.conf" "$source_dir/feeds.conf"
cp "$repo_root/configs/doorNet2-v1.0.0.config" "$source_dir/.config"
"$source_dir/scripts/feeds" update packages luci routing telephony video istore passwall_packages passwall_luci passwall2
"$source_dir/scripts/feeds" install luci-compat luci-app-store luci-app-passwall luci-app-passwall2 smartdns luci-app-smartdns adguardhome chinadns-ng

# Argon is a regular exact-pinned package; it is not treated as an iStoreOS feed.
git clone --filter=blob:none --no-checkout "$ARGON_REPOSITORY" "$source_dir/package/luci-theme-argon"
git -C "$source_dir/package/luci-theme-argon" fetch --depth=1 origin "$ARGON_COMMIT"
git -C "$source_dir/package/luci-theme-argon" checkout --detach FETCH_HEAD

make -C "$source_dir" defconfig
required_packages_file="$repo_root/config/required-packages-v1.0.0.txt"
while IFS= read -r package_name; do
	case "$package_name" in ''|'#'*) continue ;; esac
	sed -i "/^CONFIG_PACKAGE_${package_name}=/d" "$source_dir/.config"
	printf 'CONFIG_PACKAGE_%s=y\n' "$package_name" >> "$source_dir/.config"
done < "$required_packages_file"

# Kconfig cannot infer every package-metadata dependency. Normalize roots
# once, then materialize only unconditional metadata dependencies and recheck.
make -C "$source_dir" defconfig
make -C "$source_dir" target/linux/prepare
make -C "$source_dir" package/boot/uboot-rockchip/prepare
"$repo_root/scripts/verify-v1.0.0.sh" "$source_dir"
make -C "$source_dir" prepare-tmpinfo
perl "$repo_root/scripts/verify-package-closure-v1.0.0.pl" --enable-missing "$source_dir" "$source_dir/.config" "$required_packages_file"
perl "$repo_root/scripts/verify-package-closure-v1.0.0.pl" "$source_dir" "$source_dir/.config" "$required_packages_file"
make -C "$source_dir" -j"${BUILD_JOBS:-3}" V="${BUILD_VERBOSE:-s}" download
make -C "$source_dir" -j"${BUILD_JOBS:-3}" V="${BUILD_VERBOSE:-s}"
