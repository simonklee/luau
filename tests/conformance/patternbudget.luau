-- This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
-- Pattern functions charge their work and call the interrupt every so many units of it (LuauPatternBudget). The top
-- level checks that results don't change, for each place that charges; the functions below are the worst cases, which
-- the PatternBudget test calls with an interrupt that stops them.
print("testing pattern budget")

-- checks both results of string.gsub
local function gsub(s, p, r, n, expected, count)
	local got, k = string.gsub(s, p, r, n)
	if got ~= expected or k ~= count then
		error(`gsub returned {#got} bytes and {k}, expected {#expected} and {count}`, 2)
	end
end

local function set(n)
	return "[" .. string.rep("b", n) .. "a]"
end

-- a set scanned for each byte by '*' and '-'
do
	local s = string.rep("a", 300)
	assert(string.find(s, set(100) .. "*c") == nil)
	local i, j = string.find(s .. "c", set(100) .. "*c")
	assert(i == 1 and j == 301)
	assert(string.find(s, set(100) .. "-c") == nil)
	assert(string.match(s .. "c", "^(" .. set(100) .. "-)c") == s)
	assert(string.match("xbbaay", "x(" .. set(30) .. "+)y") == "bbaa")
	assert(string.match("xbbaay", "x(" .. set(30) .. "-)a") == "bb")
	assert(string.match("x", "^" .. set(30) .. "?x$") == "x")
end

-- a long literal pattern: match() steps through it without a new entry
do
	local s = string.rep("a", 1000)
	local p = string.rep("a", 997) .. "b"
	gsub(s, p, "", nil, s, 0)
	assert(string.match(s, p) == nil)
	assert(string.gmatch(s, p)() == nil)
	assert(string.find(s, p .. ".") == nil)
	assert(string.find(s, p .. "$") == nil)
	assert(string.find(s .. "b", "^" .. string.rep("a", 1000) .. "b$") == 1)
	assert(select(2, string.gsub(s, string.rep("a", 300), "")) == 3)
end

-- a literal pattern in gsub, which LuauOptimizeStringGsub searches for directly
do
	local s = string.rep("a", 1000)
	gsub(s, "a", { a = "" }, nil, "", 1000)
	assert(string.gsub(s, "a", { a = "x" }) == string.rep("x", 1000))
	assert(string.gsub(s, "a", { b = 1 }) == s)
	assert(string.gsub(s, "a", function() end) == s)
	assert(string.gsub(s, "a", "%0%0") == string.rep("a", 2000))
	gsub(s, "aa", "b", nil, string.rep("b", 500), 500)
	gsub(s, "a", "", 10, string.rep("a", 990), 10)
	assert(string.gsub("abcabc", "bc", "%%") == "a%a%")
end

-- the other cases of the linear search's reviews, small
do
	local s = string.rep("a", 4096)
	local half = string.rep("a", 128)
	gsub(s, half .. "b" .. half, "", nil, s, 0)
	gsub(s, "a", "", nil, "", 4096)
	gsub(s, "aa", "", nil, "", 2048)
	assert(string.find(s, "ab", 1, true) == nil)
	assert(#string.split(s, "ab") == 1)
	local t = string.split(string.rep("aa", 1000), "aa")
	assert(#t == 1001 and t[1] == "" and t[1001] == "")
	t = string.split(s, "a")
	assert(#t == 4097 and t[1] == "" and t[4097] == "")
	assert(string.find(string.rep("db", 200) .. "a" .. string.rep("ab", 1000) .. "dbb", "dbb", 1, true) == 2402)
end

-- %b scans the subject
do
	assert(string.find(string.rep("(", 1000), "%b()") == nil)
	local s = string.rep("(", 500) .. string.rep(")", 500)
	local i, j = string.find("x" .. s, "%b()")
	assert(i == 2 and j == 1001)
	assert(string.gsub("f(a(b)c) g(d)", "%b()", "") == "f g")
end

-- %f scans its set
do
	local s = string.rep("x", 100) .. "a"
	local f = "%f" .. set(500)
	assert(string.find(s, f) == 101)
	assert(select(2, string.gsub("a xa ya", f, "")) == 3)
	assert(string.find("aaa", f) == 1)
end

-- back-references compare the capture
do
	local s = string.rep("a", 1000) .. "b"
	assert(string.match(s, "^(a+)%1b") == string.rep("a", 500))
	assert(string.match(s, "^(a+)%1c") == nil)
	assert(string.match("abab", "^(ab)%1$") == "ab")
	assert(string.find("()", "()%1") == nil)
	assert(string.match("xyzxyz", "(x(y)z)%1") == "xyz")
end

-- replacement strings are charged by their length, since an empty capture adds nothing to the result
do
	gsub("xyz", "(q*)", string.rep("%1", 100), nil, "xyz", 4)
	gsub("xyz", "q*", string.rep("%0", 100), nil, "xyz", 4)
	gsub("xyz", "(y)", string.rep("%1", 3), nil, "xyyyz", 1)
	assert(string.gsub("hello world", "(o)", "[%1%0]") == "hell[oo] w[oo]rld")
	assert(string.gsub("abc", "", "-") == "-a-b-c-")
	assert(not pcall(string.gsub, "abc", "b", "%2"))
	assert(not pcall(string.gsub, "abc", "b", "%x"))
end

-- the classes, captures and anchors that common patterns use
do
	local text = string.rep("key = value; ", 200)
	local n = 0
	for k, v in string.gmatch(text, "(%w+) = (%w+)") do
		assert(k == "key" and v == "value")
		n += 1
	end
	assert(n == 200)
	assert(string.match("  trim me  ", "^%s*(.-)%s*$") == "trim me")
	assert(string.match("2026-11-17", "^(%d+)-(%d+)-(%d+)$") == "2026")
	assert(select(2, string.gsub(text, "%s+", " ")) == 600)
	assert(string.find(text, "value;", 1000, false) == 1008)
	assert(string.match(text, "()value", 2000) == 2009)
	local wide = "a\240\159\152\128b\240\159\152\128c"
	assert(select(2, string.gsub(wide, "[\240-\247]", "")) == 2)
end

-- gmatch pushes its captures before it saves its position, past the stack it starts with
do
	local p = string.rep("(.)", 32)
	local s = string.rep("x", 63) .. "y"
	local n = 0
	for a, b in string.gmatch(s, p) do
		n += 1
	end
	assert(n == 2)
	local t = { string.gmatch(s, p)() }
	assert(#t == 32 and t[32] == "x")
	local it = string.gmatch(s, p)
	it()
	t = { it() }
	assert(#t == 32 and t[32] == "y")
	assert(it() == nil)
end

-- string.split counts a 1-byte separator before it builds the result
do
	local t = string.split(string.rep("a,", 1000), ",")
	assert(#t == 1001 and t[1] == "a" and t[1001] == "")
	t = string.split("", ",")
	assert(#t == 1 and t[1] == "")
	t = string.split(",", ",")
	assert(#t == 2 and t[1] == "" and t[2] == "")
	t = string.split("a\0b\0", "\0")
	assert(#t == 3 and t[1] == "a" and t[2] == "b" and t[3] == "")
	t = string.split("\255x\255", "\255")
	assert(#t == 3 and t[2] == "x")
end

-- The worst cases, each seconds or more of work without an interrupt. The PatternBudget test calls them with an
-- interrupt that stops them; none returns.

-- a pcall of a worst case that the interrupt stops, 10 times
function budgetpcall()
	local s, p = string.rep("a", 256 * 1024), set(32 * 1024) .. "*c"
	for i = 1, 10 do
		local ok, message = pcall(string.find, s, p)
		assert(not ok and message == "timeout")
	end
end

-- a 32 KB set scanned for each of 256 KB by '*', from each position
function budgetset()
	return string.find(string.rep("a", 256 * 1024), set(32 * 1024) .. "*c")
end

-- the same with '-'
function budgetsetmin()
	return string.find(string.rep("a", 256 * 1024), set(32 * 1024) .. "-c")
end

-- a 10 MB literal pattern that match() steps through from each position
local longs, longp
local function long()
	longs = longs or string.rep("a", 10 * 1024 * 1024)
	longp = longp or string.rep("a", 10 * 1024 * 1024 - 300) .. "b"
	return longs, longp
end

function budgetgsub()
	local s, p = long()
	return string.gsub(s, p, "")
end

function budgetmatch()
	local s, p = long()
	return string.match(s, p)
end

function budgetgmatch()
	local s, p = long()
	return string.gmatch(s, p)()
end

function budgetfind()
	local s, p = long()
	return string.find(s, p .. ".")
end

-- 33M matches of a literal, replaced with a table's value: LuauOptimizeStringGsub's loop
function budgetgsubtable()
	return string.gsub(string.rep("a", 33000000), "a", { a = "" })
end

-- a replacement of 512K copies of an empty match, at each of 1M positions: no capture is pushed, and nothing is added
function budgetreplacement()
	return string.gsub(string.rep("a", 1024 * 1024), "q*", string.rep("%0", 512 * 1024))
end

-- %b scans to the end from each position
function budgetbalance()
	return string.find(string.rep("(", 1024 * 1024), "%b()")
end

-- a back-reference compares up to half the subject, for each length of the capture, from each position
function budgetbackref()
	return string.find(string.rep("a", 1024 * 1024), "(a*)%1b")
end

-- a 32 KB frontier set at each of 1M positions
function budgetfrontier()
	return string.gsub(string.rep("a", 1024 * 1024), "%f" .. set(32 * 1024), "")
end

-- what PatternBudgetCharges calls: a string function and its arguments, whose work is 8192 units at n and 8193 or a
-- few more at n + 1 (8192 units leave no work, and the next one calls the interrupt). Each case's sum is in a comment.
function chargecase(name, n)
	local rep = string.rep
	if name == "steps" then
		-- a step for each item and one at the end: n + 1
		return string.find, rep("a", n), "^" .. rep("a", n)
	elseif name == "set" then
		-- 2 steps, classend's scan k, the match against the set k + 2: 2k + 4
		return string.find, "b", "^[" .. rep("b", n) .. "]"
	elseif name == "setend" then
		-- 2 steps and classend's scan k; at the end of the subject the set isn't matched against: k + 2
		return string.find, "", "^[" .. rep("b", n) .. "]?"
	elseif name == "frontier" then
		-- 2 steps, classend's scan k, two matches against the set 2(k + 1): 3k + 4
		return string.find, "b", "^%f[" .. rep("b", n) .. "]"
	elseif name == "balance" then
		-- 2 steps, a unit for each byte after the first: k + 3
		return string.find, "(" .. rep("x", n) .. ")", "^%b()"
	elseif name == "backref" then
		-- 2k + 4 steps, the back-reference's k, and the capture's push 32 + k: 3k + 36
		return string.find, rep("a", 2 * n), "^(" .. rep("a", n) .. ")%1"
	elseif name == "minexpand" then
		-- 3 steps, classend's scan k, two matches against the set 2(k + 2): 3k + 7
		return string.find, "b", "^[" .. rep("b", n) .. "]-$"
	elseif name == "maxscan" then
		-- each part 5 (a step, classend 1, the first match 3), the scans 3m + 3 (the 'c' that ended the first too), and
		-- the end 1: 6m + 14; the first scan takes the short path, the second the long one, at m = 1364
		return string.find, rep("b", n) .. rep("c", n), "^[b]*[c]*$"
	elseif name == "scanend" then
		-- 5, a short scan of 1000 bytes and the 'c' that ends it 3003, 3 steps and classend's scan k (at the end of the
		-- subject the set isn't matched against): k + 3011
		return string.find, rep("b", 1000) .. "c", "^[b]*c[" .. rep("b", n) .. "]?"
	elseif name == "scanlongend" then
		-- a step, the scan of n bytes and the 'z' that ends it n + 1, the end 1: n + 3; at n + 1 the scan takes the long path,
		-- where only the 'z' takes the work past 8192
		return string.find, rep("a", n) .. "z", "^a*"
	elseif name == "position" then
		-- 2 steps, the scan k, and a step at each of k + 1 positions, where the back-reference to a position is not
		-- compared: 2k + 3
		return string.find, rep("a", n), "^()a*%1"
	elseif name == "replacement" then
		-- 2 steps and a unit for each byte of the replacement: r + 2
		return string.gsub, "a", "^a", rep("x", n)
	elseif name == "escapes" then
		-- 2 steps and a unit for each escape of the replacement: r + 2
		return string.gsub, "a", "^a", rep("%0", n)
	elseif name == "literal" then
		-- one match of the literal path, charged by the bytes it moves past: n
		return string.gsub, rep("x", n - 1) .. "y", "y", ""
	elseif name == "literaltable" then
		-- n matches of the literal path, each 1 and a capture's push 32 + 1: 34n
		return string.gsub, rep("a", n), "a", { a = "x" }
	elseif name == "literalplain" then
		-- the same with a string: n
		return string.gsub, rep("a", n), "a", "x"
	end
	error("unknown case " .. name)
end

-- what PatternBudgetGmatchRetry calls: an iterator whose first match follows a prefix of n bytes
function gmatchretry(n)
	return string.gmatch(string.rep("x", n) .. "u1u2", "u(.)")
end

-- what the interrupt count test calls: oc-context-grid's count of 4-byte UTF-8 characters
function countwide(size)
	local s = string.rep("abc\240\159\152\128 defgh", size // 13 + 1):sub(1, size)
	return select(2, string.gsub(s, "[\240-\247]", ""))
end

return "OK"
