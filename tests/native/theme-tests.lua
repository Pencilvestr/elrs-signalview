-- Compare real renderer calls across themes without changing sample state.
-- One render per callback keeps test overhead within the firmware CPU budget.
local app=loadScript('/WIDGETS/SignalView/main.lua')()
local rgb=lcd.RGB
local pairsRGB={
  {{20,27,25},{242,233,211}},{{43,61,49},{220,213,190}},
  {{255,255,255},{51,47,36}},{{167,185,173},{102,94,73}},
  {{112,217,154},{58,105,57}},{{255,195,106},{132,76,4}},
  {{255,116,116},{171,40,33}},{{118,186,255},{38,94,139}},
  {{48,65,55},{204,194,169}}}
local map={}
for _,p in ipairs(pairsRGB) do map[rgb(table.unpack(p[1]))]=rgb(table.unpack(p[2])) end
local whiteRGB={{250,249,242},{224,229,219},{39,48,43},{89,101,92},
  {35,117,65},{141,85,0},{181,41,43},{31,100,158},{212,217,205}}
local whiteMap={}
for i,p in ipairs(pairsRGB) do whiteMap[rgb(table.unpack(p[1]))]=rgb(table.unpack(whiteRGB[i])) end
local stage,sizeIndex=0,1
local sizes={{800,480},{320,240}}
local w,other,baseline,history,alerts
return function()
  if sizeIndex>#sizes then return true end
  local savedLCD,savedTime,savedW,savedH=lcd,getTime,LCD_W,LCD_H
  local ok,err=pcall(function()
    getTime=function() return 3000 end
    LCD_W,LCD_H=table.unpack(sizes[sizeIndex])
    if stage==0 then
      assert(app.options[1][1]=='Theme' and app.options[1][3]==1,'Theme default/position')
      w=app.create({x=0,y=0,w=LCD_W,h=LCD_H},{})
      assert(w.options.Theme==1,'Existing settings must stay dark')
      for _,value in ipairs({0,4,'unknown',false}) do
        app.update(w,{Theme=value});assert(w.options.Theme==1,'Invalid theme fallback')
      end
      w.sampleTime=3000;w.moduleVersion='4.1.0';w.moduleMajor=4
      local values={99,-62,-65,8,29,250,97,-75,6,0}
      for i,s in ipairs(w.sensors) do s.current=true;s.value=values[i] end
      w.displayColors={rgb(255,255,255),rgb(255,195,106),rgb(255,116,116)}
      w.antenna={dual=true,selected=1}
      history={}
      for i=1,4 do history[i]={time=2500+i*100,[1]=99-i*10,[2]=-60-i*10,[3]=-65-i*10,
        colors={w.displayColors[(i-1)%3+1],w.displayColors[(i-1)%3+1],w.displayColors[(i-1)%3+1]}} end
      w.plotHistory=history;w.historyEnd=2900;w.lossSince=3000
      alerts={};w.alerts=alerts
      other=app.create(w.zone,{Theme=2});other.sampleTime=3000;other.moduleVersion='test'
      stage=1;return
    end
    if stage==2 then app.update(w,{Theme=' Rich Ivory '});assert(w.options.Theme==2) end
    if stage==3 then
      -- Render another theme first; next callback must restore this instance.
      app.refresh(other,0);stage=4;return
    end
    if stage==4 then app.update(w,{Theme=1}) end
    if stage==5 then app.update(w,{Theme=2});assert(w.options.Theme==2) end
    if stage==6 then app.update(w,{Theme=' WHITE '});assert(w.options.Theme==3) end
    if stage==7 then app.update(w,{Theme=3});assert(w.options.Theme==3) end
    if stage==8 then app.update(w,{Theme=1}) end
    local rows={}
    local function capture(kind,...)
      rows[#rows+1]={kind,...}
    end
    lcd={sizeText=savedLCD.sizeText,
      drawText=function(...) capture('text',...) end,
      drawFilledRectangle=function(...) capture('rect',...) end,
      drawLine=function(...) capture('line',...) end}
    app.refresh(w,0)
    assert(w.plotHistory==history and w.alerts==alerts and w.lossSince==3000,'Theme reset state')
    if stage==1 then baseline=rows else
      assert(#rows==#baseline,'Theme changed drawing count')
      for i,row in ipairs(rows) do
        local old=baseline[i]
        for j=1,#row-1 do assert(row[j]==old[j],'Theme changed layout/content') end
        local expected=old[#old]
        if w.options.Theme~=1 then
          local map=w.options.Theme==3 and whiteMap or map
          if row[1]=='text' then
            -- Text flags combine a color in the high bits and font/alignment.
            local color=bit32.band(expected,0xFFFF8000)
            if color>=2147483648 then color=color-4294967296 end
            expected=(map[color] or color)+bit32.band(expected,0x7FFF)
          else expected=map[expected] or expected end
        end
        assert(row[#row]==expected,'Wrong theme color '..row[1]..' old='..old[#old]..' expected='..expected..' actual='..row[#row])
      end
    end
    print('THEME|stage_'..stage..'_'..LCD_W..'|true')
    stage=stage+1
    if stage>8 then sizeIndex=sizeIndex+1;stage=0 end
  end)
  lcd,getTime,LCD_W,LCD_H=savedLCD,savedTime,savedW,savedH
  assert(ok,'Theme test: '..tostring(err))
  return sizeIndex>#sizes
end
