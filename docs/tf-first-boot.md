# DoorNet2 V1.0.1 TF 卡首次启动安装说明

本文档针对 DoorNet2 RK3399 1GB DDR3L，目标是用独立 TF 卡首次启动
DoorNet2-V1.0.1，同时保持原有 eMMC、eMMC 内的 U-Boot 和启动分区不变。

当前状态：

```text
BUILD VERIFIED
STATIC TESTED
HARDWARE BOOT TESTED: NOT TESTED
```

V1.0.0 曾出现“TF 卡写入和回读正确，但设备仍进入原 eMMC 系统”。V1.0.1
增加了启动来源诊断和静态门禁，但没有证据证明它能改变 RK3399 BootROM 或原
eMMC TPL/SPL/U-Boot 的初始介质选择。因此 V1.0.1 是可进行安全 TF 测试的
版本，不是已经完成硬件 TF-first 验收的版本。

## 1. 适用性结论

V1.0.1 Run #3 的两个 GitHub Actions 产物都不是单独的 rootfs，而是完整的
OpenWrt Rockchip whole-disk image，文件名沿用 sysupgrade 命名但不作为本项目
当前运行中 eMMC 系统的在线 sysupgrade 输入，包含：

- MBR 分区表和 DoorNet2 确定性磁盘签名 `0xD0021000`；
- 32 MiB 起始的 16 MiB boot 分区；
- 64 MiB 起始的 root 分区；
- 32 KiB 区域的 RK3399 SPL/idbloader；
- 8 MiB 位置的 U-Boot FIT；
- 动态 root `PARTUUID` 启动脚本；
- 在本镜像 U-Boot 已经执行时生效的 conditional TF-first 启动目标 `mmc0 mmc1 ...`；
- U-Boot DTB 中 TF/SD=`mmc0`、eMMC=`mmc1`；
- `CONFIG_ENV_IS_NOWHERE`，不需要向 eMMC 写持久化 U-Boot 环境。

因此，结构结论为：

`TF_IMAGE_STRUCTURAL_CHECK=PASS`

这不是实体启动结论。BootROM 是否选择 TF、DDR3L 是否训练成功、电源、
TF 卡兼容性、物理网口和无串口时的故障原因仍为 `NOT TESTED`。

## 2. 使用哪个 V1.0.1 镜像

第一次启动建议使用 squashfs：

| 镜像 | 适用性 | 压缩包 SHA256 | 解压后 raw image SHA256 |
|---|---|---|---|
| `DoorNet2-V1.0.1-squashfs.img.gz` | 推荐首次启动，根文件系统只读、写放大较小 | `e36b6d426a4fd77903fe01a520b98ff9e0bd4c7cb0e254b27c2c8550aab0246e` | `1b45c18dd778b75182ffa3ff2301872ac9e28438a7a5eb14b644513470b3d1c2` |
| `DoorNet2-V1.0.1-ext4.img.gz` | 结构同样合格，可用于需要 ext4 根分区的场景 | `add681da5434d3ffdb054b96592c03dd11e37cde4137dfea147e495b864b7fa6` | `eabd43935370e45cb61259ae471515bee49e2523e25113247faf4bbb3fa70368` |

两个解压后的 V1.0.1 镜像均为 176,160,768 字节。正式下载位置是：

[DoorNet2 V1.0.1 Release](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/releases/tag/v1.0.1)

构建记录：[GitHub Actions Run #3](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/41670160344)。

## 3. 与野火官方说明的对照

野火官方说明：

- DoorNet2 使用 MicroSD/TF 卡；
- SD 卡写入使用 Etcher，推荐 4GB 以上 Class 10 卡和读卡器；
- 启动时使用 5V3A Type-C 供电，首次启动可能需要约 2 至 3 分钟；
- 当 eMMC 和 SD 都有系统时，官方警告默认组合可能使用 SD 的 U-Boot/kernel
  但使用 eMMC 根文件系统；
- 官方可通过 Flash/MR 按键优先 SD，或擦除 eMMC 分区表，但后者会破坏
  eMMC，本文明确不采用。

官方参考：

- [野火 OpenWrt 镜像烧录](https://doc.embedfire.com/openwrt/user_manal/zh/latest/User_Manual/quick_start/imageflash.html)
- [野火 OpenWrt 第一次启动](https://doc.embedfire.com/openwrt/user_manal/zh/latest/User_Manual/quick_start/poweron.html)
- [野火 DoorNet2 产品说明](https://doc.embedfire.com/openwrt/user_manal/zh/latest/User_Manual/board_introduce/dn2_introduce.html)

V1.0.1 的 DoorNet2 专用 U-Boot/boot.scr 诊断改动针对上述 eMMC/SD 根文件
系统混用风险做了静态检查和启动来源记录。该修正已经通过云端镜像静态验证，
但没有替代实体启动测试。

### 普通上电与 MR/Flash 的区别

普通上电是不按键、不连接 USB 数据线的低风险首次观察方式；在 eMMC 已有系统
时不能保证 TF-first。若仍进入 eMMC，不能仅凭现象判断失败发生在 BootROM、
旧 SPL、旧 U-Boot、TF DDR 训练还是脚本阶段。

野火官方说明提供上电时使用 MR/Flash 按键或触点来优先 SD/TF 的方式，并说明
该方式保留 eMMC 系统。本文不自行规定按键持续时间，应以野火针对 DoorNet2
的说明为准。

Flash(F) 还用于配合 RKDevTool 向 eMMC 烧录。以下流程绝对不能混用：

- TF 启动测试：只接电源和网络，不连接 Mac/PC USB 数据线，不启动 RKDevTool，
  不进入 MASKROM；
- eMMC 烧录：Flash + USB/RKDevTool/MASKROM，可能修改 eMMC、U-Boot 或启动区域，
  本项目不授权也不执行。

按键优先 SD 的官方说明不包含 eMMC 擦除步骤，但当前项目没有串口或实机证据
证明它已在 V1.0.1 上成功，因此 MR/Flash 路径仍为 `NOT TESTED`。

## 4. macOS 下载和压缩包校验

### 4.1 下载

在浏览器打开上面的 V1.0.1 Release 页面，下载并解压
`DoorNet2-V1.0.1` 资产到例如：

```sh
cd "$HOME/Downloads/DoorNet2-V1.0.1"
```

如果 Mac 已安装 GitHub CLI，也可以使用：

```sh
gh release download v1.0.1 \
  --repo Taipeione/DoorNet2-iStoreOS-Custom \
  --pattern 'DoorNet2-V1.0.1-*' \
  --dir "$HOME/Downloads/DoorNet2-V1.0.1"
cd "$HOME/Downloads/DoorNet2-V1.0.1"
```

### 4.2 校验压缩包

推荐首次启动使用 squashfs：

```sh
IMAGE="$HOME/Downloads/DoorNet2-V1.0.1/DoorNet2-V1.0.1-squashfs.img.gz"
shasum -a 256 "$IMAGE"
```

输出必须完全等于：

```text
e36b6d426a4fd77903fe01a520b98ff9e0bd4c7cb0e254b27c2c8550aab0246e
```

也可以检查 Release 中的 `DoorNet2-V1.0.1-SHA256SUMS`。如果 SHA256
不一致，停止，不要解压或写入 TF 卡。

## 5. macOS 解压并校验 raw image

OpenWrt sysupgrade 文件末尾带有合法的 fwtool 元数据，因此 macOS 的
`gzip -dc` 可能打印 `trailing garbage ignored` 并返回状态码 2。
这是已知格式特征，不可只看退出码；必须同时检查 raw 大小和 SHA256。

```sh
RAW="$HOME/Downloads/DoorNet2-V1.0.1/DoorNet2-V1.0.1-squashfs.img"
gzip -dc "$IMAGE" > "$RAW"
GZIP_RC=$?
if [ "$GZIP_RC" -ne 0 ] && [ "$GZIP_RC" -ne 2 ]; then
  echo "gzip failed: $GZIP_RC" >&2
  exit 1
fi

test "$(stat -f %z "$RAW")" = "176160768"
shasum -a 256 "$RAW"
```

raw image SHA256 必须为：

```text
1b45c18dd778b75182ffa3ff2301872ac9e28438a7a5eb14b644513470b3d1c2
```

这一步只在 Mac 本地创建 raw 文件，不接触 DoorNet2。

## 6. 识别正确的 TF 设备

插入 TF 读卡器前后各执行一次：

```sh
diskutil list
```

找出插入 TF 后新增的外置设备，例如 `/dev/disk4`。必须确认：

- `Removable Media: Yes`；
- `Device Location: External` 或 USB；
- 容量与 TF 卡相符；
- 不是 Mac 内置 `disk0`；
- 不是包含其他重要数据的移动硬盘。

将设备路径只保存为变量，不要在此处写入：

```sh
TF_DISK="/dev/disk4"
diskutil info "$TF_DISK"
diskutil list "$TF_DISK"
```

如果不能唯一确认 TF 设备，停止，不执行下一步。不要使用
`diskutil eraseDisk`、`partitionDisk` 或任何不确定的磁盘路径。

## 7. 写入 TF 卡

确认 `TF_DISK` 是 TF 后，卸载该 TF 的卷，但不要弹出读卡器：

```sh
diskutil unmountDisk "$TF_DISK"
RAW_TF="/dev/rdisk${TF_DISK#/dev/disk}"
sudo dd if="$RAW" of="$RAW_TF" bs=4m
sync
```

macOS 原生 `dd` 通常不显示进度；写入期间可以按一次 Ctrl-T 查看进度。
该命令只写 `TF_DISK` 指定的 TF 卡，不会访问 DoorNet2 eMMC。若
`dd` 报错、容量不足或设备路径变化，立即停止，不重试到其他设备。

写入完成后不要立即拔卡，先做完整回读校验。

## 8. 刷写后完整回读验证

当前 raw image 长度为 176,160,768 字节，即 42 个 4 MiB 块：

```sh
sudo dd if="$RAW_TF" bs=4m count=42 2>/dev/null | shasum -a 256
```

输出必须完全等于：

```text
1b45c18dd778b75182ffa3ff2301872ac9e28438a7a5eb14b644513470b3d1c2
```

然后安全弹出：

```sh
diskutil eject "$TF_DISK"
```

若回读 SHA256 不一致，不要将 TF 插入 DoorNet2；更换读卡器/TF 卡并重新
从压缩包 SHA256 开始检查。

## 9. 首次 TF 启动边界

在 TF 回读校验通过后：

1. DoorNet2 断电，插入 TF 卡。
2. 保持原 eMMC 不拆除、不擦除、不分区、不写入。
3. 不连接 RKDevTool，不进入 MASKROM，不执行任何 eMMC 烧录。
4. 第一次先使用普通上电，不执行软件 `reboot`。
5. 使用稳定的 5V3A Type-C 电源，等待 2 至 3 分钟。
6. 观察电源灯、系统灯和网口灯，并记录时间。
7. 通过路由器 DHCP 列表或 Mac 直连 LAN 进行只读 SSH 探测。

普通上电是不按键、不连接 USB 数据线的低风险首次观察方式，但不能保证
TF-first。若仍进入 eMMC，不能仅凭现象判断失败阶段。

如果普通上电仍进入 eMMC，野火官方提供了上电时使用 MR/Flash 按键或触点来
优先 SD/TF 的方式，并说明该路径保留 eMMC 系统。本文不自行规定按键持续时间，
应以野火针对 DoorNet2 的说明为准。该路径只允许连接电源和网络，禁止连接
Mac/PC USB 数据线、启动 RKDevTool 或进入 MASKROM。

DoorNet2 的 Flash(F) 按键也用于配合 RKDevTool 向 eMMC 烧录。Flash 按键启动
路径与 USB/RKDevTool/MASKROM 烧录流程不能混用，后者可能修改 eMMC、U-Boot
或启动区域，本项目不授权也不执行。

无论普通上电还是 MR/Flash 路径，本项目当前均标记为 `NOT TESTED`。如果没有
串口且没有 LAN 响应，只记录 LED、供电、TF 卡和网线现象，停止下一步写入操作。

默认 LAN 配置目标是 `192.168.100.1/24`。如果 Mac 直接接 DoorNet2
LAN 口，需要在 macOS 网络设置中临时为该 Mac Ethernet 服务设置
`192.168.100.2/24`、不填网关；这是 Mac 本机的临时设置，不是设备写入。
完成测试后将 Mac Ethernet 恢复为 DHCP。

## 10. 首次启动后的只读验收

启动后不要执行 `sysupgrade`、`reboot` 或任何 UCI 写入。按
[LAN-only 只读方案](lan-only-acceptance.md)采集：

- `/etc/openwrt_release`、`ubus call system board`、`/proc/cmdline`；
- 根文件系统、`/proc/partitions`、`/proc/mounts`、PARTUUID；
- `ip addr`、路由、DHCP、DNS 和监听端口；
- `uci show network/firewall/dhcp`；
- Dropbear/uHTTPd 服务状态和最近日志。

尤其要核对 `/proc/cmdline` 的 root PARTUUID 与 TF 卡分区一致，确认
不是“TF 的 U-Boot/kernel + eMMC rootfs”的官方警告组合。

## 11. V1.0.1 实机启动验收记录模板

没有真实日志或截图的字段填写 `UNKNOWN` 或 `NOT_TESTED`，不要凭记忆填写。

```text
DOORNET2_V1.0.1_HARDWARE_ACCEPTANCE
date_time=
operator=
board_serial_or_asset_id=
macos_version=
router_model=
tf_image=squashfs | ext4
gzip_sha256=
raw_sha256=
raw_size_bytes=
tf_card_model_and_capacity=
tf_write_readback=PASS | FAIL | NOT_TESTED

emmc_modified=NO | UNKNOWN
uboot_modified=NO | UNKNOWN
sysupgrade_executed=NO
usb_data_cable_connected=NO | YES
rkdevtool_used=NO | YES
maskrom_entered=NO | YES | UNKNOWN
startup_method=NORMAL_POWER | MR_FLASH | UNKNOWN
startup_button_details=
power_supply=5V3A | OTHER | UNKNOWN
power_on_time=
wait_seconds=
led_observation=

dhcp_entry=FOUND | NOT_FOUND | AMBIGUOUS
target_ip=
ping=PASS | FAIL | NOT_TESTED
tcp_22=OPEN | CLOSED | TIMEOUT | NOT_TESTED
ssh=PASS | AUTH_FAILED | UNREACHABLE | NOT_TESTED
running_os=
board_model=
openwrt_release=
kernel=
proc_cmdline=
root_source=
root_partuuid=
tf_mmc_device=
emmc_mmc_device=
mixed_boot=YES | NO | UNKNOWN

lan_management=PASS | FAIL | NOT_TESTED
dhcp_service=PASS | FAIL | NOT_TESTED
wan=PASS | FAIL | NOT_TESTED
ipv4=PASS | FAIL | NOT_TESTED
ipv6=PASS | FAIL | NOT_TESTED
luci=PASS | FAIL | NOT_TESTED
istore=PASS | FAIL | NOT_TESTED
package_install=PASS | FAIL | NOT_TESTED
plugin_lifecycle=PASS | FAIL | NOT_TESTED
autostart=PASS | FAIL | NOT_TESTED
reboot_persistence=PASS | FAIL | NOT_TESTED
power_loss_persistence=PASS | FAIL | NOT_TESTED
dns=PASS | FAIL | NOT_TESTED
wechat_direct_policy=PASS | FAIL | NOT_TESTED
ota=PASS | FAIL | NOT_TESTED
backup_restore=PASS | FAIL | NOT_TESTED

HARDWARE_BOOT_TESTED=PASS | FAIL | NOT_TESTED
failure_stage=UNKNOWN
evidence_files=
notes=
```

## 12. 当前状态

- TF 镜像结构：PASS；
- V1.0.1 Release 压缩包和 raw image SHA256：PASS；
- macOS 写入/回读方案：静态审查 PASS；
- 实际 TF 启动：`HARDWARE BOOT TESTED: NOT TESTED`；V1.0.0 的历史现象是插卡上电后仍进入原 eMMC，具体失败阶段 NOT TESTED；
- eMMC/U-Boot 保持不变：待实机操作后由只读信息确认；
- LuCI、iStore、网络、DNS、插件和 OTA：NOT TESTED；
- 正式 Release：V1.0.1 已发布；
- sysupgrade：未执行。

## 附录 A：V1.0.0 历史记录

以下数据保留 V1.0.0 历史证据，不作为 V1.0.1 安装依据：

- GitHub Actions Run #4：
  [41585341831](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/41585341831)
- squashfs gzip SHA256：`8bf718f5e6f651e2c18c78a076521b6dbc86f58ce16bb81ab809e6803675b64a`
- squashfs raw SHA256：`abdcd08ba37c99fb3da7d9cb68859f3b7410bdfc3868eb2509a61ee476860e89`
- ext4 gzip SHA256：`e1769c034bd39a4bfc91a38950f7b9e0bb1a1430412c02e9aa6f0c7f6308d63a`
- ext4 raw SHA256：`adbe6fc0e2974f18b65b10fed9b6e4404bb40685bbc0c202d402c299be4e41c6`
- 两份 raw 镜像大小：`176160768` bytes；
- 已报告实机现象：V1.0.0 TF 卡写入和完整回读通过，但设备仍进入原有 eMMC 系统；失败阶段当时没有串口或有效 LAN SSH 证据，保持 `NOT_TESTED`。

