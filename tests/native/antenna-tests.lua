-- Exercise detection through production acquisition and inspect both renderers.
-- Setup, each sample and rendering occupy separate callbacks to respect the
-- firmware CPU guard. Every temporarily replaced API is restored on failure.
local app=loadScript('/WIDGETS/SignalView/main.lua')()
local names={'RQly','1RSS','2RSS','RSNR','RFMD','TPWR','TQly','TRSS','TSNR','ANT'}
local sizes={{800,480},{320,240}}
local cases={
  {name='nonoverlapping_qualified_paths',samples={{100,-62,0},{200,-62,0},{220,0,-85},{320,0,-85}},selected=2},
  {name='nonoverlapping_reverse_order',samples={{100,0,-85},{200,0,-85},{220,-62,0},{320,-62,0}},selected=1},
  {name='alternating_subsecond_paths',samples={{100,-62,0},{180,-62,0},{200,0,-85},{280,0,-85},{300,-62,0},{380,-62,0}},selected=1},
  {name='sparse_observations_qualify',samples={{100,-62,-85},{3100,-62,-85}},dual=true},
  {name='dual_just_before_threshold',samples={{100,-62,-85},{180,-62,-85}},selected=1},
  {name='LQ_current_blocks_reassessment',samples={{100,-62,-85},{200,-62,-85},{300,0,0},{400,-62,0},{900,-62,0}},dual=true,missing=3},
  {name='second_path_returns_for_one_second',samples={{100,-62,-85},{200,-62,-85},{220,0,0,false,false,false},{300,-62,0},{600,-62,-85},{700,-62,-85},{720,-62,0},{1300,-62,0}},dual=true,missing=3},
  {name='one_second_second_path_during_reassess',samples={{100,-62,-85},{200,-62,-85},{220,0,0,false,false,false},{300,-62,0},{600,-62,-85},{680,-62,-85},{700,-62,0},{1200,-62,0}},selected=1},
  {name='selected_path_does_not_chase_strength',mode='Single',samples={{100,-95,-45},{200,-95,-45},{400,-105,-42}},selected=1},
  {name='loss_before_any_dual_evidence',samples={{100,0,0,false,false,false},{200,-62,0},{800,-62,0}},selected=1},
  {name='reassess_before_five_seconds',samples={{100,-62,-85},{200,-62,-85},{220,-62,-85,false,false,false},{300,-62,0},{780,-62,0}},dual=true,missing=3},
  {name='reassess_single_at_five_seconds',samples={{100,-62,-85},{200,-62,-85},{220,-62,-85,false,false,false},{300,-62,0},{800,-62,0}},selected=1},
  {name='reassess_second_only',samples={{100,-62,-85},{200,-62,-85},{220,-62,-85,false,false,false},{300,0,-85},{800,0,-85}},selected=2},
  {name='reassess_missing_second',samples={{100,-62,-85},{200,-62,-85},{220,-62,-85,false,false,false},{300,-62,false},{800,-62,false}},selected=1},
  {name='reassess_stale_second',samples={{100,-62,-85},{200,-62,-85},{220,-62,-85,false,false,false},{300,-62,-85,true,false},{800,-62,-85,true,false}},selected=1},
  {name='partial_loss_never_reassesses',samples={{100,-62,-85},{200,-62,-85},{300,-62,0},{6300,-62,0}},dual=true,missing=3},
  {name='loss_keeps_dual_frozen',samples={{100,-62,-85},{200,-62,-85},{220,-62,-85,false,false,false},{6300,-62,-85,false,false,false}},dual=true,missing=2},
  {name='both_return_cancel_reassessment',samples={{100,-62,-85},{200,-62,-85},{220,-62,-85,false,false,false},{300,-62,-85},{400,-62,-85},{500,-62,0},{6000,-62,0}},dual=true,missing=3},
  {name='brief_second_resets_single_hold',samples={{100,-62,-85},{200,-62,-85},{220,-62,-85,false,false,false},{300,-62,0},{700,-62,-85},{720,-62,0},{1100,-62,0}},dual=true,missing=3},
  {name='brief_second_then_full_single_hold',samples={{100,-62,-85},{200,-62,-85},{220,-62,-85,false,false,false},{300,-62,0},{700,-62,-85},{720,-62,0},{1220,-62,0}},selected=1},
  {name='second_returns_after_downgrade',samples={{100,-62,-85},{200,-62,-85},{220,-62,-85,false,false,false},{300,-62,0},{800,-62,0},{900,-62,-85},{1000,-62,-85}},dual=true},
  {name='forced_dual_survives_reassessment',mode='Dual',samples={{100,-62,-85},{200,-62,-85},{220,-62,-85,false,false,false},{300,-62,0},{800,-62,0}},dual=true,missing=3},
  {name='repeated_loss_restarts_hold',samples={{100,-62,-85},{200,-62,-85},{220,-62,-85,false,false,false},{300,-62,0},{700,-62,0},{720,-62,0,false,false,false},{800,-62,0},{1000,-62,0}},dual=true,missing=3},
  {name='startup_waits',samples={{100,-62,-85}},selected=1},
  {name='dual_confirmed',samples={{100,-62,-85},{200,-62,-85}},dual=true},
  {name='zero_second',samples={{100,-62,0},{200,-62,0}},selected=1,invalid=3},
  {name='second_only',samples={{100,0,-85},{200,0,-85}},selected=2,invalid=2},
  {name='brief_second',samples={{100,-62,-85},{180,-62,-85}},selected=1},
  {name='interrupted_confirmation',samples={{100,-62,-85},{160,-62,false},{220,-62,-85},{300,-62,-85}},selected=1},
  {name='equal_readings',samples={{100,-62,-62},{200,-62,-62}},dual=true},
  {name='ANT_is_not_count',ant=2,samples={{100,-62,0},{200,-62,0}},selected=1},
  {name='second_stale_keeps_dual',samples={{100,-62,-85},{200,-62,-85},{220,-62,-85,true,false}},dual=true,missing=3},
  {name='all_stale_keeps_dual',samples={{100,-62,-85},{200,-62,-85},{220,-62,-85,false,false}},dual=true,missing=2},
  {name='reconnection_keeps_dual',samples={{100,-62,-85},{200,-62,-85},{220,-62,-85,false,false},{420,-62,0}},dual=true,missing=3,invalid=3},
  {name='forced_single',mode='Single',samples={{100,-62,-85},{200,-62,-85}},selected=1},
  {name='forced_single_second',mode='Single',samples={{100,0,-85},{200,0,-85}},selected=2},
  {name='forced_dual_missing',mode='Dual',samples={{100,-62,0}},dual=true,missing=3},
  {name='invalid_mode_defaults_auto',mode='wrong',samples={{100,-62,0},{200,-62,0}},selected=1},
  {name='nan_second',samples={{100,-62,0/0},{200,-62,0/0}},selected=1,invalid=3},
  {name='positive_infinity',samples={{100,-62,math.huge},{200,-62,math.huge}},selected=1,invalid=3},
  {name='negative_infinity',samples={{100,-62,-math.huge},{200,-62,-math.huge}},selected=1,invalid=3},
  {name='positive_rssi',samples={{100,-62,10},{200,-62,10}},selected=1,invalid=3},
  {name='clock_rollback_restarts_confirmation',samples={{100,-62,-85},{180,-62,-85},{40,-62,-85},{100,-62,-85}},selected=1},
  {name='clock_rollback_keeps_dual',samples={{100,-62,-85},{200,-62,-85},{40,-62,-85}},dual=true},
  {name='independent_instances',isolation=true,samples={{100,-62,0},{200,-62,0}},selected=1},
  {name='numeric_single',mode=2,samples={{100,-62,-85},{200,-62,-85}},selected=1},
  {name='numeric_dual',mode=3,samples={{100,-62,0}},dual=true,missing=3},
  {name='missing_second',samples={{100,-62,false},{200,-62,false}},selected=1,invalid=3},
  {name='single_falls_back_to_established_path',mode='Single',samples={{100,-62,-85},{200,-62,-85},{220,0,-85},{320,0,-85}},selected=2},
  {name='single_brief_dropout_stays',mode='Single',samples={{100,-62,-85},{200,-62,-85},{220,0,-85}},selected=1,missing=2},
  {name='single_dropout_recovery_resets_hold',mode='Single',samples={{100,-62,-85},{200,-62,-85},{220,0,-85},{300,-62,-85},{320,0,-85},{400,0,-85}},selected=1,missing=2},
  {name='raw_footer_zero',footer=3,samples={{100,-62,0},{200,-62,0}},selected=1,invalid=3}
}
local index,sizeIndex,stage=1,1,0
local widget,tick,values,current
local keys={'LCD_W','LCD_H','lcd','getTime','getVersion','getFieldInfo','getSourceValue','sources'}

return function()
  local saved={}
  for _,key in ipairs(keys) do saved[key]=_G[key] end
  local case=cases[index]
  local size=sizes[sizeIndex]
  local ok,err=pcall(function()
    LCD_W,LCD_H=size[1],size[2]
    getTime=function() return tick or 100 end
    getVersion=function() return 'test','test' end
    getFieldInfo=function(name)
      for id,label in ipairs(names) do if name==label then return {id=id} end end
    end
    sources=nil
    getSourceValue=function(id) return values[id],current[id]~=false,true end
    if stage==0 then
      tick=100;values={99,-62,-85,8,29,250,97,-75,6,case.ant or 1};current={}
      widget=app.create({x=0,y=0,w=size[1],h=size[2]},
        {['Antennas']=case.mode,['Footer 1']=case.footer,['Recover s']=0})
      widget.moduleVersion='test'
      if case.isolation then
        -- A separate established dual instance must not affect this instance.
        local other=app.create(widget.zone,{})
        app.background(other);tick=200;app.background(other)
      end
      stage=1
      return
    end
    local sample=case.samples[stage]
    if sample then
      tick=sample[1]
      values[2]=sample[2]~=false and sample[2] or nil
      values[3]=sample[3]~=false and sample[3] or nil
      current[2]=sample[4]~=false;current[3]=sample[5]~=false
      current[1]=sample[6]~=false
      app.background(widget)
      stage=stage+1
      return
    end
    if case.invalid then
      assert(widget.lastSample[case.invalid]==nil,'Invalid RSSI entered history')
      assert(widget.plotHistory[#widget.plotHistory][case.invalid]==nil,'Invalid RSSI entered plot bucket')
    end
    local seen,lines={},{}
    local footerSeen={}
    local footer=size[2]-(size[1]>=600 and 64 or 36)
    lcd={drawText=function(x,y,str,flags)
      if y<110 or (size[1]>=600 and y<180) then seen[str]=(seen[str] or 0)+1 end
      if y>=footer then footerSeen[str]=true end
    end,sizeText=saved.lcd.sizeText,drawFilledRectangle=function() end,
    drawLine=function(x1,y1,x2,y2) lines[#lines+1]={x1,y1,x2,y2} end}
    -- Distinct fixed paths let us verify which antenna the single trace uses.
    local colors={saved.lcd.RGB(255,255,255),saved.lcd.RGB(255,255,255),saved.lcd.RGB(255,255,255)}
    local plotTime=widget.lossSince and widget.historyEnd or tick
    widget.plotHistory={
      {time=plotTime-200,[1]=90,[2]=-60,[3]=-100,colors=colors},
      {time=plotTime-100,[1]=90,[2]=-60,[3]=-100,colors=colors}}
    app.refresh(widget,0)
    assert(seen['dBm']==(case.dual and 2 or 1),'Each displayed antenna needs its own unit')
    if case.dual then
      assert(seen['ANT 1'] and seen['ANT 2'],'Dual labels missing')
      assert(#lines==3,'Dual view must draw two RSSI traces and LQ')
    else
      assert(seen['ANT '..case.selected],'Wrong single antenna label')
      assert(not seen['ANT '..(3-case.selected)],'Unused antenna label present')
      assert(#lines==2,'Single view must draw one RSSI trace and LQ')
      local point=widget.plotHistory[1]
      local expectedY=case.selected==1 and point.rxY1 or point.rxY2
      assert(math.abs(lines[1][2]-expectedY)<1,'Single trace uses wrong antenna')
      assert(math.abs(lines[1][3]-widget.plotHistory[2].screenX)<1,'Single trace must be solid')
    end
    if case.missing then assert(seen['--'],'Missing reading not shown as unavailable') end
    if case.footer then assert(footerSeen[size[1]>=600 and '0 dBm' or '0'],'Raw footer changed') end
    print('ANTENNA|'..case.name..'_'..size[1]..'|'..tostring(true))
    sizeIndex=sizeIndex+1
    if sizeIndex>#sizes then sizeIndex=1;index=index+1 end
    stage=0;widget=nil
  end)
  for _,key in ipairs(keys) do _G[key]=saved[key] end
  assert(ok,'Antenna case '..case.name..'/'..size[1]..': '..tostring(err))
  return index>#cases
end
