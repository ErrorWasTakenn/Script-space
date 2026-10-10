--[[
	Errors Admin (LocalScript)
	Put in: StarterPlayer > StarterPlayerScripts

	Features: 
	  - Fly (with speed box)
	  - Freecam (Camera flies freely, body stays anchored)
	  - Spectate (Partial name search & auto-fill)
	  - TP to Player (Teleports directly to target player)
	  - Walk Speed (Toggle + Box, frame-looped)
	  - Jump Power (Toggle + Box, frame-looped)
	  - Gravity (Toggle + Box)
	  - Full Bright (Lighting override)
	  - No Fog (Clears map fog & atmosphere)
	  - Noclip
	  - Invisible (Teleports character under map once with safety platform)
	  - Float
	  - Infinite Jump
	  - Player ESP & NPC ESP
	  - Touch TP Tool
	  - Unlimited FOV (Toggle + Box)
	  - Gray Theme with Sound Effects & Smooth Tweens (Shortened Compact Window)
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

---------------------------------------------------------------------
-- State
---------------------------------------------------------------------
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
local freecamCFrame = nil
local HIDE_DEPTH = 30

---------------------------------------------------------------------
-- Sound Effect
---------------------------------------------------------------------
local clickSound = Instance.new("Sound")
clickSound.SoundId = "rbxassetid://6895079853"
clickSound.Volume = 0.5
clickSound.Parent = SoundService

local function playDing()
	clickSound:Play()
end

---------------------------------------------------------------------
-- Helper Functions
---------------------------------------------------------------------
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
	for _, p in ipairs(Players:GetPlayers()) do
		local name = string.lower(p.Name)
		local displayName = string.lower(p.DisplayName)
		if string.find(name, query, 1, true) or string.find(displayName, query, 1, true) then
			return p
		end
	end
	return nil
end

---------------------------------------------------------------------
-- UI Setup & Theme (Shortened Window Size)
---------------------------------------------------------------------
local function make(class, props, parent)
	local obj = Instance.new(class)
	for k, v in pairs(props) do
		obj[k] = v
	end
	obj.Parent = parent
	return obj
end

local COLOR_BG = Color3.fromRGB(45, 45, 50)
local COLOR_BAR = Color3.fromRGB(30, 30, 35)
local COLOR_BTN = Color3.fromRGB(65, 65, 70)
local COLOR_ON = Color3.fromRGB(70, 160, 90)
local COLOR_OFF = Color3.fromRGB(180, 60, 60)
local COLOR_TEXT = Color3.fromRGB(240, 240, 245)

local gui = make("ScreenGui", {
	Name = "ErrorsAdmin",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, player:WaitForChild("PlayerGui"))

local FULL_SIZE = UDim2.fromOffset(210, 290)
local MINI_SIZE = UDim2.fromOffset(210, 24)

local window = make("Frame", {
	Name = "Window",
	Size = FULL_SIZE,
	Position = UDim2.new(1, -230, 0, 70),
	BackgroundColor3 = COLOR_BG,
	BorderSizePixel = 0,
	ClipsDescendants = true,
}, gui)
make("UICorner", { CornerRadius = UDim.new(0, 6) }, window)

local titleBar = make("Frame", {
	Name = "TitleBar",
	Size = UDim2.new(1, 0, 0, 22),
	BackgroundColor3 = COLOR_BAR,
	BorderSizePixel = 0,
}, window)

make("TextLabel", {
	Size = UDim2.new(1, -50, 1, 0),
	Position = UDim2.fromOffset(6, 0),
	BackgroundTransparency = 1,
	Text = "Errors Admin",
	TextColor3 = COLOR_TEXT,
	Font = Enum.Font.GothamBold,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
}, titleBar)

local function titleButton(text, xOffset, color)
	local b = make("TextButton", {
		Size = UDim2.fromOffset(18, 16),
		Position = UDim2.new(1, xOffset, 0, 3),
		BackgroundColor3 = color,
		Text = text,
		TextColor3 = COLOR_TEXT,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
	}, titleBar)
	make("UICorner", { CornerRadius = UDim.new(0, 3) }, b)
	return b
end

local minBtn = titleButton("–", -44, COLOR_BTN)
local closeBtn = titleButton("X", -22, Color3.fromRGB(190, 60, 60))

local content = make("ScrollingFrame", {
	Name = "Content",
	Size = UDim2.new(1, -8, 1, -26),
	Position = UDim2.fromOffset(4, 24),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 2,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
}, window)

make("UIListLayout", {
	Padding = UDim.new(0, 3),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, content)
make("UIPadding", { PaddingRight = UDim.new(0, 4), PaddingBottom = UDim.new(0, 3) }, content)

local order = 0
local function nextOrder()
	order += 1
	return order
end

local function button(text)
	local b = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundColor3 = COLOR_BTN,
		Text = text,
		TextColor3 = COLOR_TEXT,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		LayoutOrder = nextOrder(),
	}, content)
	make("UICorner", { CornerRadius = UDim.new(0, 4) }, b)
	return b
end

local function setToggleVisual(btn, name, state)
	btn.Text = name .. ": " .. (state and "ON" or "OFF")
	local targetColor = state and COLOR_ON or COLOR_OFF
	TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = targetColor }):Play()
end

local function toggleInputRow(toggleName, defaultInputText)
	local row = make("Frame", {
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
	}, content)

	local btn = make("TextButton", {
		Size = UDim2.new(0.55, -2, 1, 0),
		BackgroundColor3 = COLOR_OFF,
		Text = toggleName .. ": OFF",
		TextColor3 = COLOR_TEXT,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
	}, row)
	make("UICorner", { CornerRadius = UDim.new(0, 4) }, btn)

	local box = make("TextBox", {
		Size = UDim2.new(0.45, -2, 1, 0),
		Position = UDim2.new(0.55, 2, 0, 0),
		BackgroundColor3 = COLOR_BTN,
		Text = defaultInputText,
		TextColor3 = COLOR_TEXT,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		ClearTextOnFocus = false,
	}, row)
	make("UICorner", { CornerRadius = UDim.new(0, 4) }, box)

	return btn, box
end

---------------------------------------------------------------------
-- UI Controls Creation
---------------------------------------------------------------------
local flyBtn, speedBox = toggleInputRow("Fly", tostring(flySpeed))

local udRow = make("Frame", {
	Size = UDim2.new(1, 0, 0, 22),
	BackgroundTransparency = 1,
	LayoutOrder = nextOrder(),
}, content)

local upBtn = make("TextButton", {
	Size = UDim2.new(0.5, -2, 1, 0),
	BackgroundColor3 = COLOR_BTN,
	Text = "▲ Up",
	TextColor3 = COLOR_TEXT,
	Font = Enum.Font.GothamMedium,
	TextSize = 11,
}, udRow)

local downBtn = make("TextButton", {
	Size = UDim2.new(0.5, -2, 1, 0),
	Position = UDim2.new(0.5, 2, 0, 0),
	BackgroundColor3 = COLOR_BTN,
	Text = "▼ Down",
	TextColor3 = COLOR_TEXT,
	Font = Enum.Font.GothamMedium,
	TextSize = 11,
}, udRow)

make("UICorner", { CornerRadius = UDim.new(0, 4) }, upBtn)
make("UICorner", { CornerRadius = UDim.new(0, 4) }, downBtn)

local freecamBtn = button("")
local spectateBtn, spectateBox = toggleInputRow("Spectate", "PlayerName")
local tpPlayerBtn, tpPlayerBox = toggleInputRow("TP Player", "PlayerName")

local walkSpeedBtn, walkSpeedBox = toggleInputRow("Speed", tostring(customSpeed))
local jumpPowerBtn, jumpPowerBox = toggleInputRow("Jump", tostring(customJump))
local gravityBtn, gravityBox = toggleInputRow("Gravity", tostring(customGravity))

local fullBrightBtn = button("")
local noFogBtn = button("")
local noclipBtn = button("")
local invisBtn = button("")
local floatBtn = button("")
local infJumpBtn = button("")
local playerEspBtn = button("")
local npcEspBtn = button("")
local tpBtn = button("")
local fovBtn, fovBox = toggleInputRow("FOV", tostring(math.floor(defaultFov + 0.5)))

setToggleVisual(freecamBtn, "Freecam", false)
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

---------------------------------------------------------------------
-- Logic Handlers
---------------------------------------------------------------------
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
		if cam then
			freecamCFrame = cam.CFrame
			cam.CameraType = Enum.CameraType.Scriptable
		end
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

local function setFullBright(state)
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

local function setNoFog(state)
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

connect(infJumpBtn.Activated, function()
	playDing()
	infJump = not infJump
	setToggleVisual(infJumpBtn, "Infinite Jump", infJump)
end)

local function restoreCollisions()
	for part in pairs(savedCollide) do
		if part and part.Parent then part.CanCollide = true end
	end
	table.clear(savedCollide)
end

local function setNoclip(state)
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

local function setFloat(state)
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

local function setInvisible(state)
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

connect(playerEspBtn.Activated, function()
	playDing()
	playerEspEnabled = not playerEspEnabled
	setToggleVisual(playerEspBtn, "Player ESP", playerEspEnabled)
	updateEsp()
end)

connect(npcEspBtn.Activated, function()
	playDing()
	npcEspEnabled = not npcEspEnabled
	setToggleVisual(npcEspBtn, "NPC ESP", npcEspEnabled)
	updateEsp()
end)

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
		local _, hrp = getCh
