# Native EdgeTX tests

See [the testing guide](../../docs/TESTING.md) for prerequisites, commands, evidence levels and limitations. Run commands from the repository root.

The production widget is loaded from `WIDGETS/SignalView/main.lua`. `LabTest` is a test-only observer that forwards to it; the nineteen threshold and thirteen smoothing checks run in short stages to respect EdgeTX's per-call CPU limit. Test helpers are never included in the install ZIP.

`binding-manifest.json` pins official EdgeTX 2.12.5 library/archive hashes. Its runtime directory is repository-relative; an optional `SIGNALVIEW_RUNTIME` environment variable can select an existing verified directory. Do not change hashes just to make an unreviewed runtime load.

Fixture model/radio profiles were generated solely for simulation. Never substitute a personal radio SD-card dump and commit it. Generated results, bytecode, virtual SD cards and runtime DLLs are excluded from Git and packages.

## Antenna display tests (0.3.0 development)

Run `worker.py --radio tx16smk3 --run-dir tests/native/results/antenna-development/cases --antenna-tests` and save its output as `tests/native/results/antenna-development/cases.log`. This isolates 58 bounded sample/render checks from the normal capture suite; the worker waits for completion. Both 800x480 and 320x240 renderers are exercised.

For full-history previews, use `--antenna-preview single1` and `--antenna-preview single2`, with corresponding run directories/logs named `single1` and `single2` under the same parent. These send zero for the unused RSSI field while retaining current telemetry, matching the placeholder edge case.

The MK3 settings fixture accepts `--antenna-mode Single`. Use `--settings-probe --antenna-settings-probe --antenna-picker-probe --antenna-select-dual` to scroll to the 11th option, open its choices and select Dual; omit `--antenna-mode` on subsequent `--reuse-settings` runs. Capture the selection run as `choices-selected.log` and the restarted `--settings-probe --reuse-settings --antenna-settings-probe` run as `choices-reopened.log`, using a `settings` run directory under the same parent. `check_antennas.py` validates these logs and copied source hashes. This interaction is tied to the pinned MK3 simulator settings geometry.

`docs/verification.json` and `docs/performance-results.json` describe the published 0.2.0 release. Current development results remain under `tests/native/results/`; do not represent the old performance comparison as a measurement of a newer build.
