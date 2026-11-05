require("hs.ipc")

Profile = "(none)"

local t, p, k = hs.eventtap.event.types, hs.eventtap.event.properties, hs.keycodes.map

-- App sets (bundle IDs), from the old karabiner.edn :applications
local BROWSERS = { ["org.mozilla.firefox"] = true, ["org.nixos.firefox"] = true }
local FINDER = { ["com.apple.finder"] = true }
local NO_REMAP = {
	["com.apple.Terminal"] = true,
	["com.github.wez.wezterm"] = true,
	["dev.vencord.vesktop"] = true,
}
local KEEP_CTRL = { h = 1, m = 1, q = 1 } -- Cmd+H/M/Q hide/minimize/quit on macOS
local NATIVE_CTRL = { ["com.gather.GatherV2"] = { a = 1, c = 1, v = 1, x = 1 } } -- apps whose menus bind these to Ctrl

local HOME, END = k.home, k["end"]
local LEFT, RIGHT, UP, DOWN = k.left, k.right, k.up, k.down
local BACKSPACE, FWDDELETE = k.delete, k.forwarddelete
local F5 = k.f5
local NOMOD = { [HOME] = 1, [END] = 1, [BACKSPACE] = 1, [FWDDELETE] = 1, [F5] = 1 } -- act w/o a modifier

-- A text box is focused (Finder rename / search field, etc.) -- don't treat keys
-- like Backspace as navigation there.
local TEXT_ROLES = { AXTextField = true, AXTextArea = true, AXComboBox = true, AXSearchField = true }
local function editingText()
	local el = hs.uielement.focusedElement()
	return el ~= nil and TEXT_ROLES[el:role()] == true
end

-- Set exact modifiers (+ optional new key) on the event, then let it continue.
local function to(e, mods, key)
	e:setFlags(mods)
	if key then
		e:setKeyCode(k[key])
	end
	return false
end

keyTap = hs.eventtap.new({ t.keyDown, t.keyUp }, function(e)
	local f, code = e:getFlags(), e:getKeyCode()
	if not (f.ctrl or f.alt) and not NOMOD[code] then
		return false
	end -- normal typing: cheap bail

	local app = hs.application.frontmostApplication()
	local bid = app and app:bundleID()
	local S = f.shift -- preserve Shift for selection

	if code == HOME then
		return to(e, { ctrl = true, shift = S }, "a")
	end -- line start
	if code == END then
		return to(e, { ctrl = true, shift = S }, "e")
	end -- line end
	if code == F5 and not NO_REMAP[bid] then
		return to(e, { cmd = true }, "r")
	end -- reload

	if f.ctrl and code == LEFT then
		return to(e, { alt = true, shift = S })
	end -- word left
	if f.ctrl and code == RIGHT then
		return to(e, { alt = true, shift = S })
	end -- word right
	if f.ctrl and code == UP then
		return to(e, { cmd = true, shift = S })
	end -- doc top
	if f.ctrl and code == DOWN then
		return to(e, { cmd = true, shift = S })
	end -- doc bottom

	if f.alt and not f.ctrl and BROWSERS[bid] and (code == LEFT or code == RIGHT) then
		return to(e, { cmd = true }) -- browser back / forward
	end

	if FINDER[bid] then
		if code == FWDDELETE then
			return to(e, { cmd = true }, "delete")
		end -- move to Trash
		if code == BACKSPACE and not (f.cmd or f.alt or f.ctrl or f.shift) and not editingText() then
			return to(e, { cmd = true }, "up") -- up a directory
		end
	end

	if not f.ctrl then
		return false
	end -- everything below is a Ctrl chord
	local name = k[code]
	if NATIVE_CTRL[bid] and NATIVE_CTRL[bid][name] then
		return false
	end
	if name == "y" and not NO_REMAP[bid] then
		return to(e, { cmd = true, shift = true }, "z")
	end -- redo
	if name == "z" and not NO_REMAP[bid] then
		return to(e, { cmd = true, shift = S })
	end -- undo
	if name and name:match("^%l$") and not KEEP_CTRL[name] and not NO_REMAP[bid] then
		return to(e, { cmd = true })
	end -- Ctrl+letter -> Cmd+letter
	return false
end)

scrollTap = hs.eventtap.new({ t.scrollWheel }, function(e)
	if e:getProperty(p.scrollWheelEventIsContinuous) ~= 0 then
		return false
	end -- trackpad: skip
	-- if e:getProperty(p.eventSourceUnixProcessID) ~= 0 then
	-- 	return false
	-- end -- injected: skip
	-- for _, ax in ipairs({
	-- 	p.scrollWheelEventDeltaAxis1,
	-- 	p.scrollWheelEventFixedPtDeltaAxis1,
	-- 	p.scrollWheelEventPointDeltaAxis1,
	-- }) do
	-- 	local v = e:getProperty(ax)
	-- 	if v ~= 0 then
	-- 		e:setProperty(ax, -v)
	-- 	end
	-- end
	e:setProperty(p.scrollWheelEventDeltaAxis1, -e:getProperty(p.scrollWheelEventDeltaAxis1))

	return false
end)

-- launchctl errors harmlessly when skhd is already in the target state.
local SKHD_ON = 'launchctl bootstrap gui/$(id -u) "$HOME/Library/LaunchAgents/org.nixos.skhd.plist"'
local SKHD_OFF = "launchctl bootout gui/$(id -u)/org.nixos.skhd"

local function work()
	keyTap:start()
	scrollTap:start()
	hs.execute(SKHD_ON, true)
	Profile = "work"
end

local function linux()
	keyTap:stop()
	scrollTap:stop()
	hs.execute(SKHD_OFF, true)
	Profile = "linux"
end

work()

hs.urlevent.bind("linux", linux)
hs.urlevent.bind("work", work)
