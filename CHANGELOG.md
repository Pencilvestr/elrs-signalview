# Changelog

## 0.3.0 — pending release approval

- Infer one or two usable antenna telemetry paths after a one-second detection period.
- Add Auto / Single / Dual antenna display selection.
- Center single-antenna RSSI, identify the selected antenna, and show one solid history trace.
- Retain detected dual layout through telemetry loss; filter zero/invalid RSSI from main readings and history.
- Maintainer confirmed the 0.3.0-dev.3 build working on the TX16S MK3.
- Show readable ELRS 3.x/4.x RF modes with modulation and band in the MK3 split footer cell.
- Use raw RFMD for unknown versions/modes; mark ambiguous 3.x bands as `Band ?`.
- Show readable RF-mode names on compact screens within the existing footer spacing; RSSI threshold policy is unchanged.
- Place a muted dBm unit beside each antenna reading; center the full reading/unit group in single-antenna view.
- Refresh screenshots and the README animation, starting disconnected before showing connection and changing signals.

## 0.2.0 — 2026-10-23

First non-beta release. Includes the selectable ELRS footer from beta.3.

- Remove the unused duplicate raw-history buffer; keep the displayed 30-second weakest-value history and acquisition cadence.
- Cache plot geometry and formatted readings, reuse display colors, and compare recovery contexts without temporary strings.
- Use direct known-source lookup before case-insensitive enumeration.
- Fix a large-screen missing-antenna fallback that could draw Link Quality as receiver signal.
- Add isolated profiling and bounded before/after output comparisons.

## 0.2.0-beta.3 — 2026-10-23

- Select each footer reading with EdgeTX's native source picker.
- Support ten ELRS link sensors; preserve existing default readings and layout.
- Show unsupported selections and unavailable telemetry clearly.
- Add source-selection, saved-settings and rendering tests.
- Record successful MK3 testing with slight lag reported. Performance work is deferred.

## 0.2.0-beta.2 — 2026-10-22

- Move the large-screen RSSI Auto/Manual threshold label up eight pixels to clear the divider, preserving all other layout positions.
- Add a framebuffer check for the gap below that label.
- Record successful maintainer testing of the spacing fix on a TX16S MK3 with EdgeTX 2.12.5 and internal ELRS 4.0.0.
- Refresh simulator screenshots and the animated demonstration.

## 0.2.0-beta.1 — 2026-10-22

First named public beta release.

### Added

- ELRS SignalView project identity and SignalView picker name.
- User guides, telemetry/settings references, annotated source and screenshot provenance.
- GitHub issue forms, contribution guidance and lightweight validation workflow.
- Reproducible install packaging and portable native-test instructions.

### Carried forward from development

- Dark full-screen and single-large-area dashboard with compact and portrait layouts.
- Independent antenna readings, dual history graphs and centered footer text.
- Configurable LQ/RSSI thresholds, Auto 4.x mode mapping and delayed recovery.
- Bounded-history CPU fix and continuous left-edge clipping.
- Brief module-version discovery and safe header fallback.
- Native tests and maintainer MK3 bench feedback.

The original ELRS Diag development build used the internal 0.1.0 label throughout iterative prototyping; those iterations were not separately published releases.
