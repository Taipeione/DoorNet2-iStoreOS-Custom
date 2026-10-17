#!/bin/sh
set -eu

rootfs=${1:-}
[ -n "${2:-}" ] && policy_script=$2 || policy_script=
[ -n "$rootfs" ] && [ -d "$rootfs" ] || {
	echo "usage: $0 /path/to/built/rootfs" >&2
	exit 2
}
[ "$(id -u)" -eq 0 ] || {
	echo "This integration test requires root for an isolated chroot." >&2
	exit 2
}
command -v chroot >/dev/null 2>&1 || {
	echo "chroot is required." >&2
	exit 2
}

release_description=$(sed -n "s/^DISTRIB_DESCRIPTION=//p" "$rootfs/etc/openwrt_release")
[ "$release_description" = "'DoorNet2-V0.1'" ] || {
	echo "Unexpected firmware display name: $release_description" >&2
	exit 1
}
grep -Fq 'json_add_string ipaddr 192.168.100.1' "$rootfs/etc/board.d/99-lan-ip"
grep -Fq 'json_add_string netmask 255.255.255.0' "$rootfs/etc/board.d/99-lan-ip"
grep -Fq 'pi_ip="192.168.100.1"' "$rootfs/lib/preinit/00_preinit.conf"

test_root=$(mktemp -d "${TMPDIR:-/tmp}/doornet2-policy-test.XXXXXX")
trap 'rm -rf "$test_root"' EXIT HUP INT TERM
cp -a "$rootfs/." "$test_root/"
[ -z "$policy_script" ] || cp "$policy_script" "$test_root/usr/libexec/doornet2-policy"

uci() {
	chroot "$test_root" /sbin/uci -q "$@"
}

cp "$test_root/usr/share/passwall/0_default_config" "$test_root/etc/config/passwall"
cp "$test_root/usr/share/passwall2/0_default_config" "$test_root/etc/config/passwall2"

for config in passwall passwall2; do
	uci set "$config.WeChatDirect=shunt_rules"
	uci set "$config.WeChatDirect.remarks=WeChatDirect"
	uci set "$config.WeChatDirect.domain_list=domain:custom.example"
	uci set "$config.CNProxy=nodes"
	uci set "$config.CNProxy.protocol=_shunt"
	uci set "$config.CNProxy.shunt_group=CN"
	uci set "$config.CNProxy.WeChatDirect=_proxy"
	uci set "$config.CNMissing=nodes"
	uci set "$config.CNMissing.protocol=_shunt"
	uci set "$config.CNMissing.shunt_group=CN"
	uci set "$config.OtherGroup=nodes"
	uci set "$config.OtherGroup.protocol=_shunt"
	uci set "$config.OtherGroup.shunt_group=Other"
done
uci set doornet2.global.lan_ipv4=10.10.10.1

chroot "$test_root" /usr/libexec/doornet2-policy reconcile

for config in passwall passwall2; do
	[ "$(uci get "$config.WeChatDirect.remarks")" = "WeChatDirect" ]
	[ "$(uci get "$config.WeChatDirect.network")" = "tcp,udp" ]
	[ "$(uci get "$config.CNProxy.WeChatDirect")" = "_proxy" ]
	[ "$(uci get "$config.CNMissing.WeChatDirect")" = "_direct" ]
	! uci get "$config.OtherGroup.WeChatDirect" >/dev/null 2>&1
	domains=$(uci get "$config.WeChatDirect.domain_list")
	printf '%s\n' "$domains" | grep -Fqx 'domain:custom.example'
	printf '%s\n' "$domains" | grep -Fqx 'domain:wechat.com'
	[ "$(printf '%s\n' "$domains" | grep -Fxc 'domain:wechat.com')" -eq 1 ]
	[ "$(uci get "$config.@global[0].enabled")" = "0" ]
done
[ "$(uci get doornet2.global.lan_ipv4)" = "10.10.10.1" ]
[ "$(uci get doornet2.global.version)" = "DoorNet2-V0.1" ]

uci set passwall.@global[0].enabled=1
uci set passwall2.@global[0].enabled=1
chroot "$test_root" /usr/libexec/doornet2-policy reconcile
[ "$(uci get passwall.@global[0].enabled)" = "1" ]
[ "$(uci get passwall2.@global[0].enabled)" = "1" ]
uci set passwall.@global[0].enabled=0
uci set passwall2.@global[0].enabled=0
chroot "$test_root" /usr/libexec/doornet2-policy reconcile
[ "$(uci get passwall.@global[0].enabled)" = "0" ]
[ "$(uci get passwall2.@global[0].enabled)" = "0" ]

before=$(sha256sum "$test_root/etc/config/passwall" "$test_root/etc/config/passwall2")
chroot "$test_root" /usr/libexec/doornet2-policy reconcile
after=$(sha256sum "$test_root/etc/config/passwall" "$test_root/etc/config/passwall2")
[ "$before" = "$after" ]

echo "PASS: WeChatDirect merge, CN-group mapping, existing mapping preservation, disabled defaults, and repeat idempotence"
