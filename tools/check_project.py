"""Dependency-free checks for public structure, links, assets and source metadata."""
from pathlib import Path
import ast
import hashlib
import json
import re
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
IGNORED = {'.git', 'dist', '.runtime', '.cache', '__pycache__', 'results',
           'large-zone-probe', 'settings-persistence', 'endurance', '.venv'}


def public_files():
    return [p for p in ROOT.rglob('*') if p.is_file()
            and not any(part in IGNORED for part in p.relative_to(ROOT).parts)
            and p.suffix not in {'.log', '.luac', '.pyc'}]


def main():
    required = ['README.md', 'LICENSE', 'NOTICE.md', 'VERSION', 'CHANGELOG.md',
                'CONTRIBUTING.md', 'CODE_OF_CONDUCT.md', 'SECURITY.md',
                'WIDGETS/SignalView/main.lua', 'docs/INSTALLATION.md',
                'docs/SETTINGS.md', 'docs/TELEMETRY.md', 'docs/RF-MODES.md',
                'docs/DEVELOPMENT.md', 'docs/TESTING.md', 'docs/SCREENSHOTS.md',
                'docs/images/manifest.json', '.github/workflows/validate.yml']
    errors = [f'Missing {name}' for name in required if not (ROOT / name).is_file()]
    source = (ROOT / 'WIDGETS/SignalView/main.lua').read_text(encoding='utf-8-sig')
    version = (ROOT / 'VERSION').read_text().strip()
    if version not in source.splitlines()[0]:
        errors.append('VERSION and Lua header differ')
    if 'name="SignalView"' not in source:
        errors.append('Unexpected EdgeTX picker name')
    if not (ROOT / 'LICENSE').read_text().startswith('MIT License'):
        errors.append('Unexpected license')
    text_files = {'.md', '.lua', '.py', '.yml', '.yaml', '.json', '.txt'}
    links = 0
    for path in public_files():
        if path.suffix not in text_files:
            continue
        text = path.read_text(encoding='utf-8-sig')
        if re.search(r'[\U0001f300-\U0001faff]', text):
            errors.append(f'Emoji found in {path.relative_to(ROOT)}')
        if re.search(r'[A-Z]:\\Users\\|/U[s]ers/|/h[o]me/[^/\s]+/', text):
            errors.append(f'Personal absolute path in {path.relative_to(ROOT)}')
        if path.suffix == '.py':
            try:
                ast.parse(text, filename=str(path.relative_to(ROOT)))
            except SyntaxError as error:
                errors.append(str(error))
        if path.suffix == '.md':
            for target in re.findall(r'!?\[[^\]]*\]\(([^)]+)\)', text):
                target = target.strip().split(' "', 1)[0].strip('<>')
                if '://' in target or target.startswith(('#', 'mailto:')):
                    continue
                local = unquote(target.split('#', 1)[0])
                resolved = (path.parent / local).resolve()
                if not resolved.is_relative_to(ROOT.resolve()) or not resolved.exists():
                    errors.append(f'Broken/escaping local link in {path.relative_to(ROOT)}: {target}')
                links += 1
    manifest = json.loads((ROOT / 'docs/images/manifest.json').read_text())
    for entry in manifest['images']:
        path = ROOT / 'docs/images' / entry['file']
        if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != entry['sha256']:
            errors.append(f'Image checksum mismatch: {entry["file"]}')
    for path in (ROOT / 'WIDGETS').rglob('*'):
        if path.is_file() and path.relative_to(ROOT).as_posix() != 'WIDGETS/SignalView/main.lua':
            errors.append(f'Unexpected install payload: {path.relative_to(ROOT)}')
    if errors:
        raise SystemExit('\n'.join(errors))
    print(f'Project checks passed: {len(required)} required files, {links} local links, '
          f'{len(manifest["images"])} screenshot checksums, Python syntax and no private paths/emojis.')


if __name__ == '__main__':
    main()
