# DoorNet2 LAN-only read-only acceptance plan

本文档面向没有 USB-TTL 串口线的 macOS 用户。所有命令都只读取当前
DoorNet2 状态，不执行 sysupgrade、配置修改、重启、U-Boot/eMMC 写入或
分区操作。当前阶段只确认“设备是否已经在 LAN 上运行、SSH 是否可达以及
当前系统/启动介质是什么”，不把这些结果误认为 V1.0.0 已经在实体设备上
启动。

## 1. Safety boundary

- 将 DoorNet2 的 LAN 口接到现有路由器的 LAN 口，不要接路由器 WAN 口。
- Mac 通过 Wi-Fi 或 Ethernet 接入同一台路由器，等待一至两分钟获取租约。
- 只使用当前系统已有的路由器账号和 DoorNet2 凭据，不重置密码。
- 不执行 sysupgrade、firstboot、jffs2reset、reboot、fw_setenv、mtd
  write、flashcp、ubiformat、dd of=...、parted 或 fdisk 写入模式。
- 不安装/删除软件包，不修改 UCI、防火墙、SSH 密钥、启动脚本、U-Boot
  变量、eMMC 扇区或任何分区。

下面的报告文件只写入 Mac 本机 Desktop，不写入 DoorNet2。

## 2. macOS：从路由器 DHCP 列表找到 DoorNet2 IP

### 2.1 查看路由器网关

在 macOS Terminal 执行以下只读命令：

```sh
route -n get default | awk '/gateway:/{print "router_gateway=" $2}'
networksetup -listallnetworkservices
ifconfig
arp -an
```

第一条会打印当前默认网关。然后用浏览器打开路由器管理页：

```sh
ROUTER_IP="$(route -n get default | awk '/gateway:/{print $2}')"
open "http://$ROUTER_IP"
```

### 2.2 在路由器页面查 DHCP 租约

在路由器的只读状态页面查找以下任意名称：

- DHCP leases / DHCP clients；
- LAN clients / Attached devices；
- Connected devices / Client list。

根据 hostname、厂商、MAC 地址或最近租约时间找到 DoorNet2。hostname
可能为空或是通用名称；如果路由器显示 MAC 地址，应与设备标签或库存记录
核对。复制该行的准确 IPv4 地址，不要根据名称猜 IP。

若有多个候选项，记录候选 IP、MAC 和 hostname，不要猜测。若列表没有
DoorNet2，记录 DHCP_ENTRY=NOT_FOUND 后停止本阶段；这不等于固件无法
启动，也可能是静态地址、网络未启动、运行的是其他系统或网线/端口不对。

## 3. macOS：SSH 连接测试

将下面示例地址替换为 DHCP 列表中的准确地址。TARGET_IP 只是 Mac 的
shell 变量，不会修改网络配置：

```sh
TARGET_IP="192.168.100.123"
ping -c 3 -W 1000 "$TARGET_IP"
nc -vz -w 3 "$TARGET_IP" 22
nc -vz -w 3 "$TARGET_IP" 80
nc -vz -w 3 "$TARGET_IP" 443
```

macOS 的 ping -W 1000 使用 1000 ms 等待时间。端口 22 打开只说明有
SSH 服务监听，不证明运行的是 DoorNet2-V1.0.0。

使用当前系统已有凭据执行一次无害的单命令 SSH 测试：

```sh
ssh -o ConnectTimeout=5 -o NumberOfPasswordPrompts=1 \
  root@"$TARGET_IP" 'printf "SSH_READ_ONLY_TEST=PASS\\n"'
```

首次出现主机密钥确认时，先确认该地址确实来自 DoorNet2 的 DHCP 行，再
接受密钥。不要用 SSH 执行 uci set、service restart、reboot、sysupgrade
或任何写入命令。

若 22 端口关闭或 SSH 认证失败，记录 SSH=UNREACHABLE 或
SSH=AUTH_FAILED，不要重置凭据，也不要反复要求串口。

## 4. 完整只读信息收集

只有在单命令 SSH 测试成功后才执行。该脚本通过 OpenWrt 的
`/bin/sh` 接收标准输入，不创建远程文件。可选的 `blkid`、`lsblk`、
`ss`、`netstat` 都有检测，不存在时不会中断报告。

最后的 `tee` 只在 Mac Desktop 保存报告副本，不保存密码、私钥或
Dropbear 主机密钥：

```sh
REPORT="$HOME/Desktop/doornet2-readonly-report.txt"
ssh -o ConnectTimeout=5 -o NumberOfPasswordPrompts=1 root@"$TARGET_IP" 'sh -s' <<'REMOTE' | tee "$REPORT"
set +e

section() { printf '\n===== %s =====\n' "$1"; }

section IDENTITY
printf 'collection=read-only\n'
cat /etc/openwrt_release 2>&1
cat /etc/os-release 2>&1
uname -a 2>&1
cat /proc/cmdline 2>&1
ubus call system board 2>&1

section STORAGE_AND_BOOT
cat /proc/partitions 2>&1
cat /proc/mtd 2>&1
cat /proc/mounts 2>&1
mount 2>&1
df -h 2>&1
ls -l /dev/mmc* /dev/disk/by-partuuid 2>&1
if command -v blkid >/dev/null 2>&1; then blkid 2>&1; else echo 'blkid=NOT_INSTALLED'; fi
if command -v lsblk >/dev/null 2>&1; then lsblk 2>&1; else echo 'lsblk=NOT_INSTALLED'; fi

section NETWORK_KERNEL_VIEW
ip addr show 2>&1
ip route show 2>&1
ip -6 route show 2>&1
cat /etc/resolv.conf 2>&1
ubus call network.interface dump 2>&1

section NETWORK_UCI_VIEW
uci -q show network 2>&1
uci -q show firewall 2>&1
uci -q show dhcp 2>&1
uci -q show system 2>&1
uci -q show dropbear 2>&1
if [ -f /tmp/dhcp.leases ]; then cat /tmp/dhcp.leases; fi

section SERVICES_AND_LISTENERS
for service in dropbear uhttpd dnsmasq odhcpd; do
    if [ -x "/etc/init.d/$service" ]; then
        "/etc/init.d/$service" enabled >/dev/null 2>&1
        printf '%s_enabled_rc=%s\n' "$service" "$?"
    else
        printf '%s_init=NOT_PRESENT\n' "$service"
    fi
done
if command -v ss >/dev/null 2>&1; then
    ss -lntup 2>&1
elif command -v netstat >/dev/null 2>&1; then
    netstat -lntup 2>&1
else
    cat /proc/net/tcp /proc/net/tcp6 2>&1
fi
ps w 2>&1

section LOGS
if command -v logread >/dev/null 2>&1; then logread | tail -n 200; fi
dmesg 2>&1 | tail -n 200
REMOTE
printf 'REPORT_FILE=%s\n' "$REPORT"
```

若报告含密码、令牌、私钥或 Dropbear 主机密钥内容，发送前必须删除这些
行；不要发送 `/etc/dropbear/*_host_key` 内容。应保留系统身份、
`/proc/cmdline`、存储、网卡、路由、UCI、服务状态和错误行。

## 5. 发回 Codex 的报告格式

将下面的摘要和报告文本一起发送；没有证据的字段填写 `UNKNOWN` 或
`NOT_TESTED`，不要凭记忆填写：

```text
DOORNET2_READONLY_REPORT
macOS_model_and_version=
router_model=
router_gateway=
DHCP_ENTRY=FOUND | NOT_FOUND | AMBIGUOUS
target_ip=
target_hostname_or_mac=
LAN_port_used=
PING=PASS | FAIL
TCP_22=OPEN | CLOSED | TIMEOUT
TCP_80=OPEN | CLOSED | TIMEOUT
TCP_443=OPEN | CLOSED | TIMEOUT
SSH=PASS | AUTH_FAILED | UNREACHABLE | NOT_RUN
running_os=
board_model=
openwrt_release=
root_filesystem_and_mounts=
boot_device_and_partitions=
proc_cmdline=
NOTES=
```

## 6. 命令兼容性审查

Mac 端使用 macOS 自带的 `route`、`networksetup`、`ifconfig`、
`arp`、`ping`、`nc`、`ssh`、`open` 和 `tee`，
不需要 Homebrew 或本地编译。

远端使用 OpenWrt 标准的 BusyBox `/bin/sh`、`cat`、`ip`、`mount`、
`df`、`ps`、`uci`、`ubus`、`/proc` 和 `logread`。
脚本使用 `ip addr show`、`ip route show`，不在 macOS 主机上调用
Linux 专有的 `ip` 命令；远端可选工具均已加保护判断。

## 7. TF 卡独立启动：静态审查与安全边界

Run #4 固件的静态检查已证明：

- U-Boot 启动目标为 `mmc0 mmc1 ...`，内置 U-Boot DTB 将 TF/SD 映射为
  `mmc0`、eMMC 映射为 `mmc1`；
- SPL 启动顺序包含 SD/TF 控制器并优先于 eMMC；
- 镜像包含预期的 32 MiB boot 分区、64 MiB root 起始偏移、8 MiB FIT/U-Boot
  位置、动态 root `PARTUUID` 和 MBR signature `0xD0021000`；
- U-Boot 使用 `CONFIG_ENV_IS_NOWHERE`，不依赖向 eMMC 写入持久化环境。

以上都是源码和镜像静态证据，不能证明 BootROM 实际选择 TF、DDR3L 训练、
电源稳定性、TF 卡兼容性、物理网口或 eMMC fallback。

未来若获准进行安全测试，只考虑 TF-only 方案：

1. 先取得本文件第 4 节的完整只读报告，记录当前启动介质、分区布局和恢复路径。
2. 使用独立 TF 卡准备已验证的 Run #4 镜像，不触碰 DoorNet2 eMMC 或 U-Boot 区域。
3. 保持 eMMC 物理和逻辑内容不变，不执行 sysupgrade，不写启动变量。
4. 若没有串口且 TF 启动后没有 LAN 响应，只记录为启动结果不明，停止，不通过
   修改 U-Boot/eMMC 来“补救”。

本阶段不执行 TF 卡写入或实体启动尝试，物理测试继续标记为 `NOT TESTED`。

## 8. Current evidence status

| Check | Status |
|---|---|
| Run #4 firmware/static boot-chain verification | PASS |
| macOS DHCP-list procedure and read-only report script | STATIC REVIEW PASS |
| DoorNet2 LAN address | NOT TESTED |
| SSH reachability and credentials | NOT TESTED |
| Current OS/U-Boot/boot medium/partitions | NOT TESTED |
| TF-only boot without eMMC modification | NOT TESTED |
| LuCI, iStore, DHCP/WAN, IPv4/IPv6 and DNS on hardware | NOT TESTED |
| Plugin lifecycle, WeChatDirect and OTA on hardware | NOT TESTED |
