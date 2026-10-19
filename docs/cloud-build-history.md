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

## Run #5 — failed during rootfs package installation

- Commit: `1fac5d221f309b9e2727601743c79cd650edae08`
- Run: https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/39114017460
- Evidence: the run reached the rootfs `apk` installation phase. The earlier
  `libacl.so.1` failure did not recur, so the conditional-dependency repair was
  effective. `gettext_noop redefined` was only a compiler warning and did not
  stop the build.
- First fatal error: `apk` could not select `xz-utils`; package `xz-5.8.1-r1`
  requires it, but the package index did not contain the unselected meta
  package.
- Root cause: OpenWrt's xz Makefile declares `xz-utils` as a bare mandatory
  metadata dependency. The closure checker still handled only `+package` and
  `+CONFIG_SYMBOL:package` terms, so it did not materialize that dependency.
- Corrective action: traverse bare mandatory package edges as well, with a
  regression fixture for `xz -> xz-utils`. Failure diagnostics are now copied
  under non-hidden artifact names so final configuration and metadata are
  retrievable on every run. No firmware artifact was produced by run #5.

## Run #6 — full firmware compilation completed; artifact verifier failed

- Commit: `6e2242b00337fda25015136e40e92423699129b5`
- Run: https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/39122808591
- Evidence: `Compile complete firmware` completed successfully. The cloud log
  records both ext4 and squashfs sysupgrade images, the Rockchip/RK3399 target,
  the `embedfire,doornet2` supported-device entry and the 192.168.100.1
  preinit default. The run's final `.config` also contains `xz-utils`, so the
  bare-dependency repair from run #5 was effective.
- First fatal error: the post-build artifact verifier ran `gzip -t` directly
  on an OpenWrt sysupgrade image. OpenWrt had appended its validated `fwtool`
  JSON metadata trailer, so GNU gzip correctly decompressed the stream but
  returned status 2 for trailing data.
- Root cause: the project verifier treated a supported OpenWrt image-format
  feature as corruption.
- Corrective action: extract and validate the `fwtool` metadata (including
  DoorNet2 version, target, board and supported device); strip the known
  trailer from a disposable copy with the same OpenWrt `fwtool` tool; then run
  strict gzip integrity validation on that stripped stream. The original
  firmware remains unchanged. Release remains blocked until a replacement
  cloud run passes all artifact checks.

## Run #7 — full firmware compilation completed; checksum verifier failed

- Commit: `f882e09fcf747d9d00eb8f5976c530775b2beb0b`
- Run: https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/39128830265
- Evidence: the full cloud build completed successfully. Both generated
  `embedfire_doornet2` ext4 and squashfs sysupgrade images were copied to the
  formal `DoorNet2-V0.1-rk3399-1gb-ddr3l-*` names. The updated verifier also
  completed its fwtool metadata and stripped-gzip integrity checks before
  producing BuildInfo, Version and SHA256 files.
- First fatal error: `sha256sum -c` could not open each filename listed in
  `DoorNet2-V0.1-SHA256SUMS`.
- Root cause: the manifest deliberately contains portable relative names, but
  the verifier invoked `sha256sum -c` from the repository root rather than its
  output directory. The files existed under `artifacts/`; no image was absent
  or renamed.
- Corrective action: run both manifest generation and manifest verification
  from the artifact directory. This retains strict checksum verification and
  fails if any formal artifact is missing or altered. Release remains blocked
  until the replacement GitHub-hosted build passes.

## Run #8 — upstream dns2socks source asset unavailable

- Commit: `d0a9d2718232b08b1d19f7cb7f4a7a98a2e92cbc`
- Run: https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/39136273497
- Result: the checksum-directory repair was present in this commit, but did
  not run because the full firmware build failed earlier.
- First fatal error: PassWall's `dns2socks` recipe requested
  `SourceCode.zip` from the pinned upstream release URL. GitHub and each
  OpenWrt source mirror returned HTTP 404, ending with
  `package/feeds/passwall_packages/dns2socks/download`.
- Root cause: an upstream release asset referenced by the fixed PassWall feed
  revision was removed; this is unrelated to the DoorNet2 DTS, U-Boot,
  OpenWrt package closure, or artifact-verification changes.
- Corrective action: advance the exact-pinned `passwall_packages` feed by one
  verified upstream commit (`3ab138…` to its direct child `3ce5ce…`). That
  commit replaces only the unavailable download with the package's tracked
  source files. The next GitHub-hosted build must prove the package compiles
  and that no new dependency error replaces it.
