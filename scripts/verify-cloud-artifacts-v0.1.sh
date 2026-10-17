#!/bin/bash
set -euo pipefail

artifact_dir=${1:?usage: verify-cloud-artifacts-v0.1.sh ARTIFACT_DIR COMMIT_SHA}
commit_sha=${2:?usage: verify-cloud-artifacts-v0.1.sh ARTIFACT_DIR COMMIT_SHA}
repo_root=$(cd -- "$(dirname -- "$0")/.." && pwd)
profiles="$artifact_dir/profiles.json"
checksums="$artifact_dir/sha256sums"
manifest=$(find "$artifact_dir" -maxdepth 1 -type f -name '*embedfire_doornet2.manifest' -print -quit)
fwtool="$repo_root/work/openwrt/staging_dir/host/bin/fwtool"

test -s "$profiles"
test -s "$checksums"
test -n "$manifest"
test -x "$fwtool"

python3 - "$artifact_dir" "$profiles" "$checksums" <<'PY'
import hashlib, json, os, sys
artifact_dir, profiles_path, checksums_path = sys.argv[1:]
prefix = "DoorNet2-V0.1-"
renames = {}
for entry in os.listdir(artifact_dir):
    if "embedfire_doornet2" not in entry or not (entry.endswith(".manifest") or entry.endswith(".img.gz")):
        continue
    if entry.startswith(prefix):
        continue
    renamed = prefix + entry
    os.replace(os.path.join(artifact_dir, entry), os.path.join(artifact_dir, renamed))
    renames[entry] = renamed

profiles = json.load(open(profiles_path, encoding="utf-8"))
assert profiles.get("target") == "rockchip/armv8", profiles.get("target")
assert profiles.get("version_code") == "DoorNet2-V0.1", profiles.get("version_code")
profile = profiles.get("profiles", {}).get("embedfire_doornet2")
assert profile, "DoorNet2 RK3399 profile missing"
assert "embedfire,doornet2" in profile.get("supported_devices", [])
title = profile.get("titles", [{}])[0]
assert title.get("vendor") == "EmbedFire" and title.get("model") == "DoorNet2", title
images = [item for item in profile.get("images", []) if item.get("type") == "sysupgrade"]
assert {item.get("filesystem") for item in images} == {"ext4", "squashfs"}, images
for image in images:
    image["name"] = renames.get(image["name"], image["name"])
    assert image["name"].startswith(prefix), image["name"]
    with open(os.path.join(artifact_dir, image["name"]), "rb") as stream:
        assert image.get("sha256") == hashlib.file_digest(stream, "sha256").hexdigest(), image["name"]
with open(profiles_path, "w", encoding="utf-8") as stream:
    json.dump(profiles, stream, indent=2, ensure_ascii=False)
    stream.write("\n")
profiles_digest = hashlib.sha256(open(profiles_path, "rb").read()).hexdigest()

lines = []
for line in open(checksums_path, encoding="utf-8"):
    digest, name = line.rstrip("\n").split(maxsplit=1)
    marker = name[0] if name and name[0] in " *" else " "
    basename = name[1:] if marker != " " else name
    if basename == "profiles.json":
        digest = profiles_digest
    lines.append(f"{digest} {marker}{renames.get(basename, basename)}\n")
with open(checksums_path, "w", encoding="utf-8") as stream:
    stream.writelines(lines)
print("PASS: profiles.json identifies DoorNet2 RK3399, DoorNet2-V0.1, and ext4/squashfs images")
PY

(cd "$artifact_dir" && sha256sum --check sha256sums)
for fs in ext4 squashfs; do
	image=$(find "$artifact_dir" -maxdepth 1 -type f -name "*embedfire_doornet2-${fs}-sysupgrade.img.gz" -print -quit)
	test -n "$image"
	gzip_status=0
	gzip_report=$(gzip -t "$image" 2>&1) || gzip_status=$?
	if [ "$gzip_status" -ne 2 ] || [[ "$gzip_report" != *'trailing garbage ignored'* ]]; then
		printf 'FAIL: unexpected gzip validation result for %s: %s\n' "$image" "$gzip_report" >&2
		exit 1
	fi
	metadata=$(mktemp)
	"$fwtool" -i "$metadata" "$image"
	python3 - "$metadata" "$fs" "$image" <<'PY'
import gzip, json, struct, subprocess, sys
metadata_path, filesystem, image_path = sys.argv[1:]
metadata = json.load(open(metadata_path, encoding="utf-8"))
assert metadata.get("version", {}).get("version") == "DoorNet2-V0.1", metadata
assert "embedfire,doornet2" in metadata.get("supported_devices", []), metadata
with gzip.open(image_path, "rb") as stream:
    header = stream.read(65536)
    stream.seek(0x4000 * 512)
    fit_magic = stream.read(4)
assert header[510:512] == b"\x55\xaa", "Missing MBR disk image"
assert any(header[64 * 512:65 * 512]), "Missing RK3399 loader at sector 64"
assert fit_magic == b"\xd0\x0d\xfe\xed", "Missing U-Boot FIT at sector 0x4000"
assert struct.unpack_from("<I", header, 446 + 8)[0] == 32768, "Unexpected boot partition offset"
identified = subprocess.check_output(["file", "-"], input=header).decode().strip()
assert "DOS/MBR boot sector" in identified, identified
print(f"PASS: {filesystem} sysupgrade gzip CRC, fwtool metadata, MBR and RK3399 boot offsets")
PY
	rm -f "$metadata"
done

grep -q '^OPENWRT_COMMIT=' "$repo_root/config/source.env"
grep -q 'CONFIG_VERSION_CODE="DoorNet2-V0.1"' "$repo_root/configs/doorNet2-v0.1.config"
if grep -E -q 'R76S|RK3576|r76s|rk3576' "$manifest"; then
	echo 'FAIL: unrelated R76S/RK3576 package detected in firmware manifest' >&2
	exit 1
fi
for package in doornet2-base luci-app-store luci-compat luci-theme-argon luci-app-passwall luci-app-passwall2 smartdns luci-app-smartdns adguardhome chinadns-ng dnsmasq-full; do
	grep -E -q "^${package} - " "$manifest" || { echo "FAIL: required firmware package missing: $package" >&2; exit 1; }
done

source "$repo_root/config/source.env"
cat > "$artifact_dir/DoorNet2-V0.1-BuildInfo.txt" <<EOF
formal_name=DoorNet2-V0.1
firmware_display=DoorNet2-V0.1
ota_version=DoorNet2-V0.1
build_origin=GitHub Actions hosted runner
repository=Taipeione/DoorNet2-iStoreOS-Custom
commit=$commit_sha
openwrt_version=$OPENWRT_VERSION
openwrt_commit=$OPENWRT_COMMIT
kernel=$OPENWRT_KERNEL
istore_commit=$ISTORE_COMMIT
run_number=${GITHUB_RUN_NUMBER:-unknown}
run_url=${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-Taipeione/DoorNet2-iStoreOS-Custom}/actions/runs/${GITHUB_RUN_ID:-unknown}
target=rockchip/armv8/embedfire_doornet2
target_memory=1GB DDR3L DoorNet2 only
images=ext4,squashfs sysupgrade gzip
hardware_boot=NOT TESTED
EOF
printf '%s\n' 'PASS: cloud artifacts, required packages, profile, checksums, version and target verified.'
