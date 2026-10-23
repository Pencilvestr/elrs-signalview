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

The RSSI mode field is text, not a custom dropdown. The documented EdgeTX widget option API does not expose an arbitrary named-choice list.

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
