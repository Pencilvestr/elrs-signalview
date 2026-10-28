# ELRS SignalView 0.3.0

- Automatically adapt the display to one or two usable antenna telemetry paths, with Auto, Single and Dual options.
- Show readable RF-mode names for ELRS 3.x and 4.x. Large screens include modulation and band; compact screens retain the mode name.
- Place dBm beside each antenna reading and center the single-antenna display.
- Refresh screenshots and the README GIF, showing startup without a connection, connection, signal changes and recovery.

Unknown RF modes or firmware versions retain a labeled raw index. Ambiguous 3.x frequency bands show `Band ?`. Automatic RSSI thresholds remain ELRS 4.x only; use Manual or Off with 3.x.

Tested in five native EdgeTX 2.12.5 simulator targets. The maintainer confirmed the corresponding 0.3.0-dev.3 build working on the TX16S MK3.

To update, copy the install ZIP's `WIDGETS` folder onto the SD card and restart the radio. Existing 0.2.0 settings are retained; Antennas defaults to Auto. A SHA-256 checksum is included.
