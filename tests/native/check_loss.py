"""Verify current-source loss scenarios and native frozen-history captures."""
from pathlib import Path
import hashlib
import json
import re
from PIL import Image, ImageChops

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
RUNS=HERE/'results'


def main():
    source=(ROOT/'WIDGETS/SignalView/main.lua').read_bytes()
    checks={}
    logs={}
    for name,folder in [('cases','cases'),('preview','preview')]:
        log=(RUNS/f'loss-{name}.log').read_text(encoding='utf-8')
        logs[name]=log
        checks[name+'_completed']='PHASE|complete' in log
        checks[name+'_no_errors']=not re.search(r'CPU limit|Error in widget|Script error|Script syntax error|PANIC|not enough memory',log)
        checks[name+'_current_source']=(RUNS/f'loss-development/{folder}/sd/WIDGETS/SignalView/main.lua').read_bytes()==source
    rows=re.findall(r'^LOSS\|([^|]+)\|(true|false)$',logs['cases'],re.M)
    checks['all_cases_passed']=len(rows)==len(set(n for n,_ in rows))==54 and all(v=='true' for _,v in rows)
    folder=RUNS/'loss-development/preview'
    with Image.open(folder/'loss-frozen.png') as first, Image.open(folder/'loss-still-frozen.png') as later:
        checks['frozen_graph_pixels_unchanged']=ImageChops.difference(first.crop((24,218,777,411)),later.crop((24,218,777,411))).getbbox() is None
        checks['loss_timer_advances']=ImageChops.difference(first.crop((400,180,777,210)),later.crop((400,180,777,210))).getbbox() is not None
    with Image.open(folder/'loss-live.png') as live, Image.open(folder/'loss-frozen.png') as lost, Image.open(folder/'loss-reconnected.png') as recovered:
        checks['live_readings_change_on_loss']=ImageChops.difference(live.crop((24,74,777,180)),lost.crop((24,74,777,180))).getbbox() is not None
        checks['live_readings_return']=ImageChops.difference(lost.crop((24,74,777,180)),recovered.crop((24,74,777,180))).getbbox() is not None
    report={'status':'PASS' if all(checks.values()) else 'FAIL',
            'widget_sha256':hashlib.sha256(source).hexdigest(),'cases':len(rows),'checks':checks,
            'limits':'Native EdgeTX 2.12.5 with synthetic packets. Does not prove receiver failsafe or physical RF-link loss.'}
    (RUNS/'loss-development/verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report,indent=2))
    if report['status']!='PASS':raise SystemExit(1)


if __name__=='__main__':main()
