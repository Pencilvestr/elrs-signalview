# Contributing

Hardware test reports, clear bug reports, documentation corrections and focused pull requests are welcome.

## Reporting

Use the issue form that matches your report. Check existing issues first. Record exact versions rather than "latest" and distinguish a simulator result from a physical-radio test. Include the complete error text, view mode, settings and steps to reproduce. Redact personal data and never upload binding phrases, credentials or a personal SD-card backup.

## Code and layout changes

1. Describe the problem and the intended user-visible result before broad changes.
2. Keep changes focused and preserve bounded work in sample/draw loops.
3. Use plain Lua compatible with the tested EdgeTX environment; standard desktop Lua features are not all exposed by EdgeTX.
4. Run the project validator and Lua syntax check. For runtime changes, run relevant native tests and inspect screenshots.
5. Add meaningful regression coverage for the actual failure, not tests that repeat the implementation.
6. For layout changes, include before/after captures at affected resolutions and preserve readable labels and real telemetry gaps.
7. Update user documentation and changelog when settings or behavior change.

Tests, simulator adapters and dependencies do not belong in the installable widget directory. Never bundle generated radio settings, compiled Lua caches or simulator DLLs in releases.

## Pull requests

Explain the trigger, resulting behavior, validation performed and remaining limits. A simulator screenshot is not a hardware test. Do not claim support for a radio solely because its resolution matches an existing target.

By submitting a contribution, you agree that your contributed work can be distributed under this repository's MIT License. Keep third-party code or assets out unless their license and provenance are documented.
