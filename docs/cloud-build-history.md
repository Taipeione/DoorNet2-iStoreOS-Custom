# DoorNet2 cloud build history

Keep failed attempts and remediations for traceability. These records describe GitHub Actions only; local development images are not cloud results.

| Run | Commit | Result | Failure / action |
|---|---|---|---|
| [38993536280](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/38993536280) | `4bec3f8e575b4af979243ffc3710b2df7c9f1bad` | FAIL at Precheck; no firmware compilation started | GitHub-hosted Ubuntu did not have `rg`; the static verifier emitted `rg: not found`. Added `ripgrep` to the workflow dependency installation and retriggered from a follow-up commit. The run retained its logs/artifact. |
