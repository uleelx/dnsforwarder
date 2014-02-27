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

  local pool = {}
  local mutex = {}
  local num = 0

  local function go(f, ...)
    local co = coroutine.create(f)
    assert(coroutine.resume(co, ...))
    if coroutine.status(co) ~= "dead" then
      pool[co] = pool[co] or os.clock()
      num = num + 1
    end
  end

  local function step()
    for co, wt in pairs(pool) do
      if os.clock() >= wt then
        assert(coroutine.resume(co))
        if coroutine.status(co) == "dead" then
          pool[co] = nil
          num = num - 1
        end
      end
    end
    return num
  end

  local function sleep(n)
    n = n or 0
    pool[coroutine.running()] = os.clock() + n
    coroutine.yield()
  end

  local function loop(n)
    n = n or 0.001
    local sleep = ps.sleep or socket.sleep
    while step() ~= 0 do sleep(n) end
  end

  local function lock(o, n)
    while mutex[o] do sleep(n) end
    mutex[o] = true
  end

  local function unlock(o)
    mutex[o] = nil
  end

  local function count()
    return num
  end

  task = {
    go = go, sleep = sleep,
    step = step, loop = loop,
    lock = lock, unlock = unlock,
    count = count
  }

end

-----------------------------------------
-- TCP DNS proxy
-----------------------------------------
local cache = LRU(45)
local task = task

local hosts = {
  "8.8.8.8", "8.8.4.4",
  "208.67.222.222", "208.67.220.220"
}

local function queryDNS(host, data)
  local sock = socket.tcp()
  sock:settimeout(2)
  local recv = ""
  if sock:connect(host, 53) then
    sock:send(struct.pack(">h", #data)..data)
    sock:settimeout(0)
    repeat
      task.sleep(0.01)
      local s, status, partial = sock:receive(1024)
      recv = recv..(s or partial)
    until #recv > 0 or status == "closed"
    sock:close()
  end
  return recv
end

local lock = {}

local function transfer(skt, data, ip, port)
  local domain = (data:sub(14, -6):gsub("[^%w]", "."))
  print("domain: "..domain, "thread: "..task.count())
  if lock[domain] then return end
  lock[domain] = true
  if cache.get(domain) then
    skt:sendto(data:sub(1, 2)..cache.get(domain), ip, port)
  else
    for _, host in ipairs(hosts) do
      data = queryDNS(host, data)
      if #data > 0 then break end
      task.sleep(0)
    end
    if #data > 0 then
      data = data:sub(3)
      cache.set(domain, data:sub(3))
      skt:sendto(data, ip, port)
    end
  end
  lock[domain] = nil
end

local function udpserver()
  local udp = socket.udp()
  udp:settimeout(0)
  udp:setsockname('*', 53)
  while true do
    local data, ip, port = udp:receivefrom()
    if data then
      task.go(transfer, udp, data, ip, port)
    end
    task.sleep(0)
  end
end

task.go(udpserver)

task.loop()
