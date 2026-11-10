-- Test-only native observer. Synthetic time advances independently of firmware
-- time. Each callback performs a bounded amount of work and restores APIs.
local app=loadScript('/WIDGETS/SignalView/main.lua')()
local names={'RQly','1RSS','2RSS','RSNR','RFMD','TPWR','TQly','TRSS','TSNR','ANT'}
local keys={'getTime','getFieldInfo','getSourceValue','sources'}
local second,stage,frames=0,'fill',0
local samples={count=0,sum=0,max=0}
local live={count=0,sum=0,max=0}
local scroll={count=0,sum=0,max=0}
local initialHeap,fullHeap
local function measure(row,fn,...)
  local before=getUsage()
  fn(...)
  local cost=getUsage()-before
  row.count=row.count+1;row.sum=row.sum+cost;row.max=math.max(row.max,cost)
end
local function check(name,condition)
  assert(condition,'Archive test failed: '..name)
  print('REVIEWCHECK|'..name..'|PASS')
end
local function heap()
  collectgarbage('collect') -- isolated measurement only
  return collectgarbage('count')
end
local function observe(w,event,touch)
  if event==nil then return end
  local saved={}
  for _,key in ipairs(keys) do saved[key]=_G[key] end
  local ok,err=pcall(function()
    local tick=second*100
    local values={99,-62,-65,8,29,250,97,-75,6,0}
    getTime=function() return tick end
    getFieldInfo=function(name)
      for id,label in ipairs(names) do if name==label then return {id=id} end end
    end
    sources=nil
    getSourceValue=function(id) return values[id],true,true end
    if not initialHeap then
      initialHeap=heap()
      w.scanTime=nil
      w.moduleVersion='4.0.0';w.moduleMajor=4
    end
    if stage=='fill' then
      for i=1,8 do
        second=second+1;tick=second*100
        local dip=math.sin((second%60)/60*math.pi)^4
        values[1]=math.floor(99-55*dip)
        values[2]=math.floor(-62-43*dip)
        values[3]=values[2]-3
        measure(samples,app.background,w)
      end
      if second==904 then fullHeap=heap() end
      if second>=1800 then
        stage='checks'
        print('REVIEWMEM|'..initialHeap..'|'..fullHeap..'|'..heap())
      end
      return
    end
    if stage=='checks' then
      if app.review then
        check('capacity_after_two_wraps',w.archive.count==901)
        local points,finish,oldest,newest=app.review.window(w,1)
        check('oldest_clamped',finish==oldest and oldest==90000 and newest==180000)
        points,finish=app.review.window(w,999999)
        check('newest_clamped',finish==180000 and #points<=32)
        check('newest_values',points[#points][1]==w.plotHistory[#w.plotHistory][1])
        local a=points[#points]
        check('recorded_colors',a.colors[2]==w.plotHistory[#w.plotHistory].colors[2])
        local oldColor=a.colors[2]
        w.options.RSSIwarn=-50
        points=app.review.window(w,180000)
        check('settings_do_not_recolor_archive',points[#points].colors[2]==oldColor)
        w.options.RSSIwarn=-98
        -- Loss, same-second reconnection, and clock rollback via public sampler.
        tick=180020
        getSourceValue=function(id) return nil,false,false end
        app.background(w)
        check('loss_preserves_archive',w.archive.count==901)
        tick=180040
        getSourceValue=function(id) return values[id],true,true end
        app.background(w)
        points=app.review.window(w,180000)
        check('same_second_loss_is_gap',points[#points][1]==nil and points[#points].breakBefore)
        local other=app.create(w.zone,{})
        tick=100;app.background(other)
        tick=20;app.background(other)
        check('clock_reset_clears_archive',other.archive.count==1)
        check('instances_are_isolated',w.archive.count==901)
      end
      stage='live';frames=0
      return
    end
    w.sampleTime=tick -- matched render-only measurement
    if stage=='live' then
      measure(live,app.refresh,w,0)
      frames=frames+1
      if frames==80 then stage='scroll';frames=0 end
      return
    end
    if stage=='scroll' then
      if app.review then
        local endpoint=90000+(frames*1137)%90000
        measure(scroll,app.review.render,w,endpoint)
        check('visible_window_'..frames,#w.reviewBuffer<=32)
      else measure(scroll,app.refresh,w,0) end
      frames=frames+1
      if frames==100 then
        for name,row in pairs({sampling=samples,live=live,scroll=scroll}) do
          print('REVIEWPERF|'..name..'|'..row.count..'|'..row.sum/row.count..'|'..row.max)
        end
        print('REVIEWFINALHEAP|'..heap())
        print('REVIEWDONE|PASS')
        stage=app.review and 'edges' or 'preview'
        frames=0
      end
      return
    end
    if stage=='edges' then
      frames=frames+1
      if frames==1 then
        app.review.window(w,136500)
        local before=w.reviewBuffer[#w.reviewBuffer].time
        second=1801;tick=second*100;app.background(w)
        check('record_while_reviewing',w.archive.time[w.archive.head]==tick)
        check('recording_preserves_selected_view',w.reviewBuffer[#w.reviewBuffer].time==before)
      elseif frames==2 then
        second=1802;tick=second*100
        getSourceValue=function(id) return values[id],id~=2,true end
        app.background(w)
        local points=app.review.window(w,tick)
        check('partial_source_gap',points[#points][2]==nil and points[#points][1]==99)
      elseif frames==3 then
        second=1803;tick=second*100
        getSourceValue=function() return nil,false,false end
        app.background(w)
        check('complete_loss_freezes_archive',w.archive.time[w.archive.head]==180200)
      elseif frames==4 then
        second=1903;tick=second*100;app.background(w)
        local points=app.review.window(w,tick)
        check('reconnection_retains_time_gap',points[#points].breakBefore and points[#points].time==190300)
      elseif frames==5 then
        app.review.render(w,185000)
        check('outage_cursor_has_no_stale_values',not w.reviewView.sensors[1].current
          and not w.reviewView.sensors[2].current and not w.reviewView.sensors[3].current)
      elseif frames==6 then
        app.review.render(w,136500)
        check('old_window_survives_reconnection',w.reviewView.sensors[1].current)
        print('REVIEWEDGES|PASS')
        stage='preview'
      end
      return
    end
    if app.review then app.review.render(w,136500)
    else app.refresh(w,0) end
  end)
  for _,key in ipairs(keys) do _G[key]=saved[key] end
  assert(ok,tostring(err))
end
return {name='LabTest',options=app.options,create=app.create,update=app.update,
  refresh=observe,background=function() end}
