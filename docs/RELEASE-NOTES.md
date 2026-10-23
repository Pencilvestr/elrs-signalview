# ELRS SignalView 0.2.0-beta.3

- Choose each footer reading with EdgeTX's native source picker.
- Ten ELRS sensors supported. Existing default readings and layout retained.
- Unsupported sources are marked; missing or stale values show `--`.

## Upgrade

Record your widget settings. Copy the installation ZIP's WIDGETS folder to the SD card, restart, and re-add SignalView. Restore your thresholds and select Footer 1–4. None/unset uses the original default for that position. Select current telemetry readings, not their minimum/maximum variants.

## Testing

Working on a TX16S MK3 with EdgeTX 2.12.5 and internal ELRS 4.0.0. Slight lag reported; optimization is deferred. Receiver details and test duration remain unrecorded.

Native simulator checks cover five targets, all ten footer sensors, unsupported and stale sources, saved selections, and full-history rendering.

Download `elrs-signalview-0.2.0-beta.3.zip` for radio installation. A SHA-256 checksum is included.
