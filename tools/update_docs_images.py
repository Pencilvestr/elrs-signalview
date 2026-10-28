"""Copy source-matched native screenshots into the public gallery (Pillow)."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
RUNS=ROOT/'tests/native/results'


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--date',required=True,help='Capture date, YYYY-MM-DD')
    args=parser.parse_args()
    source=(ROOT/'WIDGETS/SignalView/main.lua').read_bytes()
    digest=hashlib.sha256(source).hexdigest()
    version=(ROOT/'VERSION').read_text().strip()
    mapping={
        'mk3-normal.png':('tx16smk3','04-connected.png'),
        'mk3-warning.png':('tx16smk3','04b-warning.png'),
        'mk3-critical.png':('tx16smk3','04c-critical.png'),
        'mk3-stale.png':('tx16smk3','06-stale.png'),
        'mk3-no-connection.png':('demo','demo-000.png'),
        'mk3-single.png':('release-single','antenna-full-history.png'),
        'mk3-history.png':('../large-zone-probe','zone-full-history.png'),
        'settings.png':('release-settings','settings-saved.png'),
        'footer-source-picker.png':('release-settings','footer-source-picker.png'),
        'tx16s.png':('tx16s','04-connected.png'),
        'tx15.png':('tx15','04-connected.png'),
        'nv14.png':('nv14','04-connected.png'),
        'pa01.png':('pa01','04-connected.png')}
    manifest_path=ROOT/'docs/images/manifest.json'
    manifest=json.loads(manifest_path.read_text())
    entries={e['file']:e for e in manifest['images']}
    for directory,image in mapping.values():
        folder=RUNS/directory
        assert (folder/'sd/WIDGETS/SignalView/main.lua').read_bytes()==source,directory
        assert (folder/image).exists(),image
    for name,(directory,image) in mapping.items():
        target=manifest_path.parent/name
        shutil.copyfile(RUNS/directory/image,target)
        with Image.open(target) as im:size=list(im.size)
        entries[name]={'file':name,'size':size,
            'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),
            'origin':version+' native simulator run: '+directory+'/'+image,
            'captured_date':args.date,'source_sha256':digest,
            'synthetic_telemetry':True,'synthetic_module_version':True}
    manifest['images']=sorted(entries.values(),key=lambda e:e['file'])
    manifest_path.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    print(f'Updated {len(mapping)} source-matched screenshots')


if __name__=='__main__':main()
