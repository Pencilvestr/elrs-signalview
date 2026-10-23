# Telemetry and display reference

[Back to README](../README.md)

## Sensor mapping

Names are resolved case-insensitively and IDs are cached. Lookup first uses `sources()` and then `getFieldInfo()` as a fallback. Measurements use `getSourceValue()` so missing, current and stale readings can be distinguished.

| Sensor | Meaning | Display |
| --- | --- | --- |
| RQly | Uplink Link Quality, % | Main reading, green bar, lower history |
| 1RSS | Receiver antenna 1 RSSI, dBm | Main reading, solid upper history |
| 2RSS | Receiver antenna 2 RSSI, dBm | Second main reading, dashed upper history when available |
| RSNR | Receiver SNR, dB | Footer |
| RFMD | RF-mode index | Raw numeric footer and Auto threshold lookup |
| TPWR | TX power reported by EdgeTX, mW | Footer |
| TQly | Downlink quality, % | Footer |
| TRSS | Downlink RSSI, dBm | Acquired internally; not displayed |
| TSNR | Downlink SNR, dB | Acquired internally; not displayed |
| ANT | Active antenna index | Acquired internally; not displayed |

The footer is centered in four columns. Compact layouts abbreviate it as TX mW, RF Mode, SNR dB and DL %. The main label is Link Quality even though CRSF's source name is RQly.

## Antennas

The second reading appears when `2RSS` is numeric and current. That is telemetry availability, not hardware identification: a second sensor field alone cannot prove that a receiver has two independently measured physical antennas. SignalView does not infer which antenna is active from the strongest number and does not display an active-antenna indicator.

## History

- Window: 30 seconds, in memory only.
- Acquisition target: at most 5 Hz; actual scheduling can be slower.
- Raw buffer: up to 151 samples within the time window.
- Display: one bucket per second per series, retaining that bucket's lowest numeric sample and its original color.
- Draw bound: at most 32 plot buckets, including the predecessor needed to clip the line at the left edge.
- Missing/stale data creates gaps. A missing reading marks that series' whole one-second bucket as a gap.

The line joins bucket values; it is not a packet-by-packet trace or exact event timestamp. It preserves short low-value dips but does not expose every recovery inside the same second. No history is written to disk. Switching between supported widget and full-screen views keeps the same instance/history; model changes, restarts and re-adding the widget start a new history.

RSSI graphs use a fixed -120 to -40 dBm scale, and LQ uses 0–100%. Values outside the plot scale are clamped for drawing; the numeric reading retains the reported value. Empty startup history is not extrapolated to fill the screen.

## Module version header

SignalView sends a directed CRSF Device Ping (0x28) while its dashboard is visible, then reads bounded Device Info (0x29) responses from the shared Lua CRSF queue. It validates handset destination 0xEA, transmitter origin 0xEE, and the ASCII ELRS serial signature before decoding the software-version bytes.

Discovery lasts at most approximately ten visible seconds, with a ping no more often than every two seconds (at most six at exact boundary timing) and at most two queue reads per 200 ms. It stops after success or timeout. The version is cached only for that widget instance and is not inferred from RFMD or an installed tool script. Restart/recreate the widget after module firmware changes or to retry a timed-out lookup.

The header shows `ELRS 4.0.0`, for example, or `ELRS 4.x dev` for unknown minor/patch bytes. Without a usable reply it retains `ELRS LINK`. Versions older than 3 are not decoded by this implementation.

Unlike normal sensor acquisition, discovery consumes the shared CRSF Lua queue. Avoid another CRSF-querying widget during discovery. Coexistence with arbitrary other CRSF Lua consumers and simultaneous internal/external CRSF modules has not been validated. SignalView sends no parameter writes, bind commands or power/rate changes.

Reference: [CRSF Device Info specification](https://github.com/crsf-wg/crsf/wiki/CRSF_FRAMETYPE_DEVICE_INFO).
