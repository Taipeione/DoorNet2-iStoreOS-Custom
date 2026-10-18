# DoorNet2-V0.1 cloud build history

This record describes only GitHub-hosted Actions runs from the newly created
public repository. Local checks are not firmware-build evidence.

| Run | Commit | Result | Root cause and remediation |
|---|---|---|---|
| [#1](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/39097977668) | `2a7cb1ceeee2533918d4cecd208c65baab1047cd` | FAIL before downloads or compilation | Feed installation completed, but the first `make defconfig` removed `luci-compat`; the build's immediate assertion stopped. Required roots were only supplied before the first normalization. The replacement flow re-applies required roots after feed-aware normalization, runs one final Kconfig pass, materializes the deterministic package-metadata closure, then rechecks it before downloads and compilation. No firmware artifact exists. |
## Run #2 — failed after full-build entry

- Commit: `87a21be0ea011308c256ec63ca0e3530386a35bd`
- Run: https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/39098278903
- Result: the `luci-compat` configuration issue from run #1 did not recur. The
  feed was installed and the build entered the full `make world` phase.
- First fatal error: the DoorNet2 U-Boot DTS patch included
  `rk3399-opp.dtsi`, which is absent from the U-Boot 2025.10 source used by
  the fixed OpenWrt revision. The U-Boot DTC stopped at that include.
- Corrective action: remove that U-Boot-only invalid include and reject it in
  the pre-build verification script. No firmware artifact was produced.

## Run #3 — failed during U-Boot package preparation

- Commit: `fbfd1d3b75bfe5e070fefecb9d1a035b4c495182`
- Run: https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/39104783578
- First fatal error: after removal of one added DTS line, the unified-diff hunk
  header still claimed 750 added lines. Git therefore rejected the patch as
  corrupt at line 906 before U-Boot source preparation.
- Corrective action: correct the hunk count to 749 and make `git apply
  --numstat` a mandatory static precheck. No firmware artifact was produced.

## Run #4 — failed after kernel DTS and U-Boot preparation

- Commit: `b60d3f4fac8a9277041ca2bb11c203e43bd72009`
- Run: https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/39105718113
- Evidence: the cloud log shows both
  `rk3399-doornet2.dtb` generation and successful staging of
  `doornet2-rk3399-u-boot-rockchip.bin`; the U-Boot patch therefore applied
  and built on the fixed OpenWrt/U-Boot sources.
- First fatal error: OpenWrt stopped while packaging `tar-1.35-r1.apk` because
  `libacl.so.1` was not supplied. `tar` enables POSIX ACL support by default
  when `USE_FS_ACL_ATTR` is enabled, which creates the metadata edge
  `+PACKAGE_TAR_POSIX_ACL:libacl`.
- Root cause: the initial closure tool deliberately ignored all conditional
  metadata edges and only traversed hand-maintained roots. It therefore missed
  a dependency of an OpenWrt-selected default package.
- Corrective action: evaluate simple enabled `CONFIG_SYMBOL:package` edges
  from the final configuration and traverse all selected packages. The added
  regression fixture proves that enabled tar ACL support materializes `libacl`
  and its `libattr` dependency before downloads or compilation. No firmware
  artifact was produced by run #4.
