# SignalView 0.5.1

SignalView now leaves a gap in the graphs when a second of telemetry is missing. After sampling resumes or a receiver reconnects in a new second, valid readings stay visible in history review.

Automatic RSSI warnings wait until the transmitter identifies itself as ELRS 4.x. If the module version is unknown or you run ELRS 3.x, select Manual to set your own thresholds.

Module discovery pauses while the dashboard is hidden and limits retries across repeated visits. SignalView also spends less time searching for missing sensors and reuses memory when sampling telemetry.

**Updating from 0.5.0 or 0.4.0:** Replace `/WIDGETS/SignalView/main.lua` and restart the radio. Your widget settings carry over.
