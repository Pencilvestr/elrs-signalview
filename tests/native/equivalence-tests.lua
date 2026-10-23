-- Independent before/after oracle: run one renderer per callback, then compare
-- every LCD command and sampled state under an identical synthetic clock.
local originalLCD=lcd
local apps={loadScript('/WIDGETS/LabTest/reference.lua')(),loadScript('/WIDGETS/SignalView/main.lua')()}
local widgets={}
local names={'RQly','1RSS','2RSS','RSNR','RFMD','TPWR','TQly','TRSS','TSNR','ANT'}
local sizes={{800,480},{480,272},{480,320},{320,480},{320,240}}
local case,side=1,1
local expected
local actual
local compareAt=1
local keys={'LCD_W','LCD_H','lcd','getTime','getVersion','getFieldInfo','getSourceValue','sources'}
return function()
  if side==3 then
    assert(#actual==#expected,'Command count differs at case '..case)
    for i=compareAt,math.min(#actual,compareAt+39) do
      local a,b=actual[i],expected[i]
      assert(#a==#b,'Argument count differs at case '..case)
      for j=1,#a do assert(a[j]==b[j],'Output differs at case '..case..' command '..i..' argument '..j) end
    end
    compareAt=compareAt+40
    if compareAt>#actual then
      print('EQUIV|'..case..'|true')
      side=1;case=case+1;expected=nil;actual=nil;compareAt=1
    end
    return case>130
  end
  local saved={}
  for _,key in ipairs(keys) do saved[key]=_G[key] end
  local commands={}
  local ok,err=pcall(function()
    local size=sizes[(case-1)%5+1]
    LCD_W,LCD_H=size[1],size[2]
    local tick=case<90 and case*40 or (case-90)*40
    function getTime() return tick end
    function getVersion() return 'test','test' end
    local idOffset=case>=70 and 100 or 0
    function getFieldInfo(name)
      if case>=45 and case<55 then return nil end -- enumeration fallback
      for i,n in ipairs(names) do if n==name then return {id=i+idOffset} end end
    end
    function sources()
      local i=0
      return function()
        i=i+1
        if names[i] then return i+idOffset,string.lower(names[i]) end
      end
    end
    local values={99-case%55,-62-case%45,-65-case%43,8-case%12,
      case%17==0 and 255 or (case%7==0 and 27 or 29),250,97-case%40,-75,6,1}
    function getSourceValue(id)
      local i=id-idOffset
      return values[i],case%19~=0 and not (i==3 and case%11==0),true
    end
    local function record(kind,...)
      commands[#commands+1]={kind,...}
    end
    lcd={RGB=originalLCD.RGB,drawText=function(...) record('text',...) end,
      drawLine=function(...) record('line',...) end,
      drawFilledRectangle=function(...) record('rect',...) end,
      exitFullScreen=function() record('exit') end}
    local app=apps[side]
    local w=widgets[side]
    if not w then
      w=app.create({x=0,y=0,w=LCD_W,h=LCD_H},{})
      w.moduleVersion='4.0.0';w.moduleMajor=4
      widgets[side]=w
    end
    w.zone={x=0,y=0,w=LCD_W,h=LCD_H}
    if case%13==0 then w.zone={x=10,y=10,w=160,h=80} end
    if case==20 or case==40 or case==70 or case==100 then
      app.update(w,{['RSSI mode']=case==20 and 'Manual' or 'Auto',
        ['RX amber']=-90,['RX red']=-100,['Recover s']=case==40 and 0 or 1,
        ['Footer 1']=8+idOffset,['Footer 2']=9+idOffset,['Footer 3']=10+idOffset,['Footer 4']=7+idOffset})
    end
    app.background(w)
    local event=case%4~=0 and 0 or nil
    if case%29==0 then event=EVT_VIRTUAL_EXIT end
    app.refresh(w,event)
    for i,s in ipairs(w.sensors) do record('sensor',i,s.id or '-',s.value or '-',s.current,s.state) end
    for i,color in ipairs(w.displayColors or {}) do record('color',i,color) end
    for i,p in ipairs(w.plotHistory or {}) do
      record('bucket',i,p.time,p.second,p[1] or '-',p[2] or '-',p[3] or '-',
        p.colors[1] or '-',p.colors[2] or '-',p.colors[3] or '-',
        p.gap[1] or false,p.gap[2] or false,p.gap[3] or false)
    end
  end)
  for _,key in ipairs(keys) do _G[key]=saved[key] end
  assert(ok,err)
  if side==1 then expected=commands;side=2
  else
    actual=commands;side=3
  end
  return case>130
end
