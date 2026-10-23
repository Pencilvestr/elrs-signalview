"""Run native firmware tests in isolated processes and produce a result gallery."""
from pathlib import Path
import argparse, concurrent.futures, hashlib, html, json, subprocess, sys, time
from PIL import Image
HERE=Path(__file__).resolve().parent
SIZES={'tx16smk3':(800,480),'tx16s':(480,272),'tx15':(480,320),'nv14':(320,480),'pa01':(320,240)}
RUN_ROOT=HERE/'results'

def run_one(radio):
    run=RUN_ROOT/radio;run.mkdir(parents=True,exist_ok=True)
    start=time.monotonic()
    with (run/'firmware.log').open('w',encoding='utf-8') as log:
        try:
            proc=subprocess.run([sys.executable,str(HERE/'worker.py'),'--radio',radio,'--run-dir',str(run)],
                                stdout=log,stderr=subprocess.STDOUT,timeout=75)
            code=proc.returncode
        except subprocess.TimeoutExpired:code=-1
    content=(run/'firmware.log').read_text(encoding='utf-8',errors='replace')
    phases={};phase='startup'
    for line in content.splitlines():
        if line.startswith('PHASE|'):phase=line.split('|')[1]
        if line.startswith('NATIVE|'):phases.setdefault(phase,[]).append(line)
    def contains(phase,*tokens):
        return any(all(t in row for t in tokens) for row in phases.get(phase,[]))
    copied=run/'sd/WIDGETS/SignalView/main.lua'
    expected=HERE.parents[1]/'WIDGETS/SignalView/main.lua'
    checks={
      'native_process_exit':code==0,
      'production_widget_loaded':'Loaded Lua widget SignalView' in content,
      'observer_loaded':'Loaded Lua widget LabTest' in content,
      'production_lua_unchanged':copied.exists() and copied.read_bytes()==expected.read_bytes(),
      'real_fullscreen_event':any('|true|' in row for rows in phases.values() for row in rows),
      'before_telemetry_not_current':contains('startup','RQly=nil,NO VALUE'),
      'connected_values':contains('connected','|true|','RQly=99,FRESH','1RSS=-62,FRESH','TPWR=250,FRESH','RFMD=29,FRESH'),
      'module_version_from_device_info':contains('connected','VERSION=4.0.0'),
      'changed_values':contains('changed','RQly=74,FRESH','1RSS=-88,FRESH','RSNR=-3,FRESH','TPWR=500,FRESH'),
      'warning_values':contains('warning','RQly=72,FRESH','1RSS=-96,FRESH','2RSS=-97,FRESH'),
      'critical_values':contains('critical','RQly=48,FRESH','1RSS=-103,FRESH','2RSS=-105,FRESH'),
      'firmware_sensor_timeout':contains('stale','RQly=74,STALE','1RSS=-88,STALE'),
      'recovery_without_restart':contains('recovery','RQly=98,FRESH','1RSS=-62,FRESH'),
      'exit_returns_to_widget_mode':contains('exit','|false|'),
      'no_lua_runtime_error':not any(t in content for t in ['PANIC','Script syntax error','Script error','attempt to call','attempt to index','not enough memory','CPU limit','Error in widget']),
    }
    threshold_rows=[line.split('|') for line in content.splitlines() if line.startswith('THRESHOLD|')]
    checks['threshold_scenarios']=len(threshold_rows)==19 and all(row[2]=='true' for row in threshold_rows)
    smooth_rows=[line.split('|') for line in content.splitlines() if line.startswith('SMOOTH|')]
    checks['smoothing_scenarios']=len(smooth_rows)==13 and all(row[2]=='true' for row in smooth_rows)
    footer_rows=[line.split('|') for line in content.splitlines() if line.startswith('FOOTER|')]
    checks['footer_scenarios']=len(footer_rows)==14 and all(row[2]=='true' for row in footer_rows)
    images=[]
    for p in sorted(run.glob('*.png')):
        with Image.open(p) as im:
            checks['frame_'+p.stem]=im.size==SIZES[radio] and len(im.getcolors(im.width*im.height) or [])>10
        images.append(p.name)
    captured=[line.split('|',1)[1]+'.png' for line in content.splitlines() if line.startswith('CAPTURE|')]
    checks['ten_expected_frames']=len(images)==10 and sorted(captured)==images
    version=next((row.split('|')[3] for rows in phases.values() for row in rows),'unknown')
    manifest=json.loads((HERE/'binding-manifest.json').read_text())
    checks['expected_firmware_version']=version==manifest['firmware_expected']
    result={'radio':radio,'firmware':version,'size':SIZES[radio],'status':'PASS' if all(checks.values()) else 'FAIL',
            'exit_code':code,'checks':checks,'images':images,'elapsed_seconds':round(time.monotonic()-start,2),
            'widget_sha256':hashlib.sha256(expected.read_bytes()).hexdigest()}
    (run/'result.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(radio,result['status'],[k for k,v in checks.items() if not v],flush=True)
    return result

def main():
    global RUN_ROOT
    parser=argparse.ArgumentParser();parser.add_argument('--radios',nargs='+',choices=SIZES,default=list(SIZES));parser.add_argument('--report-only',action='store_true');args=parser.parse_args()
    RUN_ROOT=HERE/'results'
    if args.report_only:
        expected=HERE.parents[1]/'WIDGETS/SignalView/main.lua'
        current_hash=hashlib.sha256(expected.read_bytes()).hexdigest()
        results=[json.loads((RUN_ROOT/radio/'result.json').read_text()) for radio in args.radios]
        if any(r['widget_sha256']!=current_hash for r in results):raise RuntimeError('Cannot report stale source results')
    else:
        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:results=list(pool.map(run_one,args.radios))
    dest=RUN_ROOT;dest.mkdir(exist_ok=True)
    report={'status':'PASS' if all(r['status']=='PASS' for r in results) else 'FAIL','radios':results,
            'method':'Installed Companion native firmware DLLs, original Lua, injected CRSF link-statistics packets, direct RGB565 framebuffer copies',
            'limitations':['Version coverage is the installed simulator build only','Sensor definitions are preconfigured; interactive discovery is not tested',
                           'No physical RF link or radio hardware performance test','Minimal SD assets; splash/audio assets absent',
                           'Adapter uses exact-build MSVC x64 exported C++ ABI and refuses changed library hashes']}
    (dest/'test-results.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    parts=['<!doctype html><meta charset="utf-8"><title>Native EdgeTX firmware tests</title><style>body{background:#0c121c;color:#ebf2fa;font:16px system-ui;margin:28px}section{margin:24px 0}article{display:flex;flex-wrap:wrap;gap:16px}figure{margin:0;background:#17212f;padding:12px}img{max-width:800px;width:100%;height:auto}figcaption{padding:8px}a{color:#40d7be}</style><h1>Actual EdgeTX firmware captures</h1><p>Original widget, installed simulator firmware, injected CRSF telemetry. These are framebuffer screenshots, not mock previews.</p><p>Overall: '+report['status']+' · <a href="test-results.json">Detailed test results</a></p>']
    for r in results:
        parts.append(f'<section><h2>{r["radio"]} / {r["size"][0]} × {r["size"][1]} / EdgeTX {html.escape(r["firmware"])} / {r["status"]}</h2><a href="{r["radio"]}/firmware.log">Firmware log</a><article>')
        for name in r['images']:parts.append(f'<figure><a href="{r["radio"]}/{name}"><img src="{r["radio"]}/{name}" loading="lazy"></a><figcaption>{name}</figcaption></figure>')
        parts.append('</article></section>')
    parts.append('<p>Preconfigured telemetry sensors. Results do not establish compatibility with newer firmware, every radio model, physical RF links, or hardware performance.</p>')
    page=''.join(parts)
    (dest/'index.html').write_text(page,encoding='utf-8')
    if report['status']!='PASS':sys.exit(1)

if __name__=='__main__':main()



