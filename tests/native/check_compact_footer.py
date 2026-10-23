"""Verify compact footer text centering in actual native framebuffer captures."""
from pathlib import Path
from PIL import Image
import json
here=Path(__file__).parent
checks={}
for radio in ['tx16smk3','tx16s','tx15','nv14','pa01']:
    im=Image.open(here/'results'/radio/'04-connected.png').convert('RGB')
    w,h=im.size
    wide=w>=600
    p=24 if wide else 8
    footer=h-(64 if wide else 36)
    bg=im.getpixel((0,0))
    cell=(w-2*p)/4
    for i in range(4):
        expected=p+(i+.5)*cell
        x0=int(p+i*cell);x1=int(p+(i+1)*cell)
        rows=[('label',footer+3,footer+22),('value',footer+23,h)] if wide else [('label',footer+2,footer+16),('value',footer+17,h)]
        for kind,y0,y1 in rows:
            xs=[x for y in range(y0,y1) for x in range(x0,x1) if im.getpixel((x,y))!=bg]
            checks[f'{radio}_{i}_{kind}']=bool(xs) and abs((min(xs)+max(xs))/2-expected)<=3
(here/'results/compact-footer-checks.json').write_text(json.dumps(checks,indent=2))
print(f'{sum(checks.values())}/{len(checks)} footer checks passed')
assert all(checks.values()),[k for k,v in checks.items() if not v]
