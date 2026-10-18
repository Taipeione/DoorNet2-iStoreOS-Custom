#!/bin/sh
set -eu

source_dir=${1:?OpenWrt source path required}
output_dir=${2:?Output directory required}
project_sha=${3:?Project SHA required}
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$repo_root/config/source.env"

image_dir="$source_dir/bin/targets/rockchip/armv8"
[ -d "$image_dir" ] || { echo 'Rockchip image directory missing' >&2; exit 1; }
mkdir -p "$output_dir"
for flavor in ext4 squashfs; do
	input=$(find "$image_dir" -maxdepth 1 -type f -name "*embedfire_doornet2*${flavor}*sysupgrade*.img.gz" -print -quit)
	[ -n "$input" ] || { echo "Missing ${flavor} sysupgrade image" >&2; exit 1; }
	name="DoorNet2-V0.1-rk3399-1gb-ddr3l-${flavor}-sysupgrade.img.gz"
	cp "$input" "$output_dir/$name"
	gzip -t "$output_dir/$name"
done
{
	echo "project_commit=$project_sha"
	echo "openwrt_commit=$OPENWRT_COMMIT"
	echo "openwrt_version=$OPENWRT_VERSION"
	echo "workflow=${GITHUB_WORKFLOW:-unknown}"
	echo "run_id=${GITHUB_RUN_ID:-unknown}"
	echo "run_number=${GITHUB_RUN_NUMBER:-unknown}"
	echo "runner_environment=${RUNNER_ENVIRONMENT:-unknown}"
	echo 'target=rockchip/armv8/embedfire_doornet2'
	echo 'lan=192.168.100.1/24'
} > "$output_dir/DoorNet2-V0.1-BuildInfo.txt"
echo 'DoorNet2-V0.1' > "$output_dir/DoorNet2-V0.1-Version.txt"
(cd "$output_dir" && sha256sum DoorNet2-V0.1-* > DoorNet2-V0.1-SHA256SUMS)
sha256sum -c "$output_dir/DoorNet2-V0.1-SHA256SUMS"
