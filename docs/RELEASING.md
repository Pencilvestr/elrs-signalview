# Preparing a release

[Back to README](../README.md)

## Before publication

- Confirm the version in VERSION, the Lua header and CHANGELOG.
- Run the project validator, Lua 5.3 syntax check and relevant native simulator tests.
- Inspect screenshots for every supported resolution; check warning/stale states and full history.
- Check the generated install ZIP contains only `WIDGETS/SignalView/main.lua`, INSTALL.txt and LICENSE.
- Record hardware test versions/duration if available; do not promote simulator-only targets to hardware-tested.
- Confirm source/docs agree about shared CRSF discovery, Auto 4.x limits and recovery behavior.
- Review issues/PR templates, image provenance, attribution and absence of private paths or credentials.

## Build

```text
python tools/check_project.py
python tools/build_release.py
```

The deterministic ZIP and SHA-256 file appear in `dist/`. The packaging script reads an allowlist; it never bundles DLLs, virtual radio settings, simulator logs or the developer's workspace.

## GitHub setup

Create the public repository as `Pencilvestr/elrs-signalview` when ready. Suggested description: "ExpressLRS link-status and history widget for EdgeTX color-screen radios."

Suggested topics: `edgetx`, `expresslrs`, `lua`, `telemetry`, `radiomaster`, `widget`.

Enable Issues and GitHub Actions. Optionally enable Discussions and private vulnerability reporting. The included workflow is read-only and does not publish or create tags automatically. It checks source syntax, repository links/assets and release packaging. Native tests remain a documented Windows procedure.

Use a tag matching the version, such as `v0.2.0-beta.1`, and mark the first release as a prerelease. Upload the install ZIP and its SHA-256 file. Paste [the prepared release notes](RELEASE-NOTES.md) after confirming they match the final test record. Keep source archives distinct from the install ZIP.

Publishing is a separate action from preparing this repository. Do not claim a repository, tag, CI run or release exists until it has actually been created and checked.
