#!/bin/bash
set -euo pipefail

artifact_dir=${1:?usage: verify-cloud-artifacts-v0.1.sh ARTIFACT_DIR COMMIT_SHA}
commit_sha=${2:?usage: verify-cloud-artifacts-v0.1.sh ARTIFACT_DIR COMMIT_SHA}
repo_root=$(cd -- "$(dirname -- "$0")/.." && pwd)
profiles="$artifact_dir/profiles.json"
checksums="$artifact_dir/sha256sums"
manifest=$(find "$artifact_dir" -maxdepth 1 -type f -name '*embedfire_doornet2.manifest' -print -quit)

test -s "$profiles"
test -s "$checksums"
test -n "$manifest"
python3 - "$profiles" <<'PY'
import json, sys
p = json.load(open(sys.argv[1], encoding="utf-8"))
assert p.get("target") == "rockchip/armv8", p.get("target")
assert p.get("version_number") == "V0.1", p.get("version_number")
assert p.get("version_code") == "DoorNet2-V0.1", p.get("version_code")
assert p.get("linux_kernel", {}).get("version") == "6.6.144"
profile = p.get("profiles", {}).get("embedfire_doornet2")
assert profile, "DoorNet2 RK3399 profile missing"
assert "embedfire,doornet2" in profile.get("supported_devices", [])
assert profile.get("titles") == [{"vendor": "EmbedFire", "model": "DoorNet2", "variant": "RK3399"}]
images = profile.get("images", [])
assert {i.get("filesystem") for i in images if i.get("type") == "sysupgrade"} == {"ext4", "squashfs"}
for image in images:
    if image.get("type") == "sysupgrade":
        assert image.get("sha256") and image.get("name", "").endswith(".img.gz")
print("PASS: profiles.json identifies DoorNet2 RK3399, V0.1, Linux 6.6.144, ext4 and squashfs")
PY

(cd "$artifact_dir" && sha256sum --check sha256sums)
for fs in ext4 squashfs; do
	image=$(find "$artifact_dir" -maxdepth 1 -type f -name "*embedfire_doornet2-${fs}-sysupgrade.img.gz" -print -quit)
	test -n "$image"
	gzip -t "$image"
	file "$image"
done
grep -q 'CONFIG_VERSION_DIST="DoorNet2"' "$repo_root/configs/doorNet2-v0.1.config"
grep -q 'CONFIG_VERSION_NUMBER="V0.1"' "$repo_root/configs/doorNet2-v0.1.config"
grep -q 'CONFIG_VERSION_CODE="DoorNet2-V0.1"' "$repo_root/configs/doorNet2-v0.1.config"
grep -q 'CONFIG_PACKAGE_u-boot-doornet2-rk3399=y' "$repo_root/configs/doorNet2-v0.1.config"
if grep -E -q 'R76S|RK3576|r76s|rk3576' "$manifest"; then
	echo 'FAIL: unrelated R76S/RK3576 package detected in firmware manifest' >&2
	exit 1
fi

cat > "$artifact_dir/cloud-build-manifest.txt" <<EOF
build_origin=GitHub Actions hosted runner
repository=Taipeione/DoorNet2-iStoreOS-Custom
commit=$commit_sha
version=DoorNet2-V0.1
target=rockchip/armv8/embedfire_doornet2
source_commit=$(awk -F= '$1 == "ISTOREOS_COMMIT" {print $2}' "$repo_root/config/source.env")
kernel=6.6.144
images=ext4,squashfs sysupgrade gzip
EOF
sha256sum "$artifact_dir"/*sysupgrade.img.gz
printf '%s\n' 'PASS: cloud artifacts, profile, image formats, checksums, version and target verified.'
