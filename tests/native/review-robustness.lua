-- Regression coverage for version gating, graph discontinuities and discovery.
-- Run one bounded case per callback against the unmodified installable source.
local app=loadScript('/WIDGETS/SignalView/main.lua')()
local keys={'lcd','getTime','getFieldInfo','getSourceValue','sources','crossfireTelemetryPush','crossfireTelemetryPop'}
local names={'RQly','1RSS','2RSS','RSNR','RFMD','TPWR','TQly','TRSS','TSNR','ANT'}
local stage,versionWidget,pushes,pops=0,nil,0,0
local visit
local function check(name,ok)
 assert(ok,'Robustness test failed: '..name)
 print('ROBUST|'..name..'|PASS')
end
local function refresh(w,event,touch)
 if event==nil or stage>=27 then app.refresh(w,event,touch);return end
 stage=stage+1
 local saved={}
 for _,key in ipairs(keys) do saved[key]=_G[key] end
 local ok,err=pcall(function()
  local tick=1000
  local values={99,-105,-105,8,7,250,97,-75,6,0}
  getTime=function() return tick end
  getFieldInfo=function(name) for id,label in ipairs(names) do if name==label then return {id=id} end end end
  sources=nil
  getSourceValue=function(id) return values[id],true,true end
  crossfireTelemetryPush=function() pushes=pushes+1;return true end
  crossfireTelemetryPop=function() pops=pops+1;return nil end
  local texts,lines={},0
  lcd={sizeText=saved.lcd.sizeText,drawFilledRectangle=function() end,
   drawText=function(_,_,text) texts[text]=true end,
   drawLine=function() lines=lines+1 end}
  local f=app.create({x=0,y=0,w=LCD_W,h=LCD_H},{['Recover s']=0})
  if stage==1 then
   app.background(f)
   check('unknown_version_muted',f.lastSample.colors[2]==saved.lcd.RGB(167,185,173))
  elseif stage==2 then
   f.moduleMajor=3;app.background(f)
   check('legacy_version_muted',f.lastSample.colors[2]==saved.lcd.RGB(167,185,173))
  elseif stage==3 then
   f.moduleMajor=4;app.background(f)
   check('confirmed_v4_amber',f.lastSample.colors[2]==saved.lcd.RGB(255,195,106))
  elseif stage==4 then
   app.update(f,{['RSSI mode']=2,['RX amber']=-98,['RX red']=-103,['Recover s']=0});app.background(f)
   check('manual_without_version',f.lastSample.colors[2]==saved.lcd.RGB(255,116,116))
  elseif stage==5 then
   app.update(f,{['RSSI mode']=3});app.background(f)
   check('off_without_version',f.lastSample.colors[2]==saved.lcd.RGB(255,255,255))
  elseif stage==6 or stage==7 then
   f.moduleMajor=4;app.background(f);tick=stage==6 and 1500 or 1199;app.background(f)
   app.refresh(f,0)
   check(stage==6 and 'live_missing_seconds_gap' or 'live_adjacent_jitter_connected',lines==(stage==6 and 0 or 3))
   lines=0;app.review.render(f,tick)
   check(stage==6 and 'review_missing_seconds_gap' or 'review_adjacent_jitter_connected',lines==(stage==6 and 0 or 3))
  elseif stage==8 then
   versionWidget=f;pushes=0;pops=0;app.refresh(f,0)
   check('discovery_initial_ping',pushes==1 and pops==1)
  elseif stage==9 then
   tick=1020;app.refresh(versionWidget,0)
   tick=1040;app.background(versionWidget)
   tick=10000;app.refresh(versionWidget,0)
   check('discovery_resumes_after_hidden',pushes==2 and versionWidget.versionElapsed==20)
  elseif stage==10 then
   tick=10020
   crossfireTelemetryPop=function() return 0x29,{0xEA,0xEE,84,88,0,69,76,82,83,0,0,0,0,0,4,1,0,0,0} end
   app.refresh(versionWidget,0)
   check('delayed_version_received',versionWidget.moduleVersion=='4.1.0')
  elseif stage==11 then
   versionWidget=f;tick=1000;app.refresh(f,0)
   tick=2020;local before=pushes;app.refresh(f,0)
   check('visible_budget_bounded',pushes==before)
  elseif stage==12 then
   tick=3000;app.background(versionWidget);tick=5000;local before=pushes;app.refresh(versionWidget,0)
   check('timeout_not_restarted_forever',pushes==before)
  elseif stage==13 then
   versionWidget=f;app.refresh(f,0)
   tick=1020;f.zone={x=0,y=0,w=100,h=100};app.refresh(f,nil)
   tick=10000;f.zone={x=0,y=0,w=LCD_W,h=LCD_H};local before=pushes;app.refresh(f,nil)
   check('small_zone_pauses_discovery',pushes==before+1 and (f.versionElapsed or 0)==0)
  elseif stage==14 or stage==16 then
   local enumerated=0
   getFieldInfo=function(name) for id,label in ipairs(names) do if name==label and id~=10 then return {id=id} end end end
   sources=function() local i=0;return function() i=i+1;if i<=94 then enumerated=enumerated+1;return i,'unrelated'..i end end end
   f.scanTime=nil;app.background(f);tick=1200;app.background(f)
   if stage==14 then
    tick=2000;app.background(f)
    check('optional_source_fallback_backoff',enumerated==188)
   else
    tick=900;app.background(f)
    check('fallback_clock_rollback',enumerated==188)
   end
  elseif stage==15 then
   local enumerated=0
   getFieldInfo=function(name) for id,label in ipairs(names) do if name==string.lower(label) then return {id=id} end end end
   sources=function() local i=0;return function() i=i+1;if names[i] then enumerated=enumerated+1;return i,string.lower(names[i]) end end end
   f=app.create({x=0,y=0,w=LCD_W,h=LCD_H},{})
   tick=1200;app.background(f)
   check('resolved_legacy_names_cached',enumerated==10 and f.sensors[1].id==1 and f.sensors[10].id==10)
  elseif stage==17 then
   f.moduleMajor=4;app.background(f)
   tick=1020;getSourceValue=function() return nil,false,false end;app.background(f)
   check('diagnostic_sample_clears_stale_fields',f.lastSample[1]==nil and f.lastSample[2]==nil and f.lastSample[3]==nil and f.lastSample.colors[1]==nil and f.archive.count==1)
  elseif stage==18 or stage==19 then
   f.moduleMajor=4;app.background(f)
   if stage==19 then
    tick=1020;getSourceValue=function() return nil,false,false end;app.background(f)
    getSourceValue=function(id) return values[id],true,true end
   end
   tick=1500;app.background(f)
   tick=1520;values[1]=97;values[2]=-106;app.background(f)
   tick=1540;values[1]=98;app.background(f)
   local a=f.archive;local index=a.head
   check(stage==18 and 'post_gap_bucket_retains_minima' or 'new_second_reconnection_retains_minima',a.quality[index]==97 and a.rx1[index]==-106 and a.breaks[index])
   app.review.render(f,1540)
   check(stage==18 and 'post_gap_review_readings' or 'new_second_reconnection_review_readings',f.reviewView.sensors[1].value==97 and f.reviewView.sensors[2].value==-106)
  elseif stage==20 then
   f.moduleMajor=4;app.background(f)
   tick=1020;getSourceValue=function() return nil,false,false end;app.background(f)
   tick=1040;getSourceValue=function(id) return values[id],true,true end;app.background(f)
   tick=1060;app.background(f)
   check('same_second_reconnection_stays_gap',f.archive.quality[f.archive.head]==nil and f.archive.breaks[f.archive.head])
   tick=1100;app.background(f);tick=1120;app.background(f)
   check('next_second_after_reconnection_recovers',f.archive.quality[f.archive.head]==99)
  elseif stage==21 then
   versionWidget=f;tick=10000;app.refresh(f,0)
   tick=20;app.background(f);tick=40;local before=pushes;app.refresh(f,0)
   check('hidden_clock_rollback_retries',pushes==before+1)
   tick=60;crossfireTelemetryPop=function() return 0x29,{0xEA,0xEE,84,88,0,69,76,82,83,0,0,0,0,0,4,1,0,0,0} end
   app.refresh(f,0)
   check('hidden_clock_rollback_receives_version',f.moduleVersion=='4.1.0')
  elseif stage==22 then
   tick=10000;app.refresh(f,0);tick=40;local before=pushes;app.refresh(f,0)
   check('visible_clock_rollback_retries',pushes==before+1)
  elseif stage==23 or stage==25 or stage==26 or stage==27 then
   if not visit then visit=0;versionWidget=f;pushes=0;pops=0 end
   visit=visit+1;tick=1000+visit*200
   if stage==25 then
    crossfireTelemetryPop=function() pops=pops+1;return 0x2B,{} end
   elseif stage==26 and visit==7 then
    crossfireTelemetryPop=function() pops=pops+1;return 0x29,{0xEA,0xEE,84,88,0,69,76,82,83,0,0,0,0,0,4,1,0,0,0} end
   elseif stage==27 then
    crossfireTelemetryPush=function() pushes=pushes+1;return false end
   end
   app.refresh(versionWidget,0);app.background(versionWidget)
   local limit=stage==23 and 110 or (stage==25 and 60 or (stage==26 and 7 or 8))
   if visit<limit then stage=stage-1
   else
    if stage==23 or stage==25 then
     check(stage==23 and 'brief_visits_empty_queue_bounded' or 'brief_visits_busy_queue_bounded',pushes==6 and pops==102)
    elseif stage==26 then
     check('late_reply_after_final_ping_accepted',pushes==6 and versionWidget.moduleVersion=='4.1.0')
    else
     check('failed_push_attempts_bounded',pushes==6)
     print('ROBUSTDONE|PASS')
    end
    visit=nil
   end
  elseif stage==24 then
   tick=20;app.background(versionWidget);tick=40
   local beforePush,beforePop=pushes,pops;app.refresh(versionWidget,0)
   check('rollback_does_not_replenish_work_limits',pushes==beforePush and pops==beforePop)

  end
 end)
 for _,key in ipairs(keys) do _G[key]=saved[key] end
 assert(ok,tostring(err))
end
return {name='LabTest',options=app.options,create=app.create,update=app.update,refresh=refresh,background=app.background}
