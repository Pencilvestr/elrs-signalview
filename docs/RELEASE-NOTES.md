# ELRS SignalView 0.2.0-beta.1

First named public beta of the EdgeTX ExpressLRS dashboard previously developed as ELRS Diag.

## Included

- Full-screen and single near-full-screen widget views, with the top bar off.
- Independent receiver antenna readings and solid/dashed histories.
- Thirty-second receiver-signal and Link Quality graphs with bounded drawing work.
- White/amber/red readings, immediate worsening indications and configurable recovery hold.
- ELRS 4.x automatic RSSI thresholds, Manual and Off modes.
- Module-reported firmware version discovery with a header fallback.
- Centered footer values, compact/portrait layouts and explicit stale-data handling.

## Fixes carried into this beta

- Bounded plot history avoids the early MK3 CPU-limit failure.
- A retained predecessor and clipping prevent a moving gap at the left edge for continuous data.
- Time labels clear the footer separator.
- Small widget areas remain blank with no prompt.

## Installation

Copy the install ZIP's WIDGETS directory into the root of the SD card and select SignalView. Use a one-widget layout with the top bar off, or open full screen. For ELRS Diag development installations, remove the old instance and add SignalView; record and re-enter custom settings.

## Testing and limitations

The maintainer reported successful bench operation on a TX16S MK3 with an internal ELRS 4.x module. Exact hardware patch versions, receiver and timed duration have not yet been recorded. Native EdgeTX 2.12.5 tests cover five representative resolutions; these do not prove every radio model or hardware performance. Version lookup uses the shared CRSF Lua queue briefly. Auto RSSI decoding is for ELRS 4.x, not 3.x. History is a one-second weakest-value representation, not a packet logger. There are no audible alarms or flight-control actions.

Please report the exact radio, firmware versions, receiver, RF mode, settings, test duration and full error message. Community testing is particularly useful for single-antenna receivers, additional radios and extended hardware operation.
