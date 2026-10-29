# Settings, thresholds and colors

[Back to README](../README.md)

Open **Widget Settings** for SignalView. EdgeTX stores these settings per widget instance in the model. They are not stored in a shared custom configuration file.

| Label | Default | Allowed input | Application |
| --- | --- | --- | --- |
| Theme | Dark | Dark / Rich Ivory / White | Dashboard colors |
| LQ amber | 80 | 1–100 | Amber when LQ is below this percentage |
| LQ red | 60 | 0–99 | Red when LQ is below this percentage |
| RSSI mode | Auto | Auto / Manual / Off | Native dropdown; controls receiver-signal thresholds |
| RX amber | -98 | -130 to -1 dBm | Manual amber boundary; inclusive |
| RX red | -103 | -130 to -1 dBm | Manual red boundary; inclusive |
| Recover s | 1 | 0–10 seconds | Sustained-improvement time for current readings/bar |
| Footer 1 | None → TPWR | Native source picker | Left footer reading |
| Footer 2 | None → RFMD | Native source picker | Second footer reading |
| Footer 3 | None → RSNR | Native source picker | Third footer reading |
| Footer 4 | None → TQly | Native source picker | Right footer reading |
| Antennas | Auto | Auto / Single / Dual | Antenna display policy |
| History | Both | Both / Receiver Signal / Link Quality | Visible history graphs |

RSSI mode, Antennas, Theme and History use the native CHOICE dropdown available in EdgeTX 2.12.5.

Version 0.4.0 replaces the RSSI mode text field with a dropdown in the same menu position. On upgrading a saved text setting, EdgeTX initializes this changed field to **Auto**; reselect **Manual** or **Off** if needed. Other settings retain their positions. Firmware without CHOICE retains the text field; blank text uses Auto, and recognized names ignore capitalization and surrounding spaces. Unrecognized values still display `Use Auto/Manual/Off` rather than silently overriding an explicit setting.

## History view

**History** is appended after Antennas, preserving all settings in the existing theme-first builds. Both is the default, including when upgrading without a saved History selection.

- **Both:** retain the existing receiver-signal and Link Quality graphs.
- **Receiver Signal:** use the history area for one taller RSSI graph. Auto/Single/Dual still controls the antenna traces; dual view keeps the solid and dashed traces.
- **Link Quality:** use the history area for one taller LQ graph.

Single-graph views include midpoint labels. Main readings, footer values, the 30-second time window and warning colors are unchanged. Both histories continue to be collected in the same bounded buffer, so switching views retains recorded data, including frozen history. Complete loss still means all three main graph sources are unavailable; selecting one graph does not change loss detection. The option affects presentation only.

On firmware without CHOICE, enter `Both`, `Receiver Signal` or `Link Quality` in the text field. Names are case-insensitive; missing or invalid values use Both. Upgrading from the theme-first build requires replacing the Lua and restarting; no widget recreation is needed for this added option. Older option orders still require the migration described below.

## Theme

Choose **Dark**, **Rich Ivory** or **White** in Widget Settings → Theme. Dark is the default. Theme is the first menu entry. When upgrading from a build with Theme at the bottom or without Theme, record your settings, remove the widget instance, restart after replacing the Lua, then add SignalView again and restore your settings. EdgeTX stores options by position; reusing the old instance can shift thresholds and footer selections. Firmware without CHOICE uses a text field accepting these names; missing or invalid values use Dark.

White uses the approved neutral off-white background with dark charcoal text. It is appended as the third choice, preserving existing Dark and Rich Ivory selections. Rich Ivory uses a warm cream background with dark text, green normal signal/bar, blue normal Link Quality history, and darker amber/red warnings. The references to white readings below describe Dark; Rich Ivory uses dark text for the same healthy state. Changing themes preserves layout, readings, recorded history, frozen history and recovery timers. Each widget instance has its own saved theme.

## Selectable ELRS footer

`Footer 1` through `Footer 4` select the bottom values from left to right. Each uses EdgeTX's built-in source picker: choose a discovered telemetry sensor from the normal source list. No sensor codes need to be typed. The list includes non-ELRS sources, but this widget renders only the supported ELRS fields below.

| Sensor | Displayed value | Units |
| --- | --- | --- |
| `TPWR` | Transmit power | mW |
| `RFMD` | RF mode | Version-aware name; large screens also show modulation and band. Unknown modes/versions show a labeled raw index. |
| `RSNR` | Receiver SNR | dB |
| `TQly` | Downlink quality | % |
| `TRSS` | Downlink RSSI | dBm |
| `TSNR` | Downlink SNR | dB |
| `ANT` | Active antenna | EdgeTX-reported antenna number |
| `RQly` | Link Quality | % |
| `1RSS` | Receiver antenna 1 RSSI | dBm |
| `2RSS` | Receiver antenna 2 RSSI | dBm |

An unset/None selection retains that position's original default: TX power, RF mode, receiver SNR, downlink quality. Positions are independent and may repeat a sensor. Labels and units follow the selection; compact screens put units in the heading. Readings retain their white appearance and centered positions. Missing/stale telemetry displays `--`; other selected sources display `UNSUPPORTED` (`Unsup.` on compact screens) and `--`. Choose the current reading rather than a sensor's minimum/maximum variant. Sensor recognition uses the standard discovered ELRS names; renamed sensors may not be recognized.

After installing, restart the radio. Upgrading from 0.2.0 to 0.3.0 preserves settings and adds Antennas with its Auto default. For earlier text-selector builds, record your thresholds and recovery setting, remove and re-add SignalView, then restore them and select the footer sources.

## Antenna display

`Antennas` follows Footer 4. EdgeTX 2.12.5 presents a native Auto / Single / Dual dropdown; firmware without CHOICE falls back to a text field. Missing or invalid selections use Auto.

- **Auto:** require both RSSI paths to be usable together for one second before first showing dual view. Sequential evidence from paths that never overlap does not qualify. Version 0.4.0 reassesses after complete link-data loss: five continuous seconds with only one usable path switches to single view. Both paths qualifying for one second ends reassessment in dual view. Partial dropouts during an established connection do not trigger reassessment.
- **Single:** always show one path. Prefer the current selected antenna; switch only after it has been unavailable for a second and the other has supplied usable readings continuously for a second. The label identifies ANT 1 or ANT 2. History always belongs to that labeled path.
- **Dual:** always show both labeled readings and solid/dashed histories, with `--` and gaps for unavailable readings.

Zero, nonnumeric, nonfinite, positive or stale RSSI does not qualify for the main display. Weak finite negative signals remain visible. Auto preserves its layout and frozen history during complete link-data loss. On reconnection, any interruption or change of the sole usable path resets the five-second hold; another complete loss restarts observation. These timing choices are display policies, not ELRS recommendations. Telemetry cannot distinguish a changed receiver from a dual receiver with an unavailable path; choose Dual to keep both slots visible. Published 0.3.0 retains dual detection until widget restart/recreation. This preference never changes receiver antenna or RF settings.

The one-second evidence hold is fixed and independent of color recovery. Existing 0.2.0 SOURCE-footer settings retain their positions; verify the new option after installing and restarting.

## Link Quality

With defaults, LQ below 60% is red, 60–79% is amber, and 80–100% is white. The normal LQ bar is green; the normal LQ history is blue. A value exactly at a percentage boundary belongs to the better raw category.

`LQ red` must be lower than `LQ amber`. Invalid ordering mutes classification and displays `Check LQ settings`. Footer downlink quality is a separate telemetry value and is not classified by these thresholds.

ELRS suggests 60% as an OSD LQ alarm starting point. The 80% early-warning stage is SignalView's design choice. Read the [official guidance](https://www.expresslrs.org/quick-start/pre-1stflight/#rssi-and-link-quality); these are configurable display thresholds, not automatic flight decisions.

## Receiver signal in dBm

More-negative dBm values mean weaker signal. A single fixed dBm alarm is not appropriate for every RF mode.

### Auto

The current numeric RFMD must be available and current. SignalView uses its ELRS 4.x sensitivity table:

- Amber starts at sensitivity +10 dB.
- Red starts at sensitivity +5 dB.

These are inclusive boundaries. For sensitivity -108 dBm, raw readings above -98 are white, -98 through greater than -103 are amber, and -103 or lower are red. Each antenna is evaluated separately.

The two-stage policy derives from ELRS's recommended [5–10 dB warning margin](https://www.expresslrs.org/info/signal-health/#rssi-sensitivity-limit). It does not measure remaining range or guarantee that packets can be decoded.

The complete RFMD table and its reference are in [RF modes](RF-MODES.md). Unknown/missing/stale modes display `RSSI auto unavailable`. A detected firmware major other than 4 displays `Auto needs ELRS 4.x`. The absence of a detected version does not prove that the connected module uses 4.x; use Auto only when you have confirmed that independently.

### Manual

Use RX amber and RX red as absolute dBm boundaries. RX red must be more negative than RX amber. Invalid ordering disables classification visibly. Defaults -98/-103 are an example corresponding to a -108 dBm sensitivity limit; they are not universal recommendations.

### Off

Disables RSSI warning classification. Current RSSI is white and normal RSSI history is green. Missing values still remain missing. LQ classification is unaffected.

## Recovery behavior

Worsening colors appear at the next acquisition opportunity. Improvement must persist for `Recover s` and cross a fixed recovery margin: 2 percentage points for LQ or 2 dB for RSSI. Each of the three main readings has its own timer. An interruption restarts recovery. Mode/threshold changes, a backward clock or stale/missing data reset affected state.

For example, an amber LQ reading needs at least 82% with default settings before it can become white after the hold. A red reading can recover through amber. This is display hysteresis, not an audible alarm or an RF-control action.

Zero seconds disables both the recovery hold and the recovery margin. History colors always follow raw classification rather than smoothed current colors, so the graph can recover before the large number does. Previously recorded graph colors are not recalculated after a threshold or mode change.

## Status text

`Telemetry current` means EdgeTX considers the LQ source current. It is not a declaration that the entire RC link is safe. `No current telemetry` reflects unavailable/stale LQ. Receiver power-off is recognized when EdgeTX expires the sensor; the widget does not independently detect lost RF packets before that expiry.
