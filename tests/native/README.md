# Native EdgeTX tests

See [the testing guide](../../docs/TESTING.md) for prerequisites, commands, evidence levels and limitations. Run commands from the repository root.

The production widget is loaded from `WIDGETS/SignalView/main.lua`. `LabTest` is a test-only observer that forwards to it; the nineteen threshold and thirteen smoothing checks run in short stages to respect EdgeTX's per-call CPU limit. Test helpers are never included in the install ZIP.

`binding-manifest.json` pins official EdgeTX 2.12.5 library/archive hashes. Its runtime directory is repository-relative; an optional `SIGNALVIEW_RUNTIME` environment variable can select an existing verified directory. Do not change hashes just to make an unreviewed runtime load.

Fixture model/radio profiles were generated solely for simulation. Never substitute a personal radio SD-card dump and commit it. Generated results, bytecode, virtual SD cards and runtime DLLs are excluded from Git and packages.

## Antenna display tests (0.3.0 development)

Run `worker.py --radio tx16smk3 --run-dir tests/native/results/antenna-development/cases --antenna-tests` and save its output as `tests/native/results/antenna-development/cases.log`. This isolates 104 bounded sample/render checks, including complete-loss antenna reassessment from the normal capture suite; the worker waits for completion. Both 800x480 and 320x240 renderers are exercised.

For full-history previews, use `--antenna-preview single1` and `--antenna-preview single2`, with corresponding run directories/logs named `single1` and `single2` under the same parent. These send zero for the unused RSSI field while retaining current telemetry, matching the placeholder edge case.

The MK3 settings fixture accepts `--antenna-mode Single`. Use `--settings-probe --antenna-settings-probe --antenna-picker-probe --antenna-select-dual` to scroll to the 11th option, open its choices and select Dual; omit `--antenna-mode` on subsequent `--reuse-settings` runs. Capture the selection run as `choices-selected.log` and the restarted `--settings-probe --reuse-settings --antenna-settings-probe` run as `choices-reopened.log`, using a `settings` run directory under the same parent. `check_antennas.py` validates these logs and copied source hashes. This interaction is tied to the pinned MK3 simulator settings geometry.

`docs/verification.json` describes published 0.3.0 functional checks; `docs/performance-results.json` retains the 0.2.0 performance comparison. Current development results remain under `tests/native/results/`; do not represent older measurements as current-source results.

## Frozen history tests (local 0.4.0 development)

Run `worker.py --radio tx16smk3 --run-dir tests/native/results/loss-development/cases --loss-tests` and save output as `tests/native/results/loss-cases.log`. The bounded public-API cases cover startup, a full window, loss within a bucket, a long freeze, both renderers, reconnection within the same second, partial sensors, valid zero LQ, separate instances and clock reset.

For actual firmware timeout and recovery captures, run `worker.py --radio tx16smk3 --run-dir tests/native/results/loss-development/preview --loss-preview --profile` and save output as `tests/native/results/loss-preview.log`. This fills the history, degrades the injected signal, stops CRSF packets, waits beyond 30 seconds, then reconnects. Use `check_loss.py` to verify source-matched logs and identical frozen graph pixels.

## History-view tests (local dev.3)

Run `worker.py --radio tx16smk3 --run-dir tests/native/results/history-cases --history-tests`. Expect 35 passing `HISTORY|...|true` cases across all five screen geometries and no script/CPU errors. Cases cover default/invalid settings, text/numeric choices, selected traces, single/dual antennas, frozen-history retention, plot-cache recalculation and exact restoration of Both after switching. Use `--history "Receiver Signal"` or `--history "Link Quality"` for native saved selections; `--reuse-settings` reopens the same fixture.

## Theme tests (local development)

Use `worker.py --radio tx16smk3 --run-dir tests/native/results/theme-final --theme-tests --theme "Rich Ivory"`. The theme suite compares renderer commands in 800×480 and 320×240 layouts, checks defaults and invalid selections, verifies numeric and text selections, alternates widget instances, and retains frozen history and alert state across changes. Fourteen `THEME|...|true` rows indicate completion; also check the log for script/CPU errors. `--theme` persists the selected value in the simulator model; `--reuse-settings` reopens it on a subsequent run. Omit `--theme-tests` for normal screenshots and add `--profile` for instruction-budget measurements without functional-test overhead.
