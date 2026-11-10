# SignalView 0.5.0

## Added

- Review up to 15 minutes of receiver signal and Link Quality history in full screen.
- Hold a graph for one second and release, or hold Enter, to enter review. Scroll with the wheel, supported navigation controls or touch; short Exit or Live returns to the live dashboard.
- Recording continues during review. The oldest data rolls off when the buffer fills; recorded history remains available during telemetry loss.

## Improved

- Reuse graph geometry while inspecting history to reduce repeated calculations.
- Preserve the selected antenna in historical readings, including ANT 2 in Single view.
- Keep historical readings visible across normal sample-timing variation while preserving genuine gaps.

## Updating

From 0.4.0, replace `/WIDGETS/SignalView/main.lua` and restart the radio. Existing widget settings are retained. History is stored in memory and clears on restart; review is available only in full screen.
