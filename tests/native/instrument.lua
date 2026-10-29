-- Test-only observer. Production widget remains unchanged in its own folder.
local app=loadScript('/WIDGETS/SignalView/main.lua')()
local profiling=loadScript('/WIDGETS/LabTest/profile-enabled.lua')()
local profiled=profiling and loadScript('/WIDGETS/LabTest/profile.lua')()
local function observe(w,event,touch)
  if w._historyTest then
    if w._historyTest() then w._historyTest=nil end
    return
  end
  if w._themeTest then
    if w._themeTest() then w._themeTest=nil end
    return
  end
  if not profiling and not w._areaTest then
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
  -- Test stages can render several fixtures themselves. Keep each stage in
  -- its own callback rather than spending the same CPU budget on a live draw.
  if w._thresholdTest then
    if w._thresholdTest() then w._thresholdTest=nil end
    return
  end
  if w._lossTest then
    if w._lossTest() then w._lossTest=nil end
    return
  end
  if w._smoothTest then
    if w._smoothTest() then w._smoothTest=nil end
    return
  end
  if w._footerTest then
    if w._footerTest() then w._footerTest=nil end
    return
  end
  if not w._thresholdTest and not w._smoothTest and not w._footerTest and w._rfTest then
    if w._rfTest() then w._rfTest=nil end
    return
  end
  if not w._thresholdTest and not w._smoothTest and not w._footerTest and w._antennaTest then
    if w._antennaTest() then w._antennaTest=nil end
    return
  end
  if not w._thresholdTest and not w._smoothTest and not w._footerTest and w._equivalenceTest then
    if w._equivalenceTest() then w._equivalenceTest=nil end
    -- The oracle already executes a renderer. Do not spend a second widget's
    -- full drawing budget in the same callback during this isolated test.
    return
  end
  if profiled then profiled('refresh',app.refresh,w,event,touch)
  else app.refresh(w,event,touch) end
  local now=getTime()
  if not w._labTick or now-w._labTick>=50 then
    w._labTick=now
    local row={'NATIVE',tostring(now),tostring(event~=nil),tostring(getVersion())}
    for _,s in ipairs(w.sensors) do
      row[#row+1]=s.name..'='..tostring(s.value)..','..s.state
    end
    local last=w.lastSample or (w.history and w.history[#w.history])
    if last then row[#row+1]='COLORS='..tostring(last.colors[1])..','..tostring(last.colors[2])..','..tostring(last.colors[3]) end
    row[#row+1]='HIST='..tostring(w.lastSample and 1 or (w.history and #w.history or 0))..',PLOT='..tostring(w.plotHistory and #w.plotHistory or 0)
    row[#row+1]='VERSION='..tostring(w.moduleVersion)
    print(table.concat(row,'|'))
  end
end
local function create(zone,options)
  local w=app.create(zone,options)
  if profiling then
    local direct,count=0,0
    for _,sensor in ipairs(w.sensors) do
      local info=getFieldInfo(sensor.name)
      if info and info.id==sensor.id then direct=direct+1 end
    end
    for id,name in sources() do count=count+1 end
    print('PERFAPI|'..direct..'|'..count)
  end
  print('ZONE|'..zone.x..'|'..zone.y..'|'..zone.w..'|'..zone.h)
  print('CONFIG|'..w.options.LQwarn..'|'..w.options.LQcrit..'|'..w.options.RSSImode..'|'..w.options.RSSIwarn..'|'..w.options.RSSIcrit..'|'..w.options.Recover)
  local fields={}
  for _,field in ipairs(w.options.footer) do fields[#fields+1]=field[1] end
  print('FOOTERCONFIG|'..table.concat(fields,'|'))
  print('ANTENNACONFIG|'..w.options.Antennas)
  print('THEMECONFIG|'..w.options.Theme)
  print('HISTORYCONFIG|'..w.options.History)
  if not profiling then
    if loadScript('/WIDGETS/LabTest/history-enabled.lua')() then
      w._historyTest=loadScript('/WIDGETS/LabTest/history-tests.lua')()
    end
    if loadScript('/WIDGETS/LabTest/theme-enabled.lua')() then
      w._themeTest=loadScript('/WIDGETS/LabTest/theme-tests.lua')()
    end
    if loadScript('/WIDGETS/LabTest/loss-enabled.lua')() then
      w._lossTest=loadScript('/WIDGETS/LabTest/loss-tests.lua')()
    end
    w._thresholdTest=loadScript('/WIDGETS/LabTest/threshold-tests.lua')()
    w._smoothTest=loadScript('/WIDGETS/LabTest/smoothing-tests.lua')()
    w._footerTest=loadScript('/WIDGETS/LabTest/footer-tests.lua')()
    if loadScript('/WIDGETS/LabTest/rf-enabled.lua')() then
      w._rfTest=loadScript('/WIDGETS/LabTest/rf-tests.lua')()
    end
    if loadScript('/WIDGETS/LabTest/antenna-enabled.lua')() then
      w._antennaTest=loadScript('/WIDGETS/LabTest/antenna-tests.lua')()
    end
    if loadScript('/WIDGETS/LabTest/reference-enabled.lua')() then
      w._equivalenceTest=loadScript('/WIDGETS/LabTest/equivalence-tests.lua')()
    end
  end
  -- Exercise production Auto defaults; no test-only threshold overrides.
  return w
end
return {name='LabTest',options=app.options,create=create,update=app.update,refresh=observe,
  background=function(w) if profiled then profiled('background',app.background,w) else app.background(w) end end}
