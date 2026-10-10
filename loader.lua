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
	[104178853788462] = "np8cj4k", -- Run a Sari-Sari Store!
}
local universes = {
	[10126644530] = "np8cj4k",
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
if fn then
	fn()
else
	-- GitHub could not be reached: open the key window directly
	getgenv().EYNCH_GAME = "sari-sari"
	local ok2 = pcall(function()
		loadstring(game:HttpGet(KEY_WINDOW))()
	end)
	if not ok2 then
		notify("Could not load. Check your internet and try again.")
	end
end
