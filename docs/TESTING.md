# Testing and compatibility evidence

[Back to README](../README.md)

## Evidence levels

Physical-radio feedback and native simulation are recorded separately. A simulator pass is not a guarantee for every radio sharing that screen resolution, every EdgeTX release, a physical RF link, or a particular CPU/memory workload.

### Physical radio

The maintainer tested a TX16S MK3 with its internal ELRS 4.x module and an active connection. The original renderer failed with a CPU-limit error. After the bounded-history fix, the maintainer reported that it ran without CPU-limit issues. Subsequent feedback reported the scrolling-edge and module-version changes working correctly.

The maintainer subsequently installed the local SignalView spacing fix and reported it working as expected on a TX16S MK3 running EdgeTX 2.12.5 and internal ELRS 4.0.0. This is the functional change included in 0.2.0-beta.2. The native-source-picker footer was subsequently tested on the same MK3 setup and reported working, with slight lag. This report is included in beta.3; the cause of lag has not been measured. The receiver model, receiver firmware, test duration and flight conditions have not been recorded. No formal flight qualification or extended hardware endurance claim is made.

### Native simulator

The suite uses official EdgeTX 2.12.5 Windows simulator libraries for TX16S MK3 (800×480), TX16S (480×272), TX15 (480×320), NV14 (320×480) and PA01 (320×240). It boots the firmware in isolated processes and takes real RGB565 framebuffer captures. It does not rely on desktop screen capture.

The prepared beta's machine-readable [verification record](verification.json) includes the exact widget SHA-256, target results and supplemental image checks. It is a local verification record, not a GitHub Actions run.

Checks cover source integrity, loading, full-screen entry/exit, normal view, current/changed/stale/recovered telemetry, warning states, simulated Device Info version decoding, nineteen threshold scenarios, thirteen smoothing/settings scenarios and fourteen footer scenarios per target. Footer cases cover all ten ELRS fields, labels/units, unsupported sources, defaults and unavailable data. A separate MK3 test opens the native source picker, selects TPWR and verifies that it survives a restart. Additional pixel checks cover footer centering, warning colors, time-label clearance and a full-history trace reaching the left edge.

The early extended MK3 run reproduced the old CPU-limit failure. A corrected development build completed a 120-second continuous telemetry soak followed by timeout, recovery and exit. A later normal-widget run exceeded a full 30-second window with bounded plot counts and no CPU error. These historical runs are useful evidence, not a substitute for rerunning endurance tests after functional changes.

Sensor definitions are preconfigured. Test packets are synthetic, and the module-version response is injected. Interactive sensor discovery, arbitrary other Lua scripts, physical RF performance, simultaneous internal/external CRSF modules, and long-duration hardware behavior are not established by these checks.

## Reproduce native tests on Windows x64

The adapter uses the exact MSVC x64 ABI exported by the pinned libraries. It is experimental and is not an official EdgeTX automation API. Do not bypass fingerprint failures or point it at an arbitrary Companion build.

Prerequisites: Python 3.10 or newer, Pillow, a full 7-Zip executable with NSIS extraction support, and network access for the initial official-runtime download.

From the repository root:

```powershell
python -m pip install -r tests/native/requirements.txt
python tests/native/prepare_runtime.py --extractor "C:\Program Files\7-Zip\7z.exe"
python tests/native/run_tests.py
python tests/native/check_dashboard.py
python tests/native/check_compact_footer.py
```

For only the MK3, add `--radios tx16smk3` to `run_tests.py`. Regenerate the combined report without rerunning using `--report-only`; it rejects results for a different source hash.

`prepare_runtime.py` downloads the official pinned archive, verifies it and extracts selected DLLs. It does not execute the installer or modify an installed Companion. Binaries, caches and generated settings are ignored by Git and excluded from release packages. `SIGNALVIEW_RUNTIME` can point to an already extracted, fingerprint-matching `bin` directory.

Open `tests/native/results/index.html` after a run. Settings-restart and full-history probes are separate commands:

```powershell
python tests/native/worker.py --radio tx16smk3 --run-dir tests/native/settings-persistence --settings-probe
python tests/native/worker.py --radio tx16smk3 --run-dir tests/native/settings-persistence --settings-probe --reuse-settings
python tests/native/worker.py --radio tx16smk3 --run-dir tests/native/large-zone-probe --zone-probe
python tests/native/check_widget_area.py
python tests/native/worker.py --radio tx16smk3 --run-dir tests/native/endurance --soak-seconds 120
```

The settings probe seeds non-default fixture settings, lets native EdgeTX save them, then reopens that saved profile in a second process. It tests persistence, not typing through the settings editor. The zone probe uses one widget with the top bar off. The endurance worker is separate from the normal runner's 75-second timeout.

## Community hardware test checklist

- Record exact radio, EdgeTX version, ELRS version, receiver and RF mode.
- Compare each displayed reading with EdgeTX telemetry.
- Check one/two-antenna behavior and both view modes.
- Verify settings survive restart and differ between instances if used separately.
- Exercise warning/recovery thresholds at the bench with temporary Manual settings.
- Fill the complete history and continue over several rollovers.
- Check receiver power-off/stale handling and recovery.
- Monitor for CPU-limit, memory, slow UI or unexpected blanking.
- Verify the module version against the official ELRS tool.

Report results through the hardware-test issue form. Include a duration; do not describe an untimed check as an endurance test.
