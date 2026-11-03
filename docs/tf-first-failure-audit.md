# DoorNet2 V1.0.0 TF-first 启动故障审计

审计对象：DoorNet2 RK3399、1GB DDR3L、`rockchip/armv8/embedfire_doornet2`。
审计范围是源码、U-Boot 2025.10 补丁、V1.0.0 Run #4 产物和已报告的真实现象。
没有执行 eMMC/U-Boot 写入、sysupgrade 或本地完整固件编译。

## 结论摘要

V1.0.0 Run #4 的 TF raw 镜像结构通过，但“普通上电时 TF 必然优先”没有被
证明，且真实设备目前继续进入原有 eMMC 系统。当前最有证据支持的结论是：

1. TF 镜像自身包含有效的 RK3399 idbloader、U-Boot FIT、boot 分区、rootfs、
   动态 `PARTUUID` 和 TF-first 的 U-Boot distro 扫描顺序。
2. 这些设置只在该 TF 镜像的 TPL/SPL/U-Boot 被执行后才有作用。
3. RK3399 BootROM 的初始介质选择发生在上述阶段之前；如果它选择了仍然有效的
   eMMC 引导链，TF 镜像中的 `boot_targets`、`CONFIG_ENV_IS_NOWHERE` 和 DTB
   无法覆盖那个已经运行的旧引导链。
4. 因此本次现象不能通过“再次把 `mmc0 mmc1` 写进 TF 镜像”解决。没有串口，
   也还没有当前系统的只读 LAN 报告，无法把故障精确归类到 BootROM、旧 SPL、
   旧 U-Boot 或 TF DDR 训练失败中的某一个。

## 启动链

```text
RK3399 reset
    │
    ▼
BootROM：选择并加载初始介质的 TPL/SPL
    │       （可能是 eMMC，也可能是 SD/TF；TF 镜像无法修改这一阶段）
    ▼
TPL：DDR3L 初始化
    │
    ▼
SPL：加载 BL31/U-Boot proper
    │    /chosen/u-boot,spl-boot-order 仅在此阶段的 SPL 生效
    ▼
U-Boot proper：distro boot_targets=mmc0 mmc1 ...
    │            mmc0=SD/TF，mmc1=eMMC（本项目编译的 U-Boot DTB）
    ▼
boot.scr：从当前 `${devtype} ${devnum}:2` 读取 PARTUUID
    │
    ▼
Linux rootfs：TF 的 `d0021000-02` 或其他实际启动介质的分区 UUID
```

RK3399 家族启动资料将 BootROM、TPL、SPL、U-Boot proper 区分为先后阶段；
U-Boot 源码也把 RK3399 BootROM 返回的 eMMC 和 SD 控制器路径分别映射到
`/mmc@fe330000` 和 `/mmc@fe320000`。这说明 `mmc0/mmc1` 是运行中 U-Boot
的设备别名，不是对 BootROM 初始选择的重写。

## 逐项根因判定

| 类别 | 当前判定 | 证据 | 尚缺证据 |
|---|---|---|---|
| A. BootROM 直接选择 eMMC | 高可能，未证实 | 设备正常回到原 eMMC；RK3399 BootROM 先于 TF U-Boot；TF 结构校验通过 | 串口早期日志、BootROM source id 或等价硬件证据 |
| B. BootROM 加载 eMMC 旧 SPL/TPL | 高可能，未证实 | eMMC 原系统仍可启动；TF 镜像无法替换 eMMC loader | TPL/SPL 串口日志、当前 eMMC 启动介质只读信息 |
| C. eMMC 旧 U-Boot 优先 eMMC | 可能，未证实 | 野火官方明确记录 eMMC+SD 可能出现“SD U-Boot/kernel + eMMC rootfs”混合；当前项目不能控制旧 U-Boot 环境 | U-Boot `printenv`、`mmc list`、启动日志或 Linux `/proc/cmdline` |
| D. TF/eMMC 映射与源码假设不一致 | 静态不支持；硬件仍未证实 | Run #4 FIT DTB 的 `mmc0=/mmc@fe320000`、`mmc1=/mmc@fe330000` 通过校验 | 目标板实际运行的 DTB/U-Boot 输出 |
| E. TF SPL/FIT/boot.scr 错误 | 静态不支持 | MBR、SPL 区域、FIT、boot 分区、rootfs、FIT hash、boot.scr 全部通过 | TF 上电时是否真正执行、DDR3L 是否训练成功 |
| F. Linux 根 PARTUUID 错误 | 静态不支持；运行未证实 | boot.scr 动态执行 `part uuid ${devtype} ${devnum}:2 uuid`，raw root PARTUUID 为 `d0021000-02` | TF 启动后的 `/proc/cmdline`、`findmnt`、`blkid` |

“高可能”不是“已证实”。没有串口和只读 LAN 信息时，A/B/C 不能进一步拆分。

## 已完成的静态修复与检查增强

本次没有修改启动链策略，也没有触碰设备。原因是现有源码策略已经覆盖了
“当本镜像的 SPL/U-Boot 正在运行时”的 TF-first 路径；改变它不能合法地覆盖
eMMC 中旧的 BootROM 后续链。为避免把静态结果冒充硬件结论，本次完成：

- `scripts/verify-doornet2-boot.py` 现在可直接检查 raw 或 gzip 镜像；
- 验证编译后 FIT DTB 的 `/chosen/u-boot,spl-boot-order`，要求实际值为
  `same-as-spl`、TF、eMMC，而非只检查源码文本；
- 将输出改为“conditional TF-first”，明确列出 BootROM、旧 eMMC loader、
  DDR3L 和 eMMC fallback 仍为 `NOT TESTED`；
- 修正文档中“源码声明即普通上电 TF-first”的过度表述；
- 增加 V1.0.0 源码门禁，防止未来删除 SPL 启动顺序声明。

## 为什么暂不重新构建

当前没有证据表明另一个 TF 镜像可以在不改变 eMMC 引导链的情况下改变
BootROM 的普通上电选择。盲目重建只会生成结构相同、无法解释当前现象的
新镜像，不符合项目“每次失败先定位根因”的要求。因此本阶段不触发新的
GitHub Actions 完整编译，也不发布新版本。

如果后续只读报告或串口证明是“TF 镜像已执行但映射/脚本错误”，再针对该证据
修改源码并用 GitHub Actions 生成新的版本；如果证明必须改变 eMMC 中的 U-Boot，
则必须单独取得批准，本项目不会自动执行。

## 当前安全下一步

允许且建议：

- 对当前 eMMC 系统执行 `docs/lan-only-acceptance.md` 的只读 SSH 收集；
- 收集 `/proc/cmdline`、`findmnt`、`/proc/partitions`、`ubus call system board`、
  `dmesg`/`logread` 中可访问的启动介质信息；
- 若用户之后选择硬件路径，先记录野火 MR/Flash 按键方案的风险边界，仍不擦除
  eMMC、不写 U-Boot、不执行 sysupgrade。

禁止：

- `dd` 写入 eMMC、`mtd`、`fw_setenv`、`sysupgrade`、分区调整；
- 用“能进入原系统”推断 TF 已启动；
- 在没有新的技术修复依据时重复完整 Actions 编译。

## 状态

- 源码审查：`STATIC TESTED`
- Run #4 TF raw/gzip 结构：`BUILD VERIFIED`
- TF 镜像完整性：`BUILD VERIFIED`（此前独立 SHA256 已通过）
- TF 实际启动：`HARDWARE TESTED — FAIL/NOT BOOTED FROM TF`（用户报告）
- BootROM/TPL/SPL/U-Boot 具体失败阶段：`NOT TESTED`
- 网络、LuCI、iStore、插件、DNS、OTA：`NOT TESTED`
- eMMC/U-Boot 修改：未执行
