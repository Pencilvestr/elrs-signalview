# RF-mode display and automatic thresholds

[Back to settings](SETTINGS.md)

## Readable footer

On large screens, an RFMD footer selection displays the readable mode beside its modulation and band. For example, ELRS 4.x RFMD 29 becomes `500Hz | LoRa / 2.4G`. The group stays centered in any of the four selectable slots. Long Full-resolution labels use a smaller font to fit the same space. Compact screens show the readable mode name under `RF Mode`, preserving the existing footer and graph spacing; modulation and band are omitted.

The map is chosen from the transmitter module's detected major version, not inferred from the RFMD value. The same number can mean different modes: RFMD 11 is `D500` on 3.x and `K1000 Full` on 4.x. Unknown/undetected versions, unsupported indices and malformed indices show `RF MODE RAW` with the original number; missing or stale data shows `--`. This avoids presenting a guessed packet rate as fact. Restart/recreate the widget after changing module firmware to refresh its cached version.

Labels follow the [official RFMD tables](https://www.expresslrs.org/info/signal-health/#rf-mode-indexes-rfmd). The 3.x band mapping also uses the [3.5.6 rate definitions](https://github.com/ExpressLRS/ExpressLRS/blob/3.5.6/src/include/common.h) and [radio configurations](https://github.com/ExpressLRS/ExpressLRS/blob/3.5.6/src/src/common.cpp), checked October 28, 2026. Only modes present in the verified configurations are named. `900M` denotes the sub-GHz band family, not a claim that the transmitter is operating on exactly 900 MHz; `X-Band` means dual band.

3.x indices 2, 4, 5 and 7 are shared across frequency bands in supported configurations. Their rate and modulation can be shown, but the footer says `Band ?`. No band is guessed from the transmitter name, antenna count or signal strength. Display decoding does not extend automatic RSSI thresholds to 3.x: use Manual or Off there.

## ELRS 4.x automatic RSSI thresholds

Values derive from the official RFMD table above, checked October 21, 2026. Do not apply these indices to ELRS 3.x. Amber/red margins are SignalView policy, not two separately specified ELRS alarm levels.

| RFMD | Band | Sensitivity, dBm | Amber at/below | Red at/below |
| --- | --- | --- | --- | --- |
| 0 | 900 MHz | -123 | -113 | -118 |
| 1 | 900 MHz | -120 | -110 | -115 |
| 2 | 900 MHz | -117 | -107 | -112 |
| 3 | 900 MHz | -112 | -102 | -107 |
| 5 | 900 MHz | -112 | -102 | -107 |
| 6 | 900 MHz | -111 | -101 | -106 |
| 7 | 900 MHz | -111 | -101 | -106 |
| 10 | 900 MHz | -112 | -102 | -107 |
| 11 | 900 MHz | -101 | -91 | -96 |
| 21 | 2.4 GHz | -115 | -105 | -110 |
| 23 | 2.4 GHz | -112 | -102 | -107 |
| 24 | 2.4 GHz | -112 | -102 | -107 |
| 27 | 2.4 GHz | -108 | -98 | -103 |
| 28 | 2.4 GHz | -105 | -95 | -100 |
| 29 | 2.4 GHz | -105 | -95 | -100 |
| 30 | 2.4 GHz | -104 | -94 | -99 |
| 31 | 2.4 GHz | -104 | -94 | -99 |
| 32 | 2.4 GHz | -104 | -94 | -99 |
| 33 | 2.4 GHz | -104 | -94 | -99 |
| 34 | 2.4 GHz | -103 | -93 | -98 |
| 35 | 2.4 GHz | -103 | -93 | -98 |
| 36 | 2.4 GHz | -103 | -93 | -98 |
| 100 | Dual band | -112 | -102 | -107 |
| 101 | Dual band | -112 | -102 | -107 |

Unknown indices stay unclassified in Auto. Modes not in this table require updated verified mapping or Manual thresholds.
