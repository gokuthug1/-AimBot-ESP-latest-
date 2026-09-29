--[[
    Utility Functions v2.1.0
    
    This module provides robust, universal utility functions used throughout the system:
    - Mathematical calculations & vector geometry
    - Player and NPC validation and filtering
    - Screen/world coordinate conversions with Viewport support
    - 3D-to-2D bounding box projections (never collapses or inverts)
    - Line-of-sight raycasting with modern Exclude/Blacklist support
    - Joint resolution for R6 and R15 character rigs
    - Color, visual, and Drawing API helpers
    - Universal executor compatibility (Synapse, Krnl, Script-Ware, Fluxus, Wave, Delta, etc.)
    
    Author: gokuthug1
    License: MIT
]]

local Utils = {}

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

-- Local references
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Re-acquire camera if it resets
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	Camera = Workspace.CurrentCamera
end)

--[[------------------------------------------------------------------------------
    Universal Environment Helpers
--------------------------------------------------------------------------------]]

function Utils:GetGenEnv()
	if type(getgenv) == "function" then
		return getgenv()
	end
	return _G
end

function Utils:GetSafeGuiParent()
	local success, hui = pcall(function()
		if type(gethui) == "function" then
			return gethui()
		end
		return nil
	end)
	if success and hui then
		return hui
	end

	local coreGuiSuccess, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if coreGuiSuccess and coreGui then
		local rbxGui = coreGui:FindFirstChild("RobloxGui")
		if rbxGui then
			return rbxGui
		end
		return coreGui
	end

	if LocalPlayer then
		local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if playerGui then
			return playerGui
		end
	end

	return Workspace
end

function Utils:HasDrawingAPI()
	return type(Drawing) == "table" and type(Drawing.new) == "function"
end

function Utils:SafeCreateDrawing(drawingType, properties)
	if not self:HasDrawingAPI() then
		return nil
	end
	local success, obj = pcall(function()
		local d = Drawing.new(drawingType)
		if properties then
			for k, v in pairs(properties) do
				d[k] = v
			end
		end
		return d
	end)
	if success then
		return obj
	end
	return nil
end

--[[------------------------------------------------------------------------------
    Mathematical & Geometry Utilities
--------------------------------------------------------------------------------]]

function Utils:GetDistance(pos1, pos2)
	return (pos1 - pos2).Magnitude
end

function Utils:GetDistance2D(pos1, pos2)
	local diff = pos1 - pos2
	return math.sqrt(diff.X ^ 2 + diff.Y ^ 2)
end

function Utils:Clamp(value, minVal, maxVal)
	return math.max(minVal, math.min(maxVal, value))
end

function Utils:Lerp(a, b, t)
	return a + (b - a) * t
end

function Utils:Round(number, decimals)
	decimals = decimals or 0
	local mult = 10 ^ decimals
	return math.floor(number * mult + 0.5) / mult
end

function Utils:AngleBetween(pos1, pos2)
	local diff = pos2 - pos1
	return math.atan2(diff.Z, diff.X)
end

function Utils:GetGuiInset()
	local success, inset = pcall(function()
		return GuiService:GetGuiInset()
	end)
	if success and inset then
		return inset
	end
	return Vector2.zero
end

--[[------------------------------------------------------------------------------
    Screen / World Coordinate Conversions
--------------------------------------------------------------------------------]]

function Utils:WorldToScreen(position)
	if not Camera then
		Camera = Workspace.CurrentCamera
	end
	if not Camera then
		return Vector2.zero, false
	end
	local point, onScreen = Camera:WorldToViewportPoint(position)
	return Vector2.new(point.X, point.Y), onScreen, point.Z
end

function Utils:WorldToViewport(position)
	return self:WorldToScreen(position)
end

function Utils:ScreenToWorld(screenPosition, distance)
	if not Camera then
		Camera = Workspace.CurrentCamera
	end
	if not Camera then
		return Vector3.zero
	end
	local ray = Camera:ViewportPointToRay(screenPosition.X, screenPosition.Y)
	return ray.Origin + (ray.Direction * (distance or 1000))
end

function Utils:GetScreenCenter()
	if not Camera then
		Camera = Workspace.CurrentCamera
	end
	if not Camera then
		return Vector2.new(960, 540)
	end
	local viewportSize = Camera.ViewportSize
	return Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
end

function Utils:IsOnScreen(position, margin)
	margin = margin or 0
	local screenPos, onScreen = self:WorldToScreen(position)
	if not onScreen then
		return false
	end

	if not Camera then
		Camera = Workspace.CurrentCamera
	end
	local viewportSize = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)

	return screenPos.X >= -margin
		and screenPos.X <= viewportSize.X + margin
		and screenPos.Y >= -margin
		and screenPos.Y <= viewportSize.Y + margin
end

--[[------------------------------------------------------------------------------
    3D Bounding Box to 2D Screen Projection
    (Uses 8 3D bounding corners - never collapses or inverts at vertical angles)
--------------------------------------------------------------------------------]]

function Utils:GetBoundingBoxCorners(character)
	if not character or not character.Parent then
		return nil, nil, false
	end
	if not Camera then
		Camera = Workspace.CurrentCamera
	end
	if not Camera then
		return nil, nil, false
	end

	local root = self:GetTargetRootPart(character)
	if not root then
		return nil, nil, false
	end

	local cframe, size = character:GetBoundingBox()
	local halfX, halfY, halfZ = size.X / 2, size.Y / 2, size.Z / 2

	local corners = {
		cframe * CFrame.new(halfX, halfY, halfZ),
		cframe * CFrame.new(-halfX, halfY, halfZ),
		cframe * CFrame.new(halfX, -halfY, halfZ),
		cframe * CFrame.new(-halfX, -halfY, halfZ),
		cframe * CFrame.new(halfX, halfY, -halfZ),
		cframe * CFrame.new(-halfX, halfY, -halfZ),
		cframe * CFrame.new(halfX, -halfY, -halfZ),
		cframe * CFrame.new(-halfX, -halfY, -halfZ),
	}

	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge
	local visibleCorners = 0

	for _, corner in ipairs(corners) do
		local screenPos, onScreen = Camera:WorldToViewportPoint(corner.Position)
		if onScreen then
			visibleCorners = visibleCorners + 1
		end
		if screenPos.X < minX then
			minX = screenPos.X
		end
		if screenPos.Y < minY then
			minY = screenPos.Y
		end
		if screenPos.X > maxX then
			maxX = screenPos.X
		end
		if screenPos.Y > maxY then
			maxY = screenPos.Y
		end
	end

	if visibleCorners > 0 then
		local width = math.max(1, maxX - minX)
		local height = math.max(1, maxY - minY)
		return Vector2.new(minX, minY), Vector2.new(width, height), true
	end

	return nil, nil, false
end

--[[------------------------------------------------------------------------------
    Target & Player Validation
--------------------------------------------------------------------------------]]

function Utils:GetTargetRootPart(character)
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
		or character.PrimaryPart
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("UpperTorso")
end

function Utils:GetTargetHead(character)
	if not character then
		return nil
	end
	return character:FindFirstChild("Head")
end

function Utils:GetPartVelocity(part)
	if not part then
		return Vector3.zero
	end
	local success, vel = pcall(function()
		return part.AssemblyLinearVelocity or part.Velocity or Vector3.zero
	end)
	if success and vel then
		return vel
	end
	return Vector3.zero
end

function Utils:IsTargetAlive(character)
	if not character or not character.Parent then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	local root = self:GetTargetRootPart(character)
	return root ~= nil
end

function Utils:IsPlayerAlive(player)
	if not player or not player.Parent then
		return false
	end
	return self:IsTargetAlive(player.Character)
end

function Utils:GetHealthPercentage(target)
	local character = typeof(target) == "Instance" and (target:IsA("Player") and target.Character or target) or nil
	if not character then
		return 0
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.MaxHealth <= 0 then
		return 0
	end
	return self:Clamp((humanoid.Health / humanoid.MaxHealth) * 100, 0, 100)
end

function Utils:IsTeammate(player)
	if not LocalPlayer or not player then
		return false
	end
	if player == LocalPlayer then
		return true
	end
	if LocalPlayer.Team ~= nil and player.Team ~= nil then
		return LocalPlayer.Team == player.Team
	end
	if LocalPlayer.TeamColor ~= nil and player.TeamColor ~= nil then
		return LocalPlayer.TeamColor == player.TeamColor
	end
	return false
end

--[[------------------------------------------------------------------------------
    Line of Sight & Raycasting
--------------------------------------------------------------------------------]]

function Utils:HasLineOfSight(from, to, ignoreList)
	if not Camera then
		Camera = Workspace.CurrentCamera
	end
	local rayParams = RaycastParams.new()

	local filterType = Enum.RaycastFilterType.Exclude
	if not filterType then
		filterType = Enum.RaycastFilterType.Blacklist
	end
	rayParams.FilterType = filterType
	rayParams.IgnoreWater = true

	local filterDescendants = { Camera }
	if LocalPlayer and LocalPlayer.Character then
		table.insert(filterDescendants, LocalPlayer.Character)
	end
	if ignoreList then
		for _, inst in ipairs(ignoreList) do
			if typeof(inst) == "Instance" then
				table.insert(filterDescendants, inst)
			end
		end
	end
	rayParams.FilterDescendantsInstances = filterDescendants

	local direction = to - from
	local result = Workspace:Raycast(from, direction, rayParams)
	return result == nil
end

function Utils:IsPartVisible(targetPart, targetCharacter)
	if not targetPart or not targetCharacter then
		return false
	end
	if not Camera then
		Camera = Workspace.CurrentCamera
	end
	local rayParams = RaycastParams.new()
	local filterType = Enum.RaycastFilterType.Exclude
	if not filterType then
		filterType = Enum.RaycastFilterType.Blacklist
	end
	rayParams.FilterType = filterType
	rayParams.IgnoreWater = true

	local filterDescendants = { Camera }
	if LocalPlayer and LocalPlayer.Character then
		table.insert(filterDescendants, LocalPlayer.Character)
	end
	rayParams.FilterDescendantsInstances = filterDescendants

	local origin = Camera.CFrame.Position
	local direction = targetPart.Position - origin
	local result = Workspace:Raycast(origin, direction, rayParams)

	if not result then
		return true
	end
	return result.Instance:IsDescendantOf(targetCharacter)
end

function Utils:IsPlayerVisible(player, fromPosition)
	if not self:IsPlayerAlive(player) then
		return false
	end
	local character = player.Character
	local root = self:GetTargetRootPart(character)
	if not root then
		return false
	end
	return self:IsPartVisible(root, character)
end

--[[------------------------------------------------------------------------------
    Target Filtering & Prioritization
--------------------------------------------------------------------------------]]

function Utils:GetValidTargets(options)
	options = options or {}
	local targets = {}
	local genv = self:GetGenEnv()
	local config = (genv.AimbotESP and genv.AimbotESP.Config) or {}
	local aimbotConfig = config.aimbot or {}

	local teamCheck = options.teamCheck ~= nil and options.teamCheck or (aimbotConfig.teamCheck ~= false)
	local targetNPCs = options.targetNPCs ~= nil and options.targetNPCs or (aimbotConfig.targetNPCs == true)
	local maxDistance = options.maxDistance or aimbotConfig.maxDistance or 1500
	local visibilityCheck = options.visibilityCheck ~= nil and options.visibilityCheck
		or (aimbotConfig.visibilityCheck == true)

	if not Camera then
		Camera = Workspace.CurrentCamera
	end
	local camPos = Camera and Camera.CFrame.Position or Vector3.zero

	-- 1. Gather Players
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and self:IsPlayerAlive(player) then
			if not (teamCheck and self:IsTeammate(player)) then
				local character = player.Character
				local root = self:GetTargetRootPart(character)
				if root then
					local dist = (camPos - root.Position).Magnitude
					if dist <= maxDistance then
						local isVis = self:IsPartVisible(root, character)
						if not visibilityCheck or isVis then
							local humanoid = character:FindFirstChildOfClass("Humanoid")
							table.insert(targets, {
								player = player,
								character = character,
								distance = dist,
								health = humanoid.Health,
								maxHealth = humanoid.MaxHealth,
								position = root.Position,
								velocity = self:GetPartVelocity(root),
								isNPC = false,
								isVisible = isVis,
							})
						end
					end
				end
			end
		end
	end

	-- 2. Gather NPCs if enabled
	if targetNPCs then
		local activeNPCs = genv.AimbotESP and genv.AimbotESP.ActiveNPCs or {}
		for _, npc in ipairs(activeNPCs) do
			if npc and npc.Parent and self:IsTargetAlive(npc) then
				local root = self:GetTargetRootPart(npc)
				if root then
					local dist = (camPos - root.Position).Magnitude
					if dist <= maxDistance then
						local isVis = self:IsPartVisible(root, npc)
						if not visibilityCheck or isVis then
							local humanoid = npc:FindFirstChildOfClass("Humanoid")
							table.insert(targets, {
								player = nil,
								character = npc,
								distance = dist,
								health = humanoid.Health,
								maxHealth = humanoid.MaxHealth,
								position = root.Position,
								velocity = self:GetPartVelocity(root),
								isNPC = true,
								isVisible = isVis,
							})
						end
					end
				end
			end
		end
	end

	return targets
end

function Utils:CalculateThreatLevel(target)
	local distanceFactor = math.max(0, 1 - (target.distance / 500))
	local healthFactor = (target.health / math.max(1, target.maxHealth))
	local velocityFactor = math.min(1, target.velocity.Magnitude / 50)
	return (distanceFactor * 0.5) + (healthFactor * 0.3) + (velocityFactor * 0.2)
end

function Utils:SortTargetsByPriority(targets, priorityMode, aimPartName)
	priorityMode = priorityMode or "Distance"
	aimPartName = aimPartName or "Head"

	if priorityMode == "Distance" then
		table.sort(targets, function(a, b)
			return a.distance < b.distance
		end)
	elseif priorityMode == "Health" then
		table.sort(targets, function(a, b)
			return a.health < b.health
		end)
	elseif priorityMode == "Threat" then
		table.sort(targets, function(a, b)
			return self:CalculateThreatLevel(a) > self:CalculateThreatLevel(b)
		end)
	elseif priorityMode == "Crosshair" or priorityMode == "FOV" then
		local screenCenter = self:GetScreenCenter()
		table.sort(targets, function(a, b)
			local partA = a.character:FindFirstChild(aimPartName) or self:GetTargetRootPart(a.character)
			local partB = b.character:FindFirstChild(aimPartName) or self:GetTargetRootPart(b.character)
			if not partA or not partB then
				return a.distance < b.distance
			end
			local screenA = self:WorldToScreen(partA.Position)
			local screenB = self:WorldToScreen(partB.Position)
			return (screenA - screenCenter).Magnitude < (screenB - screenCenter).Magnitude
		end)
	end

	return targets
end

--[[------------------------------------------------------------------------------
    Color & Rig Utilities
--------------------------------------------------------------------------------]]

function Utils:GetHealthColor(healthPercent)
	local ratio = self:Clamp(healthPercent / 100, 0, 1)
	return Color3.fromRGB(math.floor(255 * (1 - ratio)), math.floor(255 * ratio), 30)
end

function Utils:GetTeamColor(player)
	if player and player.Team then
		return player.Team.TeamColor.Color
	end
	return Color3.fromRGB(255, 255, 255)
end

function Utils:GetDistanceColor(distance, maxDistance)
	local ratio = math.min(1, distance / maxDistance)
	if ratio < 0.3 then
		return Color3.fromRGB(255, 60, 60)
	elseif ratio < 0.6 then
		return Color3.fromRGB(255, 220, 50)
	else
		return Color3.fromRGB(60, 255, 60)
	end
end

function Utils:HSVtoRGB(h, s, v)
	return Color3.fromHSV(h, s, v)
end

function Utils:GetRigJoints(character)
	if not character then
		return {}
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local isR15 = humanoid and humanoid.RigType == Enum.HumanoidRigType.R15

	if isR15 then
		return {
			{ "Head", "UpperTorso" },
			{ "UpperTorso", "LowerTorso" },
			{ "UpperTorso", "LeftUpperArm" },
			{ "LeftUpperArm", "LeftLowerArm" },
			{ "LeftLowerArm", "LeftHand" },
			{ "UpperTorso", "RightUpperArm" },
			{ "RightUpperArm", "RightLowerArm" },
			{ "RightLowerArm", "RightHand" },
			{ "LowerTorso", "LeftUpperLeg" },
			{ "LeftUpperLeg", "LeftLowerLeg" },
			{ "LeftLowerLeg", "LeftFoot" },
			{ "LowerTorso", "RightUpperLeg" },
			{ "RightUpperLeg", "RightLowerLeg" },
			{ "RightUpperLeg", "RightFoot" },
		}
	else
		return {
			{ "Head", "Torso" },
			{ "Torso", "Left Arm" },
			{ "Torso", "Right Arm" },
			{ "Torso", "Left Leg" },
			{ "Torso", "Right Leg" },
		}
	end
end

return Utils
