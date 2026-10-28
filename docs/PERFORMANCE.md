# Performance review — 0.2.0

[Back to README](../README.md)

The widget can use less CPU and memory without reducing its sampling cadence,
history window or refresh frequency. The changes are included in 0.2.0. Confirmation on the physical MK3 is pending.

## Changes

- Remove the duplicate 151-sample raw buffer. The screen already uses the
  one-second weakest-value buckets, which still retain short dips, original
  colors, missing-data gaps and a predecessor for continuous left-edge clipping.
  Keep only the latest raw sample for diagnostics.
- Compute scrolling X positions once per bucket per frame. Cache Y coordinates
  until bucket values or widget dimensions change. Keep this cache per instance.
- Format sensor numbers only when their values change and reuse display-color
  storage. Avoid allocating a full-screen rectangle table every refresh.
- Compare recovery contexts as numeric fields instead of concatenating strings.
  Compute effective RSSI thresholds once per sample.
- Look up the ten known sensors directly. Keep case-insensitive enumeration as a
  fallback. The native fixture exposes 94 sources; all ten ELRS names resolve
  directly, so the common path avoids enumerating that list every two seconds.
- Remove the unused `status` helper.

The coordinate cache adds a small amount of retained state. That costs less
memory than the removed duplicate buffer and reduces repeated drawing math.
The source file grows slightly; runtime memory is the useful metric here.

## Measurements

See [the measured results](performance-results.json) for exact values and source
hashes. The controlled pair uses identical test observers and official EdgeTX
2.12.5 MK3 simulator libraries at 800 × 480. Each run has 60 seconds of changing
telemetry followed by warning, stale-data, recovery and exit phases.

| Measurement | Released beta.3 | 0.2.0 |
| --- | ---: | ---: |
| Live refresh Lua instruction budget | 45.86% | 40.08% |
| Worst steady refresh instruction budget | 54.00% | 45.00% |
| Retained isolated VM heap | 161.63 KiB | 134.74 KiB |
| Heap growth after startup | 97.18 KiB | 67.73 KiB |

The approximate improvement is **13% lower live Lua instruction-budget use** and
**17% less retained Lua VM memory**. Repeated exploratory runs were consistent
with these results. The JSON records the matched release pair.

`getUsage()` reports consumed **Lua instructions**, not total CPU utilization.
It does not measure time spent inside native LCD or source API functions.
See [EdgeTX's API definition](https://luadoc.edgetx.org/2.10/part_iii_-_opentx_lua_api_reference/general-functions-less-than-greater-than-luadoc-begin-general/getusage).

Heap measurements use `collectgarbage('count')` after a test-only full collection
at 45 seconds. They include the isolated Windows x64 Lua VM and observer. They
are retained heap, not peak memory, radio RAM usage or operating-system process
memory. No explicit garbage collection is added to the installed widget.

## Correctness finding

The large-screen renderer used an `and/or` expression that substituted Link
Quality when an antenna's history value was absent. This could draw a false RSSI
segment. Explicit indexing now leaves that segment absent. Normal readings,
layout, fonts, thresholds and recovery behavior are unchanged.

The independent comparison first reproduced that mismatch against untouched
beta.3. Its final reference is beta.3 with **only this one-line selection bug
corrected**. All other drawing and sampled-state output is compared directly.
The baseline used for performance measurements is untouched beta.3.

## Validation

- Five native radio targets; 19 threshold, 13 recovery/settings and 15
  footer/missing-trace cases per target.
- 130 deterministic before/after cases compare every LCD command, sensor state,
  displayed color and plot bucket. Coverage includes all five dimensions,
  resizing, a full window, source-ID changes, lookup fallback, mode/settings
  changes, stale/single-antenna data, clock rollback, small areas and exit.
- 12 MK3 framebuffer checks, 40 footer alignment checks and 21 widget-area
  checks, including full-history normal-view operation.
- Native source-picker selection survives a restart.
- Baseline and optimized profiling runs complete without widget CPU-limit or
  runtime errors. The oracle splits rendering and comparison across callbacks
  so the test harness respects the same CPU guard.

Generated logs, copied sources and framebuffer captures are under
`tests/native/results/performance/`; they are excluded from releases.
`tools/analyze_performance.py` verifies completed runs, source hashes, the
matched observers and the exact reference correction before writing the report.

To reproduce, save the released beta.3 Lua as
`tests/native/results/performance/beta3-baseline.lua`. Use the normal native-test
runtime setup, then run `worker.py` with `--profile --soak-seconds 60`, once with
`--widget-source` pointing to that baseline and once with the working source.
Use distinct run directories and logs named `baseline-control` and
`final-control`. Earlier exploratory runs are kept separately from the matched release pair. The differential run uses `--reference-source` with the one-line
corrected reference and waits for all 130 comparisons.

## Remaining limits

The reported lag is not diagnosed or proven fixed. Physical testing must check
menu responsiveness, full-screen/normal views, stale-data handling and a
sustained live connection. Source API cost, native LCD drawing, other scripts
and firmware scheduling can still dominate real-radio responsiveness.

Reducing refresh rate or sampling frequency could save more work, but would
change behavior. Framebuffer reuse needs a separate firmware-aware design to
avoid stale regions or missed warnings. Neither is included in this build.
