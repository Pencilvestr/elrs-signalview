"""Build a deterministic, allowlisted SD-card install ZIP with SHA-256."""
from pathlib import Path
import hashlib
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    version = (ROOT / 'VERSION').read_text().strip()
    if not re.fullmatch(r'\d+\.\d+\.\d+(?:-[a-z0-9.]+)?', version):
        raise ValueError('Invalid VERSION')
    destination = ROOT / 'dist'
    destination.mkdir(exist_ok=True)
    filename = f'elrs-signalview-{version}.zip'
    archive = destination / filename
    instructions = f'''ELRS SignalView {version}

Copy WIDGETS into the root of your EdgeTX SD card, preserving other widgets.
The final path must be /WIDGETS/SignalView/main.lua.
Restart the radio and choose SignalView in the model's widget setup.
Use one widget with the top bar OFF, or open full screen. Small areas stay blank.

Migrating from ELRS Diag: remove the old instance, add SignalView, and re-enter
any custom settings. The product name and install directory have changed.

Defaults: LQ amber 80%, LQ red 60%, RSSI mode Auto, Manual RX amber/red
-98/-103 dBm, Recover s 1. Auto is for confirmed ELRS 4.x only. RSSI mode is
a text field accepting Auto, Manual or Off. Record settings before upgrades.

This is a public beta. Begin with a bench test, with propellers
removed or the motor disconnected. See the project README for documentation,
testing limits and feedback instructions. Module-version discovery briefly
uses the shared CRSF Lua queue; avoid another querying widget during discovery.

No model or RF settings are written by the widget. No test files are installed.
'''
    entries = {
        'WIDGETS/SignalView/main.lua': (ROOT / 'WIDGETS/SignalView/main.lua').read_bytes(),
        'LICENSE': (ROOT / 'LICENSE').read_bytes(),
        'INSTALL.txt': instructions.encode('utf-8'),
    }
    with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as output:
        for name, content in sorted(entries.items()):
            info = zipfile.ZipInfo(name, date_time=(2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            output.writestr(info, content)
    with zipfile.ZipFile(archive) as output:
        assert set(output.namelist()) == set(entries)
        assert output.testzip() is None
        for name, content in entries.items():
            assert output.read(name) == content
    digest = hashlib.sha256(archive.read_bytes()).hexdigest()
    (destination / (filename + '.sha256')).write_text(f'{digest}  {filename}\n', encoding='ascii')
    print(f'Built {archive.name}; verified {len(entries)} files; SHA-256 {digest}')


if __name__ == '__main__':
    main()
