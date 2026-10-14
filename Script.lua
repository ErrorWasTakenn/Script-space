local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("ErrorsAdmin") then
	playerGui.ErrorsAdmin:Destroy()
end

for _, guiObj in ipairs(playerGui:GetChildren()) do
	if guiObj.Name == "ErrorsAdminPopout" then
		guiObj:Destroy()
	end
end

local flying = false
local freecamming = false
local spectating = false
local gravityEnabled = false
local speedEnabled = false
local jumpEnabled = false
local fullBrightEnabled = false
local noFogEnabled = false
local fovEnabled = false
local noclip = false
local invisible = false
local floating = false
local infJump = false
local airSwimEnabled = false
local playerEspEnabled = false
local npcEspEnabled = false
local touchTpEnabled = false
local antiVoidEnabled = false
local morphEnabled = false
local soundsMuted = false

local invertColorsEnabled = false
local blackAndWhiteEnabled = false

local showHeaders = true
local showPlayerCat = true
local showVisualsCat = true
local showWorldCat = true
local showFunCat = true
local showPingFps = false

local flySpeed = 50
local freecamSpeed = 50
local customSpeed = 50
local customJump = 100
local customGravity = 50
local customFov = 70

local defaultGravity = workspace.Gravity
local defaultFov = workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70

local origAmbient = Lighting.Ambient
local origOutdoorAmbient = Lighting.OutdoorAmbient
local origBrightness = Lighting.Brightness
local origGlobalShadows = Lighting.GlobalShadows
local origClockTime = Lighting.ClockTime
local origFogEnd = Lighting.FogEnd
local origFogStart = Lighting.FogStart

local uiUp, uiDown = false, false
local keyUp, keyDown = false, false

local bodyVel, bodyGyro
local invisPlatform
local floatPlatform
local lastWaterRegion = nil
local savedCollide = {}
local connections = {}

local tpTool = nil
local spectateTarget = nil
local origHumanoidDescription = nil

local freecamPos = Vector3.zero
local HIDE_DEPTH = 30

local clickSound = Instance.new("Sound")
clickSound.SoundId = "rbxassetid://6895079853"
clickSound.Volume = 0.5
clickSound.Parent = SoundService

local function playDing()
	if not soundsMuted then
		clickSound:Play()
	end
end

local colorCorrection = Lighting:FindFirstChild("ErrorsAdminCC")
if not colorCorrection then
	colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Name = "ErrorsAdminCC"
	colorCorrection.Parent = Lighting
end

local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(connections, c)
	return c
end

local function getChar()
	local char = player.Character
	if not char then return end
	return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

local function findTargetPlayer(query)
	if not query or query == "" then return nil end
	query = string.lower(query)

	local otherPlayers = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			table.insert(otherPlayers, p)
		end
	end

	if query == "random" then
		if #otherPlayers > 0 then
			return otherPlayers[math.random(1, #otherPlayers)]
		end
		return nil
	end

	for _, p in ipairs(Players:GetPlayers()) do
		if string.lower(p.Name) == query or string.find(string.lower(p.Name), query, 1, true) then
			return p
		end
	end
	return nil
end

local function getUserIdFromInput(input)
	local num = tonumber(input)
	if num then return num end

	local target = findTargetPlayer(input)
	if target then return target.UserId end

	local success, userId = pcall(function()
		return Players:GetUserIdFromNameAsync(input)
	end)
	if success and userId then return userId end
	return nil
end

local function make(class, props, parent)
	local obj = Instance.new(class)
	for k, v in pairs(props) do
		obj[k] = v
	end
	obj.Parent = parent
	return obj
end

local COLOR_BG = Color3.fromRGB(45, 45, 50)
local COLOR_BTN = Color3.fromRGB(65, 65, 70)
local COLOR_ON = Color3.fromRGB(70, 160, 90)
local COLOR_OFF = Color3.fromRGB(180, 60, 60)
local COLOR_CATEGORY = Color3.fromRGB(35, 35, 40)
local COLOR_TEXT = Color3.fromRGB(240, 240, 245)

local PIXEL_FONT = Enum.Font.SpecialElite

local gui = make("ScreenGui", {
	Name = "ErrorsAdmin",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local hudFrame = make("Frame", {
	Name = "PingFpsHUD",
	Size = UDim2.fromOffset(130, 24),
	Position = UDim2.fromOffset(10, 10),
	BackgroundColor3 = Color3.fromRGB(25, 25, 30),
	BorderSizePixel = 0,
	Visible = false,
	Active = true,
}, gui)
make("UICorner", { CornerRadius = UDim.new(0, 5) }, hudFrame)

local hudText = make("TextLabel", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Text = "FPS: -- | Ping: --ms",
	TextColor3 = COLOR_TEXT,
	Font = PIXEL_FONT,
	TextSize = 10,
}, hudFrame)

do
	local dragging, dragStart, startPos, dragInput

	connect(hudFrame.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = hudFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)

	connect(hudFrame.InputChanged, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	connect(UserInputService.InputChanged, function(input)
		if dragging and input == dragInput then
			local delta = input.Position - dragStart
			hudFrame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

local FULL_SIZE = UDim2.fromOffset(210, 200)
local MINI_SIZE = UDim2.fromOffset(210, 22)

local window = make("Frame", {
	Name = "Window",
	Size = FULL_SIZE,
	Position = UDim2.new(1, -225, 0, 60),
	BackgroundColor3 = COLOR_BG,
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, gui)
make("UICorner", { CornerRadius = UDim.new(0, 5) }, window)

local titleBar = make("Frame", {
	Name = "TitleBar",
	Size = UDim2.new(1, 0, 0, 20),
	BackgroundColor3 = Color3.fromRGB(20, 20, 25),
	BorderSizePixel = 0,
}, window)

local titleText = make("TextLabel", {
	Size = UDim2.new(1, -65, 1, 0),
	Position = UDim2.fromOffset(5, 0),
	BackgroundTransparency = 1,
	Text = "Errors Admin",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	Font = PIXEL_FONT,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
}, titleBar)

local titleTweenInfo = TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local titleTween = TweenService:Create(titleBar, titleTweenInfo, {
	BackgroundColor3 = Color3.fromRGB(230, 230, 235)
})
local textTween = TweenService:Create(titleText, titleTweenInfo, {
	TextColor3 = Color3.fromRGB(20, 20, 25)
})
titleTween:Play()
textTween:Play()

local function titleButton(text, xOffset, color)
	local b = make("TextButton", {
		Size = UDim2.fromOffset(16, 14),
		Position = UDim2.new(1, xOffset, 0, 3),
		BackgroundColor3 = color,
		Text = text,
		TextColor3 = COLOR_TEXT,
		Font = PIXEL_FONT,
		TextSize = 10,
	}, titleBar)
	make("UICorner", { CornerRadius = UDim.new(0, 3) }, b)
	return b
end

local settingsBtn = titleButton("⚙", -57, COLOR_BTN)
local minBtn = titleButton("–", -38, COLOR_BTN)
local closeBtn = titleButton("X", -19, Color3.fromRGB(190, 60, 60))

local mainTab = make("ScrollingFrame", {
	Name = "MainTab",
	Size = UDim2.new(1, -6, 1, -22),
	Position = UDim2.fromOffset(3, 21),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 2,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	Visible = true,
}, window)

local settingsTab = make("ScrollingFrame", {
	Name = "SettingsTab",
	Size = UDim2.new(1, -6, 1, -22),
	Position = UDim2.fromOffset(3, 21),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 2,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	Visible = false,
}, window)

local function makeLayout(parent)
	make("UIListLayout", {
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, parent)
	make("UIPadding", { PaddingRight = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }, parent)
end
makeLayout(mainTab)
makeLayout(settingsTab)

local order = 0
local function nextOrder()
	order += 1
	return order
end

local function makeCategory(title)
	local catFrame = make("Frame", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		LayoutOrder = nextOrder(),
	}, mainTab)

	local headerBtn = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundColor3 = COLOR_CATEGORY,
		Text = "▲  " .. title,
		TextColor3 = COLOR_TEXT,
		Font = PIXEL_FONT,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, catFrame)
	make("UICorner", { CornerRadius = UDim.new(0, 4) }, headerBtn)
	make("UIPadding", { PaddingLeft = UDim.new(0, 6) }, headerBtn)

	local container = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.fromOffset(0, 22),
		BackgroundTransparency = 1,
	}, catFrame)

	local listLayout = make("UIListLayout", {
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, container)

	local expanded = true

	local function updateCategorySize()
		if not showHeaders then
			headerBtn.Visible = false
			container.Position = UDim2.fromOffset(0, 0)
			catFrame.Size = UDim2.new(1, 0, 0, listLayout.AbsoluteContentSize.Y)
		else
			headerBtn.Visible = true
			container.Position = UDim2.fromOffset(0, 22)
			local targetH = expanded and (22 + listLayout.AbsoluteContentSize.Y) or 20
			catFrame.Size = UDim2.new(1, 0, 0, targetH)
		end
	end

	connect(headerBtn.Activated, function()
		playDing()
		expanded = not expanded
		headerBtn.Text = (expanded and "▲  " or "▼  ") .. title
		updateCategorySize()
	end)

	connect(listLayout:GetPropertyChangedSignal("AbsoluteContentSize"), updateCategorySize)

	return container, catFrame, updateCategorySize
end

local function makePopoutButton(text, clickCallback, getStateFn)
	local popoutGui = make("ScreenGui", {
		Name = "ErrorsAdminPopout",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, playerGui)

	local btn = make("TextButton", {
		Size = UDim2.fromOffset(120, 24),
		Position = UDim2.new(0.5, -60, 0.2, 0),
		BackgroundColor3 = getStateFn() and COLOR_ON or COLOR_OFF,
		Text = text .. ": " .. (getStateFn() and "ON" or "OFF"),
		TextColor3 = COLOR_TEXT,
		Font = PIXEL_FONT,
		TextSize = 10,
		Active = true,
		Draggable = true,
	}, popoutGui)
	make("UICorner", { CornerRadius = UDim.new(0, 4) }, btn)

	local closePopout = make("TextButton", {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(1, -16, 0, 5),
		BackgroundColor3 = Color3.fromRGB(190, 60, 60),
		Text = "X",
		TextColor3 = COLOR_TEXT,
		Font = PIXEL_FONT,
		TextSize = 8,
	}, btn)
	make("UICorner", { CornerRadius = UDim.new(0, 3) }, closePopout)

	connect(closePopout.Activated, function()
		playDing()
		popoutGui:Destroy()
	end)

	connect(btn.Activated, function()
		clickCallback()
		btn.Text = text .. ": " .. (getStateFn() and "ON" or "OFF")
		btn.BackgroundColor3 = getStateFn() and COLOR_ON or COLOR_OFF
	end)
end
local function setupHoldToPopout(btn, text, clickCallback, getStateFn)
	local holding = false
	local holdDuration = 3
	local elapsed = 0

	connect(btn.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			holding = true
			elapsed = 0
			task.spawn(function()
				while holding do
					task.wait(0.1)
					if holding then
						elapsed += 0.1
						if elapsed >= holdDuration then
							holding = false
							playDing()
							makePopoutButton(text, clickCallback, getStateFn)
							break
						end
					end
				end
			end)
		end
	end)

	connect(btn.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			holding = false
		end
	end)
end

local function categoryButton(parent, text, clickCallback, getStateFn)
	local b = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundColor3 = COLOR_OFF,
		Text = text .. ": OFF",
		TextColor3 = COLOR_TEXT,
		Font = PIXEL_FONT,
		TextSize = 11,
		LayoutOrder = nextOrder(),
	}, parent)
	make("UICorner", { CornerRadius = UDim.new(0, 4) }, b)

	if clickCallback and getStateFn then
		setupHoldToPopout(b, text, clickCallback, getStateFn)
	end

	return b
end

local function setToggleVisual(btn, name, state)
	btn.Text = name .. ": " .. (state and "ON" or "OFF")
	local targetColor = state and COLOR_ON or COLOR_OFF
	TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = targetColor }):Play()
end

local function toggleInputRow(parent, toggleName, defaultInputText)
	local row = make("Frame", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	}, parent)

	local btn = make("TextButton", {
		Size = UDim2.new(0.55, -2, 1, 0),
		BackgroundColor3 = COLOR_OFF,
		Text = toggleName .. ": OFF",
		TextColor3 = COLOR_TEXT,
		Font = PIXEL_FONT,
		TextSize = 11,
	}, row)
	make("UICorner", { CornerRadius = UDim.new(0, 4) }, btn)

	local box = make("TextBox", {
		Size = UDim2.new(0.45, -2, 1, 0),
		Position = UDim2.new(0.55, 2, 0, 0),
		BackgroundColor3 = COLOR_BTN,
		Text = defaultInputText,
		TextColor3 = COLOR_TEXT,
		Font = PIXEL_FONT,
		TextSize = 11,
		ClearTextOnFocus = false,
	}, row)
	make("UICorner", { CornerRadius = UDim.new(0, 4) }, box)

	return btn, box
end

local playerCat, playerCatFrame, updatePlayerCat = makeCategory("Player Controls")
local visualsCat, visualsCatFrame, updateVisualsCat = makeCategory("ESP & Visuals")
local worldCat, worldCatFrame, updateWorldCat = makeCategory("World & Teleport")
local funCat, funCatFrame, updateFunCat = makeCategory("Fun Features")

local flyBtn, speedBox = toggleInputRow(playerCat, "Fly", tostring(flySpeed))

local udRow = make("Frame", {
	Size = UDim2.new(1, 0, 0, 20),
	BackgroundTransparency = 1,
	LayoutOrder = nextOrder(),
}, playerCat)

local upBtn = make("TextButton", {
	Size = UDim2.new(0.5, -2, 1, 0),
	BackgroundColor3 = COLOR_BTN,
	Text = "▲ Up",
	TextColor3 = COLOR_TEXT,
	Font = PIXEL_FONT,
	TextSize = 11,
}, udRow)

local downBtn = make("TextButton", {
	Size = UDim2.new(0.5, -2, 1, 0),
	Position = UDim2.new(0.5, 2, 0, 0),
	BackgroundColor3 = COLOR_BTN,
	Text = "▼ Down",
	TextColor3 = COLOR_TEXT,
	Font = PIXEL_FONT,
	TextSize = 11,
}, udRow)

make("UICorner", { CornerRadius = UDim.new(0, 4) }, upBtn)
make("UICorner", { CornerRadius = UDim.new(0, 4) }, downBtn)

local walkSpeedBtn, walkSpeedBox = toggleInputRow(playerCat, "Speed", tostring(customSpeed))
local jumpPowerBtn, jumpPowerBox = toggleInputRow(playerCat, "Jump", tostring(customJump))
local morphBtn, morphBox = toggleInputRow(playerCat, "Morph", "Username/ID")

local fovBtn, fovBox = toggleInputRow(visualsCat, "FOV", tostring(math.floor(defaultFov + 0.5)))
local freecamBtn, freecamBox = toggleInputRow(worldCat, "Freecam", tostring(freecamSpeed))
local spectateBtn, spectateBox = toggleInputRow(worldCat, "Spectate", "PlayerName")
local tpPlayerBtn, tpPlayerBox = toggleInputRow(worldCat, "TP Player", "PlayerName")
local gravityBtn, gravityBox = toggleInputRow(worldCat, "Gravity", tostring(customGravity))

local setNoclip, setInvisible, setFloat, setInfJump, setAirSwim
local setPlayerEsp, setNpcEsp, setFullBright, setNoFog, setTouchTp
local setAntiVoid, setInvertColors, setBlackAndWhite

local noclipBtn = categoryButton(playerCat, "Noclip", function() setNoclip(not noclip) end, function() return noclip end)
local invisBtn = categoryButton(playerCat, "Invisible", function() setInvisible(not invisible) end, function() return invisible end)
local floatBtn = categoryButton(playerCat, "Float", function() setFloat(not floating) end, function() return floating end)
local infJumpBtn = categoryButton(playerCat, "Infinite Jump", function() infJump = not infJump; setToggleVisual(infJumpBtn, "Infinite Jump", infJump) end, function() return infJump end)
local airSwimBtn = categoryButton(playerCat, "Air Swim", function() setAirSwim(not airSwimEnabled) end, function() return airSwimEnabled end)

local playerEspBtn = categoryButton(visualsCat, "Player ESP", function() playerEspEnabled = not playerEspEnabled; setToggleVisual(playerEspBtn, "Player ESP", playerEspEnabled); updateEsp() end, function() return playerEspEnabled end)
local npcEspBtn = categoryButton(visualsCat, "NPC ESP", function() npcEspEnabled = not npcEspEnabled; setToggleVisual(npcEspBtn, "NPC ESP", npcEspEnabled); updateEsp() end, function() return npcEspEnabled end)
local fullBrightBtn = categoryButton(visualsCat, "Full Bright", function() setFullBright(not fullBrightEnabled) end, function() return fullBrightEnabled end)
local noFogBtn = categoryButton(visualsCat, "No Fog", function() setNoFog(not noFogEnabled) end, function() return noFogEnabled end)

local tpBtn = categoryButton(worldCat, "Touch TP", function() setTouchTp(not touchTpEnabled) end, function() return touchTpEnabled end)
local antiVoidBtn = categoryButton(worldCat, "Anti Void", function() setAntiVoid(not antiVoidEnabled) end, function() return antiVoidEnabled end)

local invertColorsBtn = categoryButton(funCat, "Invert Colors", function() invertColorsEnabled = not invertColorsEnabled; setToggleVisual(invertColorsBtn, "Invert Colors", invertColorsEnabled); updateColorEffects() end, function() return invertColorsEnabled end)
local blackAndWhiteBtn = categoryButton(funCat, "Black & White", function() blackAndWhiteEnabled = not blackAndWhiteEnabled; setToggleVisual(blackAndWhiteBtn, "Black & White", blackAndWhiteEnabled); updateColorEffects() end, function() return blackAndWhiteEnabled end)

local showPingFpsBtn = categoryButton(settingsTab, "Show Ping & FPS")
local hideHeadersBtn = categoryButton(settingsTab, "Hide Headers")
local disableSoundsBtn = categoryButton(settingsTab, "Mute Sounds")
local togglePlayerCatBtn = categoryButton(settingsTab, "Player Group")
local toggleVisualsCatBtn = categoryButton(settingsTab, "Visuals Group")
local toggleWorldCatBtn = categoryButton(settingsTab, "World Group")
local toggleFunCatBtn = categoryButton(settingsTab, "Fun Group")

local function updateSettingsVisuals()
	setToggleVisual(showPingFpsBtn, "Show Ping & FPS", showPingFps)
	setToggleVisual(hideHeadersBtn, "Hide Headers", not showHeaders)
	setToggleVisual(disableSoundsBtn, "Mute Sounds", soundsMuted)
	setToggleVisual(togglePlayerCatBtn, "Player Group", showPlayerCat)
	setToggleVisual(toggleVisualsCatBtn, "Visuals Group", showVisualsCat)
	setToggleVisual(toggleWorldCatBtn, "World Group", showWorldCat)
	setToggleVisual(toggleFunCatBtn, "Fun Group", showFunCat)
end
connect(showPingFpsBtn.Activated, function()
	showPingFps = not showPingFps
	hudFrame.Visible = showPingFps
	updateSettingsVisuals()
	playDing()
end)

connect(hideHeadersBtn.Activated, function()
	showHeaders = not showHeaders
	updatePlayerCat()
	updateVisualsCat()
	updateWorldCat()
	updateFunCat()
	updateSettingsVisuals()
	playDing()
end)

connect(disableSoundsBtn.Activated, function()
	soundsMuted = not soundsMuted
	SoundService.Volume = soundsMuted and 0 or 1
	updateSettingsVisuals()
	playDing()
end)

connect(togglePlayerCatBtn.Activated, function()
	showPlayerCat = not showPlayerCat
	playerCatFrame.Visible = showPlayerCat
	updateSettingsVisuals()
	playDing()
end)

connect(toggleVisualsCatBtn.Activated, function()
	showVisualsCat = not showVisualsCat
	visualsCatFrame.Visible = showVisualsCat
	updateSettingsVisuals()
	playDing()
end)

connect(toggleWorldCatBtn.Activated, function()
	showWorldCat = not showWorldCat
	worldCatFrame.Visible = showWorldCat
	updateSettingsVisuals()
	playDing()
end)

connect(toggleFunCatBtn.Activated, function()
	showFunCat = not showFunCat
	funCatFrame.Visible = showFunCat
	updateSettingsVisuals()
	playDing()
end)

updateSettingsVisuals()

setToggleVisual(morphBtn, "Morph", false)
setToggleVisual(antiVoidBtn, "Anti Void", false)
setToggleVisual(walkSpeedBtn, "Speed", false)
setToggleVisual(jumpPowerBtn, "Jump", false)
setToggleVisual(gravityBtn, "Gravity", false)
setToggleVisual(fullBrightBtn, "Full Bright", false)
setToggleVisual(noFogBtn, "No Fog", false)
setToggleVisual(noclipBtn, "Noclip", false)
setToggleVisual(invisBtn, "Invisible", false)
setToggleVisual(floatBtn, "Float", false)
setToggleVisual(infJumpBtn, "Infinite Jump", false)
setToggleVisual(airSwimBtn, "Air Swim", false)
setToggleVisual(playerEspBtn, "Player ESP", false)
setToggleVisual(npcEspBtn, "NPC ESP", false)
setToggleVisual(tpBtn, "Touch TP", false)
setToggleVisual(invertColorsBtn, "Invert Colors", false)
setToggleVisual(blackAndWhiteBtn, "Black & White", false)

local inSettings = false
local tweenInfoTab = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

connect(settingsBtn.Activated, function()
	playDing()
	inSettings = not inSettings
	settingsBtn.BackgroundColor3 = inSettings and COLOR_ON or COLOR_BTN

	local hideTab = inSettings and mainTab or settingsTab
	local showTab = inSettings and settingsTab or mainTab

	TweenService:Create(hideTab, tweenInfoTab, { Position = UDim2.fromOffset(inSettings and -180 or 180, 21) }):Play()
	task.delay(0.1, function()
		hideTab.Visible = false
		showTab.Position = UDim2.fromOffset(inSettings and 180 or -180, 21)
		showTab.Visible = true
		TweenService:Create(showTab, tweenInfoTab, { Position = UDim2.fromOffset(3, 21) }):Play()
	end)
end)

local function clearAirSwimWater()
	if lastWaterRegion then
		pcall(function()
			workspace.Terrain:FillRegion(lastWaterRegion, 4, Enum.Material.Air)
		end)
		lastWaterRegion = nil
	end
end

function setAirSwim(state)
	airSwimEnabled = state
	setToggleVisual(airSwimBtn, "Air Swim", state)
	if not state then clearAirSwimWater() end
end

connect(airSwimBtn.Activated, function()
	playDing()
	setAirSwim(not airSwimEnabled)
end)

task.spawn(function()
	while true do
		task.wait(0.2)
		if airSwimEnabled then
			local _, hrp = getChar()
			if hrp then
				clearAirSwimWater()
				local size = Vector3.new(10, 10, 10)
				local cf = hrp.CFrame
				local region = Region3.new(hrp.Position - (size/2), hrp.Position + (size/2))
				region = region:ExpandToGrid(4)

				pcall(function()
					workspace.Terrain:FillBlock(cf, size, Enum.Material.Water)
					lastWaterRegion = region
				end)
			end
		else
			clearAirSwimWater()
		end
	end
end)

function updateColorEffects()
	if invertColorsEnabled then
		colorCorrection.Contrast = -2
		colorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
	else
		colorCorrection.Contrast = 0
		colorCorrection.TintColor = Color3.fromRGB(255, 255, 255)
	end

	if blackAndWhiteEnabled then
		colorCorrection.Saturation = -1
	else
		colorCorrection.Saturation = 0
	end
end

connect(invertColorsBtn.Activated, function()
	playDing()
	invertColorsEnabled = not invertColorsEnabled
	setToggleVisual(invertColorsBtn, "Invert Colors", invertColorsEnabled)
	updateColorEffects()
end)

connect(blackAndWhiteBtn.Activated, function()
	playDing()
	blackAndWhiteEnabled = not blackAndWhiteEnabled
	setToggleVisual(blackAndWhiteBtn, "Black & White", blackAndWhiteEnabled)
	updateColorEffects()
end)

local function applyMorph(userId)
	local _, _, hum = getChar()
	if not hum then return end

	local success, desc = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(userId)
	end)

	if success and desc then
		if not origHumanoidDescription then
			pcall(function()
				origHumanoidDescription = hum:GetAppliedDescription()
			end)
		end
		hum:ApplyDescription(desc)
	end
end

local function resetMorph()
	local _, _, hum = getChar()
	if hum and origHumanoidDescription then
		hum:ApplyDescription(origHumanoidDescription)
	end
end

local function setMorph(state)
	morphEnabled = state
	setToggleVisual(morphBtn, "Morph", state)
	if state then
		local targetId = getUserIdFromInput(morphBox.Text)
		if targetId then
			applyMorph(targetId)
		else
			morphEnabled = false
			setToggleVisual(morphBtn, "Morph", false)
		end
	else
		resetMorph()
	end
end

connect(morphBtn.Activated, function()
	playDing()
	setMorph(not morphEnabled)
end)

local function cleanVoidZones()
	pcall(function()
		for _, part in ipairs(workspace:GetDescendants()) do
			if part:IsA("BasePart") then
				local name = string.lower(part.Name)
				if string.find(name, "void") or string.find(name, "killzone") or string.find(name, "deadzone") then
					part:Destroy()
				end
			end
		end
	end)
end

function setAntiVoid(state)
	antiVoidEnabled = state
	setToggleVisual(antiVoidBtn, "Anti Void", state)
	if state then cleanVoidZones() end
end

connect(antiVoidBtn.Activated, function()
	playDing()
	setAntiVoid(not antiVoidEnabled)
end)

local function stopFly()
	flying = false
	if bodyVel then bodyVel:Destroy() bodyVel = nil end
	if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
	local _, _, hum = getChar()
	if hum then hum.PlatformStand = false end
	setToggleVisual(flyBtn, "Fly", false)
end

local function startFly()
	local _, hrp, hum = getChar()
	if not hrp or not hum then return end
	hum.PlatformStand = true

	bodyVel = Instance.new("BodyVelocity")
	bodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	bodyVel.Velocity = Vector3.zero
	bodyVel.Parent = hrp

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	bodyGyro.P = 1e4
	bodyGyro.CFrame = hrp.CFrame
	bodyGyro.Parent = hrp

	flying = true
	setToggleVisual(flyBtn, "Fly", true)
end

connect(flyBtn.Activated, function()
	playDing()
	if flying then stopFly() else startFly() end
end)
connect(speedBox.FocusLost, function()
	local n = tonumber(speedBox.Text)
	if n then flySpeed = math.clamp(n, 1, 5000) end
	speedBox.Text = tostring(flySpeed)
end)

local function setFreecam(state)
	freecamming = state
	setToggleVisual(freecamBtn, "Freecam", state)
	local cam = workspace.CurrentCamera
	local _, hrp = getChar()

	if state then
		if cam then freecamPos = cam.CFrame.Position end
		if hrp then hrp.Anchored = true end
	else
		if hrp then hrp.Anchored = false end
		if cam then
			cam.CameraType = Enum.CameraType.Custom
			local _, _, hum = getChar()
			cam.CameraSubject = hum or player.Character
		end
	end
end

connect(freecamBtn.Activated, function()
	playDing()
	setFreecam(not freecamming)
end)

connect(freecamBox.FocusLost, function()
	local n = tonumber(freecamBox.Text)
	if n then
		freecamSpeed = math.clamp(n, 1, 5000)
		freecamBox.Text = tostring(freecamSpeed)
	else
		freecamBox.Text = tostring(freecamSpeed)
	end
end)

local function setWalkSpeed(state)
	speedEnabled = state
	setToggleVisual(walkSpeedBtn, "Speed", state)
	if not state then
		local _, _, hum = getChar()
		if hum then hum.WalkSpeed = 16 end
	end
end

connect(walkSpeedBtn.Activated, function()
	playDing()
	setWalkSpeed(not speedEnabled)
end)

connect(walkSpeedBox.FocusLost, function()
	local n = tonumber(walkSpeedBox.Text)
	if n then
		customSpeed = math.max(0, n)
		walkSpeedBox.Text = tostring(customSpeed)
	end
end)

local function setJumpPower(state)
	jumpEnabled = state
	setToggleVisual(jumpPowerBtn, "Jump", state)
	if not state then
		local _, _, hum = getChar()
		if hum then
			if hum.UseJumpPower then hum.JumpPower = 50 else hum.JumpHeight = 7.2 end
		end
	end
end

connect(jumpPowerBtn.Activated, function()
	playDing()
	setJumpPower(not jumpEnabled)
end)

connect(jumpPowerBox.FocusLost, function()
	local n = tonumber(jumpPowerBox.Text)
	if n then
		customJump = math.max(0, n)
		jumpPowerBox.Text = tostring(customJump)
	end
end)

local function setGravity(state)
	gravityEnabled = state
	setToggleVisual(gravityBtn, "Gravity", state)
	if not state then workspace.Gravity = defaultGravity end
end

connect(gravityBtn.Activated, function()
	playDing()
	setGravity(not gravityEnabled)
end)

connect(gravityBox.FocusLost, function()
	local n = tonumber(gravityBox.Text)
	if n then
		customGravity = n
		gravityBox.Text = tostring(customGravity)
	end
end)

function setFullBright(state)
	fullBrightEnabled = state
	setToggleVisual(fullBrightBtn, "Full Bright", state)
	if not state then
		Lighting.Ambient = origAmbient
		Lighting.OutdoorAmbient = origOutdoorAmbient
		Lighting.Brightness = origBrightness
		Lighting.GlobalShadows = origGlobalShadows
		Lighting.ClockTime = origClockTime
	end
end

connect(fullBrightBtn.Activated, function()
	playDing()
	setFullBright(not fullBrightEnabled)
end)

function setNoFog(state)
	noFogEnabled = state
	setToggleVisual(noFogBtn, "No Fog", state)
	if state then
		Lighting.FogStart = 0
		Lighting.FogEnd = 1e9
		for _, v in ipairs(Lighting:GetChildren()) do
			if v:IsA("Atmosphere") then v.Density = 0 end
		end
	else
		Lighting.FogStart = origFogStart
		Lighting.FogEnd = origFogEnd
	end
end

connect(noFogBtn.Activated, function()
	playDing()
	setNoFog(not noFogEnabled)
end)

local function setSpectate(state)
	spectating = state
	setToggleVisual(spectateBtn, "Spectate", state)
	local cam = workspace.CurrentCamera

	if state then
		local target = findTargetPlayer(spectateBox.Text)
		if target and target.Character then
			spectateTarget = target
			spectateBox.Text = target.Name
			if cam then
				cam.CameraSubject = target.Character:FindFirstChildOfClass("Humanoid") or target.Character:FindFirstChild("HumanoidRootPart")
			end
		else
			spectating = false
			setToggleVisual(spectateBtn, "Spectate", false)
		end
	else
		spectateTarget = nil
		if cam then
			local _, _, hum = getChar()
			cam.CameraSubject = hum or player.Character
		end
	end
end

connect(spectateBtn.Activated, function()
	playDing()
	setSpectate(not spectating)
end)

connect(tpPlayerBtn.Activated, function()
	playDing()
	local target = findTargetPlayer(tpPlayerBox.Text)
	if target and target.Character then
		tpPlayerBox.Text = target.Name
		local _, hrp = getChar()
		local targetHrp = target.Character:FindFirstChild("HumanoidRootPart")
		if hrp and targetHrp then
			hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 3)
		end
	end
end)

local function holdButton(btn, setter)
	connect(btn.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			setter(true)
		end
	end)
	connect(btn.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			setter(false)
		end
	end)
end
holdButton(upBtn, function(v) uiUp = v end)
holdButton(downBtn, function(v) uiDown = v end)

connect(UserInputService.InputBegan, function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.E then keyUp = true end
	if input.KeyCode == Enum.KeyCode.Q then keyDown = true end
end)

connect(UserInputService.InputEnded, function(input)
	if input.KeyCode == Enum.KeyCode.E then keyUp = false end
	if input.KeyCode == Enum.KeyCode.Q then keyDown = false end
end)

connect(UserInputService.JumpRequest, function()
	if infJump then
		local _, _, hum = getChar()
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

local function restoreCollisions()
	for part in pairs(savedCollide) do
		if part and part.Parent then part.CanCollide = true end
	end
	table.clear(savedCollide)
end

function setNoclip(state)
	noclip = state
	setToggleVisual(noclipBtn, "Noclip", state)
	if not state then restoreCollisions() end
end

connect(noclipBtn.Activated, function()
	playDing()
	setNoclip(not noclip)
end)

local function clearFloatPlatform()
	if floatPlatform then floatPlatform:Destroy() floatPlatform = nil end
end

function setFloat(state)
	floating = state
	setToggleVisual(floatBtn, "Float", state)
	if state then
		if not floatPlatform then
			floatPlatform = make("Part", {
				Name = "ErrorsAdminFloatPlatform",
				Size = Vector3.new(10, 1, 10),
				Anchored = true,
				CanCollide = true,
				Transparency = 1,
			}, workspace)
		end
	else
		clearFloatPlatform()
	end
end

connect(floatBtn.Activated, function()
	playDing()
	setFloat(not floating)
end)

local function clearInvisibleState()
	invisible = false
	if invisPlatform then invisPlatform:Destroy() invisPlatform = nil end
	setToggleVisual(invisBtn, "Invisible", false)
end

function setInvisible(state)
	invisible = state
	setToggleVisual(invisBtn, "Invisible", state)
	local _, hrp = getChar()
	if state and hrp then
		hrp.CFrame = hrp.CFrame - Vector3.new(0, HIDE_DEPTH, 0)
		invisPlatform = make("Part", {
			Name = "ErrorsAdminInvisPlatform",
			Size = Vector3.new(30, 1, 30),
			Anchored = true,
			CanCollide = true,
			Transparency = 1,
			CFrame = hrp.CFrame - Vector3.new(0, 3.5, 0),
		}, workspace)
	else
		clearInvisibleState()
	end
end

connect(invisBtn.Activated, function()
	playDing()
	setInvisible(not invisible)
end)

local function applyHighlight(model, color, name)
	if not model:FindFirstChild(name) then
		local hl = Instance.new("Highlight")
		hl.Name = name
		hl.FillColor = color
		hl.OutlineColor = color
		hl.FillTransparency = 0.5
		hl.OutlineTransparency = 0
		hl.Parent = model
	end
end

local function removeHighlight(model, name)
	local hl = model:FindFirstChild(name)
	if hl then hl:Destroy() end
end

local function updateEsp()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			if playerEspEnabled then
				applyHighlight(p.Character, Color3.fromRGB(0, 255, 100), "PlayerESP_Highlight")
			else
				removeHighlight(p.Character, "PlayerESP_Highlight")
			end
		end
	end

	if npcEspEnabled then
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
				applyHighlight(obj, Color3.fromRGB(0, 150, 255), "NPCESP_Highlight")
			end
		end
	else
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Model") then removeHighlight(obj, "NPCESP_Highlight") end
		end
	end
end

local function removeTouchTpTool()
	if tpTool then tpTool:Destroy() tpTool = nil end
end

local function giveTouchTpTool()
	removeTouchTpTool()
	tpTool = Instance.new("Tool")
	tpTool.Name = "Touch TP"
	tpTool.RequiresHandle = false

	tpTool.Activated:Connect(function()
		local mouse = player:GetMouse()
		local _, hrp = getChar()
		if mouse and hrp and mouse.Hit then
			hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
		end
	end)

	tpTool.Parent = player:WaitForChild("Backpack")
end

function setTouchTp(state)
	touchTpEnabled = state
	setToggleVisual(tpBtn, "Touch TP", state)
	if state then giveTouchTpTool() else removeTouchTpTool() end
end

connect(tpBtn.Activated, function()
	playDing()
	setTouchTp(not touchTpEnabled)
end)

local frameCount = 0
local lastFpsUpdate = os.clock()

connect(RunService.Stepped, function()
	local _, hrp, hum = getChar()

	local vInput = 0
	if keyUp or uiUp then vInput += 1 end
	if keyDown or uiDown then vInput -= 1 end

	if vInput ~= 0 and hrp then
		if floating and floatPlatform then
			floatPlatform.CFrame = floatPlatform.CFrame + Vector3.new(0, vInput * 1, 0)
			hrp.CFrame = hrp.CFrame + Vector3.new(0, vInput * 1, 0)
		elseif not flying then
			hrp.CFrame = hrp.CFrame + Vector3.new(0, vInput * 1, 0)
		end
	end

	if hum then
		if speedEnabled then hum.WalkSpeed = customSpeed end
		if jumpEnabled then
			if hum.UseJumpPower then hum.JumpPower = customJump else hum.JumpHeight = customJump end
		end
	end

	if gravityEnabled then workspace.Gravity = customGravity end
	if noFogEnabled then Lighting.FogStart = 0 Lighting.FogEnd = 1e9 end

	if antiVoidEnabled and hrp then
		local voidThreshold = workspace.FallenPartsDestroyHeight + 15
		if hrp.Position.Y <= voidThreshold then
			hrp.CFrame = CFrame.new(hrp.Position.X, voidThreshold + 50, hrp.Position.Z)
			hrp.AssemblyLinearVelocity = Vector3.zero
		end
	end

	if noclip then
		local char = player.Character
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then
					savedCollide[part] = true
					part.CanCollide = false
				end
			end
		end
	end

	if floating and floatPlatform then
		local _, fHrp, h = getChar()
		if fHrp and h then
			if h:GetState() == Enum.HumanoidStateType.Freefall or h:GetState() == Enum.HumanoidStateType.Landed or h:GetState() == Enum.HumanoidStateType.Running then
				if fHrp.AssemblyLinearVelocity.Y <= 0 and (vInput == 0) then
					floatPlatform.CFrame = CFrame.new(fHrp.Position.X, fHrp.Position.Y - 3.5, fHrp.Position.Z)
				end
			end
		end
	end
end)

connect(RunService.RenderStepped, function(dt)
	local cam = workspace.CurrentCamera

	if showPingFps then
		frameCount += 1
		local now = os.clock()
		if now - lastFpsUpdate >= 0.001 then
			local fps = math.floor(frameCount / math.max(now - lastFpsUpdate, 0.0001))
			local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
			hudText.Text = string.format("FPS: %d | Ping: %dms", fps, ping)
			frameCount = 0
			lastFpsUpdate = now
		end
	end

	if fullBrightEnabled then
		Lighting.Ambient = Color3.fromRGB(255, 255, 255)
		Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
		Lighting.Brightness = 2
		Lighting.GlobalShadows = false
		Lighting.ClockTime = 14
	end

	if playerEspEnabled or npcEspEnabled then updateEsp() end

	if freecamming and cam then
		local _, _, hum = getChar()
		local moveDir = hum and hum.MoveDirection or Vector3.zero

		local look3D = cam.CFrame.LookVector
		local right3D = cam.CFrame.RightVector

		local forwardInput = moveDir:Dot(Vector3.new(look3D.X, 0, look3D.Z).Unit)
		local rightInput = moveDir:Dot(Vector3.new(right3D.X, 0, right3D.Z).Unit)

		local v = 0
		if keyUp or uiUp then v += 1 end
		if keyDown or uiDown then v -= 1 end

		local camMove = (look3D * forwardInput) + (right3D * rightInput) + Vector3.new(0, v, 0)
		if camMove.Magnitude > 0 then
			freecamPos = freecamPos + (camMove.Unit * (freecamSpeed * dt))
		end

		cam.CFrame = CFrame.new(freecamPos) * cam.CFrame.Rotation
	end

	if flying then
		local _, hrp, hum = getChar()
		if hrp and hum and bodyVel and bodyVel.Parent and cam then
			local look, right = cam.CFrame.LookVector, cam.CFrame.RightVector
			local flatLook = Vector3.new(look.X, 0, look.Z)
			local flatRight = Vector3.new(right.X, 0, right.Z)

			local move = hum.MoveDirection
			local f = flatLook.Magnitude > 0.001 and move:Dot(flatLook.Unit) or 0
			local r = flatRight.Magnitude > 0.001 and move:Dot(flatRight.Unit) or 0

			local v = 0
			if keyUp or uiUp then v += 1 end
			if keyDown or uiDown then v -= 1 end

			bodyVel.Velocity = (look * f + right * r + Vector3.new(0, v, 0)) * flySpeed
			bodyGyro.CFrame = cam.CFrame
		end
	end
end)

connect(player.CharacterAdded, function()
	stopFly()
	setFreecam(false)
	setSpectate(false)
	clearInvisibleState()
	setFloat(false)
	clearAirSwimWater()
	table.clear(savedCollide)
	if touchTpEnabled then giveTouchTpTool() end
	if morphEnabled then
		task.wait(0.5)
		local targetId = getUserIdFromInput(morphBox.Text)
		if targetId then applyMorph(targetId) end
	end
end)

do
	local dragging, dragStart, startPos, dragInput

	connect(titleBar.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = window.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)

	connect(titleBar.InputChanged, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	connect(UserInputService.InputChanged, function(input)
		if dragging and input == dragInput then
			local delta = input.Position - dragStart
			window.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

local minimized = false
connect(minBtn.Activated, function()
	playDing()
	minimized = not minimized
	mainTab.Visible = not minimized and not inSettings
	settingsTab.Visible = not minimized and inSettings
	local targetSize = minimized and MINI_SIZE or FULL_SIZE
	TweenService:Create(window, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = targetSize }):Play()
	minBtn.Text = minimized and "+" or "–"
end)

connect(closeBtn.Activated, function()
	playDing()
	pcall(function() titleTween:Cancel() end)
	pcall(function() textTween:Cancel() end)
	stopFly()
	setFreecam(false)
	setSpectate(false)
	setNoclip(false)
	setInvisible(false)
	setFloat(false)
	setAirSwim(false)
	setTouchTp(false)
	setFov(false)
	setWalkSpeed(false)
	setJumpPower(false)
	setGravity(false)
	setFullBright(false)
	setNoFog(false)
	setAntiVoid(false)
	setMorph(false)
	
	playerEspEnabled = false
	npcEspEnabled = false
	updateEsp()

	SoundService.Volume = 1
	if colorCorrection then colorCorrection:Destroy() end

	for _, guiObj in ipairs(playerGui:GetChildren()) do
		if guiObj.Name == "ErrorsAdminPopout" then
			guiObj:Destroy()
		end
	end

	local cam = workspace.CurrentCamera
	if cam then 
		cam.FieldOfView = defaultFov 
		cam.CameraType = Enum.CameraType.Custom
		cam.CameraSubject = getChar() or player.Character 
	end

	for _, c in ipairs(connections) do
		pcall(function() c:Disconnect() end)
	end
	table.clear(connections)
	gui:Destroy()
end)
