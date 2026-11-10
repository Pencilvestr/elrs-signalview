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

Updating from 0.4.0: replace the Lua and restart. Keep your existing widget
instance and settings. For older versions, see docs/INSTALLATION.md in the repo.

History review requires full screen. Hold the graph for one second and release,
or hold Enter. Scroll with the wheel/navigation controls or touch. Short Exit
or Live returns to current readings. History is a rolling, in-memory 15-minute
archive and clears on restart. Recording continues during review.

Theme defaults to Dark; Rich Ivory and White are also available.
History defaults to Both; Receiver Signal and Link Quality select one graph.
Antennas defaults to Auto; Single and Dual remain available.
LQ amber/red defaults are 80%/60%. Auto RSSI is for confirmed ELRS 4.x only;
use Manual or Off for other versions. Manual RX amber/red defaults: -98/-103 dBm.
Very early history windows may display negative uptime labels. See the
telemetry reference in the repository for limitations and discovery behavior.

Begin with a bench test, with propellers
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
