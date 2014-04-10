local socket = require("socket")
local struct = require("struct")

-----------------------------------------
-- LRU cache function
-----------------------------------------
local function LRU(size)
  local keys, dict = {}, {}

  local function get(key)
    local value = dict[key]
    if value and keys[1] ~= key then
      for i, k in ipairs(keys) do
        if k == key then
          table.insert(keys, 1, table.remove(keys, i))
          break
        end
      end
    end
    return value
  end

  local function set(key, value)
    if not get(key) then
      if #keys == size then
        dict[keys[size]] = nil
        table.remove(keys)
      end
      table.insert(keys, 1, key)
    end
    dict[key] = value
  end

  return {set = set, get = get}
end

-----------------------------------------
-- task package
-----------------------------------------
do

  local create, resume, status, yield, running = coroutine.create, coroutine.resume, coroutine.status, coroutine.yield, coroutine.running
  local insert, remove, pack, unpack = table.insert, table.remove, table.pack, unpack or table.unpack
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
    local sleep = ps and ps.sleep or socket.sleep
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

end

local task = task

-----------------------------------------
-- TCP DNS proxy
-----------------------------------------
local CACHE_SIZE = 20
local NUM_WORKERS = 10
local HOSTS = {
  "8.8.8.8", "8.8.4.4",
  "208.67.222.222", "208.67.220.220"
}

local function queryDNS(host, data)
  local sock = socket.tcp()
  sock:settimeout(1)
  local ret = sock:connect(host, 53)
  if not ret then task.sleep(1) end
  ret = ""
  if sock:send(struct.pack(">h", #data)..data) then
    sock:settimeout(0)
    repeat
      task.sleep(0.02)
      local s, status, partial = sock:receive(1024)
      ret = ret..(s or partial)
    until #ret > 0 or status == "closed"
  end
  sock:close()
  return ret
end

local function worker(w_id, cache, input, output)
  while true do
    local data, ip, port = input()
    local domain = (data:sub(14, -6):gsub("[^%w]", "."))
    print("domain: "..domain, "worker: "..w_id)
    local ID, key = data:sub(1, 2), data:sub(3)
    if cache.get(key) then
      output(ID..cache.get(key):sub(5), ip, port)
    else
      for _, host in ipairs(HOSTS) do
        data = queryDNS(host, data)
        if #data > 0 then break end
      end
      if #data > 0 then
        cache.set(key, data)
        output(data:sub(3), ip, port)
      end
    end
  end
end

local function replier(udp, output)
  while true do
    local data, ip, port = output()
    udp:sendto(data, ip, port)
  end
end

local function listener(udp, input)
  while true do
    local data, ip, port = udp:receivefrom()
    if data and #data > 0 then
      input(data, ip, port)
    end
    task.sleep(0.05)
  end
end

local cache = LRU(CACHE_SIZE)
local input, output = task.chan(), task.chan()
local udp = socket.udp()
udp:settimeout(0)
udp:setsockname('*', 53)

task.go(listener, udp, input)
task.go(replier, udp, output)
for i = 1, NUM_WORKERS do
  task.go(worker, i, cache, input, output)
end
task.loop()
