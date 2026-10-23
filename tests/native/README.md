# Native EdgeTX tests

See [the testing guide](../../docs/TESTING.md) for prerequisites, commands, evidence levels and limitations. Run commands from the repository root.

The production widget is loaded from `WIDGETS/SignalView/main.lua`. `LabTest` is a test-only observer that forwards to it; the nineteen threshold and thirteen smoothing checks run in short stages to respect EdgeTX's per-call CPU limit. Test helpers are never included in the install ZIP.

`binding-manifest.json` pins official EdgeTX 2.12.5 library/archive hashes. Its runtime directory is repository-relative; an optional `SIGNALVIEW_RUNTIME` environment variable can select an existing verified directory. Do not change hashes just to make an unreviewed runtime load.

Fixture model/radio profiles were generated solely for simulation. Never substitute a personal radio SD-card dump and commit it. Generated results, bytecode, virtual SD cards and runtime DLLs are excluded from Git and packages.
