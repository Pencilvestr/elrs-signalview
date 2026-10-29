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
function sample() tick=tick+20;w.options.Recover=0;w.scanTime=tick;app.background(w);return w.lastSample end
p=sample()
end,
function()
app.update(w,{['RSSI mode']=1});p=sample()
assert(w.options.RSSImode==0 and p.colors[2]==amber,'Auto dropdown classification')
print('RSSIMODE|auto|true')
end,
function()
app.update(w,{['RSSI mode']=2,['RX amber']=-90,['RX red']=-100});p=sample()
assert(w.options.RSSImode==1 and p.colors[2]==amber,'Manual dropdown classification')
print('RSSIMODE|manual|true')
end,
function()
app.update(w,{['RSSI mode']=3});p=sample()
assert(w.options.RSSImode==2 and p.colors[2]==white,'Off dropdown classification')
print('RSSIMODE|off|true')
end,
function()
app.update(w,{['RSSI mode']='   '});p=sample()
assert(w.options.RSSImode==0 and p.colors[2]==amber,'Blank fallback must be Auto')
print('RSSIMODE|blank_defaults_auto|true')
app.update(w,{['RSSI mode']=0});p=sample()
assert(w.options.RSSImode==0 and p.colors[2]==amber,'Uninitialized choice must be Auto')
app.update(w,{});p=sample()
end,
function()
checks.auto_500Hz=p.colors[2]==amber and p.colors[3]==amber
original=p.colors[2]
values[5]=27;p=sample()
end,
function()
checks.mode_change_250Hz=p.colors[2]==white
end,
function()
checks.history_retains_color=w.plotHistory[1].colors[2]==original
values[5]=255;p=sample();checks.unknown_mode=p.colors[2]==muted
values[5]=29;current[5]=false;p=sample();checks.stale_mode=p.colors[2]==muted
current[5]=true;values[5]=13;p=sample();checks.no_legacy_guess=p.colors[2]==muted
app.update(w,{RSSImode=1,RSSIwarn=-90,RSSIcrit=-100});p=sample()
end,
function()
checks.manual_override=p.colors[2]==amber
values[2]=-101;p=sample();checks.manual_critical=p.colors[2]==red
app.update(w,{RSSImode=2});p=sample();checks.off=p.colors[2]==white
app.update(w,{RSSImode=1,RSSIwarn=-100,RSSIcrit=-90});p=sample()
end,
function()
checks.invalid_manual=p.colors[2]==muted
app.update(w,{})
for _,case in ipairs({{80,white},{79,amber},{60,amber},{59,red}}) do
 values[1]=case[1];p=sample();checks['LQ_'..case[1]]=p.colors[1]==case[2]
end
values[5]=27
for _,case in ipairs({{-97,white},{-98,amber},{-102,amber},{-103,red}}) do
 values[2]=case[1];p=sample();checks['RSSI_'..case[1]]=p.colors[2]==case[2]
end
current[2]=false;p=sample();checks.missing_antenna_gap=p[2]==nil
app.refresh(w,0)

for k,v in pairs(checks) do print('THRESHOLD|'..k..'|'..tostring(v));assert(v,k) end
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
