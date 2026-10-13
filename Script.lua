local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

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

local function categoryButton(parent, text)
	local b = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundColor3 = COLOR_BTN,
		Text = text,
		TextColor3 = COLOR_TEXT,
		Font = PIXEL_FONT,
		TextSize = 11,
		LayoutOrder = nextOrder(),
	}, parent)
	make("UICorner", { CornerRadius = UDim.new(0, 4) }, b)
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
local noclipBtn = categoryButton(playerCat, "")
local invisBtn = categoryButton(playerCat, "")
local floatBtn = categoryButton(playerCat, "")
local infJumpBtn = categoryButton(playerCat, "")
local morphBtn, morphBox = toggleInputRow(playerCat, "Morph", "Username/ID")

local playerEspBtn = categoryButton(visualsCat, "")
local npcEspBtn = categoryButton(visualsCat, "")
local fullBrightBtn = categoryButton(visualsCat, "")
local noFogBtn = categoryButton(visualsCat, "")
local fovBtn, fovBox = toggleInputRow(visualsCat, "FOV", tostring(math.floor(defaultFov + 0.5)))

local freecamBtn, freecamBox = toggleInputRow(worldCat, "Freecam", tostring(freecamSpeed))
local spectateBtn, spectateBox = toggleInputRow(worldCat, "Spectate", "PlayerName")
local tpPlayerBtn, tpPlayerBox = toggleInputRow(worldCat, "TP Player", "PlayerName")
local tpBtn = categoryButton(worldCat, "")
local gravityBtn, gravityBox = toggleInputRow(worldCat, "Gravity", tostring(customGravity))
local antiVoidBtn = categoryButton(worldCat, "")

local invertColorsBtn = categoryButton(funCat, "")
local blackAndWhiteBtn = categoryButton(funCat, "")

local function updateColorEffects()
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

setToggleVisual(invertColorsBtn, "Invert Colors", false)
setToggleVisual(blackAndWhiteBtn, "Black & White", false)

local showPingFpsBtn = categoryButton(settingsTab, "")
local hideHeadersBtn = categoryButton(settingsTab, "")
local disableSoundsBtn = categoryButton(settingsTab, "")
local togglePlayerCatBtn = categoryButton(settingsTab, "")
local toggleVisualsCatBtn = categoryButton(settingsTab, "")
local toggleWorldCatBtn = categoryButton(settingsTab, "")
local toggleFunCatBtn = categoryButton(settingsTab, "")

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
setToggleVisual(playerEspBtn, "Player ESP", false)
setToggleVisual(npcEspBtn, "NPC ESP", false)
setToggleVisual(tpBtn, "Touch TP", false)

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
