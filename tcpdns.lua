local socket = socket or require("socket")
local struct = struct or require("struct")
local insert, remove = table.insert, table.remove

local hosts = {"8.8.8.8", "8.8.4.4", "208.67.222.222", "208.67.220.220"}
local udp = socket.udp()
local threads = {}

local function LRU(size)
  local keys, dic, lru = {}, {}, {}

  function lru.add(key, value)
    if #keys == size then
      dic[keys[size]] = nil
      remove(keys)
    end
    insert(keys, 1, key)
    dic[key] = value
  end

  function lru.get(key)
    local value = dic[key]
    if value and keys[1] ~= key then
      for i, k in ipairs(keys) do
        if k == key then
          insert(keys, 1, remove(keys, i))
          break
        end
      end
    end
    return value
  end

  return lru
end

local cache = LRU(20)

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
      if status == "timeout" then coroutine.yield(sock) end
    until status == "closed"
  end
  return recv
end

local function new(data, ip, port)
  return coroutine.wrap(function()
    local data, ip, port = data, ip, port
    local domain = (data:sub(14, -6):gsub("[^%w]", "."))
    print("domain: "..domain, "thread: "..#threads)
    local packet = cache.get(domain)
    if packet then
      udp:sendto(data:sub(1, 2)..packet, ip, port)
    else
      for _, host in ipairs(hosts) do
        data = queryDNS(host, data)
        if #data > 0 then break end
      end
      if #data > 0 then
        data = data:sub(3)
        cache.add(domain, data:sub(3))
        udp:sendto(data, ip, port)
      end
    end
  end)
end

local function dispatch()
  local i = 1
  while threads[i] do
    local sock = threads[i]()
    if not sock then
      remove(threads, i)
    else
      i = i + 1
    end
  end
  if i > 1 then socket.sleep(0.03) end
end

local function mainLoop()
  udp:settimeout(0)
  udp:setsockname('*', 53)
  local data, ip, port
  while true do
    data, ip, port = udp:receivefrom()
    if data then insert(threads, new(data, ip, port)) end
    if #threads > 0 then dispatch() else socket.sleep(0.01) end
  end
end

mainLoop()
