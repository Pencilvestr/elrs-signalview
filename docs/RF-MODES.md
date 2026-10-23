# ELRS 4.x automatic RF-mode thresholds

[Back to settings](SETTINGS.md)

This is the table embedded in the beta source. Values derive from the [official ExpressLRS Signal Health RFMD table](https://www.expresslrs.org/info/signal-health/#rf-mode-indexes-rfmd), checked October 21, 2026. Do not apply these indices to ELRS 3.x. Amber/red margins are SignalView policy, not two separately specified ELRS alarm levels.

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

Unknown indices stay unclassified in Auto. A raw RFMD is displayed in the footer rather than a guessed packet-rate label. Modes not in this table require updated verified mapping or Manual thresholds.
