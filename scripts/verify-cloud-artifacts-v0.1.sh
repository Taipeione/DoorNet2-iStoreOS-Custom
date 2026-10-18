#!/bin/sh
set -eu

source_dir=${1:?OpenWrt source path required}
output_dir=${2:?Output directory required}
project_sha=${3:?Project SHA required}
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
. "$repo_root/config/source.env"

image_dir="$source_dir/bin/targets/rockchip/armv8"
[ -d "$image_dir" ] || { echo 'Rockchip image directory missing' >&2; exit 1; }
fwtool="$source_dir/staging_dir/host/bin/fwtool"
[ -x "$fwtool" ] || { echo 'OpenWrt host fwtool is missing after the firmware build' >&2; exit 1; }
mkdir -p "$output_dir"
verification_dir=$(mktemp -d "$output_dir/.sysupgrade-verify.XXXXXX")
trap 'rm -rf "$verification_dir"' EXIT
for flavor in ext4 squashfs; do
	input=$(find "$image_dir" -maxdepth 1 -type f -name "*embedfire_doornet2*${flavor}*sysupgrade*.img.gz" -print -quit)
	[ -n "$input" ] || { echo "Missing ${flavor} sysupgrade image" >&2; exit 1; }
	name="DoorNet2-V0.1-rk3399-1gb-ddr3l-${flavor}-sysupgrade.img.gz"
	cp "$input" "$output_dir/$name"

	# OpenWrt sysupgrade images intentionally carry fwtool metadata after the
	# compressed payload.  Validate that trailer with fwtool, then remove it
	# from a disposable copy before applying the strict gzip integrity check.
	metadata="$verification_dir/${flavor}.json"
	"$fwtool" -q -i "$metadata" "$output_dir/$name"
	python3 - "$metadata" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as metadata_file:
    metadata = json.load(metadata_file)

expected_version = {
    "dist": "DoorNet2",
    "version": "DoorNet2-V0.1",
    "target": "rockchip/armv8",
    "board": "embedfire_doornet2",
}
if metadata.get("metadata_version") != "1.1":
    raise SystemExit("unexpected sysupgrade metadata_version")
if metadata.get("compat_version") != "1.0":
    raise SystemExit("unexpected sysupgrade compatibility version")
if "embedfire,doornet2" not in metadata.get("supported_devices", []):
    raise SystemExit("sysupgrade metadata does not support embedfire,doornet2")
for key, value in expected_version.items():
    if metadata.get("version", {}).get(key) != value:
        raise SystemExit(f"sysupgrade metadata {key!r} is not {value!r}")
PY
	stripped="$verification_dir/${flavor}.img.gz"
	cp "$output_dir/$name" "$stripped"
	"$fwtool" -q -s /dev/null -t "$stripped" || :
	"$fwtool" -q -i /dev/null -t "$stripped"
	gzip -t "$stripped"
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
