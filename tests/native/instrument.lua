-- Test-only observer. Production widget remains unchanged in its own folder.
local app=loadScript('/WIDGETS/SignalView/main.lua')()
local function observe(w,event,touch)
  if not w._areaTest then
    w._areaTest=true
    local original=lcd
    local count=0
    lcd={drawText=function() count=count+1 end,drawFilledRectangle=function() end,drawLine=function() count=count+1 end}
    local ok,err=pcall(function()
      local small=app.create({x=10,y=10,w=160,h=80},options)
      app.refresh(small,nil)
    end)
    lcd=original
    assert(ok,err);assert(count==0,'Small area must stay blank')
    print('AREA|small_blank|true')
  end
  if w._thresholdTest and w._thresholdTest() then w._thresholdTest=nil end
  if w._smoothTest and w._smoothTest() then w._smoothTest=nil end
  if not w._thresholdTest and not w._smoothTest and w._footerTest and w._footerTest() then w._footerTest=nil end
  app.refresh(w,event,touch)
  local now=getTime()
  if not w._labTick or now-w._labTick>=50 then
    w._labTick=now
    local row={'NATIVE',tostring(now),tostring(event~=nil),tostring(getVersion())}
    for _,s in ipairs(w.sensors) do
      row[#row+1]=s.name..'='..tostring(s.value)..','..s.state
    end
    local last=w.history and w.history[#w.history]
    if last then row[#row+1]='COLORS='..table.concat(last.colors,',') end
    row[#row+1]='HIST='..tostring(w.history and #w.history or 0)..',PLOT='..tostring(w.plotHistory and #w.plotHistory or 0)
    row[#row+1]='VERSION='..tostring(w.moduleVersion)
    print(table.concat(row,'|'))
  end
end
local function create(zone,options)
  local w=app.create(zone,options)
  print('ZONE|'..zone.x..'|'..zone.y..'|'..zone.w..'|'..zone.h)
  print('CONFIG|'..w.options.LQwarn..'|'..w.options.LQcrit..'|'..w.options.RSSImode..'|'..w.options.RSSIwarn..'|'..w.options.RSSIcrit..'|'..w.options.Recover)
  local fields={}
  for _,field in ipairs(w.options.footer) do fields[#fields+1]=field[1] end
  print('FOOTERCONFIG|'..table.concat(fields,'|'))
  w._thresholdTest=loadScript('/WIDGETS/LabTest/threshold-tests.lua')()
  w._smoothTest=loadScript('/WIDGETS/LabTest/smoothing-tests.lua')()
  w._footerTest=loadScript('/WIDGETS/LabTest/footer-tests.lua')()
  -- Exercise production Auto defaults; no test-only threshold overrides.
  return w
end
return {name='LabTest',options=app.options,create=create,update=app.update,refresh=observe,background=app.background}
