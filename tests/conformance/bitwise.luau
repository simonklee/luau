-- This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
-- This file is based on Lua 5.x tests -- https://github.com/lua/lua/tree/master/testes
print("testing bitwise operations")

local function noinline(x, ...) local s, r = pcall(function(y) return y end, x) return r end

assert(bit32.band() == bit32.bnot(0))
assert(bit32.btest() == true)
assert(bit32.bor() == 0)
assert(bit32.bxor() == 0)

assert(bit32.band() == bit32.band(0xffffffff))
assert(bit32.band(1,2) == 0)


-- out-of-range numbers
assert(bit32.band(-1) == 0xffffffff)
assert(bit32.band(2^33 - 1) == 0xffffffff)
assert(bit32.band(-2^33 - 1) == 0xffffffff)
assert(bit32.band(2^33 + 1) == 1)
assert(bit32.band(-2^33 + 1) == 1)
assert(bit32.band(-2^40) == 0)
assert(bit32.band(2^40) == 0)
assert(bit32.band(-2^40 - 2) == 0xfffffffe)
assert(bit32.band(2^40 - 4) == 0xfffffffc)

assert(bit32.band(noinline(-1)) == 0xffffffff)
assert(bit32.band(noinline(2^33 - 1)) == 0xffffffff)
assert(bit32.band(noinline(-2^33 - 1)) == 0xffffffff)
assert(bit32.band(noinline(2^33 + 1)) == 1)
assert(bit32.band(noinline(-2^33 + 1)) == 1)
assert(bit32.band(noinline(-2^40)) == 0)
assert(bit32.band(noinline(2^40)) == 0)
assert(bit32.band(noinline(-2^40 - 2)) == 0xfffffffe)
assert(bit32.band(noinline(2^40 - 4)) == 0xfffffffc)

assert(bit32.lrotate(0, -1) == 0)
assert(bit32.lrotate(0, 7) == 0)
assert(bit32.lrotate(0x12345678, 4) == 0x23456781)
assert(bit32.rrotate(0x12345678, -4) == 0x23456781)
assert(bit32.lrotate(0x12345678, -8) == 0x78123456)
assert(bit32.rrotate(0x12345678, 8) == 0x78123456)
assert(bit32.lrotate(0xaaaaaaaa, 2) == 0xaaaaaaaa)
assert(bit32.lrotate(0xaaaaaaaa, -2) == 0xaaaaaaaa)

assert(bit32.lrotate(noinline(0), -1) == 0)
assert(bit32.lrotate(noinline(0), 7) == 0)
assert(bit32.lrotate(noinline(0x12345678), 4) == 0x23456781)
assert(bit32.rrotate(noinline(0x12345678), -4) == 0x23456781)
assert(bit32.lrotate(noinline(0x12345678), -8) == 0x78123456)
assert(bit32.rrotate(noinline(0x12345678), 8) == 0x78123456)
assert(bit32.lrotate(noinline(0xaaaaaaaa), 2) == 0xaaaaaaaa)
assert(bit32.lrotate(noinline(0xaaaaaaaa), -2) == 0xaaaaaaaa)

for i = -50, 50 do
  assert(bit32.lrotate(0x89abcdef, i) == bit32.lrotate(0x89abcdef, i%32))
end

local function lrotateregression1(x: number)
  local y = bit32.bxor(x, 0x12345)
  return bit32.lrotate(y, y)
end
assert(lrotateregression1(noinline(0)) == 0x2468a0)

assert(bit32.lshift(0x12345678, 4) == 0x23456780)
assert(bit32.lshift(0x12345678, 8) == 0x34567800)
assert(bit32.lshift(0x12345678, -4) == 0x01234567)
assert(bit32.lshift(0x12345678, -8) == 0x00123456)
assert(bit32.lshift(0x12345678, 32) == 0)
assert(bit32.lshift(0x12345678, -32) == 0)
assert(bit32.rshift(0x12345678, 4) == 0x01234567)
assert(bit32.rshift(0x12345678, 8) == 0x00123456)
assert(bit32.rshift(0x12345678, 32) == 0)
assert(bit32.rshift(0x12345678, -32) == 0)
assert(bit32.arshift(0x12345678, 0) == 0x12345678)
assert(bit32.arshift(0x12345678, 1) == 0x12345678 / 2)
assert(bit32.arshift(0x12345678, -1) == 0x12345678 * 2)
assert(bit32.arshift(-1, 1) == 0xffffffff)
assert(bit32.arshift(-1, 24) == 0xffffffff)
assert(bit32.arshift(-1, 32) == 0xffffffff)
assert(bit32.arshift(-1, -1) == (-1 * 2) % 2^32)

assert(bit32.lshift(noinline(0x12345678), 4) == 0x23456780)
assert(bit32.lshift(noinline(0x12345678), 8) == 0x34567800)
assert(bit32.lshift(noinline(0x12345678), -4) == 0x01234567)
assert(bit32.lshift(noinline(0x12345678), -8) == 0x00123456)
assert(bit32.lshift(noinline(0x12345678), 32) == 0)
assert(bit32.lshift(noinline(0x12345678), -32) == 0)
assert(bit32.rshift(noinline(0x12345678), 4) == 0x01234567)
assert(bit32.rshift(noinline(0x12345678), 8) == 0x00123456)
assert(bit32.rshift(noinline(0x12345678), 32) == 0)
assert(bit32.rshift(noinline(0x12345678), -32) == 0)
assert(bit32.arshift(noinline(0x12345678), 0) == 0x12345678)
assert(bit32.arshift(noinline(0x12345678), 1) == 0x12345678 / 2)
assert(bit32.arshift(noinline(0x12345678), -1) == 0x12345678 * 2)
assert(bit32.arshift(noinline(-1), 1) == 0xffffffff)
assert(bit32.arshift(noinline(-1), 24) == 0xffffffff)
assert(bit32.arshift(noinline(-1), 32) == 0xffffffff)
assert(bit32.arshift(noinline(-1), -1) == (-1 * 2) % 2^32)

print("+")
-- some special cases
local c = {0, 1, 2, 3, 10, 0x80000000, 0xaaaaaaaa, 0x55555555,
           0xffffffff, 0x7fffffff}

for _, b in pairs(c) do
  assert(bit32.band(b) == b)
  assert(bit32.band(b, b) == b)
  assert(bit32.btest(b, b) == (b ~= 0))
  assert(bit32.band(b, b, b) == b)
  assert(bit32.btest(b, b, b) == (b ~= 0))
  assert(bit32.band(b, bit32.bnot(b)) == 0)
  assert(bit32.bor(b, bit32.bnot(b)) == bit32.bnot(0))
  assert(bit32.bor(b) == b)
  assert(bit32.bor(b, b) == b)
  assert(bit32.bor(b, b, b) == b)
  assert(bit32.bxor(b) == b)
  assert(bit32.bxor(b, b) == 0)
  assert(bit32.bxor(b, 0) == b)
  assert(bit32.bxor(b, b, b) == b)
  assert(bit32.bxor(b, b, b, b) == 0)
  assert(bit32.bnot(b) ~= b)
  assert(bit32.bnot(bit32.bnot(b)) == b)
  assert(bit32.bnot(b) == 2^32 - 1 - b)
  assert(bit32.lrotate(b, 32) == b)
  assert(bit32.rrotate(b, 32) == b)
  assert(bit32.lshift(bit32.lshift(b, -4), 4) == bit32.band(b, bit32.bnot(0xf)))
  assert(bit32.rshift(bit32.rshift(b, 4), -4) == bit32.band(b, bit32.bnot(0xf)))
  for i = -40, 40 do
    assert(bit32.lshift(b, i) == math.floor((b * 2^i) % 2^32))
  end
end

assert(not pcall(bit32.band, {}))
assert(not pcall(bit32.bnot, "a"))
assert(not pcall(bit32.lshift, 45))
assert(not pcall(bit32.lshift, 45, print))
assert(not pcall(bit32.rshift, 45, print))

print("+")


-- testing extract/replace

assert(bit32.extract(0x12345678, 0, 4) == 8)
assert(bit32.extract(0x12345678, 4, 4) == 7)
assert(bit32.extract(0xa0001111, 28, 4) == 0xa)
assert(bit32.extract(0xa0001111, 31, 1) == 1)
assert(bit32.extract(0x50000111, 31, 1) == 0)
assert(bit32.extract(0xf2345679, 0, 32) == 0xf2345679)
assert(bit32.extract(0xa0001111, 0) == 1)
assert(bit32.extract(0xa0001111, 16) == 0)
assert(bit32.extract(0xa0001111, 31) == 1)
assert(bit32.extract(42, 1, 3) == 5)

assert(bit32.extract(noinline(0x12345678), 0, 4) == 8)
assert(bit32.extract(0x12345678, noinline(0), 4) == 8)
assert(bit32.extract(0x12345678, 0, noinline(4)) == 8)
assert(bit32.extract(noinline(0x12345678), 4, 4) == 7)
assert(bit32.extract(noinline(0xa0001111), 28, 4) == 0xa)
assert(bit32.extract(noinline(0xa0001111), 31, 1) == 1)
assert(bit32.extract(noinline(0x50000111), 31, 1) == 0)
assert(bit32.extract(noinline(0xf2345679), 0, 32) == 0xf2345679)
assert(bit32.extract(noinline(0xa0001111), 0) == 1)
assert(bit32.extract(noinline(0xa0001111), 16) == 0)
assert(bit32.extract(noinline(0xa0001111), 31) == 1)
assert(bit32.extract(noinline(42), 1, 3) == 5)

local pos pos = 1
assert(bit32.extract(42, pos, 3) == 5) -- test bit32.extract builtin instead of bit32.extractk

assert(not pcall(bit32.extract, 0, -1))
assert(not pcall(bit32.extract, 0, 32))
assert(not pcall(bit32.extract, 0, 0, 33))
assert(not pcall(bit32.extract, 0, 31, 2))

assert(bit32.replace(0x12345678, 5, 28, 4) == 0x52345678)
assert(bit32.replace(0x12345678, 0x87654321, 0, 32) == 0x87654321)
assert(bit32.replace(0, 1, 2) == 2^2)
assert(bit32.replace(0, -1, 4) == 2^4)
assert(bit32.replace(-1, 0, 31) == 2^31 - 1)
assert(bit32.replace(-1, 0, 1, 2) == 2^32 - 7)

assert(bit32.replace(noinline(0x12345678), 5, 28, 4) == 0x52345678)
assert(bit32.replace(0x12345678, noinline(5), 28, 4) == 0x52345678)
assert(bit32.replace(0x12345678, 5, noinline(28), 4) == 0x52345678)
assert(bit32.replace(0x12345678, 5, 28, noinline(4)) == 0x52345678)
assert(bit32.replace(noinline(0x12345678), 0x87654321, 0, 32) == 0x87654321)
assert(bit32.replace(noinline(0), 1, 2) == 2^2)
assert(bit32.replace(noinline(0), -1, 4) == 2^4)
assert(bit32.replace(noinline(-1), 0, 31) == 2^31 - 1)
assert(bit32.replace(noinline(-1), 0, 1, 2) == 2^32 - 7)

-- testing countlz/countrc
assert(bit32.countlz(0) == 32)
assert(bit32.countlz(42) == 26)
assert(bit32.countlz(0xffffffff) == 0)
assert(bit32.countlz(0x80000000) == 0)
assert(bit32.countlz(0x7fffffff) == 1)

assert(bit32.countlz(noinline(0)) == 32)
assert(bit32.countlz(noinline(42)) == 26)
assert(bit32.countlz(noinline(0xffffffff)) == 0)
assert(bit32.countlz(noinline(0x80000000)) == 0)
assert(bit32.countlz(noinline(0x7fffffff)) == 1)

assert(bit32.countrz(0) == 32)
assert(bit32.countrz(1) == 0)
assert(bit32.countrz(42) == 1)
assert(bit32.countrz(0x80000000) == 31)
assert(bit32.countrz(0x40000000) == 30)
assert(bit32.countrz(0x7fffffff) == 0)

assert(bit32.countrz(noinline(0)) == 32)
assert(bit32.countrz(noinline(1)) == 0)
assert(bit32.countrz(noinline(42)) == 1)
assert(bit32.countrz(noinline(0x80000000)) == 31)
assert(bit32.countrz(noinline(0x40000000)) == 30)
assert(bit32.countrz(noinline(0x7fffffff)) == 0)

-- testing byteswap
assert(bit32.byteswap(0x10203040) == 0x40302010)
assert(bit32.byteswap(0) == 0)
assert(bit32.byteswap(-1) == 0xffffffff)

assert(bit32.byteswap(noinline(0x10203040)) == 0x40302010)
assert(bit32.byteswap(noinline(0)) == 0)
assert(bit32.byteswap(noinline(-1)) == 0xffffffff)

-- bit32.bor(n, 0) must clear top bits
-- we check this obscuring the constant through a global to make sure this gets evaluated fully
high32 = 0x42_1234_5678
assert(bit32.bor(high32, 0) == 0x1234_5678)

--[[
This test verifies a fix in luauF_replace() where if the 4th
parameter was not a number, but the first three are numbers, it will
cause the Luau math library to crash.
]]--

assert(bit32.replace(-1, 0, 1, "2") == 2^32 - 7)

-- many of the tests above go through fastcall path
-- to make sure the basic implementations are also correct we test some functions with string->number coercions
assert(bit32.lrotate("0x12345678", 4) == 0x23456781)
assert(bit32.rrotate("0x12345678", -4) == 0x23456781)
assert(bit32.arshift("0x12345678", 1) == 0x12345678 / 2)
assert(bit32.arshift("-1", 32) == 0xffffffff)
assert(bit32.arshift("-1", 1) == 0xffffffff)
assert(bit32.bnot("1") == 0xfffffffe)
assert(bit32.band("1", 3) == 1)
assert(bit32.band(1, "3") == 1)
assert(bit32.band(1, 3, "5") == 1)
assert(bit32.bor("1", 2) == 3)
assert(bit32.bor(1, "2") == 3)
assert(bit32.bor(1, 3, "5") == 7)
assert(bit32.bxor("1", 3) == 2)
assert(bit32.bxor(1, "3") == 2)
assert(bit32.bxor(1, 3, "5") == 7)
assert(bit32.btest(1, "3") == true)
assert(bit32.btest("1", 3) == true)
assert(bit32.countlz("42") == 26)
assert(bit32.countrz("42") == 1)
assert(bit32.extract("42", 1, 3) == 5)
assert(bit32.byteswap("0xa1b2c3d4") == 0xd4c3b2a1)

-- numbers within 64-bit integer range wrap around, numbers outside of it (and NaN) convert to 0
do
  local function id(x) return x end

  for _, v in {id(2^63), id(-2^63), id(2^64), id(1e300), id(math.huge), id(-math.huge), id(0/0)} do
    assert(bit32.bor(v) == 0)
    assert(bit32.band(v, 0xffffffff) == 0)
    assert(bit32.bxor(v, 1) == 1)
    assert(bit32.lshift(v, 1) == 0)
    assert(bit32.countlz(v) == 32)
    assert(select(2, pcall(bit32.bor, v)) == 0)
  end

  assert(bit32.bor(id(2^53 + 2)) == 2)
  assert(bit32.bor(id(2^63 - 1024)) == 0xfffffc00)
  assert(select(2, pcall(bit32.bor, id(2^53 + 2))) == 2)
end

-- shift, rotate and field arguments that don't fit in an int (or NaN) take the generic path
do
  local function id(x) return x end

  for _, v in {id(2^31), id(-2^31 - 1), id(2^32 + 3), id(2^63), id(-2^63), id(2^64), id(1e300), id(math.huge), id(-math.huge), id(0/0)} do
    assert(bit32.arshift(-8, v) == 0)
    assert(bit32.lshift(1, v) == 0)
    assert(bit32.rshift(0x80000000, v) == 0)
    assert(bit32.lrotate(3, v) == 3)
    assert(bit32.rrotate(3, v) == 3)
    assert(not pcall(bit32.extract, 0xff, v))
    assert(not pcall(bit32.extract, 0xff, 0, v))
    assert(not pcall(bit32.replace, 0, 1, v))
    assert(not pcall(bit32.replace, 0, 1, 0, v))
  end

  -- field + width past the int range is out of range, not an overflow
  for _, fw in {{id(2^31 - 1), nil}, {id(2^31 - 1), id(1)}, {id(1), id(2^31 - 1)}, {id(2^31 - 31), id(2^31 - 31)}} do
    assert(not pcall(bit32.extract, 0xffffffff, fw[1], fw[2]))
    assert(not pcall(bit32.replace, 0, 1, fw[1], fw[2]))
  end
  assert(bit32.extract(0xffffffff, id(31), id(1)) == 1)
  assert(bit32.replace(0, 1, id(31), id(1)) == 0x80000000)

  -- the same through direct calls with a single result, which are fast calls (and native code under codegen)
  local function e(x, f, w) return (bit32.extract(x, f, w)) end
  local function r(n, v, f, w) return (bit32.replace(n, v, f, w)) end
  for _, fw in {{2^31 - 1, 1}, {1, 2^31 - 1}, {2^31 - 31, 2^31 - 31}, {32, 1}} do
    assert(not pcall(e, 0xffffffff, fw[1], fw[2]))
    assert(not pcall(r, 0, 3, fw[1], fw[2]))
  end
  assert(e(0xffffffff, 31, 1) == 1)
  assert(r(0, 3, 31, 1) == 0x80000000)

  -- rotating by -2^31 or 2^31 is a multiple of 32
  assert(bit32.rrotate(3, id(-2^31)) == 3)
  assert(bit32.lrotate(3, id(-2^31)) == 3)
  assert(bit32.rrotate(3, id(-5)) == 96)
  assert(bit32.rrotate(3, id(5)) == 0x18000000)
  assert(select(2, pcall(bit32.rrotate, 3, id(-2^31))) == 3)
  assert(select(2, pcall(bit32.rrotate, 3, id(-5))) == 96)
  assert(select(2, pcall(bit32.arshift, -8, id(2^31))) == 0)
  assert(select(2, pcall(bit32.arshift, -8, id(-2^31))) == 0)
  assert(select(2, pcall(bit32.rshift, 8, id(-2^31))) == 0)
  assert(select(2, pcall(bit32.lshift, 8, id(-2^31))) == 0)
end

return('OK')
