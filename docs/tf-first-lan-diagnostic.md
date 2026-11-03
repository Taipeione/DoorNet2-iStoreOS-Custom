# DoorNet2 TF-first LAN-only 诊断报告

收集日期：2026-11-03（Asia/Shanghai）
项目提交：d68bd9701a76156e2c809ac5ee04a0c1b140d955
安全范围：仅进行 Mac 本地路由、ARP、HTTP、SSH 连接测试；没有执行任何远端
写入、重启、sysupgrade、fw_setenv、mtd 或磁盘操作。

## 1. 结论摘要

当前 Mac 位于 192.168.50.0/24，地址为 192.168.50.198，默认网关为
192.168.50.1。192.168.50.1 返回 LuCI 页面，SSH 握手返回 Dropbear，
因此它是当前最可能的 DoorNet2/OpenWrt 地址候选。

但是，现有本地 SSH 密钥未被接受：

    root@192.168.50.1: Permission denied (publickey,password).

所以本阶段没有取得设备上的 /proc/cmdline、挂载表、MMC、Device Tree、
dmesg 或 fw_printenv 输出。根文件系统来源、TF 是否被 Linux 识别、是否
存在混合启动，全部保持 UNKNOWN / NOT TESTED，不能根据 LuCI 页面或“能进
原系统”推断。

## 2. 本机网络身份

### 命令

    route -n get default
    ifconfig
    arp -an

### 关键原始输出

    route to: default
    destination: default
    mask: default
    gateway: 192.168.50.1
    interface: en1
    flags: <UP,GATEWAY,DONE,PRCLONING,GLOBAL>

    en1: ...
        inet 192.168.50.198 netmask 0xffffff00 broadcast 192.168.50.255
        status: active

ARP 表中可见 192.168.50.1 以及其他局域网主机。为了避免把用户局域网的
MAC 地址写入公开项目文档，本报告不保存其他主机的硬件地址。

## 3. IP 身份确认

### LuCI HTTP 只读检查

命令：

    curl -k -m 5 -sS http://192.168.50.1/

页面文本中包含：

    LuCI - Lua Configuration Interface

HTTP 响应为 200 OK。该证据确认 192.168.50.1 是一个 OpenWrt/LuCI
管理端候选，但还不能确认其具体 DoorNet2 型号或当前启动介质。

### SSH 服务识别

命令：

    ssh -vv -o BatchMode=yes -o ConnectTimeout=5 \
      -o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=yes \
      root@192.168.50.1 'printf "SSH_READ_ONLY_TEST=PASS\n"'

关键输出：

    Connecting to 192.168.50.1 [192.168.50.1] port 22.
    Connection established.
    remote software version dropbear
    Server host key: ssh-ed25519
    The fingerprint for the ED25519 key sent by the remote host is
    SHA256:NKumj4lJXTU7u4d5VrYgBSxqQyJrCfPRFmZeHRsjBt0.
    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!
    Host key verification failed.

项目中原有 known_hosts 对该地址保存了不同的旧主机密钥。没有自动删除或
覆盖本地记录。

为排除仅是本地旧 host key 阻止连接，执行了一次不写入 known_hosts 的连接
测试：

    ssh -o BatchMode=yes -o ConnectTimeout=5 \
      -o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      root@192.168.50.1 'printf "SSH_READ_ONLY_TEST=PASS\n"'

原始结果：

    root@192.168.50.1: Permission denied (publickey,password).

该命令没有执行远端 shell，也没有修改设备或持久化本地 SSH 配置。

## 4. 远端只读采集状态

下列项目因 SSH 认证未通过，均未执行：

| 项目 | 状态 |
|---|---|
| /etc/openwrt_release、/etc/os-release | NOT COLLECTED |
| uname -a、ubus call system board | NOT COLLECTED |
| /proc/cmdline | NOT COLLECTED |
| /proc/mounts、mount、df | NOT COLLECTED |
| /proc/partitions、/dev/mmc*、blkid | NOT COLLECTED |
| dmesg/logread 中 mmc、rootfs、PARTUUID | NOT COLLECTED |
| /sys/class/mmc_host/ | NOT COLLECTED |
| Device Tree aliases | NOT COLLECTED |
| fw_printenv | NOT RUN；没有确认工具和配置 |

因此当前不能判断：

- Linux 根文件系统来自 eMMC 还是 TF；
- TF 是否被 Linux 识别；
- TF 是否有 boot 分区；
- 是否存在 TF U-Boot/kernel + eMMC rootfs 混合启动；
- 当前运行的 U-Boot 环境是否包含 eMMC-first 顺序。

## 5. 待凭据可用时的完整只读命令

以下命令已经在项目 LAN-only 方案中审查，待用户提供当前系统已有的 SSH
凭据后执行。它们只读取信息，不包括重启、UCI 写入、环境写入或分区写入：

    TARGET_IP="192.168.50.1"
    REPORT="$HOME/Desktop/doornet2-readonly-report.txt"
    ssh -o ConnectTimeout=5 -o NumberOfPasswordPrompts=1 \
      -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
      root@"$TARGET_IP" 'sh -s' <<'REMOTE' | tee "$REPORT"
    set +e
    section() { printf '\n===== %s =====\n' "$1"; }

    section IDENTITY
    cat /etc/openwrt_release 2>&1
    cat /etc/os-release 2>&1
    uname -a 2>&1
    ubus call system board 2>&1

    section BOOT_AND_MOUNTS
    cat /proc/cmdline 2>&1
    cat /proc/mounts 2>&1
    cat /proc/partitions 2>&1
    mount 2>&1
    df -h 2>&1

    section MMC_AND_BLOCKS
    blkid 2>&1
    ls -l /dev/mmc* /dev/disk/by-partuuid 2>&1
    find /sys/class/mmc_host -maxdepth 3 -type f -o -type l 2>&1
    for f in /sys/class/mmc_host/*/*/name \
             /sys/class/mmc_host/*/*/type \
             /sys/class/mmc_host/*/*/manfid \
             /sys/class/mmc_host/*/*/serial \
             /sys/class/mmc_host/*/*/cid \
             /sys/class/mmc_host/*/*/csd; do
        [ -r "$f" ] && printf '%s=' "$f" && cat "$f"
    done

    section DEVICE_TREE
    for f in /proc/device-tree/aliases/mmc0 \
             /proc/device-tree/aliases/mmc1 \
             /proc/device-tree/chosen/bootargs \
             /proc/device-tree/model \
             /proc/device-tree/compatible; do
        if [ -r "$f" ]; then
            printf '%s=' "$f"
            tr '\000' ' ' < "$f"
            printf '\n'
        fi
    done

    section LOGS
    dmesg 2>&1 | grep -Ei 'mmc|sdhci|sdmmc|rootfs|PARTUUID|EXT4|squashfs' 2>&1
    logread 2>&1 | grep -Ei 'mmc|sdhci|sdmmc|rootfs|PARTUUID|EXT4|squashfs' 2>&1

    section UBOOT_ENV_READ_ONLY
    if command -v fw_printenv >/dev/null 2>&1; then
        fw_printenv 2>&1
    else
        echo 'fw_printenv=NOT_INSTALLED'
    fi
    REMOTE

fw_printenv 只有在设备已有正确 /etc/fw_env.config 时才有诊断价值；即使
可用，也只允许 fw_printenv，禁止 fw_setenv。

## 6. 当前启动链判定

| 判断项 | 当前结果 | 原因 |
|---|---|---|
| 当前设备 IP | 192.168.50.1，高可信候选 | LuCI + Dropbear + 默认网关；型号仍未由远端系统确认 |
| 当前系统 | OpenWrt/LuCI 候选 | HTTP 页面证据 |
| 根文件系统来源 | UNKNOWN | 未能通过 SSH 读取 /proc/mounts/cmdline |
| TF Linux 识别 | UNKNOWN | 未能读取 /sys/class/mmc_host、blkid、dmesg |
| TF 启动分区 | UNKNOWN | 未能读取分区和挂载信息 |
| TF/eMMC 混合启动 | UNKNOWN | 没有 /proc/cmdline、U-Boot 或 rootfs 证据 |
| BootROM/TPL/SPL/U-Boot 失败阶段 | NOT TESTED | 无串口，也无远端启动日志 |

## 7. 下一步所需证据

只需要当前原 eMMC 系统已有的 SSH 登录凭据；不需要串口、不需要刷写设备。
凭据可用后，重新执行第 5 节命令并回传报告。报告应保留：

- /proc/cmdline；
- /proc/mounts、/proc/partitions、blkid；
- /sys/class/mmc_host 设备名、类型、CID/CSD（如可读）；
- Device Tree aliases/mmc0、aliases/mmc1；
- mmc/sdhci/rootfs/PARTUUID 相关日志；
- fw_printenv 输出（若工具和配置存在）。

当前不建议重新构建固件。没有远端证据证明 TF 镜像已执行前，重复修改
boot_targets 或重新生成同类镜像不能区分 BootROM、旧 eMMC loader 和 TF
DDR 训练问题。

## 8. 安全状态

- 设备写入：未执行
- eMMC/U-Boot：未修改
- sysupgrade：未执行
- 重启：未执行
- fw_setenv：未执行
- 完整固件构建：未执行
- SSH 远端只读采集：因认证失败未执行
- 根文件系统来源：NOT TESTED
- TF 识别与混合启动：NOT TESTED

