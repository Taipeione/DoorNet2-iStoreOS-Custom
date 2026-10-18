#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_dir=${1:?pinned OpenWrt source path required}
test -f "$source_dir/scripts/metadata.pm"

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/doornet2-closure.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT HUP INT TERM

printf '%s\n' \
  'CONFIG_PACKAGE_root=y' \
  'CONFIG_PACKAGE_tar=y' \
  'CONFIG_PACKAGE_TAR_POSIX_ACL=y' > "$work_dir/.config"
printf '%s\n' 'root' > "$work_dir/required-packages"
printf '%s\n' \
  'Source-Makefile: package/root/Makefile' \
  'Package: root' \
  'Source-Makefile: feeds/packages/utils/tar/Makefile' \
  'Package: tar' \
  'Depends: +PACKAGE_TAR_POSIX_ACL:libacl +PACKAGE_TAR_XATTR:libattr' \
  'Source-Makefile: feeds/packages/utils/acl/Makefile' \
  'Package: libacl' \
  'Depends: +libattr' \
  'Source-Makefile: feeds/packages/utils/attr/Makefile' \
  'Package: libattr' > "$work_dir/.packageinfo"

mkdir -p "$work_dir/source/scripts" "$work_dir/source/tmp"
cp "$source_dir/scripts/metadata.pm" "$work_dir/source/scripts/metadata.pm"
cp "$work_dir/.packageinfo" "$work_dir/source/tmp/.packageinfo"
perl "$repo_root/scripts/verify-package-closure-v0.1.pl" --enable-missing \
  "$work_dir/source" "$work_dir/.config" "$work_dir/required-packages"
grep -qx 'CONFIG_PACKAGE_libacl=y' "$work_dir/.config"
grep -qx 'CONFIG_PACKAGE_libattr=y' "$work_dir/.config"
perl "$repo_root/scripts/verify-package-closure-v0.1.pl" \
  "$work_dir/source" "$work_dir/.config" "$work_dir/required-packages"
printf '%s\n' 'DoorNet2-V0.1 conditional package-closure regression: PASS'
