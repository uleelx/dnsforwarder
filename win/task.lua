local pool = {}
local clk = setmetatable({}, {__mode = "k"})
local mutex = {}

local function go(f, ...)
  local co = coroutine.create(f)
  coroutine.resume(co, ...)
  if coroutine.status(co) ~= "dead" then
    table.insert(pool, co)
    clk[co] = clk[co] or os.clock()
  end
end

local function step()
  local i = 1
  while pool[i] and os.clock() >= clk[pool[i]] do
    coroutine.resume(pool[i])
    if coroutine.status(pool[i]) == "dead" then
      table.remove(pool, i)
    else
      i = i + 1
    end
  end
  return #pool
end

local function wait(n)
  n = n or 0
  clk[coroutine.running()] = os.clock() + n
  coroutine.yield()
end

local function loop(n)
  n = n or 0.001
  local sleep = ps.sleep or socket.sleep
  repeat
    sleep(n)
  until step() == 0
end

local function lock(o)
  while mutex[o] do
    coroutine.yield()
  end
  mutex[o] = true
end

local function unlock(o)
  mutex[o] = nil
end

task = {
  go = go, wait = wait,
  step = step, loop = loop,
  lock = lock, unlock = unlock
}

package.loaded["task"] = task