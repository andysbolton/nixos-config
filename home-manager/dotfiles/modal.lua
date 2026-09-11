-- Vim-style modal copy/scroll modes: y-operator (yy, yiw, y$, ...), text
-- objects (iw/iW/i(/i"), visual tracking, /-search integration, and a scroll
-- mode. Span math lives in motions.lua (pure lua, tested headless via
-- `nvim -l test_motions.lua`)
local wezterm = require("wezterm")
local act = wezterm.action
local motions = require("motions")

local M = {}

local copy_and_close = act.Multiple({
	act.CopyTo("ClipboardAndPrimarySelection"),
	act.CopyMode("ClearPattern"),
	"ScrollToBottom",
	act.CopyMode("Close"),
})

-- selection changes reach the window state CopyTo reads via a deferred
-- notification (TermWindowNotif::Apply in overlay/copy.rs), so a select-then-copy
-- in one key batch copies nothing; delay the copy until the queue drains, and
-- close later still so the yanked selection is briefly visible
local function yank(pre_actions)
	if #pre_actions == 0 then
		return copy_and_close
	end
	return wezterm.action_callback(function(window, pane)
		for _, a in ipairs(pre_actions) do
			window:perform_action(a, pane)
		end
		wezterm.time.call_after(0.1, function()
			window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
		end)
		wezterm.time.call_after(0.4, function()
			window:perform_action(
				act.Multiple({ act.CopyMode("ClearPattern"), "ScrollToBottom", act.CopyMode("Close") }),
				pane
			)
		end)
	end)
end

local close_copy_mode = act.Multiple({ act.CopyMode("ClearPattern"), "ScrollToBottom", act.CopyMode("Close") })

local exit_copy_mode = wezterm.action_callback(function(window, pane)
	wezterm.GLOBAL.copy_visual = nil
	wezterm.GLOBAL.copy_pending = nil
	window:perform_action(close_copy_mode, pane)
end)

local function visual_mode(mode)
	return wezterm.action_callback(function(window, pane)
		wezterm.GLOBAL.copy_pending = nil
		if wezterm.GLOBAL.copy_visual == mode then
			wezterm.GLOBAL.copy_visual = nil
			window:perform_action(act.CopyMode("ClearSelectionMode"), pane)
		else
			wezterm.GLOBAL.copy_visual = mode
			window:perform_action(act.CopyMode({ SetSelectionMode = mode }), pane)
		end
	end)
end

local mode_labels = {
	copy_mode = "COPY",
	search_mode = "SEARCH",
	scroll_mode = "SCROLL",
}

function M.apply_to_config(config)
	config.keys = config.keys or {}
	table.insert(config.keys, {
		key = "c",
		mods = "ALT",
		action = wezterm.action_callback(function(window, pane)
			wezterm.GLOBAL.copy_visual = nil
			wezterm.GLOBAL.copy_pending = nil
			window:perform_action(act.ActivateCopyMode, pane)
			window:perform_action(act.CopyMode("ClearPattern"), pane)
		end),
	})
	table.insert(config.keys, {
		key = "n",
		mods = "ALT",
		action = act.ActivateKeyTable({ name = "scroll_mode", one_shot = false }),
	})

	if wezterm.gui then
		local defaults = wezterm.gui.default_key_tables()
		local copy_mode = defaults.copy_mode
		local search_mode = defaults.search_mode

		local function yank_motion(motion)
			return yank({ act.CopyMode({ SetSelectionMode = "Cell" }), act.CopyMode(motion) })
		end

		-- the copy-mode overlay resolves keys against its own key-table stack first
		-- (wezterm #7851), so ActivateKeyTable can't implement operator-pending;
		-- the y-operator state lives in GLOBAL and dispatches inside copy_mode instead
		local function operator_key(key, mods, default_action, y_action, yi_action, vi_action)
			return {
				key = key,
				mods = mods,
				action = wezterm.action_callback(function(window, pane)
					local pending = wezterm.GLOBAL.copy_pending
					wezterm.GLOBAL.copy_pending = nil
					if pending == "y" then
						window:perform_action(y_action, pane)
					elseif pending == "yi" and yi_action then
						window:perform_action(yi_action, pane)
					elseif pending == "vi" and vi_action then
						window:perform_action(vi_action, pane)
					else
						window:perform_action(default_action, pane)
					end
				end),
			}
		end

		local function operator_infix(key)
			return {
				key = key,
				mods = "NONE",
				action = wezterm.action_callback(function()
					if wezterm.GLOBAL.copy_pending == "y" then
						wezterm.GLOBAL.copy_pending = "yi"
					elseif wezterm.GLOBAL.copy_visual then
						wezterm.GLOBAL.copy_pending = "vi"
					end
				end),
			}
		end

		-- text objects: measure the cursor (selection to line start = cursor
		-- column and left text; selection to line end = line text), compute the
		-- span in motions.lua (cell-accurate, so multibyte glyphs are safe),
		-- rebuild it from absolute motions, then yank or stay visual.
		-- Selection reads are async (deferred notification), so each read polls
		-- until the text changes. Divergence: the selection read trims trailing
		-- blanks, so a cursor on whitespace acts on the previous WORD
		local function poll_selection(window, pane, prev, tries, cb)
			wezterm.time.call_after(0.03, function()
				local text = window:get_selection_text_for_pane(pane) or ""
				if (#text > 0 and text ~= prev) or tries <= 1 then
					cb(text)
				else
					poll_selection(window, pane, prev, tries - 1, cb)
				end
			end)
		end

		local UTF8_LAST = "[\1-\127\194-\253][\128-\191]*$"

		local function object(kind, span_fn)
			return wezterm.action_callback(function(window, pane)
				local before = window:get_selection_text_for_pane(pane) or ""
				window:perform_action(act.CopyMode("ClearSelectionMode"), pane)
				window:perform_action(act.CopyMode({ SetSelectionMode = "Cell" }), pane)
				window:perform_action(act.CopyMode("MoveToStartOfLine"), pane)
				poll_selection(window, pane, before, 12, function(prefix)
					window:perform_action(act.CopyMode("ClearSelectionMode"), pane)
					if #prefix == 0 then
						return
					end
					local last = prefix:match(UTF8_LAST) or ""
					local col = wezterm.column_width(prefix) - math.max(wezterm.column_width(last), 1)
					window:perform_action(act.CopyMode({ SetSelectionMode = "Cell" }), pane)
					window:perform_action(act.CopyMode("MoveToEndOfLineContent"), pane)
					poll_selection(window, pane, prefix, 12, function(line)
						window:perform_action(act.CopyMode("ClearSelectionMode"), pane)
						local s, e = span_fn(line, col)
						if not s then
							return
						end
						window:perform_action(act.CopyMode("MoveToStartOfLine"), pane)
						for _ = 1, s do
							window:perform_action(act.CopyMode("MoveRight"), pane)
						end
						window:perform_action(act.CopyMode({ SetSelectionMode = "Cell" }), pane)
						for _ = 1, e - s do
							window:perform_action(act.CopyMode("MoveRight"), pane)
						end
						if kind == "yank" then
							wezterm.time.call_after(0.1, function()
								window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
							end)
							wezterm.time.call_after(0.4, function()
								window:perform_action(close_copy_mode, pane)
							end)
						else
							wezterm.GLOBAL.copy_visual = "Cell"
						end
					end)
				end)
			end)
		end

		local function word_span_fn(big)
			return function(line, col)
				return motions.word_span(line, col, wezterm.column_width, big)
			end
		end

		local function delim_span_fn(open, close)
			return function(line, col)
				return motions.delim_span(line, col, wezterm.column_width, open, close)
			end
		end

		local yank_word = object("yank", word_span_fn(false))
		local select_word = object("select", word_span_fn(false))
		local yank_WORD = object("yank", word_span_fn(true))
		local select_WORD = object("select", word_span_fn(true))
		local yank_ib = object("yank", delim_span_fn("(", ")"))
		local select_ib = object("select", delim_span_fn("(", ")"))
		local yank_iB = object("yank", delim_span_fn("{", "}"))
		local select_iB = object("select", delim_span_fn("{", "}"))

		-- appended entries override defaults; matching them in place is unreliable
		-- because default_key_tables() returns "mapped:"-prefixed key names
		for _, binding in ipairs({
			{ key = "/", mods = "NONE", action = act.Search({ CaseSensitiveString = "" }) },
			{ key = "n", mods = "NONE", action = act.CopyMode("NextMatch") },
			{ key = "N", mods = "NONE", action = act.CopyMode("PriorMatch") },
			{ key = "N", mods = "SHIFT", action = act.CopyMode("PriorMatch") },
			{ key = "v", mods = "NONE", action = visual_mode("Cell") },
			{ key = "V", mods = "NONE", action = visual_mode("Line") },
			{ key = "V", mods = "SHIFT", action = visual_mode("Line") },
			{ key = "v", mods = "CTRL", action = visual_mode("Block") },
			{
				key = "y",
				mods = "NONE",
				action = wezterm.action_callback(function(window, pane)
					if wezterm.GLOBAL.copy_visual then
						wezterm.GLOBAL.copy_visual = nil
						wezterm.GLOBAL.copy_pending = nil
						window:perform_action(yank({}), pane)
					elseif wezterm.GLOBAL.copy_pending == "y" then
						wezterm.GLOBAL.copy_pending = nil
						window:perform_action(yank({ act.CopyMode({ SetSelectionMode = "Line" }) }), pane)
					else
						wezterm.GLOBAL.copy_pending = "y"
					end
				end),
			},
			operator_infix("i"),
			operator_infix("a"),
			operator_key(
				"w",
				"NONE",
				act.CopyMode("MoveForwardWord"),
				yank_motion("MoveForwardWord"),
				yank_word,
				select_word
			),
			operator_key(
				"W",
				"NONE",
				act.CopyMode("MoveForwardWord"),
				yank_motion("MoveForwardWordEnd"),
				yank_WORD,
				select_WORD
			),
			operator_key(
				"W",
				"SHIFT",
				act.CopyMode("MoveForwardWord"),
				yank_motion("MoveForwardWordEnd"),
				yank_WORD,
				select_WORD
			),
			operator_key("e", "NONE", act.CopyMode("MoveForwardWordEnd"), yank_motion("MoveForwardWordEnd")),
			operator_key(
				"b",
				"NONE",
				act.CopyMode("MoveBackwardWord"),
				yank_motion("MoveBackwardWord"),
				yank_ib,
				select_ib
			),
			operator_key("B", "NONE", act.Nop, act.Nop, yank_iB, select_iB),
			operator_key("B", "SHIFT", act.Nop, act.Nop, yank_iB, select_iB),
			operator_key("$", "NONE", act.CopyMode("MoveToEndOfLineContent"), yank_motion("MoveToEndOfLineContent")),
			operator_key("$", "SHIFT", act.CopyMode("MoveToEndOfLineContent"), yank_motion("MoveToEndOfLineContent")),
			operator_key("0", "NONE", act.CopyMode("MoveToStartOfLine"), yank_motion("MoveToStartOfLine")),
			operator_key(
				"^",
				"NONE",
				act.CopyMode("MoveToStartOfLineContent"),
				yank_motion("MoveToStartOfLineContent")
			),
			operator_key(
				"^",
				"SHIFT",
				act.CopyMode("MoveToStartOfLineContent"),
				yank_motion("MoveToStartOfLineContent")
			),
			{
				key = "Escape",
				mods = "NONE",
				action = wezterm.action_callback(function(window, pane)
					wezterm.GLOBAL.copy_pending = nil
					if wezterm.GLOBAL.copy_visual then
						wezterm.GLOBAL.copy_visual = nil
						window:perform_action(act.CopyMode("ClearSelectionMode"), pane)
					else
						window:perform_action(close_copy_mode, pane)
					end
				end),
			},
			{ key = "q", mods = "NONE", action = exit_copy_mode },
			{ key = "c", mods = "CTRL", action = exit_copy_mode },
			{ key = "g", mods = "CTRL", action = exit_copy_mode },
		}) do
			table.insert(copy_mode, binding)
		end

		for _, spec in ipairs({
			{ "(", "(", ")" },
			{ ")", "(", ")" },
			{ "{", "{", "}" },
			{ "}", "{", "}" },
			{ "[", "[", "]" },
			{ "]", "[", "]" },
			{ '"', '"', '"' },
			{ "'", "'", "'" },
			{ "`", "`", "`" },
			{ ">", ">", "<" },
			{ ">", "<", "<" },
		}) do
			local key, open, close = spec[1], spec[2], spec[3]
			local yank_a = object("yank", delim_span_fn(open, close))
			local select_a = object("select", delim_span_fn(open, close))
			for _, mods in ipairs({ "NONE", "SHIFT" }) do
				table.insert(copy_mode, operator_key(key, mods, act.Nop, act.Nop, yank_a, select_a))
			end
		end

		for _, binding in ipairs({
			{ key = "Enter", mods = "NONE", action = act.CopyMode("AcceptPattern") },
			{
				key = "Escape",
				mods = "NONE",
				action = act.Multiple({ act.CopyMode("ClearPattern"), act.CopyMode("AcceptPattern") }),
			},
		}) do
			table.insert(search_mode, binding)
		end

		config.key_tables = {
			copy_mode = copy_mode,
			search_mode = search_mode,
			scroll_mode = {
				{ key = "Escape", mods = "NONE", action = act.PopKeyTable },
				{ key = "q", mods = "NONE", action = act.PopKeyTable },
				{ key = "c", mods = "CTRL", action = act.PopKeyTable },
				{ key = "j", mods = "NONE", action = act.ScrollByLine(1) },
				{ key = "k", mods = "NONE", action = act.ScrollByLine(-1) },
				{ key = "J", mods = "SHIFT", action = act.ScrollByLine(5) },
				{ key = "K", mods = "SHIFT", action = act.ScrollByLine(-5) },
				{ key = "d", mods = "NONE", action = act.ScrollByPage(0.5) },
				{ key = "u", mods = "NONE", action = act.ScrollByPage(-0.5) },
				{ key = "D", mods = "SHIFT", action = act.ScrollByPage(1) },
				{ key = "U", mods = "SHIFT", action = act.ScrollByPage(-1) },
				{ key = "g", mods = "NONE", action = act.ScrollToTop },
				{ key = "G", mods = "SHIFT", action = act.ScrollToBottom },
				{ key = "{", mods = "NONE", action = act.ScrollToPrompt(-1) },
				{ key = "{", mods = "SHIFT", action = act.ScrollToPrompt(-1) },
				{ key = "}", mods = "NONE", action = act.ScrollToPrompt(1) },
				{ key = "}", mods = "SHIFT", action = act.ScrollToPrompt(1) },
				{ key = "v", mods = "NONE", action = act.Multiple({ act.PopKeyTable, act.ActivateCopyMode }) },
				{
					key = "/",
					mods = "NONE",
					action = act.Multiple({ act.PopKeyTable, act.Search({ CaseSensitiveString = "" }) }),
				},
			},
		}
	end

	wezterm.on("update-status", function(window, pane)
		local label = mode_labels[window:active_key_table()]
		if label == "COPY" then
			if wezterm.GLOBAL.copy_visual then
				label = "VISUAL"
			elseif wezterm.GLOBAL.copy_pending then
				label = "COPY (" .. wezterm.GLOBAL.copy_pending .. ")"
			end
		end
		if label then
			window:set_right_status(wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { Color = "#46BDFF" } },
				{ Text = "-- " .. label .. " --  " },
			}))
		else
			window:set_right_status("")
		end
	end)
end

return M
