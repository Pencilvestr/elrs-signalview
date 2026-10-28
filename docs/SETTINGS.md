# Settings, thresholds and colors

[Back to README](../README.md)

Open **Widget Settings** for SignalView. EdgeTX stores these settings per widget instance in the model. They are not stored in a shared custom configuration file.

| Label | Default | Allowed input | Application |
| --- | --- | --- | --- |
| LQ amber | 80 | 1–100 | Amber when LQ is below this percentage |
| LQ red | 60 | 0–99 | Red when LQ is below this percentage |
| RSSI mode | Auto | `Auto`, `Manual`, `Off` | Text field; case-insensitive, surrounding spaces ignored |
| RX amber | -98 | -130 to -1 dBm | Manual amber boundary; inclusive |
| RX red | -103 | -130 to -1 dBm | Manual red boundary; inclusive |
| Recover s | 1 | 0–10 seconds | Sustained-improvement time for current readings/bar |
| Footer 1 | None → TPWR | Native source picker | Left footer reading |
| Footer 2 | None → RFMD | Native source picker | Second footer reading |
| Footer 3 | None → RSNR | Native source picker | Third footer reading |
| Footer 4 | None → TQly | Native source picker | Right footer reading |

The RSSI mode field remains a text field. The new Antennas option uses the native CHOICE dropdown available in EdgeTX 2.12.5.

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

`Antennas` is appended after Footer 4, preserving the existing option positions. EdgeTX 2.12.5 presents a native Auto / Single / Dual dropdown; firmware without CHOICE falls back to a text field. Missing or invalid selections use Auto.

- **Auto:** require one second of usable RSSI evidence for each path, then retain dual layout for the widget lifetime. Until then, show one centered value and its own solid history trace.
- **Single:** always show one path. Prefer the current selected antenna; switch only after it has been unavailable for a second and the other has supplied usable readings continuously for a second. The label identifies ANT 1 or ANT 2. History always belongs to that labeled path.
- **Dual:** always show both labeled readings and solid/dashed histories, with `--` and gaps for unavailable readings.

Zero, nonnumeric, nonfinite, positive or stale RSSI does not qualify for the main display. Weak finite negative signals remain visible. Auto remembers prior dual evidence during disconnects; restart/recreate the widget to clear it when changing receivers within the same model. This display preference never changes receiver antenna or RF settings.

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
