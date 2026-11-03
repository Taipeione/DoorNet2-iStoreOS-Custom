# DoorNet2 cloud build history

This record describes only GitHub-hosted Actions runs from the public
repository. Local checks are not firmware-build evidence. Runs #1-#8 below
belong to the historical V0.1 workflow. The current main line is V1.0.1.
The V1.0.1 release is tagged from the successful build commit
`7243b4cb58a467e36d6f44d996de3f6b91bacc89`.
The public Actions API exposes V1.0.0 runs #1-#4 and V1.0.1 runs #1-#3; no
V0.1 Run #9 is present in the repository's public run inventory, so an
external handoff reference to that number is not treated as evidence. The old V0.1
run URLs below are retained as historical project records, but `gh run view`
currently reports them unavailable after the old workflow was removed; they
are not used as current build proof.

## V1.0.1 — diagnostic/static hardening release

| Run | Commit | Result | Evidence |
|---|---|---|---|
| [#1](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/41663687611) | `ad61712` | FAIL before compilation | The build script files were committed without executable mode. The first fatal error was `Permission denied` when Actions invoked `scripts/build-v1.0.1.sh`. Corrected in `7243b4c`; no firmware artifact was accepted. |
| [#2](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/41663983589) | `7243b4c` | CANCELLED during compilation | The run entered full OpenWrt compilation and produced no fatal build error before it was cancelled after prolonged monitoring. It produced no accepted firmware artifact and is not build evidence. |
| [#3](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/41670160344) | `7243b4c` | SUCCESS; released as v1.0.1 | Full GitHub-hosted build, static checks, artifact generation, SHA256 verification and Artifact upload passed. Artifact ZIP ID `13253373282`, digest `sha256:bfc6cb0a468138145b8721e557c3da38fff8680a536437ec84c894180f0d5338`. |

Run #3 BuildInfo binds the release to OpenWrt `v25.12.5`, commit
`f0a60eee2fe051741c643ea6118718aae1ef17fb`, target
`rockchip/armv8/embedfire_doornet2`, and LAN `192.168.100.1/24`.
Independent post-download checks reproduced the Artifact digest and verified
both raw images at 176160768 bytes with MBR `55aa`, disk signature
`0xd0021000`, root PARTUUID `d0021000-02`, non-empty RK3399 loader area, FIT
at 8 MiB, dynamic root PARTUUID commands and the DoorNet2 boot-source marker.
Hardware boot remains `NOT TESTED`; the release does not claim that the
unchanged eMMC BootROM/TPL/SPL path selects TF on ordinary power-on.

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

## V1.0.0 Run #1 — legacy source tree did not contain current build scripts

- Run: https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/39261403393
- Commit: `6355bcd2446a221dddb9108f8d37c8da23b6921f`
- Result: FAIL during the old Python syntax-check step because the V1.0.0
  scripts were not yet present in that commit. It produced no firmware.

## V1.0.0 Run #2 — case-sensitive configuration path

- Run: https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/41584219482
- Commit: `4ca186fb27c36d36b9ebf826431fe94bc29201bd`
- First fatal error: the build script requested
  `configs/doorNet2-v1.0.0.config`, while the tracked file was
  `configs/doornet2-v1.0.0.config`.
- Corrective action: normalize all active references to the tracked lowercase
  filename. No firmware artifact was produced.

## V1.0.0 Run #3 — U-Boot 2025.10 patch context

- Run: https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/41584416726
- Commit: `cfab258012ef90c36919b6495a5c611199396831`
- First fatal error: U-Boot package preparation rejected
  `998-doornet2-tf-first.patch` because upstream U-Boot 2025.10 writes the
  `BOOT_TARGETS` define with a tab, while the patch context required spaces.
- Corrective action: update only that patch context and verify both U-Boot
  patches against the exact upstream source before rebuilding. No firmware
  artifact was produced.

## V1.0.0 Run #4 — successful cloud build and checked artifact

- Run: https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/41585341831
- Commit: `0a2aa2062a23d7f7db4cc09296a4cfc04be5ca0e`
- Result: SUCCESS in 1h26m. Complete OpenWrt compilation, boot-chain
  verification, BuildInfo/Version generation, SHA256 verification and
  artifact upload all passed.
- Artifact: [DoorNet2-V1.0.0](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/41585341831/artifacts/13211258157)
- Artifact ZIP: 114857491 bytes; GitHub upload digest
  `f4e18f91760820719e9c143d5335404eb895dfb15f1a522273ff2c8a8169befb`.
- Firmware SHA256:
  - ext4: `e1769c034bd39a4bfc91a38950f7b9e0bb1a1430412c02e9aa6f0c7f6308d63a`
  - squashfs: `8bf718f5e6f651e2c18c78a076521b6dbc86f58ce16bb81ab809e6803675b64a`
- BuildInfo binds the artifact to OpenWrt `v25.12.5`, commit
  `f0a60eee2fe051741c643ea6118718aae1ef17fb`, target
  `rockchip/armv8/embedfire_doornet2`, and LAN `192.168.100.1/24`.
- This is cloud/source/artifact acceptance only. ROM boot order, DDR3L
  training, physical Ethernet, eMMC fallback and all runtime tests remain
  `NOT TESTED`; no formal Release has been created.
