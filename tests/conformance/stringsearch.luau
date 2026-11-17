-- This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
-- Worst cases for plain substring search: each one takes seconds if the search is O(n*m), and milliseconds if it is linear
print("testing plain substring search worst cases")

local s = string.rep("a", 2^21)

-- every position matches all but the last byte of the needle
local p = string.rep("a", 2^17 - 1) .. "b"
assert(string.find(s, p, 1, true) == nil)
assert(string.find(s, p) == nil)
assert(string.find(s .. "b", p, 1, true) == 2^21 - 2^17 + 2)
assert(#string.split(s, p) == 1)

-- the first and the last bytes of the separator match at every position
local sep = string.rep("a", 2^16) .. "b" .. string.rep("a", 2^16)
assert(#string.split(s, sep) == 1)
assert(string.find(s, sep, 1, true) == nil)

-- string.gsub with a literal pattern searches the same way when its literal fast path is on
if optimizestringgsub then
  assert(select(2, string.gsub(s, sep, "")) == 0)
  assert(select(2, string.gsub(s .. "b" .. s, sep, "")) == 1)
end

-- the first byte of the needle at every position, and a dense first byte of the right part in the two-way search
local t = string.rep("a", 2^22)
assert(string.find(t, "ab", 1, true) == nil)
assert(#string.split(t, "ab") == 1)
assert(string.find(string.rep("ba", 2^21), "babaa", 1, true) == nil)
assert(string.find(string.rep("ab", 2^21) .. "b", "ababb", 1, true) == 2^22 - 3)

return "OK"
