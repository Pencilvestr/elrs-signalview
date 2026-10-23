# Installation and updating

[Back to README](../README.md)

## Requirements

- An EdgeTX color-screen radio with Lua widgets and the `getSourceValue` API. Native testing currently uses EdgeTX 2.12.5.
- An ELRS telemetry connection and discovered telemetry sensors. Auto RSSI classification targets ELRS 4.x.
- A one-widget view with the top bar off, or full-screen widget mode.

The source API exists in older EdgeTX versions, but that alone does not establish compatibility with this widget.

## Install from a release ZIP

1. Back up the SD card and model configuration.
2. Unzip the install package on your computer.
3. Merge its `WIDGETS` directory into the root of the radio SD card. Preserve other widgets.
4. Check the resulting path:

```text
SD card/
└── WIDGETS/
    └── SignalView/
        └── main.lua
```

5. Safely eject USB storage or the SD card, then restart the radio.
6. Select the intended model. In its screen/widget setup, choose a one-widget layout, disable the top bar, and select **SignalView**.
7. Connect the receiver. If readings are missing, use EdgeTX's telemetry page to discover sensors, then return to the widget. Its sensor scan repeats approximately every two seconds.

The repository itself also contains `WIDGETS/SignalView/main.lua`; you can install that directory directly. Do not copy the whole repository into `WIDGETS`.

## Supported view sizes

Normal widget mode requires an area covering at least 95% of the radio screen's width and height, with a minimum area size of 300 × 240 pixels. This deliberately excludes small and multi-widget zones. Full-screen mode uses the complete radio screen.

No prompt or compact summary is drawn in unsupported areas. If the widget looks blank, check the layout and top-bar setting first. Top-bar-specific layout adjustments are intentionally not provided.

## Upgrading

For an update with the same settings schema, replace `main.lua` and restart the radio. Keep a copy of the previous working file for rollback.

When release notes announce a settings-schema change, remove and re-add the widget instance so EdgeTX initializes the new options. Record your old settings first. A compiled `main.luac` from an earlier installation may be removed from the widget folder if EdgeTX appears to keep loading an old build; do not remove unrelated scripts or files.

### Migrating from ELRS Diag

The development widget was installed at `/WIDGETS/ELRSDiag/main.lua` and appeared as `ELRS Diag`. SignalView uses a new directory and picker name. Remove the old widget from the model, add SignalView, and re-enter any custom thresholds. The old directory can be kept as an inactive backup. Avoid keeping both widgets active because version discovery uses the shared CRSF Lua queue briefly.

## First bench check

Remove propellers or disconnect the motor before testing.

1. Compare Link Quality, RSSI and TX power against EdgeTX telemetry readings.
2. Confirm the expected antenna fields and RFMD value.
3. Compare the detected version with the official ELRS tool. A missing version reply leaves `ELRS LINK` in the header.
4. Let the history fill for at least 30 seconds and continue across several rollovers.
5. Change a widget setting and restart the radio to verify persistence.
6. Turn the receiver off, wait for EdgeTX to mark telemetry stale, then turn it back on. Verify hidden current numbers, graph gaps and recovery.
7. Test both full-screen and single-widget views. Leave it running while checking for errors or slowing controls.

Warning colors can be exercised using temporary Manual thresholds at the bench; restore the intended mode/settings afterward. These tests do not replace a range test or your normal flight-safety procedures.

## Rollback

Restore the previous `main.lua`, restart, and restore its recorded widget settings if the schema changed. To uninstall, remove the widget instance from the model before removing its directory. This widget does not modify RF settings or install anything on the receiver.
