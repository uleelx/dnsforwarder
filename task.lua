local task = {}

local threads = {}
local lock = {}

function task.go(f, ...)
  local thread = coroutine.create(f)
  coroutine.resume(thread, ...)
  if coroutine.status(thread) ~= "dead" then
    table.insert(threads, thread)
  end
end

function task.step()
  local i = 1
  while threads[i] do
    coroutine.resume(threads[i])
    if coroutine.status(threads[i]) == "dead" then
      table.remove(threads, i)
    else
      i = i + 1
    end
  end
  return #threads
end

function task.mutex(o, flag)
  if flag == nil then
    while lock[o] do
      coroutine.yield()
    end
    lock[o] = true
  elseif flag == false then
    lock[o] = nil
  end
end

return task