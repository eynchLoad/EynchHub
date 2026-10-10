-- Eynch Hub | game router
-- Finds out which game you are in and runs that game's file from the games/ folder.
if not game:IsLoaded() then
	game.Loaded:Wait()
end

local RAW = "https://raw.githubusercontent.com/eynchLoad/EynchHub/main/games/"
local KEY_WINDOW = "https://eynch-key.eynchhub.workers.dev/loader"

-- Roblox game -> file in games/ (without .lua). Add a line here for each new game.
-- Match by PlaceId (one place) or UniverseId (the whole game, including its other places).
local places = {
	[104178853788462] = "97pjmyz", -- Run a Sari-Sari Store!
}
local universes = {
	[10126644530] = "97pjmyz",
}

local function notify(text)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "Eynch Hub",
			Text = text,
			Duration = 6,
		})
	end)
end

local file = places[game.PlaceId] or universes[game.GameId]
if not file then
	notify("This game is not supported yet.")
	return
end

local ok, source = pcall(game.HttpGet, game, RAW .. file .. ".lua")
local fn = ok and type(source) == "string" and loadstring(source)
local ran = false
if fn then
	ran = pcall(fn)
end
if not ran then
	-- GitHub could not be reached, or the game file failed to start: open the key window instead
	getgenv().EYNCH_GAME = "sari-sari"
	local ok2 = pcall(function()
		loadstring(game:HttpGet(KEY_WINDOW))()
	end)
	if not ok2 then
		notify("Could not load. Check your internet and try again.")
	end
end
