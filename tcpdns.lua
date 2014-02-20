local socket = socket or require("socket")
local struct = struct or require("struct")

local hosts = {"8.8.8.8", "8.8.4.4", "208.67.222.222", "208.67.220.220"}
local udp = socket.udp()
local threads = {}
local mem = {}

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
    if mem[domain] then
      udp:sendto(data:sub(1, 2)..mem[domain], ip, port)
    else
      for _, host in ipairs(hosts) do
        data = queryDNS(host, data)
        if #data > 0 then break end
      end
      if #data > 0 then
        data = data:sub(3)
        mem[domain] = data:sub(3)
        udp:sendto(data, ip, port)
      end
    end
  end)
end

local function dispatch()
  local i = 1
  local timeout = {}
  while threads[i] do
    local sock = threads[i]()
    if not sock then
      table.remove(threads, i)
    else
      i = i + 1
      timeout[#timeout + 1] = sock
    end
  end
  if #timeout > 3 and #timeout == #threads then
    socket.select(timeout, nil, 0.1)
  end
end

local function mainLoop()
  udp:settimeout(0)
  udp:setsockname('*', 53)
  local data, ip, port
  while true do
    data, ip, port = udp:receivefrom()
    if data then threads[#threads + 1] = new(data, ip, port) end
    if #threads > 0 then dispatch() else socket.sleep(0.01) end
  end
end

mainLoop()