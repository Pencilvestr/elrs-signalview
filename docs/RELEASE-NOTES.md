# SignalView 0.4.0

## Added

- **Themes:** Dark, Rich Ivory and White. Dark remains the default.
- **History selection:** Both, Receiver Signal or Link Quality. Both remains the default; single graphs fill the history area.
- **Frozen history:** retain the graphs when all main telemetry sources become unavailable, show an elapsed-loss timer, and leave a break when telemetry returns.

## Improved

- Auto antenna detection requires both RSSI paths to qualify together for one second before first showing dual view.
- After complete telemetry loss, Auto returns to single view after five continuous seconds with only one usable RSSI path.
- Added graph separation on TX16S, TX15 and NV14 layouts.
- Restored midpoint scale labels on NV14 graphs.
- Updated documentation, screenshots and the animated demonstration.

## Fixed

- Replaced the RSSI mode text field with an **Auto / Manual / Off** dropdown.
- Blank or uninitialized RSSI mode settings now default to Auto.
- Switching history views preserves recorded and frozen history.

## Updating

**From 0.3.0:** record your widget settings, remove the widget instance, replace the Lua and restart. Add SignalView again and restore your settings. Theme now occupies the first settings position.
