# ELRS SignalView 0.2.0

First non-beta release.

- Reduce Lua work and retained memory through bounded history, cached graph geometry and formatted readings.
- Fix missing antenna data drawing a false receiver-signal segment.
- Keep the approved layout, sampling cadence, alert behavior and selectable ELRS footer.

## Testing

Five native EdgeTX 2.12.5 simulator targets pass. Includes 130 before/after comparisons, threshold and recovery checks, saved footer selections and full-history rendering.

Earlier builds were bench-tested on a TX16S MK3 with EdgeTX 2.12.5 and internal ELRS 4.0.0. The optimized build still needs physical confirmation; the previously reported slight lag is not proven fixed. See the performance report for measurements and limits.

## Install or update

Download `elrs-signalview-0.2.0.zip`, copy its WIDGETS folder to the SD card and restart. Upgrading from beta.3 preserves settings. Older text-selector builds need the widget re-added after recording settings. Select current ELRS sensors, not min/max variants; None uses the default for that position.

A SHA-256 checksum is included.
