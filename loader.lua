-- Eynch Hub | game loader
-- Finds out which game you are in and runs that game's script from the games/ folder of this repo.
-- Nothing else is contacted.
if not game:IsLoaded() then
	game.Loaded:Wait()
end

local RAW = "https://raw.githubusercontent.com/eynchLoad/EynchHub/main/games/"

-- One line per game. To add a game: upload its script to games/ and add a line here.
--   file      the file name in games/ (without .lua)
--   places    PlaceIds that load it
--   universes UniverseIds that load it (covers a game's other places too)
local GAMES = {
	{
		name = "Run a Sari-Sari Store!",
		file = "lkxk514",
		places = { 104178853788462 },
		universes = { 10126644530 },
	},
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

local function find()
	for _, g in ipairs(GAMES) do
		for _, id in ipairs(g.places or {}) do
			if id == game.PlaceId then return g end
		end
		for _, id in ipairs(g.universes or {}) do
			if id == game.GameId then return g end
		end
	end
end

local match = find()
if not match then
	local names = {}
	for _, g in ipairs(GAMES) do names[#names + 1] = g.name end
	notify("This game is not supported yet. Supported: " .. table.concat(names, ", "))
	return
end

-- do not run twice in the same session
if getgenv and getgenv().EynchHubLoaded then
	notify(match.name .. " is already loaded.")
	return
end

-- download (two tries), then run
local source
for attempt = 1, 2 do
	local ok, body = pcall(game.HttpGet, game, RAW .. match.file .. ".lua")
	if ok and type(body) == "string" and #body > 100 then
		source = body
		break
	end
	task.wait(1)
end
if not source then
	notify("Could not download the script. Check your internet and try again.")
	return
end

local fn, err = loadstring(source)
if not fn then
	notify("The script could not start on this executor.")
	warn("[Eynch Hub] " .. tostring(err))
	return
end

if getgenv then getgenv().EynchHubLoaded = true end
local ok, runErr = pcall(fn)
if not ok then
	if getgenv then getgenv().EynchHubLoaded = nil end
	notify("The script stopped with an error.")
	warn("[Eynch Hub] " .. tostring(runErr))
end
