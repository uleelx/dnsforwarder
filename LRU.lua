return function (size)
  local keys, dic, lru = {}, {}, {}

  function lru.add(key, value)
    if not lru.get(key) then
      if #keys == size then
        dic[keys[size]] = nil
        table.remove(keys)
      end
      table.insert(keys, 1, key)
    end
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