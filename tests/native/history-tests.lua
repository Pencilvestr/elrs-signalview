-- Public callbacks, one renderer per firmware callback. Switch the same frozen
-- history between views to catch stale geometry caches and unintended resets.
local app=loadScript('/WIDGETS/SignalView/main.lua')()
local sizes={{800,480},{480,272},{480,320},{320,480},{320,240}}
local index,stage=1,0
local w,history,alerts,baseline,rxY,lqY
local modes={1,' Receiver Signal ',3,1,2,' Link Quality ',1}
return function()
  if index>#sizes then return true end
  local oldLCD,oldTime,oldW,oldH=lcd,getTime,LCD_W,LCD_H
  local ok,err=pcall(function()
    LCD_W,LCD_H=table.unpack(sizes[index])
    getTime=function() return 3000 end
    if stage==0 then
      assert(app.options[13][1]=='History' and app.options[13][3]==1,'Default/option position')
      w=app.create({x=0,y=0,w=LCD_W,h=LCD_H},{})
      assert(w.options.History==1,'Missing setting must default to Both')
      for _,v in ipairs({0,4,'unknown',false}) do
        app.update(w,{History=v});assert(w.options.History==1,'Invalid selection fallback')
      end
      w.sampleTime=3000;w.moduleVersion='4.0.0';w.moduleMajor=4
      local values={99,-62,-65,8,29,250,97,-75,6,0}
      for i,s in ipairs(w.sensors) do s.current=true;s.value=values[i] end
      local c=oldLCD.RGB(255,255,255)
      w.displayColors={c,c,c};w.antenna={dual=true,selected=1}
      history={}
      for i=1,4 do history[i]={time=2400+i*100,[1]=50,[2]=-80,[3]=-85,colors={c,c,c}} end
      w.plotHistory=history;w.historyEnd=2800;w.lossSince=2900
      alerts={};w.alerts=alerts
      stage=1;return
    end
    app.update(w,{History=modes[stage]})
    assert(w.options.History==({1,2,3,1,2,3,1})[stage],'Selection parse')
    if stage==5 then w.antenna.dual=false end
    if stage==7 then w.antenna.dual=true end
    local rows,lines={},{}
    local function capture(kind,...)
      local row={kind,...};rows[#rows+1]=row
      if kind=='line' then lines[#lines+1]=row end
    end
    lcd={sizeText=oldLCD.sizeText,drawText=function(...) capture('text',...) end,
      drawLine=function(...) capture('line',...) end,
      drawFilledRectangle=function(...) capture('rect',...) end}
    app.refresh(w,0)
    assert(w.plotHistory==history and #history==4 and w.alerts==alerts and w.lossSince==2900,'History/state reset')
    local expected=({9,6,3,9,3,3,9})[stage]
    assert(#lines==expected,'Wrong visible traces')
    if stage==1 then
      baseline=rows;rxY=history[1].rxY1;lqY=history[1].lqY
    elseif stage==2 then assert(history[1].rxY1>rxY,'RX did not expand')
    elseif stage==3 then assert(history[1].lqY<lqY,'LQ did not expand')
    elseif stage==4 or stage==7 then
      assert(history[1].rxY1==rxY and history[1].lqY==lqY,'Geometry cache did not restore')
      assert(#rows==#baseline,'Both drawing count changed')
      for i,row in ipairs(rows) do
        for j,v in ipairs(row) do assert(v==baseline[i][j],'Both view changed after switching') end
      end
    end
    for _,row in ipairs(lines) do
      assert(row[3]>=100 and row[5]<LCD_H-40,'Plot outside history area')
    end
    print('HISTORY|'..LCD_W..'x'..LCD_H..'_stage_'..stage..'|true')
    stage=stage+1
    if stage>7 then stage=0;index=index+1 end
  end)
  lcd,getTime,LCD_W,LCD_H=oldLCD,oldTime,oldW,oldH
  assert(ok,'History view test: '..tostring(err))
  return index>#sizes
end
