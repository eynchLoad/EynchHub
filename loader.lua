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

--================ key ================--
-- The key is free and is posted in the Discord server (members only). Only a hash of it is stored here, so reading this file
-- does not show it. Keep the key in the Discord channel and change KEY_HASH here if you ever change the key.
local KEY_HASH = "1c0b5dab193f35a6"
local KEY_FILE = "EynchHub/key.txt"

local function hashKey(s)
	s = "eynch|" .. s:lower()
	local function fnv(seed)
		local h = seed
		for i = 1, #s do
			h = bit32.bxor(h, s:byte(i))
			-- h * 16777619 mod 2^32, split so the numbers stay exact
			h = ((h % 65536) * 16777619 + (((math.floor(h / 65536) * 16777619) % 65536) * 65536)) % 4294967296
		end
		return string.format("%08x", h)
	end
	return fnv(2166136261) .. fnv(305419896)
end

local function keyOk(k)
	k = tostring(k or ""):gsub("^%s+", ""):gsub("%s+$", "")
	return k ~= "" and hashKey(k) == KEY_HASH, k
end

local function askKey()
	local saved
	pcall(function()
		if isfile and readfile and isfile(KEY_FILE) then saved = readfile(KEY_FILE) end
	end)
	if saved and keyOk(saved) then return true end

	local done, passed = false, false
	local host = (gethui and gethui()) or game:GetService("CoreGui")
	-- never stack two key windows (an old one from an earlier run)
	pcall(function()
		for _, old in ipairs(host:GetChildren()) do
			if old.Name == "EynchKey" then old:Destroy() end
		end
	end)
	local gui = Instance.new("ScreenGui")
	gui.Name = "EynchKey"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 1000
	gui.Parent = host

	local card = Instance.new("CanvasGroup")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.fromOffset(290, 340)
	card.BackgroundColor3 = Color3.fromRGB(22, 12, 30)
	card.BackgroundTransparency = 0
	card.GroupTransparency = 1
	card.Parent = gui
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 20)
	local pop = Instance.new("UIScale", card)
	pop.Scale = 0.9

	local rim = Instance.new("UIStroke", card)
	rim.Thickness = 1.5
	rim.Color = Color3.new(1, 1, 1)
	local rimGrad = Instance.new("UIGradient", rim)
	rimGrad.Color = ColorSequence.new(PINK, PURPLE)
	rimGrad.Rotation = 35

	-- spinning gradient ring + logo (same as the loading card)
	local ringBox = Instance.new("Frame")
	ringBox.BackgroundTransparency = 1
	ringBox.AnchorPoint = Vector2.new(0.5, 0)
	ringBox.Position = UDim2.new(0.5, 0, 0, 16)
	ringBox.Size = UDim2.fromOffset(96, 96)
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
	local logoBox = Instance.new("Frame")
	logoBox.BackgroundTransparency = 1
	logoBox.AnchorPoint = Vector2.new(0.5, 0.5)
	logoBox.Position = UDim2.fromScale(0.5, 0.5)
	logoBox.Size = UDim2.fromOffset(72, 72)
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
	title.Position = UDim2.fromOffset(0, 120)
	title.Size = UDim2.new(1, 0, 0, 24)
	title.Text = "Eynch Hub"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextColor3 = Color3.fromRGB(250, 240, 247)
	title.Parent = card

	local msg = Instance.new("TextLabel")
	msg.BackgroundTransparency = 1
	msg.Position = UDim2.fromOffset(12, 146)
	msg.Size = UDim2.new(1, -24, 0, 18)
	msg.Text = "Join our Discord to get the free key"
	msg.Font = Enum.Font.Gotham
	msg.TextSize = 12
	msg.TextColor3 = Color3.fromRGB(190, 160, 182)
	msg.Parent = card

	-- key box with a gradient outline
	local box = Instance.new("TextBox")
	box.AnchorPoint = Vector2.new(0.5, 0)
	box.Position = UDim2.new(0.5, 0, 0, 176)
	box.Size = UDim2.fromOffset(220, 36)
	box.BackgroundColor3 = Color3.fromRGB(40, 26, 52)
	box.BackgroundTransparency = 0.2
	box.PlaceholderText = "Paste the key here"
	box.PlaceholderColor3 = Color3.fromRGB(150, 125, 150)
	box.Text = ""
	box.ClearTextOnFocus = false
	box.Font = Enum.Font.Gotham
	box.TextSize = 14
	box.TextColor3 = Color3.new(1, 1, 1)
	box.Parent = card
	Instance.new("UICorner", box).CornerRadius = UDim.new(1, 0)
	local boxStroke = Instance.new("UIStroke", box)
	boxStroke.Thickness = 1.2
	boxStroke.Color = Color3.new(1, 1, 1)
	boxStroke.Transparency = 0.5
	Instance.new("UIGradient", boxStroke).Color = ColorSequence.new(PINK, PURPLE)

	local function button(txt, y, c1, c2)
		local b = Instance.new("TextButton")
		b.AnchorPoint = Vector2.new(0.5, 0)
		b.Position = UDim2.new(0.5, 0, 0, y)
		b.Size = UDim2.fromOffset(220, 34)
		b.AutoButtonColor = false
		b.Text = ""
		b.BackgroundColor3 = Color3.new(1, 1, 1)
		b.Parent = card
		Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
		local g = Instance.new("UIGradient", b)
		g.Color = ColorSequence.new(c1, c2)
		-- the text is its own label, so the gradient does not tint it
		local lbl = Instance.new("TextLabel")
		lbl.Name = "Label"
		lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.Text = txt
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 13
		lbl.TextColor3 = Color3.new(1, 1, 1)
		lbl.Parent = b
		local s = Instance.new("UIScale", b)
		b.MouseEnter:Connect(function()
			TweenService:Create(s, TweenInfo.new(0.12), { Scale = 1.04 }):Play()
		end)
		b.MouseLeave:Connect(function()
			TweenService:Create(s, TweenInfo.new(0.12), { Scale = 1 }):Play()
		end)
		return b
	end
	local check = button("Check key", 222, PINK, PURPLE)
	local join = button("💬  Join Discord (copies invite)", 266, Color3.fromRGB(88, 101, 242), Color3.fromRGB(150, 110, 255))

	local t = 0
	local conn = RunService.RenderStepped:Connect(function(dt)
		t = t + dt
		ringGrad.Rotation = (t * 160) % 360
		rimGrad.Rotation = 35 + math.sin(t) * 25
		pulse.Scale = 1 + 0.045 * math.sin(t * 3.2)
	end)
	TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quad), { GroupTransparency = 0 }):Play()
	TweenService:Create(pop, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Scale = 1 }):Play()

	local busy = false
	local function submit()
		if busy then return end
		local ok, k = keyOk(box.Text)
		if ok then
			busy = true
			pcall(function()
				if writefile then
					if isfolder and makefolder and not isfolder("EynchHub") then makefolder("EynchHub") end
					writefile(KEY_FILE, k)
				end
			end)
			msg.Text = "✓  Key accepted"
			msg.TextColor3 = Color3.fromRGB(150, 235, 180)
			task.wait(0.6)
			passed, done = true, true
		else
			msg.Text = "Wrong key. Get it in our Discord."
			msg.TextColor3 = Color3.fromRGB(255, 120, 130)
			-- little shake
			task.spawn(function()
				for _, dx in ipairs({ 8, -8, 5, -5, 0 }) do
					box.Position = UDim2.new(0.5, dx, 0, 176)
					task.wait(0.04)
				end
			end)
		end
	end
	check.Activated:Connect(submit)
	box.FocusLost:Connect(function(enter) if enter then submit() end end)
	join.Activated:Connect(function()
		join.Label.Text = joinDiscord() and "✓  Invite copied" or "discord.gg/" .. DISCORD_CODE
	end)

	-- X button: close without loading
	local x = Instance.new("TextButton")
	x.AnchorPoint = Vector2.new(1, 0)
	x.Position = UDim2.new(1, -10, 0, 10)
	x.Size = UDim2.fromOffset(26, 26)
	x.AutoButtonColor = false
	x.Text = "✕"
	x.Font = Enum.Font.GothamBold
	x.TextSize = 13
	x.TextColor3 = Color3.fromRGB(235, 215, 230)
	x.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	x.BackgroundTransparency = 0.9
	x.ZIndex = 5
	x.Parent = card
	Instance.new("UICorner", x).CornerRadius = UDim.new(1, 0)
	x.MouseEnter:Connect(function() x.BackgroundTransparency = 0.75 end)
	x.MouseLeave:Connect(function() x.BackgroundTransparency = 0.9 end)
	x.Activated:Connect(function() passed, done = false, true end)

	-- drag the card by holding anywhere on it (mouse or touch)
	local UIS = game:GetService("UserInputService")
	local dragging, dragStart, startPos
	local function isPress(i)
		return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
	end
	card.InputBegan:Connect(function(i)
		if isPress(i) then
			dragging, dragStart, startPos = true, i.Position, card.Position
		end
	end)
	local moveConn = UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - dragStart
			card.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	local endConn = UIS.InputEnded:Connect(function(i)
		if isPress(i) then dragging = false end
	end)

	while not done do task.wait(0.2) end
	pcall(function() moveConn:Disconnect() endConn:Disconnect() end)
	TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { GroupTransparency = 1 }):Play()
	task.wait(0.28)
	pcall(function() conn:Disconnect() end)
	pcall(function() gui:Destroy() end)
	return passed
end

if not askKey() then return end

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
