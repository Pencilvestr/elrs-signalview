# ELRS SignalView

A full-screen RC-link dashboard for EdgeTX color-screen radios using ExpressLRS telemetry.

**Version 0.3.0.**

![SignalView showing changing signal levels, alert colors and scrolling history](docs/images/signalview-demo.gif)

*Native EdgeTX 2.12.5 simulator capture with synthetic telemetry. The 40-second loop starts disconnected, establishes a link, then shows signal degradation and recovery while the history fills and footer readings change.*

## What it shows

- Large Link Quality and receiver-signal readings, with dBm beside each antenna value.
- Automatic single/dual-antenna display, with Auto, Single and Dual options.
- A 30-second history of receiver signal and Link Quality. Single view shows the selected antenna; dual view uses solid and dashed traces.
- White, amber and red current readings; green normal RSSI history and blue normal LQ history.
- Immediate worsening indications and configurable delayed recovery.
- Automatic RSSI thresholds from the verified ELRS 4.x RF-mode table, or manual thresholds.
- Four selectable ELRS footer readings using EdgeTX's source picker. Defaults: TX power, RF mode, receiver SNR and downlink quality.
- Readable RF-mode names for ELRS 3.x and 4.x. Large screens also show modulation and band when known.
- The transmitter module's reported firmware version when discovery succeeds.

It works in full screen and a single near-full-screen widget area. **Use a one-widget layout with the EdgeTX top bar off.** Small widget areas intentionally stay blank. There are no miniature dashboards, prompts, voice alarms, flight logging or RF-setting controls.

## Install

[Download the installation ZIP](https://github.com/Pencilvestr/elrs-signalview/releases/download/v0.3.0/elrs-signalview-0.3.0.zip) from the [release](https://github.com/Pencilvestr/elrs-signalview/releases/tag/v0.3.0).

1. Back up your model and SD card.
2. Copy `WIDGETS/SignalView` from this project into the SD card's existing `WIDGETS` directory.
3. Confirm the file is at `/WIDGETS/SignalView/main.lua`.
4. Restart the radio. Select **SignalView** in the model's widget setup and use a single-widget layout with the top bar off, or open the widget full screen.
5. Establish the ELRS connection and discover telemetry sensors in EdgeTX if necessary.

See [installation and updating](docs/INSTALLATION.md) for the full procedure and rollback steps. Release ZIPs are built with [the packaging tool](tools/build_release.py); use an install ZIP rather than a repository source archive when available.

## Known Issue

## Default settings

| Setting | Default | Meaning |
| --- | --- | --- |
| LQ amber | 80 | Amber below 80% |
| LQ red | 60 | Red below 60% |
| RSSI mode | Auto | Enter `Auto`, `Manual` or `Off` |
| RX amber | -98 | Manual RSSI amber boundary, dBm |
| RX red | -103 | Manual RSSI red boundary, dBm |
| Recover s | 1 | Recovery hold in seconds; 0 disables smoothing |
| Antennas | Auto | Infer available RSSI paths, or select Single / Dual |

Auto uses the current ELRS 4.x RFMD sensitivity limit plus 10 dB for amber and plus 5 dB for red. These two stages are a project policy based on ELRS's documented warning-margin guidance. The 80% LQ early warning is also a project choice; ELRS documents 60% as an OSD alarm starting point. None of these values predicts a failsafe or remaining range. [Settings and thresholds](docs/SETTINGS.md) explains boundaries, recovery and limitations.

## Screenshots

| Warning | Degraded |
| --- | --- |
| ![Amber warning state](docs/images/mk3-warning.png) | ![Red degraded state](docs/images/mk3-critical.png) |

These states use synthetic test values. Screenshots for all five resolutions, settings and full history are in the [screenshot gallery](docs/SCREENSHOTS.md).

## Known working hardware

This is a running list of setups reported working on physical radios. Reports describe the configuration and testing performed; additional hardware reports are welcome through the hardware-test issue form.

| Radio | Module / ELRS | EdgeTX | Reported testing |
| --- | --- | --- | --- |
| RadioMaster TX16S MK3 | Internal ELRS, 4.0.0 | 2.12.5 | Maintainer reported 0.3.0-dev.3 working correctly on the radio, including the updated UI. Firmware versions are from the previously documented setup. |
| PA01 | ELRS 4.1.0; module unspecified | Unknown | Community tester reported the current published release (0.3.0) working correctly. Report confirmed by the maintainer. |

The 0.3.0 release uses the same widget behavior as the tested 0.3.0-dev.3 build. Receiver model, receiver firmware and test duration have not been recorded. No in-flight validation has been recorded. New reports should include these details so the list remains useful as firmware and hardware change.

### Simulator coverage

These targets passed native EdgeTX **2.12.5** tests. Physical-radio reports are recorded above; the simulator firmware version does not identify the firmware used by community testers.

| Radio / target | Resolution | Evidence |
| --- | --- | --- |
| TX16S MK3 | 800 × 480 | Native simulator; physical report above |
| TX16S | 480 × 272 | Native simulator only |
| TX15 | 480 × 320 | Native simulator only |
| NV14 | 320 × 480 | Native simulator only |
| PA01 | 320 × 240 | Native simulator; community physical-radio report above |

RF-mode names support **ELRS 3.x and 4.x**. Automatic RSSI thresholds remain **ELRS 4.x only**; use Manual or Off for 3.x. Unknown versions/modes retain a raw RFMD label, and ambiguous 3.x bands display `Band ?`. See [testing evidence and limits](docs/TESTING.md).

## Help and feedback

Open a bug report using the repository's issue form. Include radio model, exact EdgeTX and ELRS versions, receiver model, widget settings, a photograph or screenshot, and the complete error message. Never include binding phrases, credentials or a complete personal SD-card dump.

- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Telemetry and display reference](docs/TELEMETRY.md)
- [Architecture and function map](docs/DEVELOPMENT.md)
- [Contributing](CONTRIBUTING.md)
- [Changelog](CHANGELOG.md)

## License and attribution

Released under the [MIT License](LICENSE). This is an independent community project, not an official ExpressLRS, EdgeTX or RadioMaster product. Protocol and documentation references, screenshot provenance and test-runtime attribution are listed in [NOTICE](NOTICE.md).

## Support

[![Support SignalView on Ko-fi — help support ongoing development and radio testing.](docs/assets/support-signalview.svg)](https://ko-fi.com/pencilvestr)
