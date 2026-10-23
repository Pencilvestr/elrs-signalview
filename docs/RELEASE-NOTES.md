# ELRS SignalView 0.2.0-beta.2

The RSSI Auto/Manual threshold label on the large-screen dashboard now sits eight pixels higher, leaving clear space above the divider. All other layout positions and telemetry behavior are unchanged.

## Verification

The maintainer installed the local spacing fix on a RadioMaster TX16S MK3 running EdgeTX 2.12.5 and internal ELRS 4.0.0 and reported it working as expected. Receiver model, receiver firmware and test duration remain unrecorded. The versioned beta.2 package also has fresh native EdgeTX simulator coverage across all five representative targets, with updated screenshots and an automated threshold-label clearance check.

## Installation

Download `elrs-signalview-0.2.0-beta.2.zip` from the release assets and copy its WIDGETS folder to the root of your SD card. The path is `/WIDGETS/SignalView/main.lua`. Restart the radio. Continue using SignalView in full screen or a single near-full-screen widget area with the top bar off. The widget settings schema is unchanged from beta.1; existing SignalView settings can be retained. If migrating from ELRS Diag, add SignalView and re-enter your custom settings.

## Beta limitations

Physical-radio confirmation is currently for the MK3 setup above. Other targets have simulator coverage. Automatic RSSI thresholds are for ELRS 4.x. Module-version lookup briefly uses the shared CRSF Lua queue. No in-flight qualification or timed hardware endurance result is claimed.

A SHA-256 checksum is included. The automatically generated source archives are for development; use the named installation ZIP for the radio.
