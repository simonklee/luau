-- This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
-- A pattern that is one class, alone or followed by '*', '+' or '-', scans the subject against a table of the bytes
-- instead of going through match() (LuauPatternClassScan). The top level checks a few results; differential() compares the results of
-- every class form over generated subjects with the flag on and off, through setclassscan, which the test provides.
print("testing class scan")

-- the cases the plugins use
assert(select(2, string.gsub("a\240\159\152\128b\240\159\152\128c", "[\240-\247]", "")) == 2)
assert(string.gsub("a  b \t\n c", "%s+", " ") == "a b c")
assert(string.find("abc def", "%s") == 4)
assert(string.gsub("a\0b\1c\127d\194", "[%z\1-\8\11-\31\127]", "") == "abcd\194")
do
	local t = {}
	for w in string.gmatch("ctrl+shift+k", "[^+]+") do
		table.insert(t, w)
	end
	assert(table.concat(t, ",") == "ctrl,shift,k")
	t = {}
	for w in string.gmatch("one\ntwo\n\nthree", "[^\n]+") do
		table.insert(t, w)
	end
	assert(table.concat(t, ",") == "one,two,three")
end

-- empty matches, init and the count
assert(string.gsub("abc", "%d*", "-") == "-a-b-c-")
assert(string.gsub("abc", "%a*", "-") == "--")
assert(string.gsub("abc", "%a-", "-") == "-a-b-c-")
assert(string.gsub("abc", ".", "%0%0", 2) == "aabbc")
assert(string.find("abc", "%a*", 4) == 4)
assert(string.find("abc", "%a", 4) == nil)
assert(string.find("abc", "%a", 5) == nil)
assert(string.find("abc", "%a+", -2) == 2)
assert(string.match("  x", "%S*", 2) == "")
do
	local t = {}
	for m in string.gmatch("ab1", "%a*") do
		table.insert(t, "<" .. m .. ">")
	end
	assert(table.concat(t) == "<ab><><>")
end

-- the forms that take match(): anchors, captures, other suffixes, malformed patterns
assert(string.find("ab", "^b") == nil)
assert(string.match("ab", "(b)") == "b")
assert(string.match("ab", "b?") == "")
assert(not pcall(string.find, "a", "[a"))
assert(not pcall(string.find, "a", "%"))
assert(not pcall(string.find, "a", "%f"))
assert(string.gmatch("a^", "^")() == "^")

-- long subjects: the scan runs in stretches that the work left pays for
do
	local s = string.rep("a", 20000) .. "b" .. string.rep(" ", 20000)
	assert(string.find(s, "[b]") == 20001)
	assert(#string.match(s, "%a+") == 20001)
	assert(#string.match(s, "%s+") == 20000)
	assert(select(2, string.gsub(s, "%s", "")) == 20000)
	assert(select(2, string.gsub(s, "%d*", "")) == 40002)
	assert(select(2, string.gsub(s, "[^a]+", "")) == 1)
end

local function pack(ok, ...)
	local t = table.pack(...)
	local parts = { tostring(ok) }
	for i = 1, t.n do
		table.insert(parts, type(t[i]) .. ":" .. tostring(t[i]))
	end
	return table.concat(parts, ",")
end

-- every result of the pattern functions for one case, as a string
local function results(s, p, init, n)
	local out = {}
	table.insert(out, pack(pcall(string.find, s, p, init)))
	table.insert(out, pack(pcall(string.match, s, p, init)))
	table.insert(out, pack(pcall(string.gsub, s, p, "<%0>", n)))
	table.insert(out, pack(pcall(string.gsub, s, p, "", n)))
	table.insert(out, pack(pcall(string.gsub, s, p, { a = "A", ["\0"] = false, [" "] = 1 }, n)))
	local seen = {}
	table.insert(
		out,
		pack(pcall(string.gsub, s, p, function(m)
			table.insert(seen, m)
			return if m == "b" then nil else #m
		end, n))
	)
	table.insert(out, table.concat(seen, "|"))
	local ok, it = pcall(string.gmatch, s, p)
	if ok then
		local found = {}
		table.insert(
			out,
			pack(pcall(function()
				for m in it do
					table.insert(found, m)
				end
			end))
		)
		table.insert(out, table.concat(found, "|"))
	end
	return table.concat(out, "\n")
end

local classes = {
	".", "a", "b", " ", "\0", "\127", "\128", "\255", "]", "-", "^", "$", "(", ")", "*", "+", "?", "%",
	"%a", "%A", "%c", "%C", "%d", "%D", "%g", "%G", "%l", "%L", "%p", "%P", "%s", "%S", "%u", "%U", "%w", "%W",
	"%x", "%X", "%z", "%Z", "%.", "%%", "%]", "%-", "%\0", "%\255", "%q", "%b", "%f", "%1",
	"[ab]", "[^ab]", "[a-c]", "[^a-c]", "[%a_]", "[]]", "[^]]", "[a-]", "[-a]", "[%]]", "[%]", "[a", "[", "[^",
	"[%z\1-\31\127]", "[\128-\255]", "[\0]", "[^\0-\127]", "[a-%]]", "[%a-z]", "[c-a]", "[\0-\255]", "[^\0-\255]",
	"[^]", "[]", "[a%]", "[%s%d]", "[^%s%d]", "[%A%a]", "[--/]", "[\240-\247]", "[^\n]", "[^+]", "[%w%w%w]", "[^%]",
}
local suffixes = { "", "*", "+", "-", "?", "x", "**", "+$" }
local alphabet = { "a", "b", "c", "A", "Z", "0", "9", " ", "\n", "\t", "\0", "\1", "\127", "\128", "\255", "]", "-", "_", "+", "%" }

-- compares the results with the flag on and off; returns the number of cases
function differential(subjects)
	local seed = 1
	local function rand(k)
		seed = (seed * 16807) % 2147483647
		return seed % k
	end

	local list = {}
	-- every string of up to 3 bytes over a, space and \255
	local small = { "", "a", " ", "\255" }
	for i = 2, 4 do
		for j = 2, 4 do
			table.insert(small, small[i] .. small[j])
			for k = 2, 4 do
				table.insert(small, small[i] .. small[j] .. small[k])
			end
		end
	end
	for _, s in small do
		table.insert(list, s)
	end
	-- random strings over small alphabets
	for _ = 1, subjects do
		local letters = {}
		for _ = 1, 2 + rand(3) do
			table.insert(letters, alphabet[rand(#alphabet) + 1])
		end
		local s = {}
		for _ = 1, rand(13) do
			table.insert(s, letters[rand(#letters) + 1])
		end
		table.insert(list, table.concat(s))
	end

	-- false for none
	local inits = { false, 1, 2, -1, -3, 0, 100 }
	local counts = { false, 0, 1, 2, -1 }
	local cases = 0
	for _, class in classes do
		for _, suffix in suffixes do
			local p = class .. suffix
			for _, s in list do
				local which = rand(#inits + 3)
				local init = if which < #inits then inits[which + 1] elseif which == #inits then #s else #s + which - #inits
				local n = counts[rand(#counts) + 1] or nil
				init = init or nil
				setclassscan(true)
				local on = results(s, p, init, n)
				setclassscan(false)
				local off = results(s, p, init, n)
				setclassscan(true)
				if on ~= off then
					error(string.format("pattern %q, subject %q, init %s, n %s:\non:  %q\noff: %q", p, s, tostring(init), tostring(n), on, off))
				end
				cases += 1
			end
		end
	end

	-- a gmatch iterator keeps its table, and takes match() when the flag is off at its call
	for _, made in { true, false } do
		local found = {}
		setclassscan(made)
		local it = string.gmatch("ab  c\255d", "%S+")
		setclassscan(not made)
		table.insert(found, it())
		setclassscan(made)
		table.insert(found, it())
		setclassscan(not made)
		table.insert(found, tostring((it())))
		table.insert(found, tostring((it())))
		setclassscan(true)
		assert(table.concat(found, ",") == "ab,c\255d,nil,nil", table.concat(found, ","))
	end

	return cases
end

-- what PatternClassScanCharges calls: a string function and its arguments, whose work is 8192 units at n and a few more
-- at n + 1, as patternbudget.luau's chargecase. Each case's sum is in a comment.
function chargecase(name, n)
	local rep = string.rep
	if name == "find" then
		-- the search for ']' 1, the set's test of 'a' 2, the scan n: n + 3
		return string.find, rep("a", n), "[b]"
	elseif name == "compile" then
		-- the search for ']' n, and nothing for the empty subject: n
		return string.find, "", "[" .. rep("b", n) .. "]"
	elseif name == "match" then
		-- the first byte 1, the match 1, the scan to the space n, the capture's push 32 + n: 2n + 34
		return string.match, rep("a", n) .. " ", "%a+"
	elseif name == "empty" then
		-- at each position the match 1 and the byte it compares 1, at the end the match 1: 2n + 1
		return string.gsub, rep("a", n), "%d*", ""
	elseif name == "gmatch" then
		-- the iterator's call: the set's tests of 'a' and 'b' 3 each, the scan to the 'b' n + 1, the match 1, the capture's
		-- push 33: n + 41 (gmatch searched for the ']')
		return string.gmatch(rep("a", n) .. "b", "[^a]")
	elseif name == "plain" then
		-- the first byte 1, the match 1, a unit for each byte of the replacement n: n + 2
		return string.gsub, "a", "%a", rep("x", n)
	elseif name == "plainlong" then
		-- n + 1 empty matches, each charged for the 64 KB replacement, which takes the work left below zero: an interrupt
		-- call for each match
		return string.gsub, rep("a", n), "%a-", rep("x", 65536)
	elseif name == "dotstar" then
		-- the match 1: '.' matches every byte, so nothing is scanned
		return string.find, rep("a", n), ".*"
	elseif name == "dotplus" then
		-- the first byte 1, the match 1
		return string.find, rep("a", n), ".+"
	end
	error("unknown case " .. name)
end

return "OK"
