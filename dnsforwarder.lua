local socket = require("socket")

if not task then dofile("task.lua") end
local task = task

local SERVERS = {
  "119.29.29.29", "114.114.115.110", "223.5.5.5",
  "8.8.8.8", "208.67.220.123"
}

local FAKE_IP = {
  "0.0.0.0", "1.1.1.1", "113.11.194.190", "118.5.49.6", "12.87.133.0",
  "122.218.101.190", "123.126.249.238", "123.50.49.171", "125.230.148.48", "127.0.0.2",
  "128.121.126.139", "141.101.114.4", "141.101.115.4", "159.106.121.75", "159.24.3.173",
  "16.63.155.0", "169.132.13.103", "173.201.216.6", "188.5.4.96", "189.163.17.5",
  "190.93.244.4", "190.93.245.4", "190.93.246.4", "190.93.247.4", "192.67.198.6",
  "197.4.4.12", "198.105.254.11", "2.1.1.2", "20.139.56.0", "202.106.1.2",
  "202.181.7.85", "203.161.230.171", "203.195.174.41", "203.199.57.81", "203.98.7.65",
  "207.12.88.98", "208.109.138.55", "208.56.31.43", "209.145.54.50", "209.220.30.174",
  "209.36.73.33", "209.85.229.138", "211.5.133.18", "211.8.69.27", "211.94.66.147",
  "213.169.251.35", "213.186.33.5", "216.139.213.144", "216.221.188.182", "216.234.179.13",
  "221.8.69.27", "23.89.5.60", "24.51.184.0", "243.185.187.3", "243.185.187.30",
  "243.185.187.39", "249.129.46.48", "253.157.14.165", "255.255.255.255", "28.121.126.139",
  "28.13.216.0", "31.13.68.16", "31.13.68.33", "31.13.68.49", "31.13.68.8",
  "31.13.70.1", "31.13.70.17", "37.61.54.158", "4.193.80.0", "4.36.66.178",
  "46.20.126.252", "46.38.24.209", "46.82.174.68", "49.2.123.56", "54.76.135.1",
  "59.24.3.173", "61.54.28.6", "64.33.88.161", "64.33.99.47", "64.66.163.251",
  "65.104.202.252", "65.160.219.113", "66.206.11.194", "66.45.252.237", "67.215.65.132",
  "69.55.52.253", "72.14.205.104", "72.14.205.99", "74.117.57.138", "74.125.127.102",
  "74.125.155.102", "74.125.39.102", "74.125.39.113", "77.4.7.92", "78.16.49.15",
  "8.105.84.0", "8.7.198.45", "89.31.55.106", "93.46.8.89"
}

local IP, PORT = {}, {}
local busy = false

local function replier(proxy, forwarder)
  local lifetime, interval = 5, 0.01
  repeat
    if busy then lifetime, busy = 5, false end
    local data = forwarder:receive()
    if data and #data > 0 then
      local ID = data:sub(1, 2)
      if IP[ID] and not FAKE_IP[data:sub(-4)] then
        proxy:sendto(data, IP[ID], PORT[ID])
        IP[ID], PORT[ID] = nil, nil
      end
    end
    lifetime = lifetime - interval
    task.sleep(interval)
  until lifetime < 0
end

local function listener(proxy, forwarder)
  while true do
    local data, ip, port = proxy:receivefrom()
    if data and #data > 0 then
      local domain = (data:sub(14, -6):gsub("[^%w]", "."))
      io.write(domain.."\n")
      local ID = data:sub(1, 2)
      IP[ID], PORT[ID] = ip, port
      for _, server in ipairs(SERVERS) do
        local dns_ip, dns_port = string.match(server, "([^:]*):?(.*)")
        dns_port = tonumber(dns_port) or 53
        forwarder:sendto(data, dns_ip, dns_port)
      end
      busy = true
      if task.count() == 1 then task.go(replier, proxy, forwarder) end
    end
    task.sleep(0.02)
  end
end

local function main()
  for _, ip in ipairs(FAKE_IP) do
    FAKE_IP[ip:gsub("%d+", string.char):gsub("(.).", "%1")] = true
  end

  local proxy = socket.udp()
  proxy:settimeout(0)
  assert(proxy:setsockname("*", 53))

  local forwarder = socket.udp()
  forwarder:settimeout(0)
  assert(forwarder:setsockname("*", 0))

  task.go(listener, proxy, forwarder)
  task.loop()
end

main()
