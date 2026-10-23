-- Test-only: getUsage measures Lua instruction-budget consumption, not total
-- radio CPU time. Heap counts include this isolated Lua VM and its observer.
-- Never collect garbage explicitly in the installed widget.
collectgarbage('collect')
local startHeap=collectgarbage('count')
local started=getTime()
local rows={}
local measured=false
local function call(kind,fn,...)
  local first=getUsage()
  fn(...)
  local used=getUsage()-first
  local age=getTime()-started
  local stage=age<3500 and 'warm' or 'steady'
  local key=kind..'|'..stage
  local row=rows[key]
  if not row then row={n=0,sum=0,max=0};rows[key]=row end
  row.n=row.n+1;row.sum=row.sum+used;row.max=math.max(row.max,used)
  if age>=4500 and not measured then
    measured=true
    collectgarbage('collect')
    local heap=collectgarbage('count')
    print('PERFMEM|'..startHeap..'|'..heap..'|'..(heap-startHeap))
  end
  if age>=3500 and (not row.last or age-row.last>=500) then
    row.last=age
    print('PERF|'..key..'|'..row.n..'|'..row.sum..'|'..row.max)
  end
end
return call
