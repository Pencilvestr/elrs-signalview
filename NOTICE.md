# Attribution and provenance

## Widget

ELRS SignalView is an original implementation distributed under the MIT License. It was developed under the working name ELRS Link Diagnostics / ELRS Diag. The existing copyright notice is preserved in LICENSE. The project is maintained for the Pencilvestr GitHub account.

ExpressLRS, EdgeTX and RadioMaster names identify interoperability and tested targets. This project is independent and is not an official product of those projects or manufacturers.

## References

- [ExpressLRS Signal Health](https://www.expresslrs.org/info/signal-health/): sensitivity guidance and RFMD table, checked October 21, 2026.
- [ExpressLRS Before First Flight](https://www.expresslrs.org/quick-start/pre-1stflight/): LQ OSD alarm starting point.
- [CRSF Device Info](https://github.com/crsf-wg/crsf/wiki/CRSF_FRAMETYPE_DEVICE_INFO): TX version response format and ELRS signature.
- [EdgeTX Lua guide](https://luadoc.edgetx.org/): widget lifecycle and telemetry API documentation.
- [EdgeTX 2.12.5](https://github.com/EdgeTX/edgetx/releases/tag/v2.12.5): official simulator runtime used by native tests.
- [Simulator interface](https://github.com/EdgeTX/edgetx/blob/v2.12.5/companion/src/simulation/simulatorinterface.h) and [CRSF telemetry generator](https://github.com/EdgeTX/edgetx/blob/v2.12.5/companion/src/simulation/telemetryprovidercrossfire.cpp): reference for the original test adapter.

The widget source does not embed the official ELRS configuration Lua tool or vendor binary code.

## Test runtime and screenshots

EdgeTX simulator binaries and their Qt/SDL dependencies are external components with their own licenses. They are downloaded from the official release, fingerprint-checked and used unmodified. They are not included in this repository or install ZIP. Consult the upstream distribution for its licensing terms and source.

The native adapter and synthetic test fixtures are development materials, not radio setup files for users. Fixture profiles were generated for tests rather than copied from a personal radio. Simulator screenshots show EdgeTX-rendered output of this widget; image provenance is recorded in `docs/images/manifest.json`. The settings screenshot shows the earlier test observer. No logo or icon asset is shipped with the widget.
