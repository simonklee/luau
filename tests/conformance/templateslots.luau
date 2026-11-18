-- This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
-- A table constructor with constant keys is cloned from a template, and a field written `= nil` has a slot in it.
-- With LuauTemplateNilSlots, the GC keeps those slots in the template, so clones made after a collection have them.
-- Nothing of that may be visible: a nil-valued key is never present. `livekeys(t)` (test host) counts the hash
-- nodes of `t` that hold a live key, and `templatenilslots` is the flag's value.
print("testing template nil slots")

local function span(text, style)
    local t = { text = text, fg = nil, bg = nil, bold = nil }
    if style then
        for key, value in style do
            t[key] = value
        end
    end
    return t
end

local function keys(t)
    local list = {}
    for key in t do
        table.insert(list, tostring(key))
    end
    table.sort(list)
    return table.concat(list, ",")
end

local function count(t)
    local n = 0
    for _ in pairs(t) do
        n += 1
    end
    return n
end

-- after collections the template has been traversed
collectgarbage()
collectgarbage()

do
    local s = span("a")
    assert(livekeys(s) == (if templatenilslots then 4 else 1))

    -- nil-valued keys are never present
    assert(keys(s) == "text")
    assert(count(s) == 1)
    assert(next(s) == "text" and next(s, "text") == nil)
    assert(s.fg == nil and rawget(s, "bg") == nil and s.bold == nil)
    assert(#s == 0 and rawlen(s) == 0)
end

do
    -- writes take the kept slots; the result is the same in both modes
    local t = span("b", { fg = "red", bold = true })
    assert(livekeys(t) == (if templatenilslots then 4 else 3))
    assert(keys(t) == "bold,fg,text")
    assert(t.text == "b" and t.fg == "red" and t.bold == true and t.bg == nil)

    -- the order of next is the same on every pass
    local order = {}
    for key in t do
        table.insert(order, key)
    end
    local i = 0
    for key in t do
        i += 1
        assert(order[i] == key)
    end
    assert(i == 3)

    -- removing and setting again
    t.fg = nil
    assert(keys(t) == "bold,text")
    t.bg = "blue"
    t.fg = "green"
    assert(keys(t) == "bg,bold,fg,text")

    -- the array part and the length
    assert(#t == 0)
    t[1] = "x"
    t[2] = "y"
    assert(#t == 2)
    assert(keys(t) == "1,2,bg,bold,fg,text")

    -- a key outside the template
    t.extra = 1
    assert(count(t) == 7)
end

do
    -- table.clone copies the nil slots and shows none of them
    local s = span("c")
    local c = table.clone(s)
    assert(keys(c) == "text" and next(c, "text") == nil)
    c.fg = "x"
    assert(s.fg == nil and keys(s) == "text")
    assert(keys(c) == "fg,text")
end

do
    -- a frozen clone shows no nil slot and takes no write to one
    local f = table.freeze(span("d"))
    assert(table.isfrozen(f))
    assert(keys(f) == "text")
    assert(not pcall(function()
        f.fg = "x"
    end))
    assert(f.fg == nil)

    local c = table.clone(f)
    assert(not table.isfrozen(c))
    c.bg = "y"
    assert(keys(c) == "bg,text")
end

do
    -- a clone traversed by the GC before its fields are set loses its nil slots, as before
    local s = span("e")
    collectgarbage()
    assert(livekeys(s) == 1)
    s.fg = "red"
    s.bold = false
    assert(keys(s) == "bold,fg,text")
    assert(s.fg == "red" and s.bold == false)
end

do
    -- clearing fields during traversal, with collections in between
    local t = span("f", { fg = 1, bg = 2, bold = 3 })
    local seen = 0
    for key in t do
        seen += 1
        t[key] = nil
        collectgarbage()
    end
    assert(seen == 4 and next(t) == nil)
end

do
    -- many clones under collection steps
    local live = {}
    for i = 1, 2000 do
        local style = if i % 3 == 0 then nil elseif i % 3 == 1 then { fg = i } else { bg = i, bold = true }
        local t = span(tostring(i), style)
        live[i % 50 + 1] = t
        if i % 3 == 0 then
            assert(keys(t) == "text")
        elseif i % 3 == 1 then
            assert(keys(t) == "fg,text" and t.fg == i)
        else
            assert(keys(t) == "bg,bold,text" and t.bg == i)
        end
        if i % 100 == 0 then
            collectgarbage("step", 1)
        end
    end
    collectgarbage()
end

do
    -- a template whose keys are only in the chunk: its strings stay alive with the function
    local function f()
        return { only_in_this_template_1 = nil, only_in_this_template_2 = 2 }
    end
    collectgarbage()
    local t = f()
    assert(keys(t) == "only_in_this_template_2")
    t.only_in_this_template_1 = 1
    assert(keys(t) == "only_in_this_template_1,only_in_this_template_2")
end

do
    -- a live table that another chunk reaches through an import is a table constant of that chunk, but no template:
    -- the keys deleted from it are collected
    TemplateSlotsCache = {}
    local probe = setmetatable({}, { __mode = "v" })
    local fill = loadstring([=[
        local probe = ...
        for i = 1, 30 do
            local key = {}
            probe[i] = key
            TemplateSlotsCache[key] = true
        end
        for i = 1, 30 do
            TemplateSlotsCache[probe[i]] = nil
        end
    ]=])
    -- now the table is reachable only as the constant of `fill`
    TemplateSlotsCache = nil
    fill(probe)
    assert(#probe == 30)
    collectgarbage()
    collectgarbage()
    assert(next(probe) == nil)
    assert(fill) -- `fill` and its constants stay alive until here
end

return "OK"
