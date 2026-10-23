# Troubleshooting

[Back to README](../README.md)

| Symptom | Checks |
| --- | --- |
| Widget not listed | Confirm `/WIDGETS/SignalView/main.lua`, restart, and look for SignalView rather than ELRS Diag. |
| Blank normal area | Use one widget, disable the top bar, or open full screen. Small areas intentionally have no prompt. |
| `--` readings | Confirm the receiver connection and discover sensors in EdgeTX. Check the names in the telemetry reference. Wait for the periodic rescan. |
| Numbers disappear after receiver power-off | Expected after EdgeTX marks the source stale. History gaps reflect unavailable data. |
| Second antenna absent | Check whether 2RSS is current/numeric. The widget cannot identify antenna hardware independently. |
| RSSI appears muted | Check Auto mode support, RFMD freshness, module major version, and threshold ordering. |
| `RSSI auto unavailable` | RFMD is missing, stale or absent from the verified 4.x table. Use confirmed Manual thresholds. |
| `Auto needs ELRS 4.x` | A different major version was detected. Manual mode is available; automatic 3.x decoding is not implemented. |
| `Use Auto/Manual/Off` | Enter one of those three names in the RSSI mode text setting. |
| `RSSI settings invalid` | RX red must be more negative than RX amber. |
| `Check LQ settings` | LQ red must be lower than LQ amber. |
| Header stays `ELRS LINK` | No usable module reply arrived during the discovery window. Restart/recreate the widget to retry; compare with the official ELRS tool. Avoid another CRSF-querying widget during discovery. |
| Header version does not change after flashing | Version is cached for the widget instance. Restart the radio/widget. |
| Graph is empty on the left at startup | Only recorded history is shown. Wait at least 30 seconds; earlier values are not invented. |
| A later graph gap appears | Missing/stale readings mark a one-second bucket as a gap. Continuous recorded data should reach the left edge after the window fills. |
| Current color recovers later than the graph | Expected: current text/bar uses recovery delay and margin, while history uses raw colors. |
| Very strong RSSI looks flat | The plot ceiling is -40 dBm; the numeric reading still shows the reported value. |
| Settings seem wrong after an upgrade | Check release notes for schema changes; record values, remove and re-add the instance if needed. |

## CPU-limit or memory errors

Record the exact message, including `refresh`/`background`, file path and line number. Stop relying on the widget until diagnosed. Check that the installed file matches the current release and is not an old ELRS Diag copy or compiled cache. Report time to failure, view mode, antenna count, other running widgets/scripts and whether the history was full.

The current renderer bounds graph work to 32 buckets per trace; do not replace it with the early raw-sample renderer. Native simulator passes cannot rule out hardware-specific CPU or memory behavior.

## Reporting a problem

Use the bug-report form. Include only relevant logs/screenshots with identifying data removed. Binding phrases, tokens and complete personal SD-card contents are not needed. If a proposed fix changes the layout or information hierarchy, include before/after screenshots for review.
