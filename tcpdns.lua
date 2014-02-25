local socket = require("socket")
local struct = require("struct")
local LRU = require("LRU")
local task = require("task")

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
      recv = recv..(s or partial)
      if status == "timeout" then coroutine.yield() end
    until status == "closed"
    sock:close()
  end
  return recv
end

local function transfer(skt, data, ip, port)
  local domain = (data:sub(14, -6):gsub("[^%w]", "."))
  print("domain: "..domain)
  task.mutex(domain)
  if cache.get(domain) then
    skt:sendto(data:sub(1, 2)..cache.get(domain), ip, port)
  else
    for _, host in ipairs(hosts) do
      data = queryDNS(host, data)
      if #data > 0 then break end
    end
    if #data > 0 then
      data = data:sub(3)
      cache.add(domain, data:sub(3))
      skt:sendto(data, ip, port)
    end
  end
  task.mutex(domain, false)
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
    coroutine.yield()
  end
end

task.go(udpserver)

local function loop()
  while true do
    if task.step() == 1 then
      socket.sleep(0.01)
    else
      socket.sleep(0.03)
    end
  end
end

loop()
