-- One acquisition/render action per callback, through the public widget API.
-- Firmware APIs are restored even when an assertion fails.
local app=loadScript('/WIDGETS/SignalView/main.lua')()
local names={'RQly','1RSS','2RSS','RSNR','RFMD','TPWR','TQly','TRSS','TSNR','ANT'}
local keys={'LCD_W','LCD_H','lcd','getTime','getVersion','getFieldInfo','getSourceValue','sources'}
local tick,values,current=0,{},{false,false,false}
local widget,snapshot,plots,anchor,lines
local actions={}
local function add(name,fn) actions[#actions+1]={name,fn} end
local function sample(time,mask,q,a,b)
  tick=time;current=mask
  values={q or 99,a or -62,b or -65,8,29,250,97,-75,6,0}
  app.background(widget)
end
local function digest(w)
  local parts={}
  for _,p in ipairs(w.plotHistory or {}) do
    parts[#parts+1]=table.concat({p.time,p.second,tostring(p[1]),tostring(p[2]),tostring(p[3]),
      tostring(p.colors[1]),tostring(p.colors[2]),tostring(p.colors[3]),tostring(p.breakBefore)},':')
  end
  return table.concat(parts,'|')
end
local function render(width,height)
  LCD_W,LCD_H=width,height
  local texts,segments={},{}
  local native=lcd
  lcd={sizeText=native.sizeText,drawFilledRectangle=function() end,
    drawText=function(x,y,s) texts[s]=true end,
    drawLine=function(...) local p={...};segments[#segments+1]=table.concat(p,',') end}
  widget.sampleTime=tick -- Render the same sampled instant without resampling.
  app.refresh(widget,true)
  return texts,table.concat(segments,'|'),#segments
end
add('startup_is_not_loss',function()
  widget=app.create({x=0,y=0,w=800,h=480},{['Recover s']=0})
  widget.moduleVersion='4.0.0';widget.moduleMajor=4
  sample(100,{false,false,false})
  assert(not widget.lossSince and not widget.plotHistory)
end)
for i=1,32 do
  local n=i
  add('record_'..i,function()
    sample(100+n*100,{},99-n,-62-n,-65-n)
    assert(not widget.lossSince and #widget.plotHistory<=32)
  end)
end
add('loss_preserves_last_bucket',function()
  snapshot=digest(widget);plots=widget.plotHistory;anchor=widget.historyEnd
  sample(3320,{false,false,false})
  assert(widget.lossSince==3320 and widget.historyEnd==anchor)
  assert(widget.plotHistory==plots and digest(widget)==snapshot)
end)
add('frozen_large_render',function()
  local texts
  texts,lines=render(800,480)
  assert(texts['Link data lost'] and texts['History frozen - 0 s'] and texts['Now'])
  assert(texts['--%'] and not texts['Telemetry current'])
  assert(widget.plotHistory[#plots].screenX==773)
end)
add('long_loss_retains_history',function()
  sample(123320,{false,false,false})
  assert(widget.plotHistory==plots and digest(widget)==snapshot and widget.historyEnd==anchor)
end)
add('long_loss_identical_render',function()
  local texts,after=render(800,480)
  assert(after==lines and texts['History frozen - 1200 s'])
end)
add('compact_frozen_render',function()
  local texts=render(320,240)
  assert(texts['Link data lost'] and texts['History frozen - 1200 s'] and texts['Now'])
end)
add('reconnect_marks_break',function()
  sample(123340,{})
  local p=widget.plotHistory[#widget.plotHistory]
  assert(not widget.lossSince and p.breakBefore and p[1]==99 and #widget.plotHistory<=32)
end)
add('no_line_across_long_outage',function()
  local texts,_,count=render(800,480)
  assert(count==0 and texts['Telemetry current'] and not texts['Link data lost'])
end)
add('record_after_reconnect',function() sample(123440,{}) end)
add('new_segment_renders',function()
  local _,_,count=render(800,480);assert(count==3)
end)
add('brief_loss',function() sample(123460,{false,false,false});assert(widget.lossSince) end)
add('same_second_reconnect_new_bucket',function()
  local count=#widget.plotHistory
  sample(123480,{})
  assert(#widget.plotHistory==count+1 and widget.plotHistory[#widget.plotHistory].breakBefore)
end)
add('no_line_across_brief_outage',function()
  local _,_,count=render(800,480);assert(count==3)
end)
add('compact_no_bridge',function()
  local _,_,count=render(320,240);assert(count==3)
end)
add('one_antenna_missing_continues',function()
  sample(123600,{true,true,false})
  assert(not widget.lossSince and widget.lastSample[2] and not widget.lastSample[3])
end)
add('rssi_only_continues',function()
  sample(123700,{false,true,false})
  assert(not widget.lossSince and widget.lastSample[2] and not widget.lastSample[1])
end)
add('lq_only_continues',function()
  sample(123800,{true,false,false})
  assert(not widget.lossSince and widget.lastSample[1] and not widget.lastSample[2])
end)
add('zero_lq_is_valid_data',function()
  sample(123900,{true,false,false},0)
  assert(not widget.lossSince and widget.lastSample[1]==0)
end)
add('missing_values_freeze',function()
  tick=124000;values={};current={};app.background(widget);assert(widget.lossSince)
  snapshot=digest(widget)
end)
add('other_instance_isolated',function()
  local other=app.create({x=0,y=0,w=800,h=480},{})
  tick=124100;values={99,-62,-65,8,29,250,97,-75,6,0};current={}
  app.background(other)
  assert(not other.lossSince and widget.lossSince and digest(widget)==snapshot)
end)
add('clock_reset_clears_frozen_history',function()
  sample(20,{false,false,false})
  assert(not widget.lossSince and not widget.historyEnd and not widget.plotHistory)
end)
add('connection_after_clock_reset',function()
  sample(120,{})
  assert(not widget.lossSince and #widget.plotHistory==1 and widget.historyEnd==120)
end)
local index=1
return function()
  local saved={};for _,key in ipairs(keys) do saved[key]=_G[key] end
  local action=actions[index]
  local ok,err=pcall(function()
    getTime=function() return tick end
    getVersion=function() return 'test','test' end
    getFieldInfo=function(name)
      for id,label in ipairs(names) do if name==label then return {id=id} end end
    end
    sources=nil
    getSourceValue=function(id) return values[id],current[id]~=false,true end
    action[2]()
  end)
  for _,key in ipairs(keys) do _G[key]=saved[key] end
  print('LOSS|'..action[1]..'|'..tostring(ok));assert(ok,err)
  index=index+1
  return index>#actions
end
