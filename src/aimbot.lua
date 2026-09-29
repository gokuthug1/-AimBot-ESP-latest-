--[[
    Advanced AimBot & TriggerBot System v2.1.0
    
    This module handles all aimbot and automated trigger functionality:
    - Universal target selection & prioritization (Distance, Health, Threat, Crosshair)
    - Multi-mode aiming: Camera CFrame lerp (essential for FPS/LockCenter), MouseMoveRel, and Hybrid
    - Velocity prediction & smart part targeting (Head, Torso, Smart, HumanoidRootPart)
    - Dual-engine FOV circle (Drawing API with ScreenGui fallback)
    - Full TriggerBot with universal click simulation (mouse1click, VirtualInputManager, Tool:Activate)
    - Target Reticle / Indicator visualization
    - Integration with Anti-Detection & Humanized movement
    
    Author: gokuthug1
    License: MIT
]]

local Aimbot = {}

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Local references
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	Camera = Workspace.CurrentCamera
end)

-- Aimbot state
Aimbot.CurrentTarget = nil
Aimbot.LockedTarget = nil
Aimbot.IsAiming = false
Aimbot.LastTriggerTime = 0
Aimbot.FOVCircle = nil
Aimbot.FOVDrawing = nil
Aimbot.TargetIndicator = nil
Aimbot.InputConnections = {}

-- Helper to get global environment
local function getGlobalEnv()
	if type(getgenv) == "function" then
		return getgenv()
	end
	return _G
end

-- Initialize aimbot system
function Aimbot:Initialize()
	self:CreateFOVCircle()
	self:CreateTargetIndicator()
	self:SetupInputHandling()
	print("🎯 AimBot & TriggerBot system initialized")
end

-- Helper to get configuration
function Aimbot:GetConfig()
	local genv = getGlobalEnv()
	if genv.AimbotESP and genv.AimbotESP.Config then
		return genv.AimbotESP.Config.aimbot or {}, genv.AimbotESP.Config.triggerBot or {}
	end
	return {}, {}
end

-- Helper to get Utils component
function Aimbot:GetUtils()
	local genv = getGlobalEnv()
	if genv.AimbotESP and genv.AimbotESP.Components and genv.AimbotESP.Components.Utils then
		return genv.AimbotESP.Components.Utils
	end
	-- Fallback to local require if standalone
	return nil
end

-- Helper to get AntiDetection component
function Aimbot:GetAntiDetection()
	local genv = getGlobalEnv()
	if genv.AimbotESP and genv.AimbotESP.Components and genv.AimbotESP.Components.AntiDetection then
		return genv.AimbotESP.Components.AntiDetection
	end
	return nil
end

--[[------------------------------------------------------------------------------
    FOV Circle Visualization (Drawing API + ScreenGui Fallback)
--------------------------------------------------------------------------------]]

function Aimbot:CreateFOVCircle()
	local utils = self:GetUtils()
	local config = self:GetConfig()

	-- Try Drawing API first
	if utils and utils:HasDrawingAPI() and (config.useDrawingAPI ~= false) then
		local circle = utils:SafeCreateDrawing("Circle", {
			Thickness = 1.5,
			Color = Color3.fromRGB(255, 255, 255),
			Transparency = 0.8,
			Filled = false,
			Visible = false,
			Radius = 100,
			Position = Vector2.new(960, 540),
		})
		if circle then
			self.FOVDrawing = circle
			return
		end
	end

	-- ScreenGui Fallback
	local guiParent = utils and utils:GetSafeGuiParent() or game:GetService("CoreGui")
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AimbotFOV_Gui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	pcall(function()
		screenGui.Parent = guiParent
	end)

	local circle = Instance.new("Frame")
	circle.Name = "FOVCircle"
	circle.BackgroundTransparency = 1
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.Size = UDim2.fromOffset(200, 200)
	circle.Position = UDim2.fromScale(0.5, 0.5)
	circle.Parent = screenGui

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.3
	stroke.Parent = circle

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = circle

	self.FOVCircle = circle
end

function Aimbot:CreateTargetIndicator()
	local utils = self:GetUtils()
	local guiParent = utils and utils:GetSafeGuiParent() or game:GetService("CoreGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AimbotIndicator_Gui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	pcall(function()
		screenGui.Parent = guiParent
	end)

	local indicator = Instance.new("ImageLabel")
	indicator.Name = "TargetIndicator"
	indicator.Size = UDim2.fromOffset(36, 36)
	indicator.AnchorPoint = Vector2.new(0.5, 0.5)
	indicator.BackgroundTransparency = 1
	indicator.Image = "rbxassetid://286214217"
	indicator.ImageColor3 = Color3.fromRGB(255, 50, 50)
	indicator.ZIndex = 10
	indicator.Visible = false
	indicator.Parent = screenGui

	self.TargetIndicator = indicator
end

function Aimbot:UpdateFOVCircle()
	local config = self:GetConfig()
	local utils = self:GetUtils()
	local antiDetection = self:GetAntiDetection()

	local isStealth = antiDetection and antiDetection:GetConfig().stealthMode
	local isVisible = config.enabled and config.showFOV and not isStealth

	if not Camera then
		Camera = Workspace.CurrentCamera
	end
	local viewportSize = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
	local center = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)

	-- In unlocked mouse mode, center circle around mouse cursor
	if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
		local mousePos = UserInputService:GetMouseLocation()
		center = mousePos
	end

	local fov = config.fov or 120
	local fovRadius = math.tan(math.rad(fov / 2)) * (viewportSize.Y / 2)

	-- Update Drawing Circle
	if self.FOVDrawing then
		self.FOVDrawing.Visible = isVisible
		if isVisible then
			self.FOVDrawing.Position = center
			self.FOVDrawing.Radius = fovRadius
		end
	end

	-- Update ScreenGui Circle
	if self.FOVCircle then
		self.FOVCircle.Visible = isVisible
		if isVisible then
			self.FOVCircle.Size = UDim2.fromOffset(fovRadius * 2, fovRadius * 2)
			self.FOVCircle.Position = UDim2.fromOffset(center.X, center.Y)
		end
	end
end

--[[------------------------------------------------------------------------------
    Input Handling
--------------------------------------------------------------------------------]]

function Aimbot:SetupInputHandling()
	for _, conn in ipairs(self.InputConnections) do
		conn:Disconnect()
	end
	self.InputConnections = {}

	local beganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		local config = self:GetConfig()
		local aimKey = config.aimKey or Enum.UserInputType.MouseButton2

		if (input.UserInputType == aimKey or input.KeyCode == aimKey) and config.enabled then
			self.IsAiming = true
		end
	end)
	table.insert(self.InputConnections, beganConn)

	local endedConn = UserInputService.InputEnded:Connect(function(input)
		local config = self:GetConfig()
		local aimKey = config.aimKey or Enum.UserInputType.MouseButton2

		if input.UserInputType == aimKey or input.KeyCode == aimKey then
			self.IsAiming = false
			self.LockedTarget = nil
			self.CurrentTarget = nil
		end
	end)
	table.insert(self.InputConnections, endedConn)
end

--[[------------------------------------------------------------------------------
    Target & Part Selection
--------------------------------------------------------------------------------]]

function Aimbot:GetTargetPart(character, targetMode)
	if not character then
		return nil
	end
	targetMode = targetMode or "Head"

	if targetMode == "Head" then
		return character:FindFirstChild("Head") or character.PrimaryPart
	elseif targetMode == "Torso" then
		return character:FindFirstChild("Torso")
			or character:FindFirstChild("UpperTorso")
			or character:FindFirstChild("HumanoidRootPart")
			or character.PrimaryPart
	elseif targetMode == "HumanoidRootPart" then
		return character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
	elseif targetMode == "Smart" then
		local head = character:FindFirstChild("Head")
		local torso = character:FindFirstChild("Torso")
			or character:FindFirstChild("UpperTorso")
			or character:FindFirstChild("HumanoidRootPart")

		local utils = self:GetUtils()
		if head and utils and utils:IsPartVisible(head, character) then
			return head
		end
		return torso or head or character.PrimaryPart
	end

	return character:FindFirstChild("Head") or character.PrimaryPart
end

function Aimbot:IsInFOV(targetPosition)
	local config = self:GetConfig()
	local utils = self:GetUtils()
	if not utils then
		return false
	end

	local screenPos, onScreen = utils:WorldToScreen(targetPosition)
	if not onScreen then
		return false
	end

	if not Camera then
		Camera = Workspace.CurrentCamera
	end
	local viewportSize = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
	local center = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)

	if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
		center = UserInputService:GetMouseLocation()
	end

	local distance = (screenPos - center).Magnitude
	local fovRadius = math.tan(math.rad((config.fov or 120) / 2)) * (viewportSize.Y / 2)
	return distance <= fovRadius, distance
end

function Aimbot:PredictTargetPosition(targetPart, targetVelocity)
	local config = self:GetConfig()
	if not config.prediction then
		return targetPart.Position
	end

	local predictionTime = config.predictionTime or 0.1
	return targetPart.Position + (targetVelocity * predictionTime)
end

--[[------------------------------------------------------------------------------
    Target Acquisition
--------------------------------------------------------------------------------]]

function Aimbot:FindBestTarget()
	local config = self:GetConfig()
	local utils = self:GetUtils()
	local genv = getGlobalEnv()

	if not config.enabled or not utils then
		return nil
	end
	if genv.AimbotESP and genv.AimbotESP.State and genv.AimbotESP.State.EmergencyDisabled then
		return nil
	end

	-- AimLock: keep lock on existing target if valid
	if config.aimLock and self.LockedTarget and utils:IsTargetAlive(self.LockedTarget.character) then
		local targetPart = self:GetTargetPart(self.LockedTarget.character, config.targetPart)
		if targetPart then
			local inFov, dist = self:IsInFOV(targetPart.Position)
			if inFov then
				self.LockedTarget.targetPart = targetPart
				self.LockedTarget.fovDistance = dist
				return self.LockedTarget
			end
		end
	end

	local targets = utils:GetValidTargets({
		teamCheck = config.teamCheck,
		targetNPCs = config.targetNPCs,
		maxDistance = config.maxDistance,
		visibilityCheck = config.visibilityCheck,
	})

	if #targets == 0 then
		return nil
	end

	-- Filter targets by FOV
	local fovTargets = {}
	for _, target in ipairs(targets) do
		local targetPart = self:GetTargetPart(target.character, config.targetPart)
		if targetPart then
			local inFov, fovDist = self:IsInFOV(targetPart.Position)
			if inFov then
				target.targetPart = targetPart
				target.fovDistance = fovDist
				table.insert(fovTargets, target)
			end
		end
	end

	if #fovTargets == 0 then
		return nil
	end

	-- Sort targets by configured priority mode
	local sorted = utils:SortTargetsByPriority(fovTargets, config.priorityMode, config.targetPart)
	local best = sorted[1]
	if best and config.aimLock then
		self.LockedTarget = best
	end

	return best
end

--[[------------------------------------------------------------------------------
    Smooth Aim Implementation (Camera Lerp + MouseMoveRel + Hybrid)
--------------------------------------------------------------------------------]]

function Aimbot:AimAtTarget(target)
	if not target or not target.targetPart then
		return
	end

	local config = self:GetConfig()
	local utils = self:GetUtils()
	local antiDetection = self:GetAntiDetection()

	if antiDetection and not antiDetection:IsActionAllowed("aim") then
		return
	end

	if not Camera then
		Camera = Workspace.CurrentCamera
	end
	if not Camera then
		return
	end

	local targetVel = target.velocity or (utils and utils:GetPartVelocity(target.targetPart)) or Vector3.zero
	local predictedPosition = self:PredictTargetPosition(target.targetPart, targetVel)

	-- Aim mode selection: Camera, Mouse, or Hybrid
	local aimMode = config.aimMode or "Hybrid"
	local isLockCenter = UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter

	local shouldUseCamera = (aimMode == "Camera") or (aimMode == "Hybrid" and isLockCenter)

	if shouldUseCamera then
		-- Camera CFrame Lerp / Snap
		local targetCFrame = CFrame.new(Camera.CFrame.Position, predictedPosition)
		if config.aggressiveMode then
			Camera.CFrame = targetCFrame
		else
			local smoothness = math.max(1, config.smoothness or 10)
			local factor = 1 / smoothness
			Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, factor)
		end
		if antiDetection then
			antiDetection:RecordAction("aim")
		end
	else
		-- Mouse movement simulation
		if utils then
			local screenPos, onScreen = utils:WorldToScreen(predictedPosition)
			if onScreen then
				local currentMouse = UserInputService:GetMouseLocation()
				local targetMouse = screenPos

				if antiDetection and antiDetection:GetConfig().humanization then
					targetMouse = antiDetection:HumanizeMovement(screenPos, currentMouse, config.smoothness or 10)
				end

				local deltaX = targetMouse.X - currentMouse.X
				local deltaY = targetMouse.Y - currentMouse.Y
				local distance = math.sqrt(deltaX ^ 2 + deltaY ^ 2)

				if distance > 1 then
					local smoothness = math.max(1, config.smoothness or 10)
					local stepX = deltaX / smoothness
					local stepY = deltaY / smoothness

					if type(mousemoverel) == "function" then
						mousemoverel(stepX, stepY)
					elseif type(mousemoveabs) == "function" then
						mousemoveabs(currentMouse.X + stepX, currentMouse.Y + stepY)
					else
						Camera.CFrame =
							Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, predictedPosition), 1 / smoothness)
					end

					if antiDetection then
						antiDetection:RecordAction("aim")
					end
				end
			end
		end
	end
end

--[[------------------------------------------------------------------------------
    Universal TriggerBot (Raycast & Auto-Fire)
--------------------------------------------------------------------------------]]

function Aimbot:UpdateTriggerBot()
	local _, trigConfig = self:GetConfig()
	if not trigConfig.enabled then
		return
	end

	local now = tick()
	local delay = trigConfig.delay or 0.05
	if (now - self.LastTriggerTime) < delay then
		return
	end

	local utils = self:GetUtils()
	local antiDetection = self:GetAntiDetection()

	if antiDetection and not antiDetection:IsActionAllowed("shoot") then
		return
	end

	if not Camera then
		Camera = Workspace.CurrentCamera
	end
	if not Camera then
		return
	end

	local char = LocalPlayer and LocalPlayer.Character
	local currentTool = char and char:FindFirstChildOfClass("Tool")
	if trigConfig.requireTool and not currentTool then
		return
	end

	-- Determine crosshair ray
	local rayX, rayY = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
	if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
		local mousePos = UserInputService:GetMouseLocation()
		rayX, rayY = mousePos.X, mousePos.Y
	end

	local unitRay = Camera:ViewportPointToRay(rayX, rayY)
	local rayParams = RaycastParams.new()
	local filterType = Enum.RaycastFilterType.Exclude
	if not filterType then
		filterType = Enum.RaycastFilterType.Blacklist
	end
	rayParams.FilterType = filterType
	rayParams.IgnoreWater = true

	local filterDescendants = { Camera }
	if char then
		table.insert(filterDescendants, char)
	end
	rayParams.FilterDescendantsInstances = filterDescendants

	local maxDist = trigConfig.maxDistance or 1500
	local hit = Workspace:Raycast(unitRay.Origin, unitRay.Direction * maxDist, rayParams)

	if hit and hit.Instance then
		local hitPart = hit.Instance
		local model = hitPart:FindFirstAncestorOfClass("Model")
		if not model then
			local acc = hitPart:FindFirstAncestorOfClass("Accessory")
			if acc then
				model = acc.Parent
			end
		end

		if model and utils and utils:IsTargetAlive(model) then
			local isValidTarget = false
			local targetPlayer = Players:GetPlayerFromCharacter(model)

			if targetPlayer and targetPlayer ~= LocalPlayer then
				if not (trigConfig.teamCheck and utils:IsTeammate(targetPlayer)) then
					isValidTarget = true
				end
			elseif trigConfig.targetNPCs then
				isValidTarget = true
			end

			if isValidTarget then
				self.LastTriggerTime = now

				-- Activate tool directly if present
				if currentTool then
					pcall(function()
						currentTool:Activate()
					end)
				end

				-- Universal click emulation
				task.spawn(function()
					if type(mouse1click) == "function" then
						mouse1click()
					elseif type(mouse1press) == "function" and type(mouse1release) == "function" then
						mouse1press()
						task.wait(0.015)
						mouse1release()
					else
						local cx = math.floor(rayX)
						local cy = math.floor(rayY)
						pcall(function()
							VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
							task.wait(0.015)
							VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
						end)
					end
				end)

				if antiDetection then
					antiDetection:RecordAction("shoot")
				end
			end
		end
	end
end

--[[------------------------------------------------------------------------------
    Main Update Loop
--------------------------------------------------------------------------------]]

function Aimbot:Update()
	local config = self:GetConfig()
	local utils = self:GetUtils()
	local genv = getGlobalEnv()

	self:UpdateFOVCircle()

	if not config.enabled or (genv.AimbotESP and genv.AimbotESP.State and genv.AimbotESP.State.EmergencyDisabled) then
		self.CurrentTarget = nil
		self.LockedTarget = nil
		if self.TargetIndicator then
			self.TargetIndicator.Visible = false
		end
		return
	end

	if self.IsAiming then
		local target = self:FindBestTarget()
		self.CurrentTarget = target
		if target then
			self:AimAtTarget(target)
		end
	else
		self.CurrentTarget = nil
		self.LockedTarget = nil
	end

	-- Update target indicator reticle
	if self.TargetIndicator then
		if self.CurrentTarget and self.CurrentTarget.targetPart and self.IsAiming and utils then
			local pos, onScreen = utils:WorldToScreen(self.CurrentTarget.targetPart.Position)
			self.TargetIndicator.Visible = onScreen
			if onScreen then
				self.TargetIndicator.Position = UDim2.fromOffset(pos.X, pos.Y)
				if config.targetIndicatorColor then
					self.TargetIndicator.ImageColor3 = config.targetIndicatorColor
				end
			end
		else
			self.TargetIndicator.Visible = false
		end
	end

	-- Run triggerbot
	self:UpdateTriggerBot()
end

-- Get current target info (for GUI display)
function Aimbot:GetCurrentTargetInfo()
	if self.CurrentTarget then
		local name = self.CurrentTarget.player and self.CurrentTarget.player.DisplayName
			or (self.CurrentTarget.character and self.CurrentTarget.character.Name)
			or "Target"
		return {
			name = name,
			distance = math.floor(self.CurrentTarget.distance or 0),
			health = math.floor(self.CurrentTarget.health or 0),
		}
	end
	return nil
end

-- Cleanup function
function Aimbot:Cleanup()
	for _, conn in ipairs(self.InputConnections) do
		conn:Disconnect()
	end
	self.InputConnections = {}

	if self.FOVDrawing then
		pcall(function()
			self.FOVDrawing:Remove()
		end)
		self.FOVDrawing = nil
	end

	if self.FOVCircle and self.FOVCircle.Parent then
		local gui = self.FOVCircle:FindFirstAncestorOfClass("ScreenGui")
		if gui then
			gui:Destroy()
		else
			self.FOVCircle:Destroy()
		end
		self.FOVCircle = nil
	end

	if self.TargetIndicator and self.TargetIndicator.Parent then
		local gui = self.TargetIndicator:FindFirstAncestorOfClass("ScreenGui")
		if gui then
			gui:Destroy()
		else
			self.TargetIndicator:Destroy()
		end
		self.TargetIndicator = nil
	end

	self.CurrentTarget = nil
	self.LockedTarget = nil
	self.IsAiming = false
end

return Aimbot
