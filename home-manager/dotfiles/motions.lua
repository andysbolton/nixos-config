-- Pure-lua vim text objects over one line of terminal text. No wezterm
-- imports: cell widths come from an injected width function so the library
-- runs under plain lua/LuaJIT for headless tests (nvim -l test_motions.lua).
-- All public columns are 0-based cells, never bytes.
local M = {}

-- no utf8 stdlib on LuaJIT, so split codepoints with the byte-class pattern
local UTF8_CHAR = "[\1-\127\194-\253][\128-\191]*"

-- line -> array of { ch, w = cell width, col = starting cell column }
function M.cells(line, width_fn)
	local out = {}
	local col = 0
	for ch in line:gmatch(UTF8_CHAR) do
		local w = width_fn(ch)
		if w < 1 then
			w = 1
		end
		out[#out + 1] = { ch = ch, w = w, col = col }
		out[#out].idx = #out
		col = col + w
	end
	return out
end

local function index_at(cells, col)
	for i, c in ipairs(cells) do
		if col >= c.col and col < c.col + c.w then
			return i
		end
	end
	return nil
end

-- vim classes: whitespace / keyword ([%w_] and any multibyte) / punctuation.
-- big=true collapses keyword+punct into one class (WORD = non-blank run)
local function class_of(ch, big)
	if ch:match("^%s") then
		return "space"
	end
	if big or ch:match("^[%w_]") or #ch > 1 then
		return "word"
	end
	return "punct"
end

local function span_cols(cells, s, e)
	return cells[s].col, cells[e].col + cells[e].w - 1
end

-- iw (big=false) / iW (big=true): start/end cell columns of the class run
-- under col; on whitespace, the whitespace run (vim behavior)
function M.word_span(line, col, width_fn, big)
	local cells = M.cells(line, width_fn)
	if #cells == 0 then
		return nil
	end
	local i = index_at(cells, col) or #cells
	local class = class_of(cells[i].ch, big)
	local s, e = i, i
	while s > 1 and class_of(cells[s - 1].ch, big) == class do
		s = s - 1
	end
	while e < #cells and class_of(cells[e + 1].ch, big) == class do
		e = e + 1
	end
	return span_cols(cells, s, e)
end

-- i( / i" style inner span of the innermost open..close pair containing col
-- (delimiters included in "containing"); nil when no pair or the pair is empty
function M.delim_span(line, col, width_fn, open, close)
	local cells = M.cells(line, width_fn)
	local i = index_at(cells, col)
	if not i then
		return nil
	end
	local o_idx, c_idx
	if open == close then
		local positions = {}
		for k, c in ipairs(cells) do
			if c.ch == open then
				positions[#positions + 1] = k
			end
		end
		for p = 1, #positions - 1, 2 do
			if i >= positions[p] and i <= positions[p + 1] then
				o_idx, c_idx = positions[p], positions[p + 1]
				break
			end
		end
	else
		local stack, best = {}, nil
		for k, c in ipairs(cells) do
			if c.ch == open then
				stack[#stack + 1] = k
			elseif c.ch == close and #stack > 0 then
				local a = table.remove(stack)
				if a <= i and i <= k and (not best or a > best[1]) then
					best = { a, k }
				end
			end
		end
		if best then
			o_idx, c_idx = best[1], best[2]
		end
	end
	if not o_idx or c_idx - o_idx < 2 then
		return nil
	end
	return span_cols(cells, o_idx + 1, c_idx - 1)
end

return M
