--[[
    Advanced ESP System v2.1.0
    
    This module handles all ESP (Extra Sensory Perception) and visual chams:
    - 2D Bounding Boxes (8-corner 3D-to-2D projection - never collapses or distorts)
    - Mathematically centered tracers (Bottom, Center, Top origins)
    - Bone Skeleton ESP for both R6 and R15 character rigs
    - Dynamic Health Bars with color gradient & health text
    - Player Names, DisplayNames, Distance labels, and Equipped Weapon detection
    - Head Dot indicator
    - Visible vs Occluded color differentiation
    - Target NPC ESP support
    - X-Ray / Wall Chams with pristine cache restoration
    - Full backward compatibility with custom hook extensions (custom_features.lua)
    
    Author: gokuthug1
    License: MIT
]]

local ESP = {}

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Local references
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	Camera = Workspace.CurrentCamera
end)

-- ESP storage
ESP.PlayerESP = {}
ESP.NPC_ESP = {}
ESP.XRayCache = {}
ESP.ScreenGui = nil
ESP.PlayerConnections = {}

-- Color Presets
ESP.ColorPresets = {
	Red = Color3.fromRGB(255, 60, 60),
	Green = Color3.fromRGB(60, 255, 60),
	Blue = Color3.fromRGB(60, 140, 255),
	Purple = Color3.fromRGB(180, 80, 255),
	Yellow = Color3.fromRGB(255, 230, 60),
	White = Color3.fromRGB(255, 255, 255),
}

-- Helper to get global environment
local function getGlobalEnv()
	if type(getgenv) == "function" then
		return getgenv()
	end
	return _G
end

-- Initialize ESP system
function ESP:Initialize()
	self:CreateScreenGui()
	self:SetupPlayerConnections()
	print("👁️ ESP system initialized")
end

-- Helper to get configuration
function ESP:GetConfig()
	local genv = getGlobalEnv()
	if genv.AimbotESP and genv.AimbotESP.Config then
		return genv.AimbotESP.Config.esp or {}, genv.AimbotESP.Config.world or {}
	end
	return {}, {}
end

-- Helper to get Utils component
function ESP:GetUtils()
	local genv = getGlobalEnv()
	if genv.AimbotESP and genv.AimbotESP.Components and genv.AimbotESP.Components.Utils then
		return genv.AimbotESP.Components.Utils
	end
	return nil
end

-- Create main ScreenGui
function ESP:CreateScreenGui()
	if self.ScreenGui then
		self.ScreenGui:Destroy()
	end

	local utils = self:GetUtils()
	local guiParent = utils and utils:GetSafeGuiParent() or game:GetService("CoreGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ESPSystem_V2"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	pcall(function()
		screenGui.Parent = guiParent
	end)

	self.ScreenGui = screenGui
end

-- Setup player join/leave connections
function ESP:SetupPlayerConnections()
	for _, conn in ipairs(self.PlayerConnections) do
		conn:Disconnect()
	end
	self.PlayerConnections = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			self:CreatePlayerESP(player)
		end
	end

	local addedConn = Players.PlayerAdded:Connect(function(player)
		self:CreatePlayerESP(player)
	end)
	table.insert(self.PlayerConnections, addedConn)

	local removedConn = Players.PlayerRemoving:Connect(function(player)
		self:RemovePlayerESP(player)
	end)
	table.insert(self.PlayerConnections, removedConn)
end

-- Helper to draw line using ScreenGui Frame with midpoint rotation
local function drawScreenLine(frame, p1, p2, color, thickness)
	local diff = p2 - p1
	local dist = diff.Magnitude
	if dist < 1 then
		frame.Visible = false
		return
	end
	frame.Size = UDim2.fromOffset(dist, thickness or 1.5)
	frame.Position = UDim2.fromOffset((p1.X + p2.X) / 2, (p1.Y + p2.Y) / 2)
	frame.Rotation = math.deg(math.atan2(diff.Y, diff.X))
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = color
	frame.Visible = true
end

-- Create ESP elements for a player or character
function ESP:CreatePlayerESP(player)
	if self.PlayerESP[player] then
		return self.PlayerESP[player]
	end

	if not self.ScreenGui or not self.ScreenGui.Parent then
		self:CreateScreenGui()
	end

	local espData = {
		player = player,
		character = player.Character,
		connections = {},
		elements = {},
		drawings = {},
	}

	local holder = Instance.new("Frame")
	holder.Name = "ESP_" .. (player.Name or "Target")
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromOffset(100, 100)
	holder.Position = UDim2.fromOffset(0, 0)
	holder.Visible = false
	holder.Parent = self.ScreenGui
	espData.elements.mainFrame = holder

	-- Bounding box
	local boxOutline = Instance.new("Frame")
	boxOutline.Name = "BoxOutline"
	boxOutline.BackgroundTransparency = 1
	boxOutline.BorderSizePixel = 0
	boxOutline.Size = UDim2.fromScale(1, 1)
	boxOutline.Parent = holder

	local boxStroke = Instance.new("UIStroke")
	boxStroke.Name = "BoxStroke"
	boxStroke.Color = Color3.fromRGB(255, 60, 60)
	boxStroke.Thickness = 1.5
	boxStroke.Parent = boxOutline
	espData.elements.boxOutline = boxOutline
	espData.elements.boxStroke = boxStroke

	-- Name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.new(1, 100, 0, 18)
	nameLabel.Position = UDim2.new(0.5, -50, 0, -22)
	nameLabel.Text = player.DisplayName or player.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 12
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.Parent = holder
	espData.elements.nameLabel = nameLabel

	-- Distance label
	local distanceLabel = Instance.new("TextLabel")
	distanceLabel.Name = "DistanceLabel"
	distanceLabel.BackgroundTransparency = 1
	distanceLabel.Size = UDim2.new(1, 100, 0, 15)
	distanceLabel.Position = UDim2.new(0.5, -50, 1, 4)
	distanceLabel.Text = "[0m]"
	distanceLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	distanceLabel.TextSize = 11
	distanceLabel.TextStrokeTransparency = 0.3
	distanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	distanceLabel.Font = Enum.Font.Gotham
	distanceLabel.TextXAlignment = Enum.TextXAlignment.Center
	distanceLabel.Parent = holder
	espData.elements.distanceLabel = distanceLabel

	-- Weapon label
	local weaponLabel = Instance.new("TextLabel")
	weaponLabel.Name = "WeaponLabel"
	weaponLabel.BackgroundTransparency = 1
	weaponLabel.Size = UDim2.new(1, 100, 0, 14)
	weaponLabel.Position = UDim2.new(0.5, -50, 1, 18)
	weaponLabel.Text = "Unarmed"
	weaponLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
	weaponLabel.TextSize = 10
	weaponLabel.TextStrokeTransparency = 0.3
	weaponLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	weaponLabel.Font = Enum.Font.GothamMedium
	weaponLabel.TextXAlignment = Enum.TextXAlignment.Center
	weaponLabel.Parent = holder
	espData.elements.weaponLabel = weaponLabel

	-- Health bar background
	local healthBarBG = Instance.new("Frame")
	healthBarBG.Name = "HealthBarBG"
	healthBarBG.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	healthBarBG.BorderSizePixel = 0
	healthBarBG.Size = UDim2.new(0, 4, 1, 0)
	healthBarBG.Position = UDim2.new(0, -7, 0, 0)
	healthBarBG.Parent = holder
	espData.elements.healthBarBG = healthBarBG

	local healthFill = Instance.new("Frame")
	healthFill.Name = "HealthBar"
	healthFill.BackgroundColor3 = Color3.fromRGB(60, 255, 60)
	healthFill.BorderSizePixel = 0
	healthFill.Size = UDim2.new(1, 0, 1, 0)
	healthFill.Position = UDim2.new(0, 0, 0, 0)
	healthFill.Parent = healthBarBG
	espData.elements.healthBar = healthFill

	-- Health text label
	local healthLabel = Instance.new("TextLabel")
	healthLabel.Name = "HealthLabel"
	healthLabel.BackgroundTransparency = 1
	healthLabel.Size = UDim2.new(0, 30, 0, 12)
	healthLabel.Position = UDim2.new(0, -40, 0, 0)
	healthLabel.Text = "100"
	healthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	healthLabel.TextSize = 10
	healthLabel.TextStrokeTransparency = 0.3
	healthLabel.Font = Enum.Font.GothamBold
	healthLabel.TextXAlignment = Enum.TextXAlignment.Right
	healthLabel.Parent = holder
	espData.elements.healthLabel = healthLabel

	-- Tracer line
	local tracerLine = Instance.new("Frame")
	tracerLine.Name = "TracerLine"
	tracerLine.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
	tracerLine.BorderSizePixel = 0
	tracerLine.Size = UDim2.fromOffset(10, 1.5)
	tracerLine.AnchorPoint = Vector2.new(0.5, 0.5)
	tracerLine.Visible = false
	tracerLine.Parent = self.ScreenGui
	espData.elements.tracerLine = tracerLine

	-- Head dot
	local headDot = Instance.new("Frame")
	headDot.Name = "HeadDot"
	headDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	headDot.BorderSizePixel = 0
	headDot.Size = UDim2.fromOffset(5, 5)
	headDot.AnchorPoint = Vector2.new(0.5, 0.5)
	headDot.Visible = false
	headDot.Parent = self.ScreenGui
	local headCorner = Instance.new("UICorner")
	headCorner.CornerRadius = UDim.new(1, 0)
	headCorner.Parent = headDot
	espData.elements.headDot = headDot

	-- Skeleton lines pool
	local skeletonLines = {}
	for i = 1, 16 do
		local line = Instance.new("Frame")
		line.Name = "Bone_" .. i
		line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		line.BorderSizePixel = 0
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Visible = false
		line.Parent = self.ScreenGui
		table.insert(skeletonLines, line)
	end
	espData.elements.skeleton = skeletonLines

	self.PlayerESP[player] = espData
	return espData
end

-- Remove ESP elements for a player
function ESP:RemovePlayerESP(player)
	local espData = self.PlayerESP[player]
	if not espData then
		return
	end

	for _, conn in ipairs(espData.connections or {}) do
		conn:Disconnect()
	end

	if espData.elements.mainFrame then
		espData.elements.mainFrame:Destroy()
	end
	if espData.elements.tracerLine then
		espData.elements.tracerLine:Destroy()
	end
	if espData.elements.headDot then
		espData.elements.headDot:Destroy()
	end
	if espData.elements.skeleton then
		for _, line in ipairs(espData.elements.skeleton) do
			line:Destroy()
		end
	end

	self.PlayerESP[player] = nil
end

-- Determine target color based on visibility and team
function ESP:GetTargetColor(character, isTeammate)
	local config = self:GetConfig()
	local utils = self:GetUtils()

	local isVis = true
	if utils then
		local root = utils:GetTargetRootPart(character)
		if root then
			isVis = utils:IsPartVisible(root, character)
		end
	end

	if not isVis then
		return config.occludedColor or Color3.fromRGB(120, 120, 120)
	end

	if isTeammate then
		local preset = config.teamColor or "Blue"
		return self.ColorPresets[preset] or Color3.fromRGB(60, 140, 255)
	else
		local preset = config.enemyColor or "Red"
		return self.ColorPresets[preset] or Color3.fromRGB(255, 60, 60)
	end
end

-- Update ESP for a specific player
function ESP:UpdatePlayerESP(player, espData)
	local config = self:GetConfig()
	local utils = self:GetUtils()
	local genv = getGlobalEnv()

	local isEmergency = genv.AimbotESP and genv.AimbotESP.State and genv.AimbotESP.State.EmergencyDisabled
	if not config.enabled or isEmergency or not utils or not utils:IsPlayerAlive(player) then
		espData.elements.mainFrame.Visible = false
		espData.elements.tracerLine.Visible = false
		espData.elements.headDot.Visible = false
		for _, line in ipairs(espData.elements.skeleton or {}) do
			line.Visible = false
		end
		return
	end

	local character = player.Character
	local root = utils:GetTargetRootPart(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		espData.elements.mainFrame.Visible = false
		espData.elements.tracerLine.Visible = false
		espData.elements.headDot.Visible = false
		return
	end

	if not Camera then
		Camera = Workspace.CurrentCamera
	end
	local camPos = Camera and Camera.CFrame.Position or Vector3.zero
	local distance = (camPos - root.Position).Magnitude

	if distance > (config.maxDistance or 600) then
		espData.elements.mainFrame.Visible = false
		espData.elements.tracerLine.Visible = false
		espData.elements.headDot.Visible = false
		for _, line in ipairs(espData.elements.skeleton or {}) do
			line.Visible = false
		end
		return
	end

	local isTeammate = utils:IsTeammate(player)
	if isTeammate and not config.showTeammates then
		espData.elements.mainFrame.Visible = false
		espData.elements.tracerLine.Visible = false
		espData.elements.headDot.Visible = false
		for _, line in ipairs(espData.elements.skeleton or {}) do
			line.Visible = false
		end
		return
	end

	-- Compute 3D bounding box corners projected to 2D
	local bPos, bSize, onScreen = utils:GetBoundingBoxCorners(character)
	if not onScreen or not bPos then
		espData.elements.mainFrame.Visible = false
		espData.elements.tracerLine.Visible = false
		espData.elements.headDot.Visible = false
		for _, line in ipairs(espData.elements.skeleton or {}) do
			line.Visible = false
		end
		return
	end

	local targetColor = self:GetTargetColor(character, isTeammate)

	-- Update Bounding Box & Frame
	espData.elements.mainFrame.Position = UDim2.fromOffset(bPos.X, bPos.Y)
	espData.elements.mainFrame.Size = UDim2.fromOffset(bSize.X, bSize.Y)
	espData.elements.mainFrame.Visible = true

	espData.elements.boxOutline.Visible = (config.boxes ~= false)
	espData.elements.boxStroke.Color = targetColor
	espData.elements.boxStroke.Thickness = config.thickness or 1.5

	-- Update Name Label
	espData.elements.nameLabel.Visible = (config.names ~= false)
	if espData.elements.nameLabel.Visible then
		espData.elements.nameLabel.Text = player.DisplayName or player.Name
		espData.elements.nameLabel.TextColor3 = targetColor
	end

	-- Update Distance Label
	espData.elements.distanceLabel.Visible = (config.distance ~= false)
	if espData.elements.distanceLabel.Visible then
		espData.elements.distanceLabel.Text = "[" .. math.floor(distance) .. "m]"
	end

	-- Update Weapon Label
	espData.elements.weaponLabel.Visible = (config.weapons == true)
	if espData.elements.weaponLabel.Visible then
		local tool = character:FindFirstChildOfClass("Tool")
		espData.elements.weaponLabel.Text = tool and ("🔫 " .. tool.Name) or "👤 Unarmed"
	end

	-- Update Health Bar
	local hpRatio = math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1)
	local hpColor = utils:GetHealthColor(hpRatio * 100)

	espData.elements.healthBarBG.Visible = (config.healthBars ~= false)
	if espData.elements.healthBarBG.Visible then
		espData.elements.healthBar.Size = UDim2.new(1, 0, hpRatio, 0)
		espData.elements.healthBar.Position = UDim2.new(0, 0, 1 - hpRatio, 0)
		espData.elements.healthBar.BackgroundColor3 = hpColor

		espData.elements.healthLabel.Visible = (config.healthText ~= false)
		if espData.elements.healthLabel.Visible then
			espData.elements.healthLabel.Text = tostring(math.floor(humanoid.Health))
			espData.elements.healthLabel.TextColor3 = hpColor
			espData.elements.healthLabel.Position = UDim2.new(0, -35, 1 - hpRatio, -6)
		end
	else
		espData.elements.healthLabel.Visible = false
	end

	-- Update Tracers
	espData.elements.tracerLine.Visible = (config.tracers == true)
	if espData.elements.tracerLine.Visible then
		local viewportSize = Camera.ViewportSize
		local originType = config.tracerOrigin or "Bottom"
		local startPos = Vector2.new(viewportSize.X / 2, viewportSize.Y)
		if originType == "Center" then
			startPos = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
		elseif originType == "Top" then
			startPos = Vector2.new(viewportSize.X / 2, 0)
		end

		local targetPos = Vector2.new(bPos.X + (bSize.X / 2), bPos.Y + bSize.Y)
		drawScreenLine(espData.elements.tracerLine, startPos, targetPos, targetColor, config.thickness or 1.5)
	end

	-- Update Head Dot
	local head = utils:GetTargetHead(character)
	espData.elements.headDot.Visible = (config.headDot == true) and head ~= nil
	if espData.elements.headDot.Visible and head then
		local headScreen, headVis = utils:WorldToScreen(head.Position)
		if headVis then
			espData.elements.headDot.Position = UDim2.fromOffset(headScreen.X, headScreen.Y)
			espData.elements.headDot.BackgroundColor3 = targetColor
			espData.elements.headDot.Visible = true
		else
			espData.elements.headDot.Visible = false
		end
	end

	-- Update Skeleton ESP
	local showSkeleton = (config.skeleton == true)
	local joints = showSkeleton and utils:GetRigJoints(character) or {}
	local lines = espData.elements.skeleton or {}

	for i = 1, #lines do
		local line = lines[i]
		local pair = joints[i]
		if showSkeleton and pair then
			local part1 = character:FindFirstChild(pair[1])
			local part2 = character:FindFirstChild(pair[2])
			if part1 and part2 then
				local p1, vis1 = utils:WorldToScreen(part1.Position)
				local p2, vis2 = utils:WorldToScreen(part2.Position)
				if vis1 or vis2 then
					drawScreenLine(line, p1, p2, targetColor, 1.5)
				else
					line.Visible = false
				end
			else
				line.Visible = false
			end
		else
			line.Visible = false
		end
	end
end

--[[------------------------------------------------------------------------------
    NPC ESP Support
--------------------------------------------------------------------------------]]

function ESP:UpdateNPCEsp()
	local config = self:GetConfig()
	local utils = self:GetUtils()
	if not config.enabled or not config.targetNPCs or not utils then
		for _, data in pairs(self.NPC_ESP) do
			data.elements.mainFrame.Visible = false
			data.elements.tracerLine.Visible = false
			data.elements.headDot.Visible = false
			for _, line in ipairs(data.elements.skeleton or {}) do
				line.Visible = false
			end
		end
		return
	end

	local genv = getGlobalEnv()
	local activeNPCs = genv.AimbotESP and genv.AimbotESP.ActiveNPCs or {}

	for _, npc in ipairs(activeNPCs) do
		if npc and npc.Parent and utils:IsTargetAlive(npc) then
			if not self.NPC_ESP[npc] then
				local dummyPlayer = {
					Name = npc.Name,
					DisplayName = "[NPC] " .. npc.Name,
					Character = npc,
					Team = nil,
				}
				self.NPC_ESP[npc] = self:CreatePlayerESP(dummyPlayer)
			end
			self:UpdatePlayerESP(self.NPC_ESP[npc].player, self.NPC_ESP[npc])
		else
			if self.NPC_ESP[npc] then
				self:RemovePlayerESP(self.NPC_ESP[npc].player)
				self.NPC_ESP[npc] = nil
			end
		end
	end
end

--[[------------------------------------------------------------------------------
    X-Ray / Wall Chams
--------------------------------------------------------------------------------]]

function ESP:SetXRay(enabled, opacity)
	opacity = opacity or 0.5
	for _, part in ipairs(Workspace:GetDescendants()) do
		if part:IsA("BasePart") and not part:FindFirstAncestorOfClass("Model") then
			if enabled then
				if not self.XRayCache[part] then
					self.XRayCache[part] = {
						Transparency = part.Transparency,
						Material = part.Material,
					}
				end
				part.Transparency = opacity
				part.Material = Enum.Material.SmoothPlastic
			elseif self.XRayCache[part] then
				part.Transparency = self.XRayCache[part].Transparency
				part.Material = self.XRayCache[part].Material
				self.XRayCache[part] = nil
			end
		end
	end
end

-- Main update function
function ESP:Update()
	local config, worldConfig = self:GetConfig()
	local genv = getGlobalEnv()

	if worldConfig.xrayEnabled and not self.LastXRayState then
		self:SetXRay(true, worldConfig.xrayOpacity)
		self.LastXRayState = true
	elseif not worldConfig.xrayEnabled and self.LastXRayState then
		self:SetXRay(false)
		self.LastXRayState = false
	end

	if not config.enabled or (genv.AimbotESP and genv.AimbotESP.State and genv.AimbotESP.State.EmergencyDisabled) then
		self:DisableAll()
		return
	end

	for player, espData in pairs(self.PlayerESP) do
		if player and player.Parent then
			self:UpdatePlayerESP(player, espData)
		else
			self:RemovePlayerESP(player)
		end
	end

	self:UpdateNPCEsp()
end

-- Disable all ESP elements
function ESP:DisableAll()
	for _, espData in pairs(self.PlayerESP) do
		if espData.elements.mainFrame then
			espData.elements.mainFrame.Visible = false
		end
		if espData.elements.tracerLine then
			espData.elements.tracerLine.Visible = false
		end
		if espData.elements.headDot then
			espData.elements.headDot.Visible = false
		end
		for _, line in ipairs(espData.elements.skeleton or {}) do
			line.Visible = false
		end
	end
	for _, data in pairs(self.NPC_ESP) do
		if data.elements.mainFrame then
			data.elements.mainFrame.Visible = false
		end
		if data.elements.tracerLine then
			data.elements.tracerLine.Visible = false
		end
		if data.elements.headDot then
			data.elements.headDot.Visible = false
		end
		for _, line in ipairs(data.elements.skeleton or {}) do
			line.Visible = false
		end
	end
end

-- Get ESP statistics
function ESP:GetStats()
	local visibleCount = 0
	local totalCount = 0
	for _, espData in pairs(self.PlayerESP) do
		totalCount = totalCount + 1
		if espData.elements.mainFrame and espData.elements.mainFrame.Visible then
			visibleCount = visibleCount + 1
		end
	end
	return {
		visible = visibleCount,
		total = totalCount,
	}
end

-- Cleanup function
function ESP:Cleanup()
	for _, conn in ipairs(self.PlayerConnections) do
		conn:Disconnect()
	end
	self.PlayerConnections = {}

	for player, _ in pairs(self.PlayerESP) do
		self:RemovePlayerESP(player)
	end
	for npc, _ in pairs(self.NPC_ESP) do
		if self.NPC_ESP[npc] and self.NPC_ESP[npc].player then
			self:RemovePlayerESP(self.NPC_ESP[npc].player)
		end
	end
	self.NPC_ESP = {}

	self:SetXRay(false)

	if self.ScreenGui then
		self.ScreenGui:Destroy()
		self.ScreenGui = nil
	end
end

return ESP
