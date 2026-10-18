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
cp "$repo_root/configs/doorNet2-v0.1.config" "$source_dir/.config"
"$source_dir/scripts/feeds" update packages luci routing telephony video istore passwall_packages passwall_luci passwall2
"$source_dir/scripts/feeds" install luci-compat luci-app-store luci-app-passwall luci-app-passwall2 smartdns luci-app-smartdns adguardhome chinadns-ng

# Argon is a regular exact-pinned package; it is not treated as an iStoreOS feed.
git clone --filter=blob:none --no-checkout "$ARGON_REPOSITORY" "$source_dir/package/luci-theme-argon"
git -C "$source_dir/package/luci-theme-argon" fetch --depth=1 origin "$ARGON_COMMIT"
git -C "$source_dir/package/luci-theme-argon" checkout --detach FETCH_HEAD

make -C "$source_dir" defconfig
while IFS= read -r package_name; do
	case "$package_name" in ''|'#'*) continue ;; esac
	grep -q "^CONFIG_PACKAGE_${package_name}=y$" "$source_dir/.config" || { echo "Required package dropped: $package_name" >&2; exit 1; }
done < "$repo_root/config/required-packages-v0.1.txt"
"$repo_root/scripts/verify-v0.1.sh" "$source_dir"
make -C "$source_dir" -j"${BUILD_JOBS:-3}" V="${BUILD_VERBOSE:-s}" download
make -C "$source_dir" -j"${BUILD_JOBS:-3}" V="${BUILD_VERBOSE:-s}"
