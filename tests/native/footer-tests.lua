-- Run one footer case per refresh to keep native Lua work bounded.
local app=loadScript('/WIDGETS/SignalView/main.lua')()
local cases={
  {'TPWR',6,'TX POWER','TX mW','250 mW','250'},
  {'RFMD',5,'RF MODE','RF Mode','29','29'},
  {'RSNR',4,'RX SNR','SNR dB','8 dB','8'},
  {'TQly',7,'DOWNLINK','DL %','97%','97'},
  {'TRSS',8,'DL RSSI','DL dBm','-75 dBm','-75'},
  {'TSNR',9,'DL SNR','DL dB','6 dB','6'},
  {'ANT',10,'ACTIVE ANT','ANT','2','2'},
  {'RQly',1,'LINK QUALITY','LQ %','99%','99'},
  {'1RSS',2,'RX RSSI 1','RX1 dBm','-62 dBm','-62'},
  {'2RSS',3,'RX RSSI 2','RX2 dBm','-65 dBm','-65'}
}
local index=1
return function()
  local case=cases[index]
  local original=lcd
  local ok,err=pcall(function()
    local baseline=app.create({x=0,y=0,w=800,h=480},{})
    local selected=case and baseline.sensors[case[2]].id or baseline.sensors[8].id
    if index==11 then selected=1 end -- Native input source, not ELRS telemetry.
    assert(selected,'Test source not discovered')
    local options={['Footer 1']=selected,['Footer 2']=selected,
      ['Footer 3']=selected,['Footer 4']=selected}
    if index>=14 then options={} end
    local w=app.create({x=0,y=0,w=800,h=480},options)
    w.moduleVersion='test'
    local values={99,-62,-65,8,29,250,97,-75,6,2}
    for i,s in ipairs(w.sensors) do s.value=values[i];s.current=true end
    if index==12 then w.sensors[8].current=false end
    if index==13 then w.sensors[8].value=nil;w.sensors[8].current=false end
    if index==15 then
      w.sensors[3].current=false
      local now=getTime()
      w.plotHistory={
        {time=now-200,second=0,[1]=50,[2]=-80,colors={0,0},gap={[3]=true}},
        {time=now-100,second=1,[1]=50,[2]=-80,colors={0,0},gap={[3]=true}}}
    end
    for _,size in ipairs({{800,480},{320,240}}) do
      local seen={}
      local lines=0
      lcd={drawText=function(x,y,str)
        if y>=size[2]-(size[1]>=600 and 64 or 36) then seen[str]=(seen[str] or 0)+1 end
      end,drawFilledRectangle=function() end,drawLine=function() lines=lines+1 end}
      w.zone.w=size[1];w.zone.h=size[2]
      local savedW,savedH=LCD_W,LCD_H
      LCD_W,LCD_H=size[1],size[2]
      w.sampleTime=getTime()
      local rendered,renderError=pcall(app.refresh,w,true)
      LCD_W,LCD_H=savedW,savedH
      assert(rendered,renderError)
      if case then
        assert(w.options.footer[1][1]==case[2],'Wrong sensor')
        assert(seen[case[size[1]>=600 and 3 or 4]]==4,'Wrong label')
        assert(seen[case[size[1]>=600 and 5 or 6]]==4,'Wrong value/unit')
      elseif index==11 then
        assert(seen[size[1]>=600 and 'UNSUPPORTED' or 'Unsup.']==4,'Unknown source accepted')
      elseif index==12 or index==13 then
        assert(seen[size[1]>=600 and '-- dBm' or '--']==4,'Missing/stale value shown')
      elseif index==14 then
        for i,id in ipairs({6,5,4,7}) do assert(w.options.footer[i][1]==id,'Default changed') end
      else
        assert(lines==2,'Missing antenna must not draw an LQ-derived RSSI trace')
      end
    end
  end)
  lcd=original
  print('FOOTER|'..index..'|'..tostring(ok))
  assert(ok,err)
  index=index+1
  return index>15
end
