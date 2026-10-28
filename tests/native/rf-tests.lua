-- Exercise production discovery, decoding, cache invalidation and slot bounds.
-- Setup/render run on separate callbacks to respect the native Lua CPU guard.
local app=loadScript('/WIDGETS/SignalView/main.lua')()
local cases={
  {4,0,'25Hz','LoRa','900M'},{4,1,'50Hz','LoRa','900M'},
  {4,2,'100Hz','LoRa','900M'},{4,3,'100Hz Full','LoRa','900M'},
  {4,5,'200Hz','LoRa','900M'},{4,6,'200Hz Full','LoRa','900M'},
  {4,7,'250Hz','LoRa','900M'},{4,10,'D50','LoRa','900M'},
  {4,11,'K1000 Full','FSK','900M'},{4,21,'50Hz','LoRa','2.4G'},
  {4,23,'100Hz Full','LoRa','2.4G'},{4,24,'150Hz','LoRa','2.4G'},
  {4,27,'250Hz','LoRa','2.4G'},{4,28,'333Hz Full','LoRa','2.4G'},
  {4,29,'500Hz','LoRa','2.4G'},{4,30,'D250','FLRC','2.4G'},
  {4,31,'D500','FLRC','2.4G'},{4,32,'F500','FLRC','2.4G'},
  {4,33,'F1000','FLRC','2.4G'},{4,34,'DK250','FSK','2.4G'},
  {4,35,'DK500','FSK','2.4G'},{4,36,'K1000','FSK','2.4G'},
  {4,100,'100Hz Full','LoRa','X-Band'},{4,101,'150Hz','LoRa','X-Band'},
  {3,1,'25Hz','LoRa','900M'},{3,2,'50Hz','LoRa','Band ?'},
  {3,3,'100Hz','LoRa','900M'},{3,4,'100Hz Full','LoRa','Band ?'},
  {3,5,'150Hz','LoRa','Band ?'},{3,6,'200Hz','LoRa','900M'},
  {3,7,'250Hz','LoRa','Band ?'},{3,8,'333Hz Full','LoRa','2.4G'},
  {3,9,'500Hz','LoRa','2.4G'},{3,10,'D250','FLRC','2.4G'},
  {3,11,'D500','FLRC','2.4G'},{3,12,'F500','FLRC','2.4G'},
  {3,13,'F1000','FLRC','2.4G'},{3,14,'D50','LoRa','900M'},
  {3,15,'200Hz Full','LoRa','900M'},{3,16,'DK500','FSK','2.4G'},
  {3,19,'K1000 Full','FSK','900M'},
  {false,11,'11'},{5,11,'11'},{2,11,'11'},{4,255,'255'},
  {3,29,'29'},{4,9,'9'},{4,29,'--',stale=true},
  {4,false,'--'},{4,29.5,'30'},{4,29,'500Hz','LoRa','2.4G',transition=true}
}
local keys={'lcd','LCD_W','LCD_H','getTime','getFieldInfo','sources','crossfireTelemetryPop','crossfireTelemetryPush'}
local index,stage=1,0
local w
local width,height=LCD_W,LCD_H
local wide=width>=600
local padding=wide and 24 or 8
local cellWidth=(width-2*padding)/4
local footer=height-(wide and 64 or 36)
return function()
  local saved={}
  for _,key in ipairs(keys) do saved[key]=_G[key] end
  local c=cases[index]
  local ok,err=pcall(function()
    LCD_W,LCD_H=width,height
    getTime=function() return 100 end
    getFieldInfo=function(name) if name=='RFMD' then return {id=5} end end
    sources=nil
    crossfireTelemetryPush=function() return true end
    local sent=false
    crossfireTelemetryPop=function()
      if sent or not c[1] or c[1]==2 then return end
      sent=true
      return 0x29,{0xEA,0xEE,84,88,0,69,76,82,83,0,0,0,0,0,c[1],0,0,0,0}
    end
    if stage==0 then
      w=app.create({x=0,y=0,w=width,h=height},{['Footer 1']=5,['Footer 2']=5,['Footer 3']=5,['Footer 4']=5})
      w.sampleTime=100
      w.sensors[5].value=c[2]~=false and c[2] or nil
      w.sensors[5].current=not c.stale
      stage=1
      return
    end
    local seen,measures={},0
    lcd={sizeText=function(str,font) measures=measures+1;return saved.lcd.sizeText(str,font) end,
      drawText=function(x,y,str,flags)
        if y>=footer then
          seen[str]=(seen[str] or 0)+1
          local textWidth,textHeight=saved.lcd.sizeText(str,flags)
          if bit32.band(flags,CENTER)~=0 then x=x-textWidth/2 end
          assert(y+textHeight<=height,'RF text below screen: '..str)
          local slot=math.floor((x+textWidth/2-padding)/cellWidth)
          assert(slot>=0 and slot<4 and x>=padding+slot*cellWidth and x+textWidth<=padding+(slot+1)*cellWidth,'RF text exceeds slot: '..str)
        end
      end,drawFilledRectangle=function() end,drawLine=function() end}
    if c.transition and stage==1 then
      w.sensors[5].value=11
      app.refresh(w,0)
      assert(seen['K1000 Full']==4,'Initial mode incorrect')
      w.sensors[5].value=29;stage=2
      return
    end
    app.refresh(w,0)
    assert(seen[c[3]]==4,'Wrong RF label: '..tostring(c[1])..'/'..tostring(c[2]))
    if c[4] then
      if wide then assert(seen[c[4]]==4 and seen[c[5]]==4,'Wrong modulation/band') end
      assert(seen[wide and 'RF MODE' or 'RF Mode']==4,'Missing RF label')
      assert(measures<=8,'Measurements repeated for each slot') -- RF group + two antenna readings.
    else
      assert(seen[wide and 'RF MODE RAW' or 'RF raw']==4 and not seen['LoRa'] and not seen['FSK'],'Unverified mode decoded')
    end
    print('RFMODE|'..index..'|true')
    index=index+1;stage=0
  end)
  for _,key in ipairs(keys) do _G[key]=saved[key] end
  assert(ok,err)
  return index>#cases
end
