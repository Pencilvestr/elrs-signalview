local app=loadScript('/WIDGETS/SignalView/main.lua')()
local cases={
 {'normal',1000,1120,1010,false,false,true,true},
 {'jitter_boundary',1000,1120,1100,false,false,true,true},
 {'jitter_tail',1000,1120,1119,false,false,true,true},
 {'fractional_drag',1000,1120,1119.9,false,false,true,true},
 {'next_sample',1000,1120,1120,false,false,true,true},
 {'missing_second',1000,1320,1110,false,false,false,false},
 {'reconnection',1000,1120,1110,true,false,false,false},
 {'partial_rssi_gap',1000,1120,1110,false,true,true,false},
 {'outage_middle',1000,5320,3500,true,false,false,false},
 {'near_full_second_jitter',1000,1199,1198,false,false,true,true}}
local step=0
local function refresh(w,event)
 if event==nil or step>=#cases then return end
 step=step+1
 local c=cases[step]
 local f=app.create({x=0,y=0,w=LCD_W,h=LCD_H},{})
 f.moduleMajor=4;f.moduleVersion='4.0.0'
 local color=lcd.RGB(255,255,255)
 f.archive={head=2,count=2,time={c[2],c[3]},quality={99,98},rx1={-62,-63},rx2={-65,-66},color1={color,color},color2={color,color},color3={color,color},breaks={false,c[5]},antenna={1,1}}
 if c[6] then f.archive.rx1[1]=nil;f.archive.color2[1]=nil end
 app.review.render(f,c[4])
 local q=f.reviewView.sensors[1].current==true
 local a=f.reviewView.sensors[2].current==true
 print('SCROLLGAP|'..c[1]..'|'..tostring(q==c[7] and a==c[8])..'|LQ='..tostring(q)..'|ANT1='..tostring(a))
 if step==#cases then print('SCROLLGAPDONE') end
end
return {name='LabTest',options=app.options,create=app.create,update=app.update,refresh=refresh,background=function() end}
