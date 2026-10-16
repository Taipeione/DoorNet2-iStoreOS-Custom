# Reproducible V0.1 build

V0.1 is based on the iStoreOS 24.10.8 release line at commit `a405f0378aef729f0f250c94b18a34a09b7d8890`, using Linux 6.6.144. The source pin is recorded in [`config/source.env`](../config/source.env).

On macOS, [`scripts/build-v0.1.sh`](../scripts/build-v0.1.sh) runs the build inside Docker and copies the source into a Linux case-sensitive named volume. This is required by OpenWrt/iStoreOS and avoids compiling in the macOS native filesystem.

The local builder image is used only as a Linux build environment. No R76S board files, DTS, U-Boot configuration, partition layout, or network mapping are used by DoorNet2.

The build script applies the reviewed board files, adds the DoorNet2 image/device definition, adds the U-Boot patch, sets the clean-install LAN to `192.168.100.1/24`, runs static checks, then compiles the kernel, U-Boot, and full image.
