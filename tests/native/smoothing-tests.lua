local keys={'LCD_W','LCD_H','tick','getTime','getVersion','names','values','current','sources','getFieldInfo','getSourceValue','w','white','amber','red','muted','checks','sample','app','p','original','raw','second'}
local saved,state={},{}
for _,k in ipairs(keys) do saved[k]=_G[k];state[k]=_G[k] end
local function enter() for _,k in ipairs(keys) do _G[k]=state[k] end end
local function leave() for _,k in ipairs(keys) do state[k]=_G[k];_G[k]=saved[k] end end
local steps={
function()
app=loadScript('/WIDGETS/SignalView/main.lua')()
LCD_W=800; LCD_H=480; tick=0
function getTime() return tick end
function getVersion() return 'test','test' end
names={'RQly','1RSS','2RSS','RSNR','RFMD','TPWR','TQly','TRSS','TSNR','ANT'}
values={99,-96,-97,8,29,250,97,-75,6,0}; current={}
function sources() local i=0;return function() i=i+1;if names[i] then return i,names[i] end end end
function getFieldInfo() end
function getSourceValue(id) return values[id],current[id]~=false,true end

w=app.create({x=0,y=0,w=800,h=480},{})
white=lcd.RGB(255,255,255); amber=lcd.RGB(255,195,106); red=lcd.RGB(255,116,116); muted=lcd.RGB(167,185,173)
checks={}
function sample() tick=tick+20;w.scanTime=tick;app.background(w);return w.lastSample end
current[2]=true;values[2]=-62;values[1]=99
app.update(w,{['Recover s']=1})
sample()
values[1]=50;sample();checks.immediate_degrade=w.displayColors[1]==red
values[1]=99;raw=sample();checks.recovery_held=w.displayColors[1]==red
end,
function()
checks.raw_history_recovers=raw.colors[1]==white
tick=tick+100;sample()
end,
function()
checks.recovery_after_delay=w.displayColors[1]==white
values[1]=70;sample();values[1]=81
tick=tick+160;sample()
end,
function()
checks.hysteresis_margin=w.displayColors[1]==amber
values[1]=82;sample();tick=tick+100;sample()
end,
function()
checks.hysteresis_clears=w.displayColors[1]==white
values[1]=40;sample();values[1]=99;sample();values[1]=40;sample();values[1]=99
sample();tick=tick+60;sample()
end,
function()
checks.interrupted_recovery=w.displayColors[1]==red
current[1]=false;sample();checks.stale_immediate=w.displayColors[1]==muted
current[1]=true;values[1]=99
app.update(w,{['RSSI mode']='Manual',['RX amber']=-90,['RX red']=-100,['Recover s']=0})
values[2]=-105;sample();values[2]=-60;sample()
end,
function()
checks.zero_delay=w.displayColors[2]==white
end,
function()
checks.named_manual=w.options.RSSImode==1
app.update(w,{['RSSI mode']='bad'});sample();checks.invalid_named_mode=w.displayColors[2]==muted
app.update(w,{['LQ amber']=50,['LQ red']=70});sample();checks.invalid_LQ=w.displayColors[1]==muted
second=app.create({x=0,y=0,w=800,h=480},{['LQ amber']=90})
end,
function()
checks.instance_settings_isolated=second.options.LQwarn==90 and w.options.LQwarn==50

for k,v in pairs(checks) do print('SMOOTH|'..k..'|'..tostring(v));assert(v,k) end
end
}
local index=1
return function()
 enter()
 local ok,err=pcall(steps[index])
 leave()
 assert(ok,err)
 index=index+1
 return index>#steps
end
