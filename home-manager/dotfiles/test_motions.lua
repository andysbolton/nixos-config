-- Headless tests for motions.lua. Run: nvim -l test_motions.lua
-- (must work under LuaJIT and Lua 5.4)
package.path = package.path .. ";" .. (arg and arg[0] or ""):gsub("[^/]*$", "") .. "?.lua"
local motions = require("motions")

local failures = 0
local function eq(label, got_s, got_e, want_s, want_e)
	if got_s == want_s and got_e == want_e then
		print("PASS " .. label)
	else
		failures = failures + 1
		print(string.format("FAIL %s: got (%s,%s) want (%s,%s)", label, tostring(got_s), tostring(got_e),
			tostring(want_s), tostring(want_e)))
	end
end

local ascii = function(_)
	return 1
end

-- probe line: cols  0         1         2         3         4
--                   0123456789012345678901234567890123456789012
local L1 = '[string "/x/y.lua"]:195: in main chunk: nil'

-- word_span returns two values; wrap calls:
local function ws(line, col, wf, big)
	local s, e = motions.word_span(line, col, wf, big)
	return { s, e }
end
local function ds(line, col, wf, o, c)
	local s, e = motions.delim_span(line, col, wf, o, c)
	return { s, e }
end
local function eq2(label, got, want_s, want_e)
	eq(label, got[1], got[2], want_s, want_e)
end

eq2("iW mid y.lua", ws(L1, 12, ascii, true), 8, 23)
eq2("iW on quote (WORD start)", ws(L1, 8, ascii, true), 8, 23)
eq2("iW on final colon", ws(L1, 23, ascii, true), 8, 23)
eq2("iW on space", ws(L1, 24, ascii, true), 24, 24)
eq2("iW last word nil", ws(L1, 41, ascii, true), 40, 42)
eq2("iw on y", ws(L1, 12, ascii, false), 12, 12)
eq2("iw mid lua", ws(L1, 15, ascii, false), 14, 16)
eq2("iw on dot", ws(L1, 13, ascii, false), 13, 13)
eq2("iw on 195", ws(L1, 21, ascii, false), 20, 22)
eq2("iw punct run ]:", ws(L1, 18, ascii, false), 17, 19)

-- prompt line with glyphs: <work>FOLDER ~/scratch 18GiB/24GiB @ 77% on ICON Connectivity
-- FOLDER = U+1F4C1 (4 bytes, width 2), ICON = U+F0805 (4 bytes, width 1)
local FOLDER = "\240\159\147\129"
local ICON = "\243\176\160\133"
local L2 = "<work>" .. FOLDER .. " ~/scratch 18GiB/24GiB @ 77% on " .. ICON .. " Connectivity"
local widths = { [FOLDER] = 2, [ICON] = 1 }
local glyph = function(ch)
	return widths[ch] or 1
end
-- cells: <work>=0-5, FOLDER=6-7, space=8, ~=9, /=10, scratch=11-17, space=18,
-- 18GiB=19-23, /=24, 24GiB=25-29, space=30, @=31 ...
eq2("prompt iW mem usage (mid)", ws(L2, 22, glyph, true), 19, 29)
eq2("prompt iW mem usage (start)", ws(L2, 19, glyph, true), 19, 29)
eq2("prompt iW mem usage (end)", ws(L2, 29, glyph, true), 19, 29)
eq2("prompt iw 18GiB", ws(L2, 22, glyph, false), 19, 23)
eq2("prompt iw on slash", ws(L2, 24, glyph, false), 24, 24)
eq2("prompt iW cursor inside wide glyph", ws(L2, 7, glyph, true), 0, 7)

-- delimiters
local L3 = "foo(bar, baz) end"
eq2("i( inside", ds(L3, 5, ascii, "(", ")"), 4, 11)
eq2("i( on open paren", ds(L3, 3, ascii, "(", ")"), 4, 11)
eq2("i( on close paren", ds(L3, 12, ascii, "(", ")"), 4, 11)
local L4 = "a(b(c)d)e"
eq2("nested inner", ds(L4, 4, ascii, "(", ")"), 4, 4)
eq2("nested outer", ds(L4, 6, ascii, "(", ")"), 2, 6)
local L5 = 'say "hi there" end'
eq2('i" inside', ds(L5, 6, ascii, '"', '"'), 5, 12)
local none = { motions.delim_span("no pairs here", 3, ascii, "(", ")") }
eq("i( no pair -> nil", none[1], none[2], nil, nil)
local empty = { motions.delim_span("f() x", 1, ascii, "(", ")") }
eq("i( empty pair -> nil", empty[1], empty[2], nil, nil)

-- empty / degenerate lines
local nilcase = { motions.word_span("", 0, ascii, true) }
eq("empty line -> nil", nilcase[1], nilcase[2], nil, nil)
eq2("col past EOL clamps", ws("abc", 99, ascii, true), 0, 2)

if failures == 0 then
	print("ALL PASS")
else
	print(failures .. " FAILURES")
	os.exit(1)
end
