-- This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
-- Interning and string keys under either string hash (DFFlag::LuauShortStringHash, run with the flag off and on)
print("testing string interning and string keys")

-- strings of every length up to 70 (short, the 32-byte boundary and long), built in different ways, are one string
for len = 0, 70 do
  local bytes = {}
  for i = 1, len do
    bytes[i] = (i * 37 + len) % 256
  end
  local a = string.char(table.unpack(bytes))
  local b = ""
  for i = 1, len do
    b ..= string.char(bytes[i])
  end
  local c = ("x" .. a .. "y"):sub(2, -2)
  local buf = buffer.create(len)
  for i = 1, len do
    buffer.writeu8(buf, i - 1, bytes[i])
  end
  local d = buffer.tostring(buf)
  assert(#a == len and a == b and a == c and a == d)

  local t = { [a] = len }
  assert(t[b] == len and t[c] == len and t[d] == len)

  -- strings that differ from a in one byte, at each position, are other keys
  for i = 1, len do
    local e = a:sub(1, i - 1) .. string.char((bytes[i] + 1) % 256) .. a:sub(i + 1)
    assert(e ~= a and t[e] == nil)
    t[e] = -i
  end
  local n = 0
  for k, v in t do
    n += 1
    if v == len then
      assert(k == a)
    else
      local i = -v
      assert(k ~= a and #k == len and k:sub(1, i - 1) == a:sub(1, i - 1) and k:sub(i + 1) == a:sub(i + 1))
    end
  end
  assert(n == len + 1)
end

-- embedded zeros and high bytes
assert("\0" ~= "\0\0" and "a\0b" == "a" .. "\0" .. "b" and ("\255"):rep(31) == string.rep("\255", 31))
assert(({ ["a\0"] = 1 })["a"] == nil)

-- many keys: each is found, and pairs sees each once
local keys = {}
local t = {}
for i = 1, 20000 do
  local k = (i % 3 == 0) and ("session_" .. i) or (i % 3 == 1) and (i .. "_title") or string.format("%08x", i * 2654435761 % 2 ^ 32)
  keys[i] = k
  t[k] = i
end
for i = 1, 20000 do
  assert(t[keys[i]] == i)
end
local count = 0
for k, v in pairs(t) do
  assert(keys[v] == k)
  count += 1
end
assert(count == 20000)

-- strings dropped and made again after a collection compare equal to new copies
local function make(i)
  return "tmp_" .. i
end
local weak = setmetatable({}, { __mode = "k" })
for i = 1, 1000 do
  weak[{}] = make(i)
end
collectgarbage()
for i = 1, 1000 do
  local s = make(i)
  assert(s == "tmp_" .. tostring(i))
end

return "OK"
