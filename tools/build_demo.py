"""Build the README GIF from continuous native --demo captures (requires Pillow)."""
from pathlib import Path
from datetime import date
import hashlib
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def main():
    paths = sorted((ROOT / 'tests/native/results/demo').glob('demo-*.png'))
    if len(paths) != 96:
        raise SystemExit('Expected 96 frames from the native worker --demo run')
    frames = [Image.open(path).convert('RGB') for path in paths]
    # Use one palette throughout so colors remain stable between frames.
    atlas = Image.new('RGB', (800, 480 * 4))
    for row, index in enumerate((0, 24, 48, 72)):
        atlas.paste(frames[index], (0, row * 480))
    palette = atlas.quantize(colors=128)
    indexed = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in frames]
    target = ROOT / 'docs/images/signalview-demo.gif'
    indexed[0].save(target, save_all=True, append_images=indexed[1:],
                    duration=250, loop=0, optimize=True, disposal=1)
    with Image.open(target) as gif:
        assert gif.n_frames == 96 and gif.size == (800, 480)
        assert gif.info['loop'] == 0
    manifest_path = ROOT / 'docs/images/manifest.json'
    manifest = json.loads(manifest_path.read_text())
    manifest['images'] = [entry for entry in manifest['images']
                          if entry['file'] != target.name]
    manifest['images'].append({
        'file': target.name, 'size': [800, 480], 'frames': 96,
        'duration_ms': 24000, 'sha256': hashlib.sha256(target.read_bytes()).hexdigest(),
        'origin': 'Continuous native MK3 simulator --demo capture; shared GIF palette',
        'captured_date': date.today().isoformat(),
        'source_sha256': hashlib.sha256((ROOT / 'WIDGETS/SignalView/main.lua').read_bytes()).hexdigest(),
        'synthetic_telemetry': True, 'synthetic_module_version': True})
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')
    print(f'Built {target.name}: 96 frames, 24 seconds, {target.stat().st_size:,} bytes')


if __name__ == '__main__':
    main()
