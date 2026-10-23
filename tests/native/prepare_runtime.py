"""Restore the pinned official runtime by extracting files, without installing it."""
from pathlib import Path
import argparse, hashlib, json, shutil, subprocess, urllib.request, zipfile
HERE=Path(__file__).resolve().parent
PROJECT=HERE.parents[1]

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--extractor',help='Path to a full 7z.exe with NSIS support')
    args=parser.parse_args()
    manifest=json.loads((HERE/'binding-manifest.json').read_text())
    url=manifest['source_url']
    if not url.startswith('https://github.com/EdgeTX/edgetx/releases/download/v2.12.5/'):
        raise RuntimeError('Unexpected download source')
    runtime=PROJECT/'.runtime/edgetx-2.12.5'
    downloads=PROJECT/'.cache/edgetx';downloads.mkdir(parents=True,exist_ok=True)
    archive=downloads/'edgetx-cpn-win64-v2.12.5.zip'
    def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
    if all((runtime/'bin'/name).exists() and sha(runtime/'bin'/name)==expected for name,expected in manifest['sha256'].items()):
        print('Existing pinned runtime verified; no downloads or extraction needed.')
        return
    if not archive.exists():
        print('Downloading pinned official EdgeTX package...',flush=True)
        urllib.request.urlretrieve(url,archive)
    if sha(archive)!=manifest['archive_sha256']:raise RuntimeError('Source archive fingerprint mismatch')
    with zipfile.ZipFile(archive) as z:
        name='companion-windows-2.12.5.exe'
        with z.open(name) as source,(downloads/name).open('wb') as dest:shutil.copyfileobj(source,dest)
    candidates=[args.extractor,shutil.which('7z'),r'C:\Program Files\7-Zip\7z.exe',r'C:\Program Files\NVIDIA Corporation\NVIDIA App\7z.exe']
    extractor=next((p for p in candidates if p and Path(p).is_file()),None)
    if not extractor:raise RuntimeError('Provide --extractor pointing to a full 7-Zip executable; nothing was installed')
    required=list(manifest['sha256'])
    subprocess.run([extractor,'x',str(downloads/name),'-o'+str(runtime),'-y']+['bin\\'+p for p in required],check=True)
    for name in required:
        if sha(runtime/'bin'/name)!=manifest['sha256'][name]:raise RuntimeError('Extracted fingerprint mismatch: '+name)
    print('Pinned runtime ready. Installer was not executed. Installed Companion was not changed.')

if __name__=='__main__':main()
