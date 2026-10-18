# DoorNet2 Custom Firmware

This public repository builds `DoorNet2-V0.1` for EmbedFire DoorNet2 (RK3399,
1 GB DDR3L) from standard OpenWrt. It is not an iStoreOS fork.

## Non-negotiable rules

- The repository is public and its default branch is `main`.
- Formal firmware compilation is allowed only on GitHub-hosted Actions.
  Local work is limited to editing, static validation, and cloud-log/artifact
  inspection.
- Use the fixed OpenWrt source in `config/source.env`; do not silently update
  it.
- iStore is an application feed only. Do not add iStoreOS base-system feeds,
  packages, or an iStoreOS upgrade route.
- A clean installation must use LAN `192.168.100.1/24`. Same-line upgrades
  preserve user network configuration. Cross-system iStoreOS upgrades are not
  supported unless explicitly tested.
- Keep DoorNet2-specific RK3399 DTS, U-Boot, SPL/TPL, BL31 and image-layout
  work separate from other boards. Never substitute R76S/RK3576 settings.
- Do not write a real device's eMMC, partitions, bootloader, or firmware
  without separate user authorization.
- Cloud compilation is not hardware acceptance. Boot, DDR3L training,
  Ethernet, service lifecycle, DNS routing, WeChatDirect behavior and OTA
  recovery remain `NOT TESTED` without real-device evidence.

## Naming

Workflow, job, formal artifact prefix, release title and metadata use exactly
`DoorNet2-V0.1`. The Actions run name is
`DoorNet2-V0.1 #${{ github.run_number }}`.
