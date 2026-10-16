#!/bin/sh
set -eu

source_dir=${1:-${ISTOREOS_SOURCE:-}}
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if [ -z "$source_dir" ] || [ ! -f "$source_dir/Makefile" ]; then
	printf '%s\n' 'usage: build-v0.1.sh /path/to/istoreos-source' >&2
	exit 2
fi

"$repo_root/scripts/apply-board-support.sh" "$source_dir"
"$repo_root/scripts/verify-v0.1.sh" "$source_dir"

cp "$repo_root/configs/doorNet2-v0.1.config" "$source_dir/.config"

jobs=${BUILD_JOBS:-4}
if [ "$(uname -s)" = "Darwin" ]; then
	command -v docker >/dev/null 2>&1 || { printf '%s\n' 'Docker is required on macOS.' >&2; exit 1; }
	volume=${DOORNET2_BUILD_VOLUME:-doornet2-v01-build}
	image=${DOORNET2_BUILDER_IMAGE:-r76s-builder:arm64-ubuntu2204-final}
	docker volume create "$volume" >/dev/null
	container="doornet2-v01-copy-$$"
	docker create --name "$container" -v "$volume:/src" "$image" true >/dev/null
	docker cp "$source_dir/." "$container:/src/"
	docker rm "$container" >/dev/null
	docker run --rm -e BUILD_JOBS="$jobs" -v "$volume:/src" "$image" bash -lc '
		set -eu
		make -C /src defconfig
		sed -i -e "/^CONFIG_GDB=/d" -e "/^# CONFIG_GDB is not set/d" /src/.config
		printf "%s\\n" "# CONFIG_GDB is not set" >> /src/.config
		make -C /src -j"$BUILD_JOBS" download
		make -C /src -j"$BUILD_JOBS" target/linux/compile package/boot/uboot-rockchip/compile
		make -C /src -j"$BUILD_JOBS" V=s
	'
else
	make -C "$source_dir" defconfig
	sed -i -e '/^CONFIG_GDB=/d' -e '/^# CONFIG_GDB is not set/d' "$source_dir/.config"
	printf '%s\n' '# CONFIG_GDB is not set' >> "$source_dir/.config"
	make -C "$source_dir" -j"$jobs" download
	make -C "$source_dir" -j"$jobs" target/linux/compile package/boot/uboot-rockchip/compile
	make -C "$source_dir" -j"$jobs" V=s
fi
