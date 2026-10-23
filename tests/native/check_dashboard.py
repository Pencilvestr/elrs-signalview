"""Check actual MK3 framebuffer colors, allowing RGB565 quantization."""
from pathlib import Path
import json
from PIL import Image
root=Path(__file__).parent/'results'/'tx16smk3'
def count(name,box,target):
    im=Image.open(root/(name+'.png')).convert('RGB').crop(box)
    return sum(all(abs(a-b)<=8 for a,b in zip(pixel,target)) for pixel in im.getdata())
checks={}
for name,color in [('04-connected',(255,255,255)),('04b-warning',(255,195,106)),('04c-critical',(255,116,116))]:
    checks[name+'_LQ_text']=count(name,(24,102,300,182),color)>100
    checks[name+'_antenna_text']=count(name,(410,106,720,156),color)>100
checks['normal_green_bar']=count('04-connected',(24,196,296,202),(112,217,154))>500
checks['warning_history']=count('04b-warning',(60,240,776,395),(255,195,106))>10
checks['critical_history']=count('04c-critical',(60,240,776,395),(255,116,116))>10
checks['stale_has_no_current_LQ']=count('06-stale',(24,102,300,182),(255,255,255))==0
im=Image.open(root/'04-connected.png').convert('RGB')
bg=im.getpixel((0,404))
checks['time_labels_clear_separator']=all(pixel==bg for pixel in im.crop((24,404,776,410)).getdata())
(root/'dashboard-checks.json').write_text(json.dumps(checks,indent=2))
print(json.dumps(checks,indent=2))
assert all(checks.values())
