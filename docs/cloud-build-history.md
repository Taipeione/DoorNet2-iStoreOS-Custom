# DoorNet2 cloud build history

Keep failed attempts and remediations for traceability. These records describe GitHub Actions only; local development images are not cloud results.

| Run | Commit | Result | Failure / action |
|---|---|---|---|
| [38993536280](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/38993536280) | `4bec3f8e575b4af979243ffc3710b2df7c9f1bad` | FAIL at Precheck; no firmware compilation started | GitHub-hosted Ubuntu did not have `rg`; the static verifier emitted `rg: not found`. Added `ripgrep` to the workflow dependency installation and retriggered from a follow-up commit. The run retained its logs/artifact. |
| [38993725481](https://github.com/Taipeione/DoorNet2-iStoreOS-Custom/actions/runs/38993725481) | `8e12b01716c31b99c325222613e4a0f2ede14ae7` | FAIL during feed preparation; compiler stages not reached | `config/feeds.conf` contained a 39-character third-feed revision; GitHub could not check it out and `feeds install` consequently failed. Corrected the pin to the verified 40-character remote commit and added a hard check that every feed HEAD exactly matches its configured revision. Run logs/artifact were retained. |
