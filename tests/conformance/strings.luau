-- This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
-- This file is based on Lua 5.x tests -- https://github.com/lua/lua/tree/master/testes
print('testing strings and string library')

assert('alo' < 'alo1')
assert('' < 'a')
assert('alo\0alo' < 'alo\0b')
assert('alo\0alo\0\0' > 'alo\0alo\0')
assert('alo' < 'alo\0')
assert('alo\0' > 'alo')
assert('\0' < '\1')
assert('\0\0' < '\0\1')
assert('\1\0a\0a' <= '\1\0a\0a')
assert(not ('\1\0a\0b' <= '\1\0a\0a'))
assert('\0\0\0' < '\0\0\0\0')
assert(not('\0\0\0\0' < '\0\0\0'))
assert('\0\0\0' <= '\0\0\0\0')
assert(not('\0\0\0\0' <= '\0\0\0'))
assert('\0\0\0' <= '\0\0\0')
assert('\0\0\0' >= '\0\0\0')
assert(not ('\0\0b' < '\0\0a\0'))
print('+')

assert(string.sub("123456789",2,4) == "234")
assert(string.sub("123456789",7) == "789")
assert(string.sub("123456789",7,6) == "")
assert(string.sub("123456789",7,7) == "7")
assert(string.sub("123456789",0,0) == "")
assert(string.sub("123456789",-10,10) == "123456789")
assert(string.sub("123456789",1,9) == "123456789")
assert(string.sub("123456789",-10,-20) == "")
assert(string.sub("123456789",-1) == "9")
assert(string.sub("123456789",-4) == "6789")
assert(string.sub("123456789",-6, -4) == "456")
assert(string.sub("\000123456789",3,5) == "234")
assert(("\000123456789"):sub(8) == "789")
print('+')

assert(string.find("123456789", "345") == 3)
a,b = string.find("123456789", "345")
assert(string.sub("123456789", a, b) == "345")
assert(string.find("1234567890123456789", "345", 3) == 3)
assert(string.find("1234567890123456789", "345", 4) == 13)
assert(string.find("1234567890123456789", "346", 4) == nil)
assert(string.find("1234567890123456789", ".45", -9) == 13)
assert(string.find("abcdefg", "\0", 5, 1) == nil)
assert(string.find("", "") == 1)
assert(string.find('', 'aaa', 1) == nil)
assert(('alo(.)alo'):find('(.)', 1, 1) == 4)
assert(string.find('', '1', 2) == nil)
assert(string.find('123', '2', 0) == 2)
print('+')

assert(string.len("") == 0)
assert(string.len("\0\0\0") == 3)
assert(string.len("1234567890") == 10)
assert(string.len(123) == 3)

assert(#"" == 0)
assert(#"\0\0\0" == 3)
assert(#"1234567890" == 10)

assert(string.byte("a") == 97)
assert(string.byte("\xe4") > 127)
assert(string.byte(string.char(255)) == 255)
assert(string.byte(string.char(0)) == 0)
assert(string.byte("\0") == 0)
assert(string.byte("\0\0alo\0x", -1) == string.byte('x'))
assert(string.byte("ba", 2) == 97)
assert(string.byte("\n\n", 2, -1) == 10)
assert(string.byte("\n\n", 2, 2) == 10)
assert(string.byte("") == nil)
assert(string.byte("hi", -3) == nil)
assert(string.byte("hi", 3) == nil)
assert(string.byte("hi", 9, 10) == nil)
assert(string.byte("hi", 2, 1) == nil)
assert(string.char() == "")
assert(string.char(0, 255, 0) == "\0\255\0")
assert(string.char(0, string.byte("\xe4"), 0) == "\0\xe4\0")
assert(string.char(string.byte("\xe4l\0óu", 1, -1)) == "\xe4l\0óu")
assert(string.char(string.byte("\xe4l\0óu", 1, 0)) == "")
assert(string.char(string.byte("\xe4l\0óu", -10, 100)) == "\xe4l\0óu")
assert(pcall(function() return string.char(256) end) == false)
assert(pcall(function() return string.char(-1) end) == false)
print('+')

assert(string.upper("ab\0c") == "AB\0C")
assert(string.lower("\0ABCc%$") == "\0abcc%$")
assert(string.rep('teste', 0) == '')
assert(string.rep('tés\00tê', 2) == 'tés\0têtés\000tê')
assert(string.rep('', 10) == '')
assert(string.rep('', 1e9) == '')
assert(pcall(string.rep, 'x', 2e9) == false)

assert(string.reverse"" == "")
assert(string.reverse"\0\1\2\3" == "\3\2\1\0")
assert(string.reverse"\0001234" == "4321\0")

for i=0,30 do assert(string.len(string.rep('a', i)) == i) end

assert(type(tostring(nil)) == 'string')
assert(type(tostring(12)) == 'string')
assert(''..12 == '12' and type(12 .. '') == 'string')
assert(string.find(tostring{}, 'table:'))
assert(string.find(tostring(print), 'function:'))
assert(tostring(1234567890123) == '1234567890123')
assert(#tostring('\0') == 1)
assert(tostring(true) == "true")
assert(tostring(false) == "false")

function nothing() end

assert(pcall(tostring) == false)
assert(pcall(function() return tostring(nothing()) end) == false)

print('+')

x = '"ílo"\n\\'
assert(string.format('%q%s', x, x) == '"\\"ílo\\"\\\n\\\\""ílo"\n\\')
assert(string.format('%q', "\0") == [["\000"]])
assert(string.format('%q', "\r") == [["\r"]])
assert(string.format("\0%c\0%c%x\0", string.byte("\xe4"), string.byte("b"), 140) ==
              "\0\xe4\0b8c\0")
assert(string.format('') == "")
assert(string.format("%c",34)..string.format("%c",48)..string.format("%c",90)..string.format("%c",100) ==
       string.format("%c%c%c%c", 34, 48, 90, 100))
assert(string.format("%c%c%c%c", 1, 0, 2, 3) == '\1\0\2\3')
assert(string.format("%5c%5c%5c%5c", 1, 0, 2, 3) == '    \1    \0    \2    \3')
assert(string.format("%-5c%-5c%-5c%-5c", 1, 0, 2, 3) == '\1    \0    \2    \3    ')
assert(string.format("%s\0 is not \0%s", 'not be', 'be') == 'not be\0 is not \0be')
assert(string.format("%%%d %010d", 10, 23) == "%10 0000000023")
assert(tonumber(string.format("%f", 10.3)) == 10.3)
x = string.format('"%-50s"', 'a')
assert(#x == 52)
assert(string.sub(x, 1, 4) == '"a  ')

assert(string.format("-%.20s.20s", string.rep("%", 2000)) == "-"..string.rep("%", 20)..".20s")
assert(string.format('"-%20s.20s"', string.rep("%", 2000)) ==
       string.format("%q", "-"..string.rep("%", 2000)..".20s"))

assert(string.format("%o %u %x %X", -1, -1, -1, -1) == "1777777777777777777777 18446744073709551615 ffffffffffffffff FFFFFFFFFFFFFFFF")

assert(string.format("%e %E", 1.5, -1.5) == "1.500000e+00 -1.500000E+00")

assert(pcall(string.format, "%##################d", 1) == false)
assert(pcall(string.format, "%.123d", 1) == false)
assert(pcall(string.format, "%?", 1) == false)

-- longest number that can be formated
assert(string.len(string.format('%99.99f', -1e308)) >= 100)

local function return_one_thing()
	return "hi"
end
local function return_two_nils()
	return nil, nil
end

assert(string.format("%*", return_one_thing()) == "hi")
assert(string.format("%* %*", return_two_nils()) == "nil nil")
assert(pcall(function()
	string.format("%* %* %*", return_two_nils())
end) == false)

assert(string.format("%*", "a\0b\0c") == "a\0b\0c")
assert(string.format("%*", string.rep("doge", 3000)) == string.rep("doge", 3000))
assert(string.format("%*", 42) == "42")
assert(string.format("%*", true) == "true")

assert(string.format("%*", setmetatable({}, { __tostring = function() return "ok" end })) == "ok")

local ud = newproxy(true)
getmetatable(ud).__tostring = function() return "good" end
assert(string.format("%*", ud) == "good")

assert(string.format(string.rep("%*", 100), table.unpack(table.create(100, 1))) == string.rep("1", 100))

do
	local a = "1234567890"
	a = string.format("%*%*%*%*%*", a, a, a, a, a)
	a = string.format("%*%*%*%*%*", a, a, a, a, a)
	a = string.format("%*%*%*%*%*", a, a, a, a, a)
	assert(a == string.rep("1234567890", 125))
end

assert(pcall(function()
	string.format("%#*", "bad form")
end) == false)

assert(loadstring("return 1\n--comentário sem EOL no final")() == 1)


assert(table.concat{} == "")
assert(table.concat({}, 'x') == "")
assert(table.concat({'\0', '\0\1', '\0\1\2'}, '.\0.') == "\0.\0.\0\1.\0.\0\1\2")
local a = {}; for i=1,3000 do a[i] = "xuxu" end
assert(table.concat(a, "123").."123" == string.rep("xuxu123", 3000))
assert(table.concat(a, "b", 20, 20) == "xuxu")
assert(table.concat(a, "", 20, 21) == "xuxuxuxu")
assert(table.concat(a, "", 22, 21) == "")
assert(table.concat(a, "3", 2999) == "xuxu3xuxu")

a = {"a","b","c"}
assert(table.concat(a, ",", 1, 0) == "")
assert(table.concat(a, ",", 1, 1) == "a")
assert(table.concat(a, ",", 1, 2) == "a,b")
assert(table.concat(a, ",", 2) == "b,c")
assert(table.concat(a, ",", 3) == "c")
assert(table.concat(a, ",", 4) == "")

-- string.split
do
  local function eq(a, b)
    if #a ~= #b then
      return false
    end
    for i=1,#a do
      if a[i] ~= b[i] then
        return false
      end
    end
    return true
  end

  assert(eq(string.split("abc", ""), {'a', 'b', 'c'}))
  assert(eq(string.split("abc", "b"), {'a', 'c'}))
  assert(eq(string.split("abc", "d"), {'abc'}))
  assert(eq(string.split("abc", "c"), {'ab', ''}))
  assert(eq(string.split("a,b,c"), {'a', 'b', 'c'}))
  assert(eq(string.split("", ""), {}))
  assert(eq(string.split("", ","), {''}))
  assert(eq(string.split(",", ","), {'', ''}))
  assert(eq(string.split(",a,,b,", ","), {'', 'a', '', 'b', ''}))
  assert(eq(string.split("abc", "abcd"), {'abc'}))
  assert(eq(string.split("abc", "abc"), {'', ''}))
  assert(eq(string.split("aaaa", "aa"), {'', '', ''}))
  assert(eq(string.split("aaa", "aa"), {'', 'a'}))
  assert(eq(string.split("abababa", "aba"), {'', 'b', ''}))
  assert(eq(string.split("aabaab", "ab"), {'a', 'a', ''}))
  assert(eq(string.split("aXa,aba", "aba"), {'aXa,', ''}))
  assert(eq(string.split("aaaa", "aab"), {'aaaa'}))
  assert(eq(string.split("a\r\nb\rc\n\r\nd", "\r\n"), {'a', 'b\rc\n', 'd'}))
  assert(eq(string.split("a\0b\0\0c", "\0"), {'a', 'b', '', 'c'}))
  assert(eq(string.split("a\0\0b\0c", "\0\0"), {'a', 'b\0c'}))
  assert(eq(string.split("a\0b", ""), {'a', '\0', 'b'}))

  local long = string.rep("x", 1000)
  local parts = string.split(table.concat(table.create(100, long), ";"), ";")
  assert(#parts == 100)
  for i=1,#parts do
    assert(parts[i] == long)
  end

  assert(eq(string.split("abababab", "abab"), {'', '', ''}))
  assert(eq(string.split("aabaabaab", "aab"), {'', '', '', ''}))
  assert(eq(string.split("abaabaab", "abaab"), {'', 'aab'}))
  assert(eq(string.split("xabcabcx", "abcabc"), {'x', 'x'}))
  assert(eq(string.split("\255\254\255\254", "\254\255"), {'\255', '\254'}))
end

-- plain substring search: string.find with plain = true or a pattern with no specials, and string.split
do
  local function check(s, p, init, a, b)
    local x, y = string.find(s, p, init, true)
    assert(x == a and y == b)
  end

  check("", "", nil, 1, 0)
  check("abc", "", nil, 1, 0)
  check("abc", "", 3, 3, 2)
  check("abc", "", 4, 4, 3)
  check("abc", "", 5, nil, nil)
  check("abc", "", -1, 3, 2)
  check("abc", "", -10, 1, 0)
  check("ab", "abc", nil, nil, nil)
  check("abc", "abc", nil, 1, 3)
  check("abc", "abc", 2, nil, nil)
  check("abcabc", "bc", -2, 5, 6)
  check("abcabc", "bc", -3, 5, 6)
  check("abcabc", "bc", -100, 2, 3)
  check("abcabc", "c", 7, nil, nil)
  check("aaa", "aa", 2, 2, 3)
  check("a\0b\0c", "\0c", nil, 4, 5)
  check("a\0b\0c", "\0", 3, 4, 4)
  check("a\0\0b", "\0\0b", nil, 2, 4)
  check("abaabaabab", "abab", nil, 7, 10)
  check("aaaaab", "aab", nil, 4, 6)
  check("abcabcabd", "abcabd", nil, 4, 9)
  check("babaabab", "abab", nil, 5, 8)
  check("\255\254\255\253", "\255\253", nil, 3, 4)
  check("\1\255\1\255\2", "\1\255\2", nil, 3, 5)
  assert(string.find("a\0b\0c", "b\0c") == 3)
  assert(string.find("aaaaab", "aab", 2) == 4)

  local function checkgsub(s, p, r, n, es, en)
    local x, y = string.gsub(s, p, r, n)
    assert(x == es and y == en)
  end

  checkgsub("abcabc", "bc", "X", nil, "aXaX", 2)
  checkgsub("aaaa", "aa", "b", nil, "bb", 2)
  checkgsub("aaa", "aa", "%0%0", nil, "aaaaa", 1)
  checkgsub("a\0b\0", "\0", "-", nil, "a-b-", 2)
  checkgsub("abc", "abcd", "x", nil, "abc", 0)
  checkgsub("abab", "ab", "x", 1, "xab", 1)
  checkgsub("abab", "ab", "x", 0, "abab", 0)
  checkgsub("abab", "ab", {ab = "T"}, nil, "TT", 2)
  checkgsub("abab", "ab", function(m) return m .. "!" end, nil, "ab!ab!", 2)
  checkgsub("aXa,aba", "aba", "", nil, "aXa,", 1)
  checkgsub("abaabaab", "abaab", "%%", nil, "%aab", 1)

  -- `from` is the first position where a match can start, when the caller knows that (it defaults to 1)
  local function naivefind(s, p, init, from)
    init = init or 1
    if init < 0 then
      init = math.max(#s + init + 1, 0)
    end
    init = math.max(init, 1)
    if init > #s + 1 then
      return nil
    end
    for i = math.max(init, from or 1), #s - #p + 1 do
      if string.sub(s, i, i + #p - 1) == p then
        return i, i + #p - 1
      end
    end
    return nil
  end

  local function naivesplit(s, sep, from)
    local res = {}
    if sep == "" then
      for i = 1, #s do
        table.insert(res, string.sub(s, i, i))
      end
      return res
    end
    local start, i = 1, from or 1
    while i + #sep - 1 <= #s do
      if string.sub(s, i, i + #sep - 1) == sep then
        table.insert(res, string.sub(s, start, i - 1))
        i += #sep
        start = i
      else
        i += 1
      end
    end
    table.insert(res, string.sub(s, start))
    return res
  end

  -- small alphabets so that periodic needles and near misses come up often; none of these bytes is a pattern special
  local seed = 1
  local function rand(n)
    seed = seed * 16807 % 2147483647
    return seed % n
  end

  local alphabets = {"ab", "abc", "a\0", "\255\254", "abcdefgh"}
  local function gen(alphabet, len)
    local t = table.create(len)
    for i = 1, len do
      local c = rand(#alphabet) + 1
      t[i] = string.sub(alphabet, c, c)
    end
    return table.concat(t)
  end

  for _ = 1, 10000 do
    local alphabet = alphabets[rand(#alphabets) + 1]
    local unit = gen(alphabet, rand(3) + 1)
    local s
    if rand(2) == 0 then
      s = gen(alphabet, rand(64))
    else
      -- a periodic haystack with a few bytes changed, so that needles match in part at many positions
      s = string.sub(string.rep(unit, 64), 1, rand(64))
      for _ = 1, rand(3) do
        if #s > 0 then
          local i = rand(#s) + 1
          s = string.sub(s, 1, i - 1) .. gen(alphabet, 1) .. string.sub(s, i + 1)
        end
      end
    end

    local p
    local kind = rand(4)
    if kind == 0 then
      p = gen(alphabet, rand(10))
    elseif kind == 1 then
      -- a periodic needle, sometimes with its last byte changed
      p = string.sub(string.rep(if rand(2) == 0 then unit else gen(alphabet, rand(4) + 1), 16), 1, rand(16))
      if #p > 0 and rand(2) == 0 then
        p = string.sub(p, 1, -2) .. gen(alphabet, 1)
      end
    elseif kind == 2 then
      -- a substring of the haystack
      local i = rand(#s + 1) + 1
      p = string.sub(s, i, i + rand(12) - 1)
    else
      -- a prefix of the periodic haystack with its last byte changed
      p = string.sub(string.rep(unit, 16), 1, rand(16)) .. gen(alphabet, 1)
    end

    -- a run in front of the haystack that the needle also starts with makes the search compare more bytes than it
    -- moves, so the rest of the haystack is searched with two-way; a match can't start in the run before the needle's
    -- first other byte fits
    local from
    if rand(4) == 0 then
      local c = string.sub(alphabet, 1, 1)
      p = string.rep(c, rand(3) + 2) .. p
      local run = 300 + rand(8)
      s = string.rep(c, run) .. s
      local q = string.find(p, "[^" .. c .. "]")
      from = if q then run - q + 2 else 1
    end

    local init = if rand(2) == 0 then nil else rand(2 * #s + 6) - #s - 3
    local a, b = naivefind(s, p, init, from)
    local x, y = string.find(s, p, init, true)
    assert(x == a and y == b)
    x, y = string.find(s, p, init)
    assert(x == a and y == b)

    local expected = naivesplit(s, p, from)
    local actual = string.split(s, p)
    assert(#actual == #expected)
    for i = 1, #expected do
      assert(actual[i] == expected[i])
    end

    -- string.gsub replaces the same matches as string.split finds, up to its limit
    if #p > 0 then
      local limit = if rand(3) == 0 then rand(#expected + 1) else nil
      local count = if limit then math.min(limit, #expected - 1) else #expected - 1
      local plain, escaped = expected[1], expected[1]
      for i = 2, #expected do
        plain ..= (if i - 1 <= count then "#" else p) .. expected[i]
        escaped ..= (if i - 1 <= count then "<" .. p .. ">" else p) .. expected[i]
      end
      local x, n = string.gsub(s, p, "#", limit)
      assert(x == plain and n == count)
      x, n = string.gsub(s, p, "<%0>", limit)
      assert(x == escaped and n == count)
    end
  end

  -- dense runs hand the search over to two-way, and long stretches without the needle's bytes hand it back; the pattern
  -- matcher (a position capture keeps it off the plain search) gives the expected results
  for _ = 1, 40 do
    local alphabet = alphabets[rand(#alphabets) + 1]
    local c = string.sub(alphabet, 1, 1)
    local p = string.rep(c, rand(3) + 2) .. gen(alphabet, rand(6))
    local parts = {}
    for _ = 1, 3 + rand(4) do
      local kind = rand(4)
      if kind == 0 then
        table.insert(parts, string.rep(c, 300 + rand(200)))
      elseif kind == 1 then
        table.insert(parts, gen(alphabet, 300 + rand(200)))
      elseif kind == 2 then
        table.insert(parts, string.rep("z", 4000 + rand(3000)))
      else
        table.insert(parts, p)
      end
    end
    local s = table.concat(parts)
    local pattern = p .. "()"

    local init = if rand(2) == 0 then nil else rand(#s) + 1
    local a, b = string.find(s, pattern, init)
    local x, y = string.find(s, p, init, true)
    assert(x == a and y == b)

    local expected, start = {}, 1
    while true do
      local i, j = string.find(s, pattern, start)
      if not i then
        break
      end
      table.insert(expected, string.sub(s, start, i - 1))
      start = j + 1
    end
    table.insert(expected, string.sub(s, start))

    local actual = string.split(s, p)
    assert(#actual == #expected)
    for i = 1, #expected do
      assert(actual[i] == expected[i])
    end

    local r, n = string.gsub(s, p, "#")
    assert(r == table.concat(expected, "#") and n == #expected - 1)
  end

  -- a dense prefix hands the search over to two-way, which moves through random filler (where the needle's critical byte
  -- is common) and hands the search back about 4 KiB later; the match moves across that point
  local prefix = string.rep("db", 200) .. "a"
  local filler = gen("ab", 4700)
  for _, p in {"dbb", "dbba", "dbbab"} do
    for fill = 3800, 4700 do
      local s = prefix .. string.sub(filler, 1, fill) .. p
      assert(string.find(s, p, 1, true) == #prefix + fill + 1)
    end
  end

  -- every needle "aa" .. t and haystack "aaa..." .. u for binary strings t and u up to 4 and 8 bytes: for needles that
  -- contain a "b", the run makes the search hand over to two-way, so this covers its rare branches (such as the shift by
  -- the period) exhaustively
  local function binary(code, len)
    local t = table.create(len)
    for i = 1, len do
      t[i] = if bit32.btest(code, bit32.lshift(1, i - 1)) then "b" else "a"
    end
    return table.concat(t)
  end

  for tl = 0, 4 do
    for tc = 0, 2 ^ tl - 1 do
      local p = "aa" .. binary(tc, tl)
      local q = string.find(p, "b", 1, true)
      local run = string.rep("a", 300)
      for bl = 0, 8 do
        for bc = 0, 2 ^ bl - 1 do
          local s = run .. binary(bc, bl)
          local a, b = naivefind(s, p, nil, if q then #run - q + 2 else 1)
          local x, y = string.find(s, p, 1, true)
          assert(x == a and y == b)
        end
      end
    end
  end
end

-- validate that variadic string fast calls get correct number of arguments
local function chr1(c)
  return string.char(tonumber(c));
end

assert(chr1("0") == "\0")

--[[
local locales = { "ptb", "ISO-8859-1", "pt_BR" }
local function trylocale (w)
  for _, l in ipairs(locales) do
    if os.setlocale(l, w) then return true end
  end
  return false
end

if not trylocale("collate")  then
  print("locale not supported")
else
  assert("alo" < "álo" and "álo" < "amo")
end

if not trylocale("ctype") then
  print("locale not supported")
else
  assert(string.gsub("áéíóú", "%a", "x") == "xxxxx")
  assert(string.gsub("áÁéÉ", "%l", "x") == "xÁxÉ")
  assert(string.gsub("áÁéÉ", "%u", "x") == "áxéx")
  assert(string.upper"áÁé{xuxu}ção" == "ÁÁÉ{XUXU}ÇÃO")
end

os.setlocale("C")
assert(os.setlocale() == 'C')
assert(os.setlocale(nil, "numeric") == 'C')
]]--

-- positions, characters and integer formats that don't fit in an int (or NaN)
do
  local function id(x) return x end

  for _, v in {id(2^31), id(-2^31 - 1), id(2^32 + 3), id(2^63), id(-2^63), id(2^64), id(1e300), id(math.huge), id(-math.huge), id(0/0)} do
    assert(string.byte("abc", v) == nil)
    assert(string.byte("abc", 1, v) == nil)
    assert(not pcall(string.char, v))
    assert(string.sub("abc", v) == "abc")
    assert(string.sub("abc", 1, v) == "")
    assert(select("#", table.unpack({1, 2, 3}, 1, v)) == 0)
    assert(not pcall(select, v, "a", "b"))
    assert(string.format("%c", v) == "\0")
    assert(not pcall(function() return string.char(v) end))
    assert(not pcall(string.pack, "i4", v))
  end

  -- a constant out of range is not folded (at -O2) and raises the same error
  assert(not pcall(function() return string.char(1e300) end))
  assert(not pcall(function() return string.char(65, 2^31) end))
  assert(string.char(65.5) == "A")

  -- integers out of the 64-bit range (and NaN) format as the minimum 64-bit integer
  assert(string.format("%d", id(2^31)) == "2147483648")
  assert(string.format("%d", id(-2^31 - 1)) == "-2147483649")
  assert(string.format("%x", id(-2^31 - 1)) == "ffffffff7fffffff")
  assert(string.format("%x", id(2^63)) == "8000000000000000")
  assert(string.format("%x", id(2^64 - 2048)) == "fffffffffffff800")
  for _, v in {id(2^64), id(1e300), id(math.huge), id(-math.huge), id(0/0), id(-2^63)} do
    assert(string.format("%d", v) == "-9223372036854775808")
    assert(string.format("%x", v) == "8000000000000000")
    assert(string.format("%o", v) == "1000000000000000000000")
  end
end

return('OK')


