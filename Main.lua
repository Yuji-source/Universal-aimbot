local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Core Variables
local aimLockEnabled = false
local rearThreatEnabled = false
local rearDistanceThreshold = 45
local currentPriority = "Closest"
local fovRadius = 250
local cameraSmoothness = 0.35
local currentTarget = nil
local currentColorIndex = 1

-- Customization Variables
local selectedBodyPart = "Head" -- "Head", "Torso", "HumanoidRootPart", "Legs", "Arms"
local fovThickness = 1.5
local fovTransparency = 0 -- 0% to 100%
local targetHighlightEnabled = false

-- Active Separate Buttons References
local separateLockBtn = nil
local separatePriorityBtn = nil
local separateRearBtn = nil
local separateFovBtn = nil

-- Highlight Instance
local currentHighlight = Instance.new("Highlight")
currentHighlight.Name = "TargetLockHighlight"
currentHighlight.FillTransparency = 0.5
currentHighlight.OutlineTransparency = 0

-- Color Palettes
local COLOR_PALETTES = {
	{ Name = "Cyan Neon", Accent = Color3.fromRGB(0, 230, 255), Bg = Color3.fromRGB(12, 14, 20), Surface = Color3.fromRGB(22, 26, 36) },
	{ Name = "Crimson Red", Accent = Color3.fromRGB(255, 45, 85), Bg = Color3.fromRGB(20, 10, 12), Surface = Color3.fromRGB(36, 20, 24) },
	{ Name = "Emerald Green", Accent = Color3.fromRGB(0, 230, 118), Bg = Color3.fromRGB(10, 20, 14), Surface = Color3.fromRGB(18, 36, 24) },
	{ Name = "Cobalt Blue", Accent = Color3.fromRGB(30, 144, 255), Bg = Color3.fromRGB(10, 14, 24), Surface = Color3.fromRGB(20, 26, 40) },
	{ Name = "Stealth Black", Accent = Color3.fromRGB(150, 150, 150), Bg = Color3.fromRGB(5, 5, 5), Surface = Color3.fromRGB(18, 18, 18) },
	{ Name = "Teal Wave", Accent = Color3.fromRGB(0, 206, 209), Bg = Color3.fromRGB(8, 18, 20), Surface = Color3.fromRGB(16, 32, 36) },
	{ Name = "Electric Yellow", Accent = Color3.fromRGB(255, 220, 0), Bg = Color3.fromRGB(20, 20, 10), Surface = Color3.fromRGB(36, 36, 18) },
	{ Name = "Vibrant Orange", Accent = Color3.fromRGB(255, 140, 0), Bg = Color3.fromRGB(22, 14, 8), Surface = Color3.fromRGB(38, 24, 16) },
	{ Name = "Magenta Rush", Accent = Color3.fromRGB(255, 0, 230), Bg = Color3.fromRGB(20, 10, 20), Surface = Color3.fromRGB(36, 18, 36) },
	{ Name = "Royal Purple", Accent = Color3.fromRGB(160, 32, 240), Bg = Color3.fromRGB(16, 10, 24), Surface = Color3.fromRGB(28, 18, 40) },
	{ Name = "Slate Grey", Accent = Color3.fromRGB(180, 190, 200), Bg = Color3.fromRGB(25, 28, 32), Surface = Color3.fromRGB(40, 44, 50) },
	{ Name = "Pure White", Accent = Color3.fromRGB(255, 255, 255), Bg = Color3.fromRGB(15, 15, 18), Surface = Color3.fromRGB(30, 30, 35) },
	{ Name = "Hot Pink", Accent = Color3.fromRGB(255, 105, 180), Bg = Color3.fromRGB(22, 10, 18), Surface = Color3.fromRGB(38, 18, 30) },
	{ Name = "Deep Indigo", Accent = Color3.fromRGB(75, 0, 130), Bg = Color3.fromRGB(12, 8, 20), Surface = Color3.fromRGB(22, 14, 36) },
	{ Name = "Dark Crimson", Accent = Color3.fromRGB(139, 0, 0), Bg = Color3.fromRGB(15, 5, 5), Surface = Color3.fromRGB(28, 10, 10) }
}

local COLOR_BG = COLOR_PALETTES[1].Bg
local COLOR_SURFACE = COLOR_PALETTES[1].Surface
local COLOR_ACCENT = COLOR_PALETTES[1].Accent
local COLOR_TEXT = Color3.fromRGB(240, 245, 255)
local COLOR_OFF = Color3.fromRGB(220, 50, 70)
local COLOR_ON = Color3.fromRGB(0, 220, 130)

local FONT_MAIN = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

--------------------------------------------------------------------------------
-- GUI CREATION
--------------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FuturisticAimLockGui"
ScreenGui.ResetOnSpawn = false

local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 2)
if not playerGui then playerGui = LocalPlayer end
ScreenGui.Parent = playerGui

local allStrokes = {}
local function applyGlow(object, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or COLOR_ACCENT
	stroke.Thickness = thickness or 1.5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = object
	table.insert(allStrokes, stroke)
	return stroke
end

-- Loading Screen
local LoadingFrame = Instance.new("Frame")
LoadingFrame.Name = "LoadingFrame"
LoadingFrame.Size = UDim2.new(0, 320, 0, 150)
LoadingFrame.Position = UDim2.new(0.5, -160, 0.5, -75)
LoadingFrame.BackgroundColor3 = COLOR_BG
LoadingFrame.BorderSizePixel = 0
LoadingFrame.Parent = ScreenGui
Instance.new("UICorner", LoadingFrame).CornerRadius = UDim.new(0, 12)
applyGlow(LoadingFrame, COLOR_ACCENT, 1.5)

local LoadingLabel = Instance.new("TextLabel")
LoadingLabel.Size = UDim2.new(1, -20, 0, 50)
LoadingLabel.Position = UDim2.new(0, 10, 0, 20)
LoadingLabel.BackgroundTransparency = 1
LoadingLabel.TextColor3 = COLOR_TEXT
LoadingLabel.TextSize = 13
LoadingLabel.Font = FONT_BOLD
LoadingLabel.Text = "INITIALIZING..."
LoadingLabel.Parent = LoadingFrame

local ProgressBarBg = Instance.new("Frame")
ProgressBarBg.Size = UDim2.new(1, -40, 0, 8)
ProgressBarBg.Position = UDim2.new(0, 20, 1, -35)
ProgressBarBg.BackgroundColor3 = COLOR_SURFACE
ProgressBarBg.BorderSizePixel = 0
ProgressBarBg.Parent = LoadingFrame
Instance.new("UICorner", ProgressBarBg).CornerRadius = UDim.new(0, 4)

local ProgressBar = Instance.new("Frame")
ProgressBar.Size = UDim2.new(0, 0, 1, 0)
ProgressBar.BackgroundColor3 = COLOR_ACCENT
ProgressBar.BorderSizePixel = 0
ProgressBar.Parent = ProgressBarBg
Instance.new("UICorner", ProgressBar).CornerRadius = UDim.new(0, 4)

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 580, 0, 410)
MainFrame.Position = UDim2.new(0.5, -290, 0.5, -205)
MainFrame.BackgroundColor3 = COLOR_BG
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.ClipsDescendants = false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)
applyGlow(MainFrame, COLOR_ACCENT, 1.5)

-- Left Panel
local LeftPanel = Instance.new("Frame")
LeftPanel.Size = UDim2.new(0, 270, 1, -20)
LeftPanel.Position = UDim2.new(0, 10, 0, 10)
LeftPanel.BackgroundTransparency = 1
LeftPanel.Parent = MainFrame

local LeftTitle = Instance.new("TextLabel")
LeftTitle.Size = UDim2.new(1, 0, 0, 30)
LeftTitle.BackgroundTransparency = 1
LeftTitle.Text = "SYSTEM // MAIN CONTROL"
LeftTitle.TextColor3 = COLOR_ACCENT
LeftTitle.TextSize = 13
LeftTitle.Font = FONT_BOLD
LeftTitle.Parent = LeftPanel

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, 0, 0, 34)
ToggleBtn.Position = UDim2.new(0, 0, 0, 35)
ToggleBtn.BackgroundColor3 = COLOR_OFF
ToggleBtn.TextColor3 = COLOR_TEXT
ToggleBtn.Text = "AIM LOCK: OFF"
ToggleBtn.Font = FONT_BOLD
ToggleBtn.TextSize = 12
ToggleBtn.Parent = LeftPanel
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)

local PriorityBtn = Instance.new("TextButton")
PriorityBtn.Size = UDim2.new(1, 0, 0, 34)
PriorityBtn.Position = UDim2.new(0, 0, 0, 74)
PriorityBtn.BackgroundColor3 = COLOR_SURFACE
PriorityBtn.TextColor3 = COLOR_TEXT
PriorityBtn.Text = "Priority: Closest"
PriorityBtn.Font = FONT_MAIN
PriorityBtn.TextSize = 12
PriorityBtn.Parent = LeftPanel
Instance.new("UICorner", PriorityBtn).CornerRadius = UDim.new(0, 8)

local FovBox = Instance.new("TextBox")
FovBox.Size = UDim2.new(1, 0, 0, 34)
FovBox.Position = UDim2.new(0, 0, 0, 113)
FovBox.BackgroundColor3 = COLOR_SURFACE
FovBox.TextColor3 = COLOR_TEXT
FovBox.Text = "FOV Radius: " .. tostring(fovRadius)
FovBox.Font = FONT_MAIN
FovBox.TextSize = 12
FovBox.Parent = LeftPanel
Instance.new("UICorner", FovBox).CornerRadius = UDim.new(0, 8)

local RearToggleBtn = Instance.new("TextButton")
RearToggleBtn.Size = UDim2.new(1, 0, 0, 34)
RearToggleBtn.Position = UDim2.new(0, 0, 0, 152)
RearToggleBtn.BackgroundColor3 = COLOR_OFF
RearToggleBtn.TextColor3 = COLOR_TEXT
RearToggleBtn.Text = "REAR THREAT: OFF"
RearToggleBtn.Font = FONT_BOLD
RearToggleBtn.TextSize = 12
RearToggleBtn.Parent = LeftPanel
Instance.new("UICorner", RearToggleBtn).CornerRadius = UDim.new(0, 8)

local RearDistBox = Instance.new("TextBox")
RearDistBox.Size = UDim2.new(1, 0, 0, 34)
RearDistBox.Position = UDim2.new(0, 0, 0, 191)
RearDistBox.BackgroundColor3 = COLOR_SURFACE
RearDistBox.TextColor3 = COLOR_TEXT
RearDistBox.Text = "Trigger Distance: " .. tostring(rearDistanceThreshold) .. " studs"
RearDistBox.Font = FONT_MAIN
RearDistBox.TextSize = 12
RearDistBox.Parent = LeftPanel
Instance.new("UICorner", RearDistBox).CornerRadius = UDim.new(0, 8)

-- Dropdown Container
local DropdownContainer = Instance.new("Frame")
DropdownContainer.Size = UDim2.new(1, 0, 0, 34)
DropdownContainer.Position = UDim2.new(0, 0, 0, 230)
DropdownContainer.BackgroundColor3 = COLOR_SURFACE
DropdownContainer.ClipsDescendants = true
DropdownContainer.ZIndex = 5
DropdownContainer.Parent = LeftPanel
Instance.new("UICorner", DropdownContainer).CornerRadius = UDim.new(0, 8)

local DropHeader = Instance.new("TextButton")
DropHeader.Size = UDim2.new(1, 0, 0, 34)
DropHeader.BackgroundTransparency = 1
DropHeader.TextColor3 = COLOR_ACCENT
DropHeader.Text = "Separate Button Creator  ▼"
DropHeader.Font = FONT_BOLD
DropHeader.TextSize = 11
DropHeader.ZIndex = 6
DropHeader.Parent = DropdownContainer

local DropList = Instance.new("Frame")
DropList.Size = UDim2.new(1, 0, 0, 136)
DropList.Position = UDim2.new(0, 0, 0, 34)
DropList.BackgroundTransparency = 1
DropList.ZIndex = 5
DropList.Parent = DropdownContainer

local optLock = Instance.new("TextButton")
optLock.Size = UDim2.new(1, 0, 0, 34)
optLock.Position = UDim2.new(0, 0, 0, 0)
optLock.BackgroundColor3 = COLOR_BG
optLock.TextColor3 = COLOR_TEXT
optLock.Text = "• Quick Aim Lock Toggle"
optLock.Font = FONT_MAIN
optLock.TextSize = 11
optLock.ZIndex = 6
optLock.Parent = DropList

local optPriority = Instance.new("TextButton")
optPriority.Size = UDim2.new(1, 0, 0, 34)
optPriority.Position = UDim2.new(0, 0, 0, 34)
optPriority.BackgroundColor3 = COLOR_BG
optPriority.TextColor3 = COLOR_TEXT
optPriority.Text = "• Target Priority Switch"
optPriority.Font = FONT_MAIN
optPriority.TextSize = 11
optPriority.ZIndex = 6
optPriority.Parent = DropList

local optRear = Instance.new("TextButton")
optRear.Size = UDim2.new(1, 0, 0, 34)
optRear.Position = UDim2.new(0, 0, 0, 68)
optRear.BackgroundColor3 = COLOR_BG
optRear.TextColor3 = COLOR_TEXT
optRear.Text = "• Rear Threat Toggle"
optRear.Font = FONT_MAIN
optRear.TextSize = 11
optRear.ZIndex = 6
optRear.Parent = DropList

local optFov = Instance.new("TextButton")
optFov.Size = UDim2.new(1, 0, 0, 34)
optFov.Position = UDim2.new(0, 0, 0, 102)
optFov.BackgroundColor3 = COLOR_BG
optFov.TextColor3 = COLOR_TEXT
optFov.Text = "• Dynamic FOV Toggle"
optFov.Font = FONT_MAIN
optFov.TextSize = 11
optFov.ZIndex = 6
optFov.Parent = DropList

-- Right Panel (Customization)
local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(0, 270, 1, -20)
RightPanel.Position = UDim2.new(0, 300, 0, 10)
RightPanel.BackgroundTransparency = 1
RightPanel.Parent = MainFrame

local RightTitle = Instance.new("TextLabel")
RightTitle.Size = UDim2.new(1, 0, 0, 30)
RightTitle.BackgroundTransparency = 1
RightTitle.Text = "SYSTEM // CUSTOMIZATION"
RightTitle.TextColor3 = COLOR_ACCENT
RightTitle.TextSize = 13
RightTitle.Font = FONT_BOLD
RightTitle.Parent = RightPanel

local ThemeBtn = Instance.new("TextButton")
ThemeBtn.Size = UDim2.new(1, 0, 0, 34)
ThemeBtn.Position = UDim2.new(0, 0, 0, 35)
ThemeBtn.BackgroundColor3 = COLOR_SURFACE
ThemeBtn.TextColor3 = COLOR_TEXT
ThemeBtn.Text = "Theme: Cyan Neon"
ThemeBtn.Font = FONT_MAIN
ThemeBtn.TextSize = 12
ThemeBtn.Parent = RightPanel
Instance.new("UICorner", ThemeBtn).CornerRadius = UDim.new(0, 8)

-- Body Part Selector
local BodyPartBtn = Instance.new("TextButton")
BodyPartBtn.Size = UDim2.new(1, 0, 0, 34)
BodyPartBtn.Position = UDim2.new(0, 0, 0, 74)
BodyPartBtn.BackgroundColor3 = COLOR_SURFACE
BodyPartBtn.TextColor3 = COLOR_TEXT
BodyPartBtn.Text = "Aim Part: Head"
BodyPartBtn.Font = FONT_MAIN
BodyPartBtn.TextSize = 12
BodyPartBtn.Parent = RightPanel
Instance.new("UICorner", BodyPartBtn).CornerRadius = UDim.new(0, 8)

-- FOV Thickness Input Box
local FovThicknessBox = Instance.new("TextBox")
FovThicknessBox.Size = UDim2.new(1, 0, 0, 34)
FovThicknessBox.Position = UDim2.new(0, 0, 0, 113)
FovThicknessBox.BackgroundColor3 = COLOR_SURFACE
FovThicknessBox.TextColor3 = COLOR_TEXT
FovThicknessBox.Text = "FOV Thickness: " .. tostring(fovThickness)
FovThicknessBox.Font = FONT_MAIN
FovThicknessBox.TextSize = 12
FovThicknessBox.Parent = RightPanel
Instance.new("UICorner", FovThicknessBox).CornerRadius = UDim.new(0, 8)

-- FOV Transparency Input Box
local FovTransBox = Instance.new("TextBox")
FovTransBox.Size = UDim2.new(1, 0, 0, 34)
FovTransBox.Position = UDim2.new(0, 0, 0, 152)
FovTransBox.BackgroundColor3 = COLOR_SURFACE
FovTransBox.TextColor3 = COLOR_TEXT
FovTransBox.Text = "FOV Transparency: " .. tostring(fovTransparency) .. "%"
FovTransBox.Font = FONT_MAIN
FovTransBox.TextSize = 12
FovTransBox.Parent = RightPanel
Instance.new("UICorner", FovTransBox).CornerRadius = UDim.new(0, 8)

-- Target Highlight Toggle
local HighlightBtn = Instance.new("TextButton")
HighlightBtn.Size = UDim2.new(1, 0, 0, 34)
HighlightBtn.Position = UDim2.new(0, 0, 0, 191)
HighlightBtn.BackgroundColor3 = COLOR_OFF
HighlightBtn.TextColor3 = COLOR_TEXT
HighlightBtn.Text = "TARGET HIGHLIGHT: OFF"
HighlightBtn.Font = FONT_BOLD
HighlightBtn.TextSize = 12
HighlightBtn.Parent = RightPanel
Instance.new("UICorner", HighlightBtn).CornerRadius = UDim.new(0, 8)

local SmoothnessBtn = Instance.new("TextButton")
SmoothnessBtn.Size = UDim2.new(1, 0, 0, 34)
SmoothnessBtn.Position = UDim2.new(0, 0, 0, 230)
SmoothnessBtn.BackgroundColor3 = COLOR_SURFACE
SmoothnessBtn.TextColor3 = COLOR_TEXT
SmoothnessBtn.Text = "Camera Smoothness: " .. string.format("%.2f", cameraSmoothness)
SmoothnessBtn.Font = FONT_MAIN
SmoothnessBtn.TextSize = 12
SmoothnessBtn.Parent = RightPanel
Instance.new("UICorner", SmoothnessBtn).CornerRadius = UDim.new(0, 8)

local DragToggleButton = Instance.new("TextButton")
DragToggleButton.Size = UDim2.new(0, 110, 0, 36)
DragToggleButton.Position = UDim2.new(0.05, 0, 0.15, 0)
DragToggleButton.BackgroundColor3 = COLOR_BG
DragToggleButton.TextColor3 = COLOR_ACCENT
DragToggleButton.Text = "MENU [//]"
DragToggleButton.Font = FONT_BOLD
DragToggleButton.TextSize = 12
DragToggleButton.Visible = false
DragToggleButton.Parent = ScreenGui
Instance.new("UICorner", DragToggleButton).CornerRadius = UDim.new(0, 8)
applyGlow(DragToggleButton, COLOR_ACCENT, 1)

--------------------------------------------------------------------------------
-- FOV CIRCLE RENDERER
--------------------------------------------------------------------------------
local FovCanvas = Instance.new("Frame")
FovCanvas.Name = "FovCanvas"
FovCanvas.AnchorPoint = Vector2.new(0.5, 0.5)
FovCanvas.BackgroundTransparency = 1
FovCanvas.Visible = false
FovCanvas.Parent = ScreenGui

local FovCircleStroke = Instance.new("UIStroke")
FovCircleStroke.Color = COLOR_ACCENT
FovCircleStroke.Thickness = fovThickness
FovCircleStroke.Transparency = fovTransparency / 100
FovCircleStroke.Parent = FovCanvas

local FovCorner = Instance.new("UICorner")
FovCorner.CornerRadius = UDim.new(1, 0)
FovCorner.Parent = FovCanvas

local function updateFovCircle()
	FovCanvas.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
	FovCircleStroke.Color = COLOR_ACCENT
	FovCircleStroke.Thickness = fovThickness
	FovCircleStroke.Transparency = fovTransparency / 100
end
updateFovCircle()

--------------------------------------------------------------------------------
-- DRAG LOGIC
--------------------------------------------------------------------------------
local function makeDraggable(frame)
	local dragging, dragInput, dragStart, startPos

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)

	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

makeDraggable(MainFrame)
makeDraggable(DragToggleButton)

--------------------------------------------------------------------------------
-- BODY PART RESOLVER (R6 & R15 SUPPORT)
--------------------------------------------------------------------------------
local function getCharacterTargetPart(character)
	if not character then return nil end

	if selectedBodyPart == "Head" then
		return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")

	elseif selectedBodyPart == "Torso" then
		return character:FindFirstChild("UpperTorso") 
			or character:FindFirstChild("Torso") 
			or character:FindFirstChild("HumanoidRootPart")

	elseif selectedBodyPart == "HumanoidRootPart" then
		return character:FindFirstChild("HumanoidRootPart")

	elseif selectedBodyPart == "Legs" then
		return character:FindFirstChild("RightUpperLeg") 
			or character:FindFirstChild("Right Leg") 
			or character:FindFirstChild("LeftUpperLeg") 
			or character:FindFirstChild("Left Leg") 
			or character:FindFirstChild("HumanoidRootPart")

	elseif selectedBodyPart == "Arms" then
		return character:FindFirstChild("RightUpperArm") 
			or character:FindFirstChild("Right Arm") 
			or character:FindFirstChild("LeftUpperArm") 
			or character:FindFirstChild("Left Arm") 
			or character:FindFirstChild("HumanoidRootPart")
	end

	return character:FindFirstChild("HumanoidRootPart")
end

--------------------------------------------------------------------------------
-- TARGETING LOGIC
--------------------------------------------------------------------------------
local function clearTargetAndHighlight()
	currentTarget = nil
	currentHighlight.Parent = nil
	currentHighlight.Adornee = nil
end

local function getValidTargets()
	local targets = {}
	Camera = workspace.CurrentCamera or Camera
	if not Camera then return targets end

	local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	local myChar = LocalPlayer.Character
	if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return targets end

	local myPos = myChar.HumanoidRootPart.Position
	local camCFrame = Camera.CFrame

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				local targetPart = getCharacterTargetPart(player.Character)
				if targetPart then
					local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
					local worldDistance = (targetPart.Position - myPos).Magnitude
					local targetDir = (targetPart.Position - camCFrame.Position).Unit
					local dotProduct = camCFrame.LookVector:Dot(targetDir)
					local isBehind = dotProduct < 0 or screenPos.Z <= 0

					local screenVec = Vector2.new(screenPos.X, screenPos.Y)
					local screenDist = (screenVec - viewportCenter).Magnitude

					table.insert(targets, {
						Player = player,
						Part = targetPart,
						Humanoid = humanoid,
						WorldDistance = worldDistance,
						ScreenDistance = screenDist,
						IsBehind = isBehind,
						OnScre
