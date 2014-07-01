-----------------------------------------
-- task package
-----------------------------------------

local create, resume, status, yield, running = coroutine.create, coroutine.resume, coroutine.status, coroutine.yield, coroutine.running
local insert, remove, unpack = table.insert, table.remove, unpack or table.unpack
local assert, pairs, select, clock = assert, pairs, select, os.clock

local pool = {}
local mutex = {}
local num = 0

local function go(f, ...)
  local co = create(f)
  assert(resume(co, ...))
  if status(co) ~= "dead" then
    pool[co] = pool[co] or clock()
    num = num + 1
  end
end

local function sleep(n)
  n = n or 0
  pool[running()] = clock() + n
  yield()
end

local function step()
  local nwt = 1/0
  for co, wt in pairs(pool) do
    if clock() >= wt and not mutex[mutex[co]] then
      assert(resume(co))
      if status(co) == "dead" then
        pool[co] = nil
        num = num - 1
      end
    end
    if pool[co] and not mutex[co] and nwt > pool[co] then
      nwt = pool[co]
    end
  end
  return num, nwt - clock()
end

local function loop()
  local sleep = socket.sleep
  while true do
    local num, wait = step()
    if num == 0 then break end
    if wait > 0 then sleep(wait) end
  end
end

local function lock(o)
  if mutex[o] then
    mutex[running()] = o
    yield()
  end
  if running() then
    mutex[running()] = nil
  end
  mutex[o] = true
  return o
end

local function unlock(o)
  mutex[o] = nil
end

local function close(ch)
  ch(close)
end

local function chan()
  local queue = lock{}
  return function(...)
    if select("#", ...) == 0 then
      if queue[1] and queue[1][1] == close then
        return close
      end
      if #queue < 2 then lock(queue) end
      if queue[1][1] == close then
        unlock(queue) return close
      end
      return unpack(remove(queue, 1))
    else
      insert(queue, {...})
      unlock(queue)
      yield()
    end
  end
end

local function count()
  return num
end

task = {
  go = go, sleep = sleep,
  step = step, loop = loop,
  lock = lock, unlock = unlock,
  chan = chan, close = close,
  count = count
}
