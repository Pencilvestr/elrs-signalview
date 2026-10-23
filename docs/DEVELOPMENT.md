# Architecture and development

[Back to README](../README.md)

## Repository map

```text
WIDGETS/SignalView/main.lua   Installable widget; no runtime dependencies
docs/                       User guides, references and real simulator screenshots
tests/native/               Windows native EdgeTX simulator adapter and fixtures
tools/                      Repository validation and deterministic ZIP packaging
.github/                    Issue forms, PR template and lightweight CI
VERSION                     Beta package version
CHANGELOG.md                Human-readable release history
```

## Runtime structure

The widget is intentionally a single installable Lua file. Supporting documentation and test adapters do not belong on the radio SD card. `main.lua` contains acquisition, threshold classification, history and two renderers; there are no remote libraries, fonts or image assets to install.

| Function / block | Responsibility |
| --- | --- |
| `definitions`, `C`, `sensitivity` | Sensor schema, palette and ELRS 4.x RFMD sensitivity map |
| `scan` | Case-insensitive source lookup, cached IDs and periodic rediscovery |
| Initial `sample` | Rate-limited source acquisition and current/fresh/stale state |
| `thresholds` | Auto/Manual/Off and validation; effective RSSI boundaries |
| `severity` | Raw white/amber/red/muted classification |
| `smooth` | Independent current-reading recovery timers and margins |
| Extended `sample` | Raw history, stored colors and bounded one-second plot buckets |
| `defaults` | Public option labels to copied internal settings |
| `create`, `update` | Per-instance construction and settings updates |
| `text`, `rect`, `line` | Coordinate translation for the selected drawing area |
| `versionHeader`, `discoverVersion` | Bounded foreground CRSF version discovery and header fallback |
| `value`, `displayColor` | Formatting and current-color lookup |
| `compactDashboard` | Approved compact landscape/portrait rendering |
| `dashboard` | Large-screen rendering and renderer selection |
| `refresh` | Full-screen/large-zone eligibility, background clearing and exit handling |
| `background` callback | Uses sampling without version queries or drawing |

`status` is a retained diagnostic helper, currently unused by the dashboard.

## Timing and state

EdgeTX `getTime()` returns centiseconds. Acquisition interval is 20 ticks, rediscovery interval 200 ticks, graph window 3000 ticks and a one-second bucket 100 ticks. Version discovery uses a separate visible-only ten-second budget.

Each widget table owns sensor state, options, raw history, plot buckets, alert timers and cached module version. Shared drawing-origin locals are reset at the beginning of every synchronous refresh. There is no disk persistence in the widget itself; EdgeTX persists its option values.

Sensor slots 1–3 are deliberately shared with the history schema: LQ, antenna 1 and antenna 2. Altering that order requires changes to both renderers and tests.

## Performance constraints

The first development renderer traversed up to 151 raw samples for three traces and hit EdgeTX's CPU limit on a physical MK3. The current renderers draw at most 32 buckets per trace, retain a predecessor for clipping, and use scalar previous-point coordinates. Do not restore raw-buffer rendering or add unbounded frame/packet loops.

Never infer healthy values from missing sources or connect a trace across missing data. Version discovery is the only CRSF queue consumer; do not move it into `background` or add recurring parameter requests. The current code has no RF-setting or model writes.

## Working on changes

1. Keep layout changes separate from acquisition/threshold logic.
2. Run `python tools/check_project.py` and compile `main.lua` with Lua 5.3.
3. Run the native simulator suite for affected resolutions. See [TESTING.md](TESTING.md).
4. Inspect actual screenshots for overlap, clipping, labels, gaps and colors. Runtime PASS alone does not validate appearance.
5. Exercise a full 30-second history window when changing sample/drawing loops.
6. Update documentation, screenshot provenance and release notes when behavior changes.

The renamed beta preserves the previously bench-tested executable Lua behavior except the picker name, which changes from ELRS Diag to SignalView. Added comments do not add runtime work.

## Release process

See [RELEASING.md](RELEASING.md). GitHub CI performs lightweight syntax, link/asset and packaging checks. It does not claim to run the native Windows simulator, emulate RF, or test hardware.
