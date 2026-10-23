"""Confirm full-screen and normal single-widget appearance, blank small zones."""
from pathlib import Path
from PIL import Image
import re,json,hashlib
here=Path(__file__).parent
checks={}
for radio in ['tx16smk3','tx16s','tx15','nv14','pa01']:
    root=here/'results'/radio
    log=(root/'firmware.log').read_text()
    a=Image.open(root/'07-recovery.png').convert('RGB')
    b=Image.open(root/'08-exit.png').convert('RGB')
    w,h=a.size
    chart=218 if w>=600 else (126 if h>w else 108)
    footer=h-(64 if w>=600 else 36)
    for name,box in [('readings',(0,0,w,chart-8)),('footer',(0,footer,w,h))]:
        checks[f'{radio}_{name}_unchanged']=a.crop(box).tobytes()==b.crop(box).tobytes()
    checks[f'{radio}_small_area_blank']='AREA|small_blank|true' in log
root=here/'large-zone-probe'
log=(here/'large-zone-probe.log').read_text()
counts=[tuple(map(int,m)) for m in re.findall(r'HIST=(\d+),PLOT=(\d+)',log)]
normal_ticks=[int(x) for x in re.findall(r'^NATIVE\|(\d+)\|false\|',log.split('CAPTURE|zone-connected',1)[-1],re.M)]
checks['normal_view_full_history']=bool(counts) and max(x[1] for x in counts)>=30 and bool(normal_ticks) and max(normal_ticks)-min(normal_ticks)>=3800
checks['plot_work_bounded']=bool(counts) and all(x[1]<=32 for x in counts)
checks['normal_view_no_CPU_error']=not any(x in log for x in ['CPU limit','Error in widget','PANIC']) and 'PHASE|complete' in log
source=here.parents[1]/'WIDGETS/SignalView/main.lua'
checks['soak_used_current_source']=source.read_bytes()==(root/'sd/WIDGETS/SignalView/main.lua').read_bytes()
im=Image.open(root/'zone-full-history.png').convert('RGB')
for name,color,y0,y1 in [('RSSI',(112,217,154),246,284),('LQ',(118,186,255),339,377)]:
    checks[name+'_reaches_left_edge']=any(all(abs(a-b)<=8 for a,b in zip(im.getpixel((60,y)),color)) for y in range(y0,y1))
(here/'results/widget-area-checks.json').write_text(json.dumps(checks,indent=2))
print(json.dumps(checks,indent=2))
assert all(checks.values()),[k for k,v in checks.items() if not v]
