-- ELRS SignalView 0.3.0. Original implementation, MIT licensed.
-- Main readings use EdgeTX source APIs. A bounded foreground CRSF device-info
-- query discovers the TX module version. No model or RF setting writes occur.
-- Install as /WIDGETS/SignalView/main.lua; see docs/DEVELOPMENT.md for the map.

-- Sensor order is also the history schema: 1 = LQ, 2/3 = antenna RSSI.
-- getTime() is in centiseconds: 20 = 200 ms, 100 = 1 s, 3000 = 30 s.
local definitions = {
  {"RQly", "Uplink quality", "%"},
  {"1RSS", "RX antenna 1", "dBm"},
  {"2RSS", "RX antenna 2", "dBm"},
  {"RSNR", "Receiver SNR", "dB"},
  {"RFMD", "RF mode index", "raw"},
  {"TPWR", "TX power", "mW"},
  {"TQly", "Downlink quality", "%"},
  {"TRSS", "Downlink RSSI", "dBm"},
  {"TSNR", "Downlink SNR", "dB"},
  {"ANT", "Active antenna", "raw"}
}
-- SOURCE options use EdgeTX's native picker; only these ELRS fields render.
-- Each descriptor contains sensor index, large label, compact label and units.
local footerFields={
  TPWR={6,'TX POWER','TX mW',' mW'}, RFMD={5,'RF MODE','RF Mode',''},
  RSNR={4,'RX SNR','SNR dB',' dB'}, TQLY={7,'DOWNLINK','DL %','%'},
  TRSS={8,'DL RSSI','DL dBm',' dBm'}, TSNR={9,'DL SNR','DL dB',' dB'},
  ANT={10,'ACTIVE ANT','ANT',''}, RQLY={1,'LINK QUALITY','LQ %','%'},
  ['1RSS']={2,'RX RSSI 1','RX1 dBm',' dBm'}, ['2RSS']={3,'RX RSSI 2','RX2 dBm',' dBm'}
}
local footerDefaults={'TPWR','RFMD','RSNR','TQLY'}
local sensorIndexByName={}
for index,definition in ipairs(definitions) do sensorIndexByName[string.lower(definition[1])]=index end
local invalidFooter={0,'UNSUPPORTED','Unsup.',''}
local function resolveFooter(w)
  for i,key in ipairs(footerDefaults) do
    local selected=w.options.footerSources[i]
    local field=footerFields[key]
    if type(selected)=='number' and selected~=0 then
      field=invalidFooter
      for name,candidate in pairs(footerFields) do
        if w.sensors[candidate[1]].id==selected then field=candidate;break end
      end
    elseif type(selected)=='string' and selected~='' then
      -- Accept the previous unpublished text-field build during migration.
      field=footerFields[string.upper(selected)] or invalidFooter
    end
    w.options.footer[i]=field
  end
end
local C = {
  bg=lcd.RGB(20,27,25), card=lcd.RGB(43,61,49),
  text=lcd.RGB(255,255,255), muted=lcd.RGB(167,185,173),
  accent=lcd.RGB(112,217,154), warn=lcd.RGB(255,195,106), red=lcd.RGB(255,116,116), blue=lcd.RGB(118,186,255), rule=lcd.RGB(48,65,55)
}
-- Cache sensor IDs and rescan periodically so telemetry discovery can happen
-- after widget creation. A name existing does not imply its value is current.
local function scan(w)
  -- Resolve discovered names without consuming the shared CRSF telemetry queue.
  local missing=false
  for _,sensor in ipairs(w.sensors) do
    local info=getFieldInfo(sensor.name)
    sensor.id=info and info.id or nil
    if not sensor.id then missing=true end
  end
  -- Direct lookups avoid enumerating every stick/channel/source in the common
  -- case. Keep case-insensitive enumeration for undiscovered/legacy names.
  if missing and sources then
    for id,name in sources() do
      local index=sensorIndexByName[string.lower(name)]
      if index and not w.sensors[index].id then w.sensors[index].id=id end
    end
  end
  resolveFooter(w)
  w.scanTime = getTime()
end
-- Rate-limit acquisition independently of screen refresh; EdgeTX scheduling
-- may provide fewer than five calls per second. Respect firmware freshness.
local function sample(w)
  local now = getTime()
  if w.sampleTime and now >= w.sampleTime and now-w.sampleTime < 20 then return end
  w.sampleTime = now
  if not w.scanTime or now < w.scanTime or now-w.scanTime >= 200 then scan(w) end
  for _,s in ipairs(w.sensors) do
    s.value, s.current, s.fresh = nil, false, false
    s.state = "MISSING"
    if s.id then
      if not getSourceValue then
        s.state = "API NEEDED"
      else
        s.value, s.current, s.fresh = getSourceValue(s.id)
        if s.value == nil then s.state = "NO VALUE"
        elseif not s.current then s.state = "STALE"
        elseif s.fresh then s.state = "FRESH"
        else s.state = "CURRENT" end
      end
    end
  end
end
-- Official ExpressLRS Signal Health, ELRS 4.x RFMD table, verified 2026-10-21.
-- Band and modulation are encoded by these 4.x indices; never use the 3.x map.
local sensitivity={
  [0]=-123,[1]=-120,[2]=-117,[3]=-112,[5]=-112,[6]=-111,[7]=-111,
  [10]=-112,[11]=-101,[21]=-115,[23]=-112,[24]=-112,[27]=-108,
  [28]=-105,[29]=-105,[30]=-104,[31]=-104,[32]=-104,[33]=-104,
  [34]=-103,[35]=-103,[36]=-103,[100]=-112,[101]=-112
}
-- Display metadata is versioned separately from automatic RSSI thresholds.
-- Entries: readable rate, modulation, band. See docs/RF-MODES.md for sources.
-- 3.x reuses some indices across bands (including LR1121 dual-band modes).
-- Never infer the band from module branding or carry a 4.x label into 3.x.
local rfModes={
  [4]={
    [0]={'25Hz','LoRa','900M'},[1]={'50Hz','LoRa','900M'},
    [2]={'100Hz','LoRa','900M'},[3]={'100Hz Full','LoRa','900M'},
    [5]={'200Hz','LoRa','900M'},[6]={'200Hz Full','LoRa','900M'},
    [7]={'250Hz','LoRa','900M'},[10]={'D50','LoRa','900M'},
    [11]={'K1000 Full','FSK','900M'},[21]={'50Hz','LoRa','2.4G'},
    [23]={'100Hz Full','LoRa','2.4G'},[24]={'150Hz','LoRa','2.4G'},
    [27]={'250Hz','LoRa','2.4G'},[28]={'333Hz Full','LoRa','2.4G'},
    [29]={'500Hz','LoRa','2.4G'},[30]={'D250','FLRC','2.4G'},
    [31]={'D500','FLRC','2.4G'},[32]={'F500','FLRC','2.4G'},
    [33]={'F1000','FLRC','2.4G'},[34]={'DK250','FSK','2.4G'},
    [35]={'DK500','FSK','2.4G'},[36]={'K1000','FSK','2.4G'},
    [100]={'100Hz Full','LoRa','X-Band'},[101]={'150Hz','LoRa','X-Band'}
  },
  [3]={
    [1]={'25Hz','LoRa','900M'},[2]={'50Hz','LoRa','Band ?'},
    [3]={'100Hz','LoRa','900M'},[4]={'100Hz Full','LoRa','Band ?'},
    [5]={'150Hz','LoRa','Band ?'},[6]={'200Hz','LoRa','900M'},
    [7]={'250Hz','LoRa','Band ?'},[8]={'333Hz Full','LoRa','2.4G'},
    [9]={'500Hz','LoRa','2.4G'},[10]={'D250','FLRC','2.4G'},
    [11]={'D500','FLRC','2.4G'},[12]={'F500','FLRC','2.4G'},
    [13]={'F1000','FLRC','2.4G'},[14]={'D50','LoRa','900M'},
    [15]={'200Hz Full','LoRa','900M'},[16]={'DK500','FSK','2.4G'},
    [19]={'K1000 Full','FSK','900M'}
  }
}
local function rfMode(w)
  local s=w.sensors[5]
  local map=rfModes[w.moduleMajor]
  if s.current and type(s.value)=='number' and map then return map[s.value] end
end
-- Return effective RSSI amber/red boundaries, or nil plus a visible reason.
-- RFMD alone cannot identify the ELRS major version; Auto targets 4.x only.
local function thresholds(w)
  if w.options.RSSImode==-1 then return nil,nil,'Use Auto/Manual/Off' end
  if w.options.RSSImode==2 then return nil,nil,'RSSI colors off' end
  if w.options.RSSImode==1 then
    if w.options.RSSIcrit>=w.options.RSSIwarn then return nil,nil,'RSSI settings invalid' end
    return w.options.RSSIwarn,w.options.RSSIcrit,'RSSI manual'
  end
  if w.moduleMajor and w.moduleMajor~=4 then return nil,nil,'Auto needs ELRS 4.x' end
  local s=w.sensors[5]
  local limit=s.current and type(s.value)=='number' and sensitivity[s.value]
  if not limit then return nil,nil,'RSSI auto unavailable' end
  return limit+10,limit+5,'RSSI auto'
end
local severity
local colorRanks={[C.text]=0,[C.warn]=1,[C.red]=2,[C.muted]=-1}
-- Current text/bar state is independent for each series. Worsening is immediate;
-- recovery needs both a 2-unit margin and sustained time. Raw graph colors do
-- not pass through this state machine. Staleness/context changes reset it.
local function smooth(w,index,color,now,warning,critical)
  if w.options.Recover==0 then if w.alerts then w.alerts[index]=nil end;return color end
  local s=w.sensors[index]
  local mode=index==1 and -2 or w.options.RSSImode
  local contextWarn=index==1 and w.options.LQwarn or warning
  local contextCrit=index==1 and w.options.LQcrit or critical
  w.alerts=w.alerts or {}
  local a=w.alerts[index]
  if not a or a.mode~=mode or a.warning~=contextWarn or a.critical~=contextCrit or now<a.time or color==C.muted or not s.current then
    a={mode=mode,warning=contextWarn,critical=contextCrit,color=color,time=now};w.alerts[index]=a;return color
  end
  a.time=now
  local rank,old=colorRanks[color],colorRanks[a.color]
  local upper=index==1 and w.options.LQwarn or warning
  if rank==0 and old>0 and upper and s.value<upper+2 then color=C.warn;rank=1 end
  if old<0 or rank>=old or w.options.Recover==0 then
    a.color=color;a.since=nil;a.target=nil;return color
  end
  local boundary=index==1 and (old==2 and w.options.LQcrit or w.options.LQwarn) or (old==2 and critical or warning)
  if not boundary or s.value<boundary+2 then a.since=nil;a.target=nil;return a.color end
  if a.target~=color then a.target=color;a.since=now end
  if now-a.since>=w.options.Recover*100 then a.color=color;a.since=nil;a.target=nil end
  return a.color
end
-- Sample at the original cadence; retain the latest diagnostic sample and
-- the exact same one-second plot buckets. The unused 151-sample duplicate
-- history is not needed to preserve dips, colors, gaps or the 30-second view.
-- Never draw all raw samples: that caused the original hardware CPU-limit bug.
-- Zero is an unused-RSSI placeholder, not evidence of an antenna. Keep raw
-- telemetry intact for footer selections; filter only the main RSSI/history.
local function usableRSSI(s)
  return s.current and type(s.value)=='number' and s.value<0 and s.value>-math.huge
end
-- Infer available signal paths, not physical hardware or antenna health.
-- Require a second of continuous evidence per path. Once observed, retain
-- dual layout through dropouts/reconnection so a missing path stays visible.
local function detectAntennas(w,now)
  local a=w.antenna
  if not a then a={selected=1};w.antenna=a end
  if a.time and now<a.time then a.since1=nil;a.since2=nil;a.missingSince=nil end
  a.time=now
  local first,second=usableRSSI(w.sensors[2]),usableRSSI(w.sensors[3])
  if first then
    a.since1=a.since1 or now
    if now-a.since1>=100 then a.seen1=true end
  else a.since1=nil end
  if second then
    a.since2=a.since2 or now
    if now-a.since2>=100 then a.seen2=true end
  else a.since2=nil end
  a.dual=a.seen1 and a.seen2 or false
  -- In single view, select a qualified alternative only when the chosen path
  -- is unavailable. Never follow the strongest RSSI or switch on each packet.
  local selectedAvailable=(a.selected==1 and first) or (a.selected==2 and second)
  if selectedAvailable then a.missingSince=nil
  else
    a.missingSince=a.missingSince or now
    local otherSince
    if a.selected==1 then otherSince=a.since2 else otherSince=a.since1 end
    if now-a.missingSince>=100 and otherSince and now-otherSince>=100 then
      a.selected=3-a.selected;a.missingSince=nil
    end
  end
end
local function antennaLayout(w)
  local a=w.antenna
  return w.options.Antennas=='dual' or (w.options.Antennas=='auto' and a and a.dual),a and a.selected or 1
end
local baseSample=sample
sample=function(w)
  local previous=w.sampleTime
  baseSample(w)
  if previous==w.sampleTime then return end
  local now=w.sampleTime
  detectAntennas(w,now)
  local point={time=now,colors={}}
  w.lastSample=point
  w.displayColors=w.displayColors or {}
  local warning,critical=thresholds(w)
  for i=1,3 do
    local s=w.sensors[i]
    local available=s.current and type(s.value)=='number' and (i==1 or usableRSSI(s))
    local color=available and severity(w,s,i~=1,warning,critical) or C.muted
    if available then
      point[i]=s.value
      point.colors[i]=color
    end
    w.displayColors[i]=smooth(w,i,color,now,warning,critical)
  end
  -- Bound drawing work independently of refresh frequency. Retain the weakest
  -- sample per second, with its original color, so short dips remain visible.
  if not w.plotHistory or (w.plotHistory[#w.plotHistory] and now<w.plotHistory[#w.plotHistory].time) then w.plotHistory={} end
  local plots=w.plotHistory
  local bucket=plots[#plots]
  local second=math.floor(now/100)
  if not bucket or bucket.second~=second then
    bucket={time=now,second=second,seq=second,colors={},gap={}}
    plots[#plots+1]=bucket
  end
  for i=1,3 do
    if point[i]==nil then
      bucket[i]=nil;bucket.colors[i]=nil;bucket.gap[i]=true;bucket.layoutW=nil
    elseif not bucket.gap[i] and (bucket[i]==nil or point[i]<bucket[i]) then
      bucket[i]=point[i];bucket.colors[i]=point.colors[i];bucket.layoutW=nil
    end
  end
  -- Keep one predecessor outside the window to clip a continuous line at its
  -- left edge, rather than dropping the entire crossing segment each second.
  while #plots>32 or (#plots>1 and plots[2].time<=now-3000) do table.remove(plots,1) end
end
-- Translate public setting labels to internal keys. Copy, rather than mutate,
-- EdgeTX's options table so widget instances cannot share accidental changes.
-- Legacy internal keys are accepted for existing development tests/settings.
local function defaults(options)
  local src=options or {}
  local o={}
  local names={LQwarn='LQ amber',LQcrit='LQ red',RSSIwarn='RX amber',RSSIcrit='RX red',Recover='Recover s'}
  for k,v in pairs({LQwarn=80,LQcrit=60,RSSIwarn=-98,RSSIcrit=-103,Recover=1}) do o[k]=src[names[k]] or src[k] or v end
  local mode=src['RSSI mode']
  if mode then o.RSSImode=({auto=0,manual=1,off=2})[string.match(string.lower(mode),'^%s*(.-)%s*$')] or -1
  else o.RSSImode=src.RSSImode or 0 end
  local antennas=src.Antennas
  if type(antennas)=='number' then antennas=({[1]='auto',[2]='single',[3]='dual'})[antennas] end
  antennas=type(antennas)=='string' and string.match(string.lower(antennas),'^%s*(.-)%s*$') or 'auto'
  o.Antennas=(antennas=='single' or antennas=='dual') and antennas or 'auto'
  o.footer={};o.footerSources={}
  for i,key in ipairs(footerDefaults) do
    local setting=src['Footer '..i]
    if type(setting)=='string' then
      setting=string.match(string.upper(setting),'^%s*(.-)%s*$')
      if setting~='' then key=setting end
    end
    o.footerSources[i]=setting
    o.footer[i]=footerFields[key] or invalidFooter
  end
  return o
end
-- All persistent widget state belongs to w. No history is written to the SD.
local function create(zone, options)
  local version, radio = getVersion()
  local w = {zone=zone, options=defaults(options), sensors={}, version=tostring(version), radio=tostring(radio)}
  for i,d in ipairs(definitions) do
    w.sensors[i] = {name=d[1], label=d[2], unit=d[3]}
  end
  scan(w)
  return w
end
-- Refresh is synchronous; reset this drawing origin for every instance/call.
local originX,originY=0,0
local function text(x,y,str,font,color)
  lcd.drawText(math.floor(x+originX), math.floor(y+originY), str, (font or SMLSIZE)+(color or C.text))
end
local function rect(x,y,width,height,color)
  lcd.drawFilledRectangle(math.floor(x+originX),math.floor(y+originY),math.max(1,math.floor(width)),math.max(1,math.floor(height)),color)
end
local function line(x1,y1,x2,y2,style,color)
  lcd.drawLine(x1+originX,y1+originY,x2+originX,y2+originY,style,color)
end
local function versionHeader(w)
  return w.moduleVersion and ('ELRS '..w.moduleVersion) or 'ELRS LINK'
end
-- Directed Device Ping (0x28) / Device Info (0x29), not a settings request.
-- Check handset destination, TX origin and the ELRS serial signature before
-- accepting software bytes. Cache only for this widget's lifetime; no disk IO.
local function discoverVersion(w)
  if w.moduleVersion or not crossfireTelemetryPush or not crossfireTelemetryPop then return end
  local now=getTime()
  w.versionStart=w.versionStart or now
  if now<w.versionStart or now-w.versionStart>1000 then return end
  if w.versionTick and now-w.versionTick<20 then return end
  w.versionTick=now
  if not w.versionPing or now-w.versionPing>=200 then
    crossfireTelemetryPush(0x28,{0xEE,0xEA})
    w.versionPing=now
  end
  -- The CRSF Lua queue is shared. Only inspect a bounded number while this
  -- dashboard is visible, and stop entirely after success or ten seconds.
  for i=1,2 do
    local command,data=crossfireTelemetryPop()
    if not command then break end
    if command==0x29 and type(data)=='table' and data[1]==0xEA and data[2]==0xEE then
      local zero
      for j=3,math.min(#data,35) do if data[j]==0 then zero=j;break end end
      if zero and #data>=zero+14 and data[zero+1]==69 and data[zero+2]==76 and data[zero+3]==82 and data[zero+4]==83 then
        local major,minor,patch=data[zero+10],data[zero+11],data[zero+12]
        if major and major>=3 and major<255 and minor and patch then
          w.moduleMajor=major
          w.moduleVersion=(minor==255 or patch==255) and (major..'.x dev') or (major..'.'..minor..'.'..patch)
          return
        end
      end
    end
  end
end
local function value(s)
  if not s.current or type(s.value) ~= "number" then return "--" end
  if s.textValue~=s.value then
    s.textValue=s.value;s.text=string.format("%.0f",s.value)
  end
  return s.text
end
local function antennaValue(s)
  return usableRSSI(s) and value(s) or '--'
end
-- Keep the unit beside its reading and center the complete group in single
-- view. Cache text measurements until the displayed value or font changes.
local function drawAntenna(w,index,x,y,font,centered,gap,color)
  local s=w.sensors[index]
  local shown=antennaValue(s)
  local layout=s.readingLayout
  if not layout or layout.shown~=shown or layout.font~=font then
    local width,height=lcd.sizeText(shown,font)
    local unitWidth,unitHeight=lcd.sizeText('dBm',SMLSIZE)
    layout={shown=shown,font=font,width=width,unitWidth=unitWidth,
      unitY=math.floor((height-unitHeight)*0.75)}
    s.readingLayout=layout
  end
  local left=centered and (x-(layout.width+gap+layout.unitWidth)/2) or x
  text(left,y,shown,font,color)
  text(left+layout.width+gap,y+layout.unitY,'dBm',SMLSIZE,C.muted)
end
-- Center the split as one group inside the chosen footer slot. Measure only
-- when the mode/width changes; ordinary frames reuse the cached geometry.
-- Long Full labels use the small font rather than overflowing adjacent cells.
local function drawRFMode(w,x,y,width,compact)
  local mode=rfMode(w)
  if not mode then
    text(x,y,compact and 'RF raw' or 'RF MODE RAW',SMLSIZE+CENTER,C.muted)
    text(x,y+(compact and 15 or 18),value(w.sensors[5]),(compact and SMLSIZE or MIDSIZE)+CENTER)
    return
  end
  if compact then
    text(x,y,'RF Mode',SMLSIZE+CENTER,C.muted)
    text(x,y+15,mode[1],SMLSIZE+CENTER)
    return
  end
  local layout=w.rfLayout
  if not layout or layout.mode~=mode or layout.width~=width then
    local font=MIDSIZE
    local detail=math.max((lcd.sizeText(mode[2],SMLSIZE)),(lcd.sizeText(mode[3],SMLSIZE)))
    local rate=lcd.sizeText(mode[1],font)
    if rate+detail+18>width-8 then font=SMLSIZE;rate=lcd.sizeText(mode[1],font) end
    layout={mode=mode,width=width,font=font,rate=rate,detail=detail,total=rate+detail+18}
    w.rfLayout=layout
  end
  text(x,y,'RF MODE',SMLSIZE+CENTER,C.muted)
  local left=x-layout.total/2
  text(left,y+(layout.font==SMLSIZE and 27 or 18),mode[1],layout.font)
  local divider=left+layout.rate+9
  rect(divider,y+23,1,32,C.rule)
  text(divider+9,y+19,mode[2],SMLSIZE,C.muted)
  text(divider+9,y+36,mode[3],SMLSIZE,C.muted)
end
-- Freeze each sample's color when recorded, including unavailable auto state.
severity=function(w,s,rssi,warning,critical)
  if not s.current or type(s.value)~='number' then return C.muted end
  if rssi then
    if not warning then return w.options.RSSImode==2 and C.text or C.muted end
    if s.value<=critical then return C.red end
    if s.value<=warning then return C.warn end
  else
    if w.options.LQcrit>=w.options.LQwarn then return C.muted end
    if s.value<w.options.LQcrit then return C.red end
    if s.value<w.options.LQwarn then return C.warn end
  end
  return C.text
end
local function displayColor(w,index)
  return w.displayColors and w.displayColors[index] or C.muted
end
-- X changes as the window scrolls, but settled bucket Y coordinates do not.
-- Recompute Y only when a bucket changes or the widget area is resized. Cache
-- per instance/bucket; changing screen origin does not change local geometry.
local function preparePlot(w,W,H,left,right,rxTop,rxHeight,lqTop,lqHeight)
  local now=getTime()
  for _,point in ipairs(w.plotHistory or {}) do
    point.screenX=left+(point.time-(now-3000))/3000*(right-left)
    if point.layoutW~=W or point.layoutH~=H then
      local a,b,q=point[2],point[3],point[1]
      point.rxY1=a and (rxTop+(-40-math.max(-120,math.min(-40,a)))/80*rxHeight) or nil
      point.rxY2=b and (rxTop+(-40-math.max(-120,math.min(-40,b)))/80*rxHeight) or nil
      point.lqY=q and (lqTop+(100-math.max(0,math.min(100,q)))/100*lqHeight) or nil
      point.layoutW=W;point.layoutH=H
    end
  end
end
-- Compact landscape and portrait share the approved information hierarchy.
-- Every plot uses one predecessor outside the window for left-edge clipping.
local function compactDashboard(w,W,H)
  local p=8
  local left=42
  local right=W-p-2
  local portrait=H>W
  local mid=math.floor(W/2)+4
  local top=32
  local chartTop=portrait and 126 or 108
  local footer=H-36
  local timeY=footer-20
  local graphBottom=timeY-6
  local panelH=math.floor((graphBottom-chartTop)/2)
  preparePlot(w,W,H,left,right,chartTop+17,panelH-21,chartTop+panelH+17,panelH-21)
  local q=w.sensors[1]
  text(p,6,versionHeader(w),SMLSIZE)
  text(W-p,6,w.options.LQcrit>=w.options.LQwarn and 'Check LQ settings' or (q.current and 'Telemetry current' or 'No current telemetry'),SMLSIZE+RIGHT,q.current and C.accent or C.warn)
  rect(p,24,W-p*2,1,C.text)
  text(p,top,'Link Quality',SMLSIZE,C.muted)
  text(mid,top,'Receiver Signal',SMLSIZE,C.muted)
  text(p,top+17,value(q)..'%',DBLSIZE,displayColor(w,1))
  local two,selected=antennaLayout(w)
  local aw=(W-mid-p)/(two and 2 or 1)
  for a=1,two and 2 or 1 do
    local index=(two and a or selected)+1
    local x=two and (mid+(a-1)*aw) or ((mid+W-p)/2)
    local align=two and 0 or CENTER
    drawAntenna(w,index,x,top+20,MIDSIZE,not two,3,displayColor(w,index))
    text(x,top+43,'ANT '..(index-1),SMLSIZE+align,C.muted)
  end
  local warning,critical,mode=thresholds(w)
  local modeText=warning and ((w.options.RSSImode==0 and 'Auto ' or 'Manual ')..warning..'/'..critical) or mode
  text(W-p,portrait and 100 or 89,modeText,SMLSIZE+RIGHT,C.muted)
  local by=portrait and 103 or 92
  local bw=math.floor(W*.32)
  rect(p,by,bw,5,C.card)
  if q.current and type(q.value)=='number' then
    local color=displayColor(w,1)
    rect(p,by,bw*math.max(0,math.min(100,q.value))/100,5,color==C.text and C.accent or color)
  end
  for panel=1,2 do
    local ytop=chartTop+(panel-1)*panelH
    text(left,ytop,panel==1 and (two and 'ANT1 / ANT2 dashed - dBm' or 'Receiver Signal - dBm') or 'Link Quality - %',SMLSIZE,C.muted)
    local y0=ytop+17
    local bottom=ytop+panelH-4
    local low,high=panel==1 and -120 or 0,panel==1 and -40 or 100
    for n=0,1 do
      local yy=n==0 and y0 or bottom
      rect(left,yy,right-left,1,C.rule)
      text(left-4,yy-6,tostring(n==0 and high or low),SMLSIZE+RIGHT,C.muted)
    end
    for antenna=1,(panel==1 and two) and 2 or 1 do
      local px,py
      for _,point in ipairs(w.plotHistory or {}) do
        local path=two and antenna or selected
        local index=panel==1 and path+1 or 1
        local v=point[index]
        local x=point.screenX
        if v and x<=right then
          local yy=panel==1 and (path==1 and point.rxY1 or point.rxY2) or point.lqY
          if px and x>=left then
            if px<left then py=py+(yy-py)*(left-px)/(x-px);px=left end
            local color=point.colors[index]
            if color==C.text then color=panel==1 and C.accent or C.blue end
            if antenna==1 then line(math.floor(px),math.floor(py),math.floor(x),math.floor(yy),SOLID,color)
            else line(math.floor(px),math.floor(py),math.floor((px+x)/2),math.floor((py+yy)/2),SOLID,color) end
          end
          px,py=x,yy
        else px,py=nil,nil end
      end
    end
  end
  text(left,timeY,'-30 s',SMLSIZE,C.muted)
  text((left+right)/2,timeY,'-15 s',SMLSIZE,C.muted)
  text(right,timeY,'Now',SMLSIZE+RIGHT,C.muted)
  rect(p,footer-3,W-p*2,1,C.text)
  for i,field in ipairs(w.options.footer) do
    local x=p+(i-0.5)*(W-p*2)/4
    if field[1]==5 then drawRFMode(w,x,footer+2,(W-p*2)/4,true)
    else
      text(x,footer+2,field[3],SMLSIZE+CENTER,C.muted)
      text(x,footer+17,field[1]>0 and value(w.sensors[field[1]]) or '--',SMLSIZE+CENTER)
    end
  end
end

-- Large-screen renderer. Keep layout changes separate from telemetry logic.
local function dashboard(w,W,H)
  if W<600 then compactDashboard(w,W,H);return end
  local p=W>=600 and 24 or 8
  local wide=W>=600
  local big=wide and XXLSIZE or DBLSIZE
  local medium=wide and DBLSIZE or MIDSIZE
  local small=SMLSIZE
  local top=wide and 74 or 45
  local chartTop=wide and 218 or 140
  local footer=H-(wide and 64 or 48)
  local mid=math.floor(W/2)+p/2
  text(p,12,versionHeader(w),wide and MIDSIZE or small)
  local current=w.sensors[1].current
  text(W-p,16,w.options.LQcrit>=w.options.LQwarn and 'Check LQ settings' or (current and 'Telemetry current' or 'No current telemetry'),small+RIGHT,current and C.accent or C.warn)
  rect(p,wide and 53 or 37,W-2*p,2,C.text)
  text(p,top,'Link Quality',small,C.muted)
  text(mid,top,'Receiver Signal',small,C.muted)
  local q=w.sensors[1]
  text(p,top+22,value(q)..'%',big,displayColor(w,1))
  local two,selected=antennaLayout(w)
  local antWidth=(W-mid-p)/(two and 2 or 1)
  for a=1,two and 2 or 1 do
    local index=(two and a or selected)+1
    local x=two and (mid+(a-1)*antWidth) or ((mid+W-p)/2)
    local align=two and 0 or CENTER
    drawAntenna(w,index,x,top+30,medium,not two,8,displayColor(w,index))
    text(x,top+(wide and 83 or 64),'ANT '..(index-1),small+align,C.muted)
  end
  local barY=chartTop-22
  local warning,critical,modeLabel=thresholds(w)
  -- Leave clear space below the small-font descenders and above the divider.
  text(W-p,barY-12,modeLabel..(warning and (' '..warning..' / '..critical) or ''),small+RIGHT,C.muted)
  local barW=math.floor(W*.34)
  rect(p,barY,barW,6,C.card)
  if q.current and type(q.value)=='number' then
    local color=displayColor(w,1)
    rect(p,barY,barW*math.max(0,math.min(100,q.value))/100,6,color==C.text and C.accent or color)
  end
  rect(p,chartTop-8,W-2*p,1,C.rule)
  local plotH=math.max(25,math.floor((footer-chartTop-48)/2))
  local left=p+36
  local right=W-p-3
  preparePlot(w,W,H,left,right,chartTop+28,plotH-38,chartTop+plotH+46,plotH-38)
  for panel=1,2 do
    local ytop=chartTop+(panel-1)*(plotH+18)
    text(p,ytop,panel==1 and (two and 'ANT 1 solid / ANT 2 dashed - dBm' or 'Receiver Signal - dBm') or 'Link Quality - %',small,C.muted)
    local y0=ytop+28
    local h=plotH-38
    local low,high=panel==1 and -120 or 0,panel==1 and -40 or 100
    for n=0,2 do
      local yy=y0+n*h/2
      rect(left,yy,right-left,1,C.rule)
      text(left-4,yy-7,string.format('%.0f',high-n*(high-low)/2),small+RIGHT,C.muted)
    end
    for antenna=1,(panel==1 and two) and 2 or 1 do
      local px,py
      for _,point in ipairs(w.plotHistory or {}) do
        local path=two and antenna or selected
        local index=panel==1 and path+1 or 1
        local v=point[index]
        local x=point.screenX
        if v and x<=right then
          local yy=panel==1 and (path==1 and point.rxY1 or point.rxY2) or point.lqY
          if px and x>=left then
            if px<left then py=py+(yy-py)*(left-px)/(x-px);px=left end
            local color=point.colors[index]
            if color==C.text then color=panel==1 and C.accent or C.blue end
            if antenna==1 then line(math.floor(px),math.floor(py),math.floor(x),math.floor(yy),SOLID,color)
            else line(math.floor(px),math.floor(py),math.floor((px+x)/2),math.floor((py+yy)/2),SOLID,color) end
          end
          px,py=x,yy
        else px,py=nil,nil end
      end
    end
  end
  text(left,footer-33,'-30 s',small,C.muted)
  text((left+right)/2,footer-33,'-15 s',small,C.muted)
  text(right,footer-33,'Now',small+RIGHT,C.muted)
  rect(p,footer-5,W-2*p,2,C.text)
  for i,field in ipairs(w.options.footer) do
    local x=p+(i-0.5)*(W-2*p)/4
    if field[1]==5 then drawRFMode(w,x,footer+3,(W-2*p)/4,false)
    else
      text(x,footer+3,field[2],small+CENTER,C.muted)
      local shown=field[1]>0 and value(w.sensors[field[1]]) or '--'
      text(x,footer+23,shown..field[4],(wide and MIDSIZE or small)+CENTER)
    end
  end
end

-- EdgeTX supplies events only in full screen. Normal areas must be almost the
-- whole screen: small/multi-widget zones stay blank, with no prompt or preview.
local function refresh(w,event,touch)
  sample(w)
  local full=event~=nil
  local width,height
  if full then originX,originY=0,0;width,height=LCD_W,LCD_H
  else originX,originY=w.zone.x,w.zone.y;width,height=w.zone.w,w.zone.h end
  rect(0,0,width,height,C.bg)
  local large=width>=LCD_W*0.95 and height>=LCD_H*0.95 and width>=300 and height>=240
  if not full and not large then return end
  discoverVersion(w)
  if EVT_VIRTUAL_EXIT and event == EVT_VIRTUAL_EXIT and lcd.exitFullScreen then
    lcd.exitFullScreen()
    return
  end
  dashboard(w,width,height)
end
return {
  name="SignalView", options={{"LQ amber",VALUE,80,1,100},{"LQ red",VALUE,60,0,99},{"RSSI mode",STRING,"Auto"},{"RX amber",VALUE,-98,-130,-1},{"RX red",VALUE,-103,-130,-1},{"Recover s",VALUE,1,0,10},{"Footer 1",SOURCE,0},{"Footer 2",SOURCE,0},{"Footer 3",SOURCE,0},{"Footer 4",SOURCE,0},{"Antennas",CHOICE or STRING,CHOICE and 1 or "Auto",{"Auto","Single","Dual"}}}, create=create,
  update=function(w,options) w.options=defaults(options);scan(w) end,
  refresh=refresh, background=sample
}







