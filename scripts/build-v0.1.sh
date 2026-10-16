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
cp "$repo_root/config/feeds.conf" "$source_dir/feeds.conf"

jobs=${BUILD_JOBS:-4}
if [ "$(uname -s)" = "Darwin" ]; then
	command -v docker >/dev/null 2>&1 || { printf '%s\n' 'Docker is required on macOS.' >&2; exit 1; }
	volume=${DOORNET2_BUILD_VOLUME:-doornet2-v01-build}
	image=${DOORNET2_BUILDER_IMAGE:-r76s-builder:arm64-ubuntu2204-final}
	copy_dir=$(mktemp -d "$repo_root/work/build-source.XXXXXX")
	trap 'rm -rf "$copy_dir"' EXIT HUP INT TERM
	rsync -a \
		--exclude '/build_dir/' --exclude '/staging_dir/' --exclude '/tmp/' \
		--exclude '/bin/' --exclude '/feeds/' --exclude '/.config' \
		"$source_dir/" "$copy_dir/"
	docker volume create "$volume" >/dev/null
	container="doornet2-v01-copy-$$"
	docker create --name "$container" -v "$volume:/src" "$image" true >/dev/null
	docker cp "$copy_dir/." "$container:/src/"
	docker cp "$repo_root/configs/doorNet2-v0.1.config" "$container:/src/.config"
	docker cp "$repo_root/scripts/test-policy-v0.1.sh" "$container:/src/test-policy-v0.1.sh"
	docker rm "$container" >/dev/null
	docker run --rm -e BUILD_JOBS="$jobs" -e BUILD_VERBOSE="${BUILD_VERBOSE:-}" -v "$volume:/src" "$image" bash -lc '
		set -eu
		cd /src
		if [ "$(uname -m)" = aarch64 ]; then
			bootstrap_tar=/src/dl/go1.20.14.linux-arm64.tar.gz
			bootstrap_root=/src/tmp/go-bootstrap
			if [ ! -x "$bootstrap_root/bin/go" ]; then
				curl -fL "https://go.dev/dl/go1.20.14.linux-arm64.tar.gz" -o "$bootstrap_tar"
				printf "%s  %s\\n" "2096507509a98782850d1f0669786c09727053e9fe3c92b03c0d96f48700282b" "$bootstrap_tar" | sha256sum -c -
				tar -xzf "$bootstrap_tar" -C /src/tmp
				mv /src/tmp/go "$bootstrap_root"
			fi
			grep -v "^CONFIG_GOLANG_EXTERNAL_BOOTSTRAP_ROOT=" /src/.config > /src/.config.new || true
			mv /src/.config.new /src/.config
			printf "CONFIG_GOLANG_EXTERNAL_BOOTSTRAP_ROOT=\\\"%s\\\"\\n" "$bootstrap_root" >> /src/.config
		fi
		./scripts/feeds update -a
		if grep -q "^PKG_VERSION:=0.2.6$" feeds/passwall_packages/geoview/Makefile; then
			patch -p1 < board/doorNet2/feeds/0001-geoview-go123-compatible.patch
		elif ! grep -q "^PKG_VERSION:=0.1.10$" feeds/passwall_packages/geoview/Makefile || \
			! grep -q "^PKG_HASH:=9221df928df68030893125a60bdf6d8a1fef2b199fa58ed80772cb3c17225fc5$" feeds/passwall_packages/geoview/Makefile; then
			echo "Unexpected geoview feed version or hash; refusing an unpinned build." >&2
			exit 1
		fi
		./scripts/feeds install luci-theme-argon luci-app-passwall luci-app-passwall2 smartdns luci-app-smartdns adguardhome chinadns-ng
		sed -i -e "/^CONFIG_GDB=/d" -e "/^# CONFIG_GDB is not set/d" /src/.config
		printf "%s\\n" "# CONFIG_GDB is not set" >> /src/.config
		make -C /src defconfig
		sed -i "/^CONFIG_PACKAGE_dnsmasq=/d" /src/.config
		printf "# CONFIG_PACKAGE_dnsmasq is not set\\n" >> /src/.config
		for package in u-boot-easepi-rk3528 u-boot-easepi-rk3568 u-boot-easepi-rk3568-rk809 u-boot-easepi-rk3576 u-boot-easepi-rk3588; do
			sed -i "/^CONFIG_PACKAGE_${package}=/d" /src/.config
			printf "# CONFIG_PACKAGE_%s is not set\\n" "$package" >> /src/.config
		done
		make -C /src -j"$BUILD_JOBS" download
		make -C /src -j"$BUILD_JOBS" target/linux/compile
		make -C /src -j"$BUILD_JOBS" package/boot/uboot-rockchip/compile BUILD_VARIANT=doornet2-rk3399
		make -C /src -j"$BUILD_JOBS" V="$BUILD_VERBOSE"
		/src/test-policy-v0.1.sh /src/build_dir/target-aarch64_generic_musl/root-rockchip
	'
	output_dir=${BUILD_OUTPUT_DIR:-"$repo_root/work/build-output"}
	mkdir -p "$output_dir"
	export_container="doornet2-v01-export-$$"
	docker create --name "$export_container" -v "$volume:/src" "$image" true >/dev/null
	docker cp "$export_container:/src/bin/targets/rockchip/armv8/." "$output_dir/"
	docker rm "$export_container" >/dev/null
else
	cp "$repo_root/configs/doorNet2-v0.1.config" "$source_dir/.config"
	cd "$source_dir"
	./scripts/feeds update -a
	if grep -q '^PKG_VERSION:=0.2.6$' feeds/passwall_packages/geoview/Makefile; then
		patch -p1 < board/doorNet2/feeds/0001-geoview-go123-compatible.patch
	elif ! grep -q '^PKG_VERSION:=0.1.10$' feeds/passwall_packages/geoview/Makefile || \
		! grep -q '^PKG_HASH:=9221df928df68030893125a60bdf6d8a1fef2b199fa58ed80772cb3c17225fc5$' feeds/passwall_packages/geoview/Makefile; then
		echo 'Unexpected geoview feed version or hash; refusing an unpinned build.' >&2
		exit 1
	fi
	./scripts/feeds install luci-theme-argon luci-app-passwall luci-app-passwall2 smartdns luci-app-smartdns adguardhome chinadns-ng
	if [ "$(uname -m)" = aarch64 ]; then
		bootstrap_tar="$source_dir/dl/go1.20.14.linux-arm64.tar.gz"
		bootstrap_root="$source_dir/tmp/go-bootstrap"
		mkdir -p "$source_dir/dl" "$source_dir/tmp"
		if [ ! -x "$bootstrap_root/bin/go" ]; then
			curl -fL 'https://go.dev/dl/go1.20.14.linux-arm64.tar.gz' -o "$bootstrap_tar"
			printf '%s  %s\n' '2096507509a98782850d1f0669786c09727053e9fe3c92b03c0d96f48700282b' "$bootstrap_tar" | sha256sum -c -
			tar -xzf "$bootstrap_tar" -C "$source_dir/tmp"
			mv "$source_dir/tmp/go" "$bootstrap_root"
		fi
		sed -i '/^CONFIG_GOLANG_EXTERNAL_BOOTSTRAP_ROOT=/d' "$source_dir/.config"
		printf 'CONFIG_GOLANG_EXTERNAL_BOOTSTRAP_ROOT="%s"\n' "$bootstrap_root" >> "$source_dir/.config"
	fi
	sed -i -e '/^CONFIG_GDB=/d' -e '/^# CONFIG_GDB is not set/d' "$source_dir/.config"
	printf '%s\n' '# CONFIG_GDB is not set' >> "$source_dir/.config"
	make -C "$source_dir" defconfig
	sed -i '/^CONFIG_PACKAGE_dnsmasq=/d' "$source_dir/.config"
	printf '%s\n' '# CONFIG_PACKAGE_dnsmasq is not set' >> "$source_dir/.config"
	for package in u-boot-easepi-rk3528 u-boot-easepi-rk3568 u-boot-easepi-rk3568-rk809 u-boot-easepi-rk3576 u-boot-easepi-rk3588; do
		sed -i "/^CONFIG_PACKAGE_${package}=/d" "$source_dir/.config"
		printf '# CONFIG_PACKAGE_%s is not set\n' "$package" >> "$source_dir/.config"
	done
	make -C "$source_dir" -j"$jobs" download
	make -C "$source_dir" -j"$jobs" target/linux/compile
	make -C "$source_dir" -j"$jobs" package/boot/uboot-rockchip/compile BUILD_VARIANT=doornet2-rk3399
	make -C "$source_dir" -j"$jobs" V="${BUILD_VERBOSE:-}"
	if [ "$(id -u)" -eq 0 ]; then
		"$repo_root/scripts/test-policy-v0.1.sh" "$source_dir/build_dir/target-aarch64_generic_musl/root-rockchip"
	else
		echo 'NOT TESTED: policy integration test requires root and chroot.'
	fi
	output_dir=${BUILD_OUTPUT_DIR:-"$repo_root/work/build-output"}
	mkdir -p "$output_dir"
	cp -R "$source_dir/bin/targets/rockchip/armv8/." "$output_dir/"
fi
