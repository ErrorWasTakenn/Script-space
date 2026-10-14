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
