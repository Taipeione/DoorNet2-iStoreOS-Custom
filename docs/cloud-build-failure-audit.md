# DoorNet2-V0.1 cloud build failure audit

Audit date: 2026-10-17. This record is based on the GitHub Actions run API and
the complete retained logs for runs 5--18. It describes GitHub-hosted builds
only; no local compiler output is used as evidence.

## Scope and historical state

- Repository: `Taipeione/DoorNet2-iStoreOS-Custom`, branch `main`, public.
- Workflow and job identity: `DoorNet2-V0.1`.
- The final iStoreOS-route run, [#23](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/39058691038), was deliberately cancelled after the project formally moved to a standard OpenWrt base. Its logs/artifact are retained, but it is not a failure to remediate on the new route.
- Runs numbered 1--4 in the previous history document return GitHub API 404 as
  of this audit. Their published historical notes are therefore not treated as
  independently verified evidence here. Runs 5--18 are retrievable.

## Root-cause table

| Run | Commit | First fatal step and error | Classification | Follow-up and verification state |
|---|---|---|---|---|
| [#5](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/38995074665) | `7c3514b16df87836974b101cf0de475b37553ed8` | Configuration guard: unrelated default EasePi U-Boot variants still selected. | Board configuration isolation. | `09c2249` expanded the explicit exclusions; later runs passed this gate. |
| [#6](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/38995399526) | `09c224943a7c881ff2d69e9b31ca72a6d9bdebb7` | `target/linux/compile` could not use staging host `m4` / `m4sugar.m4`. | Build-stage ordering. | `a945a4e` installs host tools before the explicit kernel stage; run 7 reached the next stage. |
| [#7](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/38995835630) | `a945a4e0e2c528780692c49a91b8b5ef6ce0a22d` | `aarch64-openwrt-linux-musl-gcc` absent during explicit kernel compile. | Build-stage ordering. | `57740ed` installs the ARM64 toolchain first; later runs built the target. |
| [#8--#11](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/38999012619) | distinct commits | Cancelled, not failed. | Superseded runs; no failure root cause assigned. | Not evidence of a compiler defect. |
| [#12](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/39000585968) | `9676bf308a951f6732264df9c7bea277f1a14f10` | U-Boot binman: `rk3399_bl31.elf` missing. | RK3399 build ordering. | `6859840` builds the RK3399 TF-A variant before the DoorNet2 U-Boot variant; run 13 passed U-Boot and generated images. |
| [#13](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/39004794032) | `6859840daa06ab9beae48436769bd5b2ebe63c1f` | Full image generation completed, then target-policy integration failed because the final configuration did not contain the required plugin set. | Final configuration integrity. | `17aa8ee` added required package selection/gating; run 14 reached the final configuration gate. This partial image is not a release artifact. |
| [#14](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/39009194821) | `17aa8eee4b9584765072c99d74bfad9cc92f0e49` | `defconfig dropped required DoorNet2 package luci-app-passwall`. | Final configuration integrity. | `7791399` reapplied the reviewed package set after the second `defconfig`; run 15 compiled packages. |
| [#15](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/39009806064) | `77913992ef59af17a6b7aba575a56bedbd9d05cf` | `Package smartdns is missing dependencies`: `libcrypto.so.3`, `libssl.so.3`. | Post-`defconfig` dependency closure. | `88a7bce` selects `libopenssl`; runs 16--18 no longer report this error. |
| [#16](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/39014655826) | `88a7bce608cc6b60573463d8e9dc0ceb49098826` | `package/install`: unresolved direct dependencies of PassWall and PassWall2, including `coreutils-*`, `ip-full`, `libuci-lua`, `luci-compat`, `lyaml`, `resolveip`, `tcping`, geodata, `unzip`, `dns2socks`, and `microsocks`. | Post-`defconfig` dependency closure. | `7790a06` selected the pinned feeds' direct runtime dependencies. |
| [#17](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/39016223645) | `731caf90f33ae952e9a900cc7cb99ffee11e1046` | Same `package/install` unresolved dependencies as run 16. | Duplicate execution of the pre-fix commit, not a failed remediation. | The direct-closure change is absent from this commit; run 18 is the first validation run containing it. |
| [#18](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/39023506224) | `7790a06fa391dbfdfc59f69a5398753955d99963` | `Package lyaml is missing dependencies`: `libyaml-0.so.2`; the pinned Makefile declares `DEPENDS:= +lua +libyaml`. | Transitive dependency omitted from the manual post-`defconfig` set. | `dc54b5b` adds `libyaml`; run 19 progressed past `lyaml`, verifying that correction. |
| [#19](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/39036397184) | `dc54b5bfc7b0b23ce7a288eac54e0a2172c8cdb9` | `Package ip-full is missing dependencies`: `libbpf.so.1`, `libelf.so.1`. Pinned metadata confirms `ip-full -> libbpf -> libelf`. | Same manual post-`defconfig` closure design flaw; `libyaml` is no longer the first failure. | Replace one-off dependency additions with a pinned-metadata recursive precheck; explicitly select `libbpf` and `libelf`, then perform one cloud retry. |
| [#20](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/39041495250) | `f7a4d8fb1e6857d96eba147652e868380bef4f1e` | The new metadata precheck rejected the leading comment in `required-packages-v0.1.txt` as an invalid package name before examining dependency closure. | Precheck input parsing defect. | Skip full-line comments, retain inline-comment handling, and retry once. No compiler or image-build stage ran. |
| [#21](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/39041997960) | `058e5d7f1185352d58cc77691a7515e0ad148746` | The complete world build finished and generated both DoorNet2 images, but the ARM64 chroot policy test exited `1` from a silent boolean assertion; its untraced script did not identify which assertion. | Test observability defect; this is not a compiler or image-generation failure. | Enable POSIX-shell command tracing in the cloud-only policy test before one diagnostic rebuild. The partial images are retained only for analysis and must not be released because final artifact verification was skipped. |
| [#22](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/39048875603) | `b83ff238efbf708fa0ece55ac6d180445f48e314` | The traced test stopped at the built-rootfs LAN assertion: the test searched for `json_add_string ipaddr 192.168.100.1`, while the generated board script correctly contains the quoted UCI value `json_add_string ipaddr "192.168.100.1"`. | Test assertion defect, not a firmware configuration defect. | Correct both quoted LAN assertions and run one required cloud validation build; retain tracing for future auditability. |

`pkg_hash_fetch_best_installation_candidate: Packages ... incompatible
architectures configured` in runs 16 and 17 is a consequent resolver message
after the missing dependencies, not an architecture root cause. Compiler
warnings (including optional Python `_curses` modules) were not the fatal
errors.

## Required process correction

The root design issue is that the final package set is written manually after
the second `defconfig`, so Kconfig does not resolve the selected feed packages'
complete dependency graph. The remediation is a cloud-side recursive
unconditional-runtime-dependency precheck generated from the exact pinned
source metadata before entering the complete world build. The workflow also
ignores documentation-only pushes; source, board, configuration, dependency,
and workflow changes still run a complete cloud build.

No iStoreOS-route run in this table passed artifact verification. The current
standard-OpenWrt migration has a separate fixed source, feeds and workflow;
none of these historical artifacts are release inputs. There is no release
candidate, no SHA256-accepted image, and no authorization to create a release.
