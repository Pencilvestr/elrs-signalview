"""Build the README GIF from continuous native --demo captures (requires Pillow)."""
from pathlib import Path
from datetime import date
import hashlib
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def main():
    paths = sorted((ROOT / 'tests/native/results/demo').glob('demo-*.png'))
    capture=json.loads((ROOT / 'tests/native/results/demo/demo-capture.json').read_text())
    source_hash=hashlib.sha256((ROOT / 'WIDGETS/SignalView/main.lua').read_bytes()).hexdigest()
    if len(paths)!=160 or capture['frames']!=160 or capture['widget_sha256']!=source_hash:
        raise SystemExit('Expected 160 current-source frames from the native worker --demo run')
    frames = [Image.open(path).convert('RGB') for path in paths]
    # Use one palette throughout so colors remain stable between frames.
    atlas = Image.new('RGB', (800, 480 * 8))
    for row, index in enumerate((0, 16, 32, 56, 80, 104, 128, 159)):
        atlas.paste(frames[index], (0, row * 480))
    palette = atlas.quantize(colors=128)
    indexed = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in frames]
    target = ROOT / 'docs/images/signalview-demo.gif'
    indexed[0].save(target, save_all=True, append_images=indexed[1:],
                    duration=250, loop=0, optimize=True, disposal=1)
    with Image.open(target) as gif:
        assert 1<gif.n_frames<=160 and gif.size == (800, 480)
        assert gif.info['loop'] == 0
        encoded_frames=gif.n_frames
        duration=0
        for index in range(encoded_frames):
            gif.seek(index);duration+=gif.info['duration']
        assert duration==40000
    manifest_path = ROOT / 'docs/images/manifest.json'
    manifest = json.loads(manifest_path.read_text())
    manifest['images'] = [entry for entry in manifest['images']
                          if entry['file'] != target.name]
    manifest['images'].append({
        'file': target.name, 'size': [800, 480], 'frames': encoded_frames,
        'captured_frames':160,'starts_disconnected':True,
        'duration_ms': duration, 'sha256': hashlib.sha256(target.read_bytes()).hexdigest(),
        'origin': 'Continuous native MK3 simulator --demo capture; shared GIF palette',
        'captured_date': date.today().isoformat(),
        'source_sha256': source_hash,
        'synthetic_telemetry': True, 'synthetic_module_version': True})
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')
    print(f'Built {target.name}: {encoded_frames} encoded frames, 40 seconds, {target.stat().st_size:,} bytes')


if __name__ == '__main__':
    main()
