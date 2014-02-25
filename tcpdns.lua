local socket = require("socket")
local struct = require("struct")

local threads = {}

local function addthread(f, ...)
  local new_thread = coroutine.create(f)
  coroutine.resume(new_thread, ...)
  if coroutine.status(new_thread) ~= "dead" then
    table.insert(threads, new_thread)
  end
end

local function step()
  if #threads == 0 then
    socket.sleep(0.01)
  else
    local i = 1
    while threads[i] do
      coroutine.resume(threads[i])
      if coroutine.status(threads[i]) == "dead" then
        table.remove(threads, i)
      else
        i = i + 1
      end
    end
    if i > 1 then socket.sleep(0.03) end
  end
end

local function LRU(size)
  local keys, dic, lru = {}, {}, {}

  function lru.add(key, value)
    if #keys == size then
      dic[keys[size]] = nil
      table.remove(keys)
    end
    table.insert(keys, 1, key)
    dic[key] = value
  end

  function lru.get(key)
    local value = dic[key]
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

  return lru
end

local cache = LRU(20)

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
      local s, status, partial = sock:receive(1024)
      recv = recv ..(s or partial)
      if status == "timeout" then coroutine.yield() end
    until status == "closed"
  end
  return recv
end

local lock = {}

local function transfer(skt, domain, data, ip, port)
  for _, host in ipairs(hosts) do
    data = queryDNS(host, data)
    if #data > 0 then break end
  end
  if #data > 0 then
    data = data:sub(3)
    cache.add(domain, data:sub(3))
    skt:sendto(data, ip, port)
  end
  lock[domain] = nil
end

local function handler(skt)
  local data, ip, port = skt:receivefrom()
  if data then
    local domain = (data:sub(14, -6):gsub("[^%w]", "."))
    local packet = cache.get(domain)
    if packet then
      skt:sendto(data:sub(1, 2)..packet, ip, port)
    elseif not lock[domain] then
      lock[domain] = true
      addthread(transfer, skt, domain, data, ip, port)
    end
    print("domain: "..domain, "thread: "..#threads)
  end
end

local udp = socket.udp()
udp:settimeout(0)
udp:setsockname('*', 53)

local function loop()
  while true do
    handler(udp)
    step()
  end
end

loop()
