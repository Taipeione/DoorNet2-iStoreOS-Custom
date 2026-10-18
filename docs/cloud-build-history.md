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
