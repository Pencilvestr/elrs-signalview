# Changelog

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
