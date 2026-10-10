-- Eynch Hub | game loader
-- Finds out which game you are in, shows a short loading animation with the Eynch logo,
-- and runs that game's script from the games/ folder of this repo. Nothing else is contacted.
if not game:IsLoaded() then
	game.Loaded:Wait()
end

local ROOT = "https://raw.githubusercontent.com/eynchLoad/EynchHub/main/"
local RAW = ROOT .. "games/"
local LOGO_URL = ROOT .. "assets/logo.png"
local DISCORD_CODE = "54aGSfX6dN"
local DISCORD_URL = "https://discord.gg/" .. DISCORD_CODE

-- One entry per game. To add a game: upload its script to games/ and add an entry here.
--   file       the file name in games/ (without .lua)
--   places     PlaceIds that load it
--   universes  UniverseIds that load it (covers a game's other places too)
--   creators   CreatorIds (user or group) that load it. One line covers EVERY game by that creator, so only use it
--              for a creator whose games the script really supports.
local GAMES = {
	{
		name = "Run a Sari-Sari Store!",
		file = "lkxk514",
		places = { 104178853788462 },
		universes = { 10126644530 },
		creators = {},
	},
}

-- Executors that cannot run the scripts. Put the name (or part of it) in lowercase, for example { "solara", "xeno" }.
-- Anyone using one gets a plain "not supported" message and nothing is loaded.
local BLOCKED_EXECUTORS = {}

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local function notify(text)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "Eynch Hub",
			Text = text,
			Duration = 6,
		})
	end)
end

--================ executor check ================--
do
	local blocked = false
	pcall(function()
		local name = tostring(identifyexecutor and identifyexecutor() or ""):lower()
		for _, bad in ipairs(BLOCKED_EXECUTORS) do
			if name:find(bad, 1, true) then blocked = true end
		end
	end)
	if blocked then
		notify("This executor isn't supported.")
		return
	end
end

--================ which game ================--
local function find()
	for _, g in ipairs(GAMES) do
		for _, id in ipairs(g.places or {}) do
			if id == game.PlaceId then return g end
		end
		for _, id in ipairs(g.universes or {}) do
			if id == game.GameId then return g end
		end
		for _, id in ipairs(g.creators or {}) do
			if id == game.CreatorId then return g end
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

-- do not run twice in the same server (a new server after a rejoin has a new JobId, so it loads again)
if getgenv and getgenv().EynchHubLoaded == game.JobId and game.JobId ~= "" then
	notify(match.name .. " is already loaded.")
	return
end

--================ loading animation ================--
-- The logo is downloaded once into the executor's workspace folder (EynchHub/logo.png). If the executor cannot do that,
-- a big "E" is drawn instead, so the animation always works.
local function getLogo()
	if not (writefile and isfile and getcustomasset) then return nil end
	local ok, asset = pcall(function()
		if isfolder and makefolder and not isfolder("EynchHub") then makefolder("EynchHub") end
		if not isfile("EynchHub/logo.png") then
			writefile("EynchHub/logo.png", game:HttpGet(LOGO_URL))
		end
		return getcustomasset("EynchHub/logo.png")
	end)
	if ok and type(asset) == "string" and asset ~= "" then return asset end
	return nil
end

-- Copies the invite. If the Discord app is open on a PC it also asks it to show the invite window; the player still
-- chooses whether to join. Nothing joins automatically.
local function joinDiscord()
	local copied = false
	if setclipboard then
		pcall(function() setclipboard(DISCORD_URL) copied = true end)
	end
	pcall(function()
		local req = (syn and syn.request) or request or http_request or (http and http.request)
		if req then
			req({
				Url = "http://127.0.0.1:6463/rpc?v=1",
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json", Origin = "https://discord.com" },
				Body = HttpService:JSONEncode({
					cmd = "INVITE_BROWSER",
					args = { code = DISCORD_CODE },
					nonce = HttpService:GenerateGUID(false),
				}),
			})
		end
	end)
	return copied
end

local PINK = Color3.fromRGB(255, 140, 185)
local PURPLE = Color3.fromRGB(190, 120, 255)

local function showSplash(text)
	local ok, api = pcall(function()
		local gui = Instance.new("ScreenGui")
		gui.Name = "EynchLoading"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = 1000
		gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

		local card = Instance.new("CanvasGroup")
		card.AnchorPoint = Vector2.new(0.5, 0.5)
		card.Position = UDim2.fromScale(0.5, 0.5)
		card.Size = UDim2.fromOffset(280, 256)
		card.BackgroundColor3 = Color3.fromRGB(22, 12, 30)
		card.BackgroundTransparency = 0.08
		card.GroupTransparency = 1
		card.Parent = gui
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 20)

		local rim = Instance.new("UIStroke", card)
		rim.Thickness = 1.5
		rim.Color = Color3.new(1, 1, 1)
		local rimGrad = Instance.new("UIGradient", rim)
		rimGrad.Color = ColorSequence.new(PINK, PURPLE)
		rimGrad.Rotation = 35

		-- spinning gradient ring around the logo
		local ringBox = Instance.new("Frame")
		ringBox.BackgroundTransparency = 1
		ringBox.AnchorPoint = Vector2.new(0.5, 0)
		ringBox.Position = UDim2.new(0.5, 0, 0, 18)
		ringBox.Size = UDim2.fromOffset(112, 112)
		ringBox.Parent = card
		local ring = Instance.new("Frame")
		ring.BackgroundTransparency = 1
		ring.Size = UDim2.fromScale(1, 1)
		ring.Parent = ringBox
		Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
		local ringStroke = Instance.new("UIStroke", ring)
		ringStroke.Thickness = 3
		ringStroke.Color = Color3.new(1, 1, 1)
		local ringGrad = Instance.new("UIGradient", ringStroke)
		ringGrad.Color = ColorSequence.new(PINK, PURPLE)
		ringGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.55, 0.9),
			NumberSequenceKeypoint.new(1, 0),
		})

		-- the logo (or a drawn E if it could not be downloaded)
		local logoBox = Instance.new("Frame")
		logoBox.BackgroundTransparency = 1
		logoBox.AnchorPoint = Vector2.new(0.5, 0.5)
		logoBox.Position = UDim2.fromScale(0.5, 0.5)
		logoBox.Size = UDim2.fromOffset(84, 84)
		logoBox.Parent = ringBox
		local pulse = Instance.new("UIScale", logoBox)

		local asset = getLogo()
		if asset then
			local img = Instance.new("ImageLabel")
			img.BackgroundTransparency = 1
			img.Size = UDim2.fromScale(1, 1)
			img.Image = asset
			img.ScaleType = Enum.ScaleType.Fit
			img.Parent = logoBox
		else
			local e = Instance.new("TextLabel")
			e.BackgroundTransparency = 1
			e.Size = UDim2.fromScale(1, 1)
			e.Text = "E"
			e.Font = Enum.Font.GothamBlack
			e.TextScaled = true
			e.TextColor3 = Color3.new(1, 1, 1)
			e.Parent = logoBox
			local g = Instance.new("UIGradient", e)
			g.Color = ColorSequence.new(PINK, PURPLE)
			g.Rotation = 90
		end

		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1
		title.Position = UDim2.fromOffset(0, 136)
		title.Size = UDim2.new(1, 0, 0, 24)
		title.Text = "Eynch Hub"
		title.Font = Enum.Font.GothamBold
		title.TextSize = 18
		title.TextColor3 = Color3.fromRGB(250, 240, 247)
		title.Parent = card

		local status = Instance.new("TextLabel")
		status.BackgroundTransparency = 1
		status.Position = UDim2.fromOffset(12, 162)
		status.Size = UDim2.new(1, -24, 0, 18)
		status.Text = text or "Loading..."
		status.Font = Enum.Font.Gotham
		status.TextSize = 12
		status.TextColor3 = Color3.fromRGB(190, 160, 182)
		status.TextTruncate = Enum.TextTruncate.AtEnd
		status.Parent = card

		-- sliding loading bar
		local track = Instance.new("Frame")
		track.AnchorPoint = Vector2.new(0.5, 0)
		track.Position = UDim2.new(0.5, 0, 0, 190)
		track.Size = UDim2.fromOffset(180, 4)
		track.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		track.BackgroundTransparency = 0.88
		track.BorderSizePixel = 0
		track.ClipsDescendants = true
		track.Parent = card
		Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
		local fill = Instance.new("Frame")
		fill.Size = UDim2.fromScale(0.4, 1)
		fill.BackgroundColor3 = Color3.new(1, 1, 1)
		fill.BorderSizePixel = 0
		fill.Parent = track
		Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
		local fillGrad = Instance.new("UIGradient", fill)
		fillGrad.Color = ColorSequence.new(PINK, PURPLE)

		-- Join Discord button
		local join = Instance.new("TextButton")
		join.AnchorPoint = Vector2.new(0.5, 0)
		join.Position = UDim2.new(0.5, 0, 0, 208)
		join.Size = UDim2.fromOffset(200, 32)
		join.AutoButtonColor = false
		join.Text = "💬  Join our Discord"
		join.Font = Enum.Font.GothamBold
		join.TextSize = 13
		join.TextColor3 = Color3.new(1, 1, 1)
		join.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
		join.BackgroundTransparency = 0.15
		join.Parent = card
		Instance.new("UICorner", join).CornerRadius = UDim.new(1, 0)
		local joinGrad = Instance.new("UIGradient", join)
		joinGrad.Color = ColorSequence.new(PINK, PURPLE)
		joinGrad.Rotation = 0
		join.Activated:Connect(function()
			local copied = joinDiscord()
			join.Text = copied and "✓  Invite copied" or "discord.gg/" .. DISCORD_CODE
			task.delay(2.5, function()
				pcall(function() join.Text = "💬  Join our Discord" end)
			end)
		end)

		local t = 0
		local conn = RunService.RenderStepped:Connect(function(dt)
			t = t + dt
			ringGrad.Rotation = (t * 160) % 360
			pulse.Scale = 1 + 0.045 * math.sin(t * 3.2)
			fill.Position = UDim2.fromScale(((t * 0.9) % 1.5) - 0.4, 0)
		end)

		TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { GroupTransparency = 0 }):Play()

		local closed = false
		return {
			setText = function(s) status.Text = s end,
			close = function()
				if closed then return end
				closed = true
				local tw = TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quad), { GroupTransparency = 1 })
				tw:Play()
				task.delay(0.35, function()
					pcall(function() conn:Disconnect() end)
					pcall(function() gui:Destroy() end)
				end)
			end,
		}
	end)
	if ok and type(api) == "table" then return api end
	return { setText = function() end, close = function() end }
end

local splash = showSplash("Loading " .. match.name .. "...")
local splashAt = os.clock()

--================ download and run ================--
-- a short random wait so a lot of players loading at once do not all hit GitHub in the same moment
task.wait(math.random() * 0.8)

splash.setText("Downloading the script...")
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
	splash.close()
	notify("Could not download the script. Check your internet and try again.")
	return
end

splash.setText("Starting...")
local fn, err = loadstring(source)
if not fn then
	splash.close()
	notify("The script could not start on this executor.")
	warn("[Eynch Hub] " .. tostring(err))
	return
end

if getgenv then getgenv().EynchHubLoaded = game.JobId end
-- keep the card up for at least 2.5 seconds so the logo and the Discord button can be seen and used
local left = 2.5 - (os.clock() - splashAt)
if left > 0 then task.wait(left) end
splash.close()
local ok, runErr = pcall(fn)
if not ok then
	if getgenv then getgenv().EynchHubLoaded = nil end
	notify("The script stopped with an error.")
	warn("[Eynch Hub] " .. tostring(runErr))
end
