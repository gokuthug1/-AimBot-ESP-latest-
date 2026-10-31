--[[
    Advanced AimBot & ESP Suite v2.2.0 (Standalone All-In-One Master)
    Zero external dependencies - runs 100% natively offline in any Roblox executor
]]

--[[----------------------------------------------------------------------------------
    Advanced AimBot & ESP Suite v2.1.0 (Universal Native Master)
    
    A sophisticated, modular AimBot, TriggerBot, and ESP system for Roblox:
    - Universal target selection, prediction, smoothing, and aim locking
    - Dual-engine visuals: Drawing API with ScreenGui fallback
    - Multi-mode aim: Camera CFrame (FPS/LockCenter), MouseMoveRel, and Hybrid
    - Advanced ESP: 2D Bounding Boxes, Midpoint Tracers, Skeletons, Health Bars, Head Dots
    - Multi-layered Anti-Detection: humanized Bezier movement, jitter, rate limiting, stealth mode
    - Next-gen UI with real-time themes, minimize-to-pill, and custom background image support
    - Centralized hotkeys: INSERT / RightShift (GUI), F1 (Aim), F2 (ESP), F3 (Tracers), F4 (Target), DELETE (Emergency)
    
    Author: gokuthug1
    License: MIT
------------------------------------------------------------------------------------]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	local startWait = tick()
	while not LocalPlayer and (tick() - startWait) < 5 do
		task.wait(0.1)
		LocalPlayer = Players.LocalPlayer
	end
end

local Camera = Workspace.CurrentCamera

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	Camera = Workspace.CurrentCamera
end)

-- Universal Global Environment
local genv = (type(getgenv) == "function" and getgenv()) or _G

-- Prevent multiple simultaneous instances & handle clean reload
if genv.AimbotESP and genv.AimbotESP.Loaded then
	warn("⚠️ [AimbotESP] Previous instance detected. Performing clean reload...")
	if genv.AimbotESP.Unload then
		pcall(function()
			genv.AimbotESP:Unload()
		end)
	end
	task.wait(0.2)
end

-- Initialize Global Suite Namespace
genv.AimbotESP = {
	Version = "2.1.0",
	BuildDate = "2026-09-28",
	Loaded = false,
	Components = {},
	Config = {},
	State = {
		AimbotEnabled = false,
		ESPEnabled = false,
		GUIVisible = true,
		EmergencyDisabled = false,
		Initialized = false,
	},
	ActiveNPCs = {},
	Connections = {},
	Debug = {
		ErrorCount = 0,
		LastError = nil,
		StartTime = tick(),
	},
}

-- Backward compatibility aliases
genv.AIMBOT_ESP_LOADED = true
genv.UltimateSuiteLoaded = true

--[[------------------------------------------------------------------------------
    Active NPC Detection & Management
--------------------------------------------------------------------------------]]

local function registerNPC(descendant)
	if descendant:IsA("Humanoid") and descendant.Parent and descendant.Parent:IsA("Model") then
		local char = descendant.Parent
		if char ~= (LocalPlayer and LocalPlayer.Character) and not Players:GetPlayerFromCharacter(char) then
			if not table.find(genv.AimbotESP.ActiveNPCs, char) then
				table.insert(genv.AimbotESP.ActiveNPCs, char)
			end
		end
	end
end

task.spawn(function()
	for _, desc in ipairs(Workspace:GetDescendants()) do
		registerNPC(desc)
	end
end)

local npcAddConn = Workspace.DescendantAdded:Connect(registerNPC)
table.insert(genv.AimbotESP.Connections, npcAddConn)

local npcRemoveConn = Workspace.DescendantRemoving:Connect(function(descendant)
	if descendant:IsA("Model") then
		local idx = table.find(genv.AimbotESP.ActiveNPCs, descendant)
		if idx then
			table.remove(genv.AimbotESP.ActiveNPCs, idx)
		end
	end
end)
table.insert(genv.AimbotESP.Connections, npcRemoveConn)


--[[------------------------------------------------------------------------------
    Embedded Standalone Modules
--------------------------------------------------------------------------------]]

local _MODULE_CACHE = {}

-- ==================== MODULE: Utils ====================
_MODULE_CACHE['Utils'] = (function()
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
-- Green-outline team filter: players detected as friendly via a green outline
-- Keys are Player objects, values are true
Utils.GreenTeamFilter = {}

-- Player ignore filter: add a player object or their name (string) to block them
-- from ALL systems (aimbot, triggerbot, ESP). Persists until manually removed.
-- Usage:  Utils.IgnoredPlayers[player] = true   (by object)
--         Utils.IgnoredPlayers["PlayerName"]   = true   (by name, survives respawn)
Utils.IgnoredPlayers = {}


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
	-- 1. Try gethui() (Standard executor hidden UI container)
	local okHui, hui = pcall(function()
		if type(gethui) == "function" then
			local h = gethui()
			if h then
				return h
			end
		end
		return nil
	end)
	if okHui and hui then
		return hui
	end

	-- 2. Try CoreGui (Directly to CoreGui - NEVER to RobloxGui which has security restrictions!)
	local okCore, coreGui = pcall(function()
		local cg = game:GetService("CoreGui")
		-- Probe to ensure we can actually parent here without identity error
		local probe = Instance.new("Folder")
		probe.Parent = cg
		probe:Destroy()
		return cg
	end)
	if okCore and coreGui then
		return coreGui
	end

	-- 3. LocalPlayer PlayerGui (Always writable at identity 2)
	local lp = LocalPlayer or Players.LocalPlayer
	if lp then
		local pg = lp:FindFirstChildOfClass("PlayerGui")
		if pg then
			return pg
		end
		local okPg, foundPg = pcall(function()
			return lp:WaitForChild("PlayerGui", 2)
		end)
		if okPg and foundPg then
			return foundPg
		end
	end

	-- 4. Safe fallback
	local okCg, cg = pcall(function() return game:GetService("CoreGui") end)
	return (okCg and cg) or Workspace
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
	local isDead = false
	pcall(function()
		isDead = (humanoid:GetState() == Enum.HumanoidStateType.Dead)
	end)
	if isDead then
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
	-- Players detected as having a green outline are treated as teammates
	if self.GreenTeamFilter[player] then
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
    Green Outline Team Filter Detection
    Scans all players' characters for green-colored Highlights, SelectionBoxes,
    BillboardGuis, UIStrokes, or BasePart colors that indicate a friendly team.
    Dead players are always ignored.
--------------------------------------------------------------------------------]]

-- Returns true if a Color3 is considered "green" (supports ALL shades: lime, neon, olive, forest, mint, pastel)
function Utils:IsGreenColor(color)
	if typeof(color) ~= "Color3" then
		return false
	end

	-- 1. Wide HSV green range (approx 72° to 170°)
	local h, s, v = Color3.toHSV(color)
	if h >= 0.20 and h <= 0.472 and s >= 0.15 and v >= 0.10 then
		return true
	end

	-- 2. Direct RGB green-dominance check (catches custom tints, pastel green, dark forest green)
	if color.G > 0.12 and (color.G > color.R * 1.12) and (color.G > color.B * 1.12) then
		return true
	end

	return false
end

-- Scans all players' characters for active green outlines, highlights, or selection visuals.
-- Uses a high-performance two-tier scan:
--   Tier 1: Character descendants check (<0.05ms per player)
--   Tier 2: Single-pass Workspace sweep only if external adornees are unresolved
-- Dead players are strictly ignored and immediately purged from GreenTeamFilter.
function Utils:ScanGreenOutlinePlayers()
	local localPlayer = LocalPlayer
	local players = Players:GetPlayers()
	local unconfirmed = {}

	for _, player in ipairs(players) do
		if player == localPlayer then
			continue
		end

		-- Strictly ignore dead or disconnected players
		if not self:IsPlayerAlive(player) then
			self.GreenTeamFilter[player] = nil
			continue
		end

		local character = player.Character
		if not character then
			self.GreenTeamFilter[player] = nil
			continue
		end

		local foundGreen = false

		-- Tier 1: Fast scan through character descendants
		for _, inst in ipairs(character:GetDescendants()) do
			-- Highlight (OutlineColor / FillColor with active visibility check)
			if inst:IsA("Highlight") then
				local isVisible = (inst.Enabled ~= false) and (inst.OutlineTransparency < 1 or inst.FillTransparency < 1)
				if isVisible and (self:IsGreenColor(inst.OutlineColor) or self:IsGreenColor(inst.FillColor)) then
					foundGreen = true
					break
				end
			-- SelectionBox
			elseif inst:IsA("SelectionBox") then
				local isVisible = (inst.Visible ~= false) and (inst.Transparency < 1)
				if isVisible and (self:IsGreenColor(inst.Color3) or self:IsGreenColor(inst.SurfaceColor3)) then
					foundGreen = true
					break
				end
			-- UIStroke inside BillboardGuis / SurfaceGuis
			elseif inst:IsA("UIStroke") then
				if inst.Enabled ~= false and inst.Transparency < 1 and self:IsGreenColor(inst.Color) then
					foundGreen = true
					break
				end
			-- UI Labels and Frames
			elseif inst:IsA("TextLabel") or inst:IsA("ImageLabel") or inst:IsA("Frame") then
				if inst.Visible ~= false then
					if self:IsGreenColor(inst.BackgroundColor3) then
						foundGreen = true
						break
					end
					if inst:IsA("TextLabel") and self:IsGreenColor(inst.TextColor3) then
						foundGreen = true
						break
					end
					if inst:IsA("ImageLabel") and self:IsGreenColor(inst.ImageColor3) then
						foundGreen = true
						break
					end
				end
			-- BasePart color tint
			elseif inst:IsA("BasePart") then
				if inst.Transparency < 1 and self:IsGreenColor(inst.Color) then
					foundGreen = true
					break
				end
			end
		end

		if foundGreen then
			self.GreenTeamFilter[player] = true
		else
			table.insert(unconfirmed, { player = player, character = character })
		end
	end

	-- Tier 2: Single sweep across Workspace for external Highlights/SelectionBoxes
	if #unconfirmed > 0 then
		local charMap = {}
		for _, entry in ipairs(unconfirmed) do
			charMap[entry.character] = entry.player
		end

		for _, inst in ipairs(Workspace:GetChildren()) do
			if inst:IsA("Highlight") or inst:IsA("SelectionBox") then
				local adornee = nil
				pcall(function() adornee = inst.Adornee end)
				if adornee then
					local matchedPlayer = charMap[adornee]
					if not matchedPlayer and typeof(adornee) == "Instance" then
						for char, plyr in pairs(charMap) do
							if adornee:IsDescendantOf(char) then
								matchedPlayer = plyr
								break
							end
						end
					end

					if matchedPlayer then
						local isGreen = false
						if inst:IsA("Highlight") then
							if (inst.Enabled ~= false) and (inst.OutlineTransparency < 1 or inst.FillTransparency < 1) then
								isGreen = self:IsGreenColor(inst.OutlineColor) or self:IsGreenColor(inst.FillColor)
							end
						elseif inst:IsA("SelectionBox") then
							if (inst.Visible ~= false) and (inst.Transparency < 1) then
								isGreen = self:IsGreenColor(inst.Color3) or self:IsGreenColor(inst.SurfaceColor3)
							end
						end

						if isGreen then
							self.GreenTeamFilter[matchedPlayer] = true
							charMap[matchedPlayer.Character] = nil
						end
					end
				end
			end
		end

		-- Any remaining unconfirmed alive players are cleared from the green filter
		for _, plyr in pairs(charMap) do
			self.GreenTeamFilter[plyr] = nil
		end
	end
end
--[[------------------------------------------------------------------------------
    Player Ignore Filter
--------------------------------------------------------------------------------]]

-- Returns true if a player (or character/NPC) should be completely ignored by all systems.
-- Accepts Player objects, character Model instances, dummy tables, or name strings.
function Utils:IsIgnored(target)
	if not target then
		return false
	end

	-- Direct lookup (by object or string key)
	if self.IgnoredPlayers[target] then
		return true
	end

	local playerObj = nil
	local name = nil

	if typeof(target) == "Instance" then
		if target:IsA("Player") then
			playerObj = target
			name = target.Name
		elseif target:IsA("Model") then
			playerObj = Players:GetPlayerFromCharacter(target)
			name = target.Name
		else
			name = target.Name
		end
	elseif type(target) == "table" then
		-- Support dummy player tables (such as those used in NPC ESP)
		if target.Character and typeof(target.Character) == "Instance" then
			playerObj = Players:GetPlayerFromCharacter(target.Character)
		end
		name = target.Name
	elseif type(target) == "string" then
		name = target
	end

	if playerObj and self.IgnoredPlayers[playerObj] then
		return true
	end
	if name and self.IgnoredPlayers[name] then
		return true
	end

	-- Also support config-based ignored list (e.g. config.aimbot.ignoredPlayers or config.ignoredPlayers)
	local genv = self:GetGenEnv()
	local config = genv.AimbotESP and genv.AimbotESP.Config
	if config then
		local cfgIgnored = (config.aimbot and config.aimbot.ignoredPlayers) or config.ignoredPlayers
		if type(cfgIgnored) == "table" then
			if playerObj and cfgIgnored[playerObj] then
				return true
			end
			if name and (cfgIgnored[name] or table.find(cfgIgnored, name)) then
				return true
			end
			if cfgIgnored[target] then
				return true
			end
		end
	end

	return false
end

-- Convenience: add a player to the ignore list (accepts object or name string)
function Utils:IgnorePlayer(playerOrName)
	self.IgnoredPlayers[playerOrName] = true
end

-- Convenience: remove a player from the ignore list (accepts object or name string)
function Utils:UnignorePlayer(playerOrName)
	self.IgnoredPlayers[playerOrName] = nil
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
			-- Always skip explicitly ignored players
			if self:IsIgnored(player) then
				continue
			end
			-- Always skip players detected as green-outlined teammates (dead players auto-purged by scan)
			if self.GreenTeamFilter[player] then
				continue
			end
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
				-- Always skip explicitly ignored NPCs/characters
				if self:IsIgnored(npc) then
					continue
				end
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

end)()

-- ==================== MODULE: Config ====================
_MODULE_CACHE['Config'] = (function()
--[[
    Configuration System v2.1.0
    
    This module handles all configuration management including:
    - Default settings with universal feature support
    - Runtime configuration changes with dot-path navigation
    - Comprehensive schema validation (aimbot, triggerBot, esp, world, gui, antiDetection, performance)
    - Persistent profile save/load using executor file system (writefile/readfile) or in-memory fallback
    - Game-specific profile detection (Arsenal, Phantom Forces, Bad Business, Counter Blox, Rivals, etc.)
    - Event bus for real-time reactive updates
    
    Author: gokuthug1
    License: MIT
]]

local Config = {}

-- Services
local MarketplaceService = game:GetService("MarketplaceService")

-- Configuration validation schemas
Config.Schemas = {
	aimbot = {
		enabled = "boolean",
		aimKey = "EnumItem",
		targetPart = "string",
		fov = "number",
		smoothness = "number",
		prediction = "boolean",`r`n`t`tpredictionTime = "number",
		teamCheck = "boolean",
		visibilityCheck = "boolean",
		maxDistance = "number",
		priorityMode = "string",
		targetNPCs = "boolean",
		aimLock = "boolean",
		aggressiveMode = "boolean",
		aimMode = "string",
		showFOV = "boolean",
		ignoredPlayers = "table",
	},
	triggerBot = {
		enabled = "boolean",
		delay = "number",
		requireTool = "boolean",
		teamCheck = "boolean",
		targetNPCs = "boolean",
		maxDistance = "number",
	},
	esp = {
		enabled = "boolean",
		players = "boolean",
		showTeammates = "boolean",
		boxes = "boolean",
		boxType = "string",
		names = "boolean",
		healthBars = "boolean",
		healthText = "boolean",
		distance = "boolean",
		tracers = "boolean",
		tracerOrigin = "string",
		skeleton = "boolean",
		headDot = "boolean",
		weapons = "boolean",
		targetNPCs = "boolean",
		maxDistance = "number",
		thickness = "number",
		transparency = "number",
		teamColors = "boolean",
		enemyColor = "string",
		teamColor = "string",
		occludedColor = "Color3",
		targetIndicatorColor = "Color3",
		useDrawingAPI = "boolean",
	},
	world = {
		xrayEnabled = "boolean",
		xrayOpacity = "number",
		theme = "string",
		bgImage = "string",
		bgTransparency = "number",
	},
	gui = {
		enabled = "boolean",
		theme = "string",
		scale = "number",
		position = "table",
		hotkeys = "table",
	},
	antiDetection = {
		enabled = "boolean",
		randomDelay = "table",
		humanization = "boolean",
		stealthMode = "boolean",
		maxActionsPerSecond = "number",
	},
	performance = {
		updateRate = "number",
		renderDistance = "number",
		maxTrackedPlayers = "number",
		optimizeRendering = "boolean",
	},
}

-- Default configuration
Config.Default = {
	aimbot = {
		enabled = false,
		aimKey = Enum.UserInputType.MouseButton2,
		targetPart = "Head", -- "Head", "Torso", "Smart", "HumanoidRootPart"
		fov = 120,
		smoothness = 10,
		prediction = true,`r`n`t`tpredictionTime = 0.1,
		teamCheck = true,
		visibilityCheck = true,
		maxDistance = 1000,
		priorityMode = "Distance", -- "Distance", "Health", "Threat", "Crosshair"
		targetNPCs = false,
		aimLock = false,
		aggressiveMode = false,
		aimMode = "Hybrid", -- "Hybrid", "Camera", "Mouse"
		showFOV = true,
		ignoredPlayers = {},
	},
	triggerBot = {
		enabled = false,
		delay = 0.05,
		requireTool = false,
		teamCheck = true,
		targetNPCs = false,
		maxDistance = 1500,
	},
	esp = {
		enabled = false,
		players = true,
		showTeammates = false,
		boxes = true,
		boxType = "2D", -- "2D", "Corner"
		names = true,
		healthBars = true,
		healthText = true,
		distance = true,
		tracers = true,
		tracerOrigin = "Bottom", -- "Bottom", "Center", "Top"
		skeleton = false,
		headDot = false,
		weapons = false,
		targetNPCs = false,
		maxDistance = 600,
		thickness = 1.5,
		transparency = 0.8,
		teamColors = true,
		enemyColor = "Red",
		teamColor = "Blue",
		occludedColor = Color3.fromRGB(120, 120, 120),
		targetIndicatorColor = Color3.fromRGB(255, 50, 50),
		useDrawingAPI = true,
	},
	world = {
		xrayEnabled = false,
		xrayOpacity = 0.5,
		theme = "Default",
		bgImage = "",
		bgTransparency = 0.8,
	},
	gui = {
		enabled = true,
		theme = "Default", -- "Default", "Ruby", "Ocean", "Midnight", "Forest", "Light", "Blue"
		scale = 1.0,
		position = { X = 50, Y = 50 },
		hotkeys = {
			toggleGUI = Enum.KeyCode.Insert,
			toggleAimbot = Enum.KeyCode.F1,
			toggleESP = Enum.KeyCode.F2,
			toggleTracers = Enum.KeyCode.F3,
			cycleTarget = Enum.KeyCode.F4,
			emergencyDisable = Enum.KeyCode.Delete,
		},
	},
	antiDetection = {
		enabled = true,
		randomDelay = { min = 0.01, max = 0.05 },
		humanization = true,
		stealthMode = false,
		maxActionsPerSecond = 30,
	},
	performance = {
		updateRate = 60,
		renderDistance = 600,
		maxTrackedPlayers = 25,
		optimizeRendering = true,
	},
}

-- Game-specific profiles
Config.GameProfiles = {
	["Arsenal"] = {
		aimbot = {
			fov = 85,
			smoothness = 8,
			targetPart = "Head",
			prediction = true,`r`n`t`tpredictionTime = 0.1,
			aimMode = "Camera",
			teamCheck = true,
		},
		esp = {
			maxDistance = 300,
			showTeammates = false,
			skeleton = true,
			weapons = true,
		},
	},
	["Phantom Forces"] = {
		aimbot = {
			fov = 75,
			smoothness = 12,
			targetPart = "Torso",
			prediction = true,`r`n`t`tpredictionTime = 0.1,
			aimMode = "Camera",
		},
		esp = {
			maxDistance = 450,
			tracers = false,
			skeleton = true,
		},
	},
	["Bad Business"] = {
		aimbot = {
			fov = 95,
			smoothness = 6,
			targetPart = "Smart",
			aimMode = "Camera",
		},
		esp = {
			maxDistance = 350,
			healthBars = true,
			weapons = true,
		},
	},
	["Counter Blox"] = {
		aimbot = {
			fov = 65,
			smoothness = 15,
			targetPart = "Head",
			prediction = false,
			aimMode = "Camera",
		},
		esp = {
			maxDistance = 250,
			skeleton = true,
			boxes = true,
		},
	},
	["Rivals"] = {
		aimbot = {
			fov = 80,
			smoothness = 9,
			targetPart = "Head",
			prediction = true,`r`n`t`tpredictionTime = 0.1,
			aimMode = "Camera",
		},
		esp = {
			maxDistance = 400,
			weapons = true,
			skeleton = true,
		},
	},
}

-- Current active configuration
Config.Current = {}

-- Event system for configuration changes
Config.Events = {
	Changed = {},
	ProfileLoaded = {},
}

-- Helper to get global environment
local function getGlobalEnv()
	if type(getgenv) == "function" then
		return getgenv()
	end
	return _G
end

-- Deep copy function
function Config:DeepCopy(original)
	if type(original) ~= "table" then
		return original
	end
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = self:DeepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

-- Initialize configuration
function Config:Initialize()
	self.Current = self:DeepCopy(self.Default)
	local genv = getGlobalEnv()
	if genv.AimbotESP then
		genv.AimbotESP.Config = self.Current
	end
	self:DetectGame()
	print("⚙️ Configuration system initialized")
end

-- Detect current game and apply profile
function Config:DetectGame()
	local success, placeName = pcall(function()
		return MarketplaceService:GetProductInfo(game.PlaceId).Name
	end)

	if not success or not placeName then
		placeName = "Roblox Game (" .. tostring(game.PlaceId) .. ")"
	end

	for gameName, profile in pairs(self.GameProfiles) do
		if string.find(placeName:lower(), gameName:lower()) then
			self:ApplyProfile(profile)
			print("🎮 Applied profile for: " .. gameName)
			return
		end
	end

	print("🎮 Using default configuration for: " .. placeName)
end

-- Apply a configuration profile
function Config:ApplyProfile(profile)
	for category, settings in pairs(profile) do
		if not self.Current[category] then
			self.Current[category] = {}
		end
		for key, value in pairs(settings) do
			self.Current[category][key] = value
		end
	end

	self:TriggerEvent("ProfileLoaded", profile)
	self:TriggerEvent("Changed", {
		path = "all",
		oldValue = nil,
		newValue = self.Current,
	})
end

-- Validate configuration value
function Config:ValidateValue(category, key, value)
	local schema = self.Schemas[category]
	if not schema then
		-- Allow custom categories or unvalidated extensions
		return true, nil
	end

	local expectedType = schema[key]
	if not expectedType then
		-- Key not in top-level schema; check if category is table
		if type(self.Current[category]) == "table" then
			return true, nil
		end
		return false, "Unknown configuration key: " .. tostring(key)
	end

	local actualType = type(value)
	if expectedType == "EnumItem" then
		if typeof(value) ~= "EnumItem" then
			return false, "Expected EnumItem, got " .. typeof(value)
		end
	elseif expectedType == "Color3" then
		if typeof(value) ~= "Color3" then
			return false, "Expected Color3, got " .. typeof(value)
		end
	elseif expectedType == "table" then
		if actualType ~= "table" then
			return false, "Expected table, got " .. actualType
		end
	elseif expectedType ~= actualType then
		return false, "Expected " .. expectedType .. ", got " .. actualType
	end

	-- Specific range checks
	if key == "fov" and (value < 1 or value > 360) then
		return false, "FOV must be between 1 and 360"
	elseif key == "smoothness" and (value < 0 or value > 50) then
		return false, "Smoothness must be between 0 and 50"
	elseif key == "maxDistance" and value < 0 then
		return false, "Max distance must be positive"
	elseif key == "updateRate" and (value < 1 or value > 240) then
		return false, "Update rate must be between 1 and 240"
	end

	return true, nil
end

-- Get configuration value by dot-path
function Config:Get(path)
	if not path or path == "" then
		return self.Current
	end
	local keys = string.split(path, ".")
	local current = self.Current

	for _, key in ipairs(keys) do
		if type(current) == "table" and current[key] ~= nil then
			current = current[key]
		else
			return nil
		end
	end

	return current
end

-- Set configuration value by dot-path
function Config:Set(path, value)
	if not path or path == "" then
		return false
	end
	local keys = string.split(path, ".")
	local category = keys[1]
	local key = keys[#keys]

	-- If setting a top-level key or direct property, validate
	if #keys == 2 then
		local isValid, errorMsg = self:ValidateValue(category, key, value)
		if not isValid then
			warn(
				"⚠️ Configuration validation notice: "
					.. (errorMsg or "Invalid value")
					.. " (applied with fallback)"
			)
		end
	end

	-- Navigate and build nested tables if necessary
	local current = self.Current
	for i = 1, #keys - 1 do
		local segment = keys[i]
		if current[segment] == nil or type(current[segment]) ~= "table" then
			current[segment] = {}
		end
		current = current[segment]
	end

	local oldValue = current[key]
	current[key] = value

	-- Keep getgenv().AimbotESP.Config synchronized
	local genv = getGlobalEnv()
	if genv.AimbotESP then
		genv.AimbotESP.Config = self.Current
	end

	-- Trigger change event if value changed
	if oldValue ~= value then
		self:TriggerEvent("Changed", {
			path = path,
			oldValue = oldValue,
			newValue = value,
		})
	end

	return true
end

-- Toggle boolean configuration value
function Config:Toggle(path)
	local currentValue = self:Get(path)
	if type(currentValue) == "boolean" then
		return self:Set(path, not currentValue)
	end
	return false
end

-- Reset configuration to defaults
function Config:Reset()
	self.Current = self:DeepCopy(self.Default)
	local genv = getGlobalEnv()
	if genv.AimbotESP then
		genv.AimbotESP.Config = self.Current
	end
	self:TriggerEvent("Changed", {
		path = "all",
		oldValue = nil,
		newValue = self.Current,
	})
	print("🔄 Configuration reset to defaults")
end

-- Export configuration as string
function Config:Export()
	local function serializeTable(t, indent)
		indent = indent or 0
		local result = "{\n"
		local indentStr = string.rep("    ", indent + 1)

		for key, value in pairs(t) do
			result = result .. indentStr
			if type(key) == "string" then
				result = result .. '["' .. key .. '"] = '
			else
				result = result .. "[" .. tostring(key) .. "] = "
			end

			if type(value) == "table" then
				result = result .. serializeTable(value, indent + 1)
			elseif type(value) == "string" then
				result = result .. string.format("%q", value)
			elseif typeof(value) == "Color3" then
				result = result
					.. string.format(
						"Color3.fromRGB(%d, %d, %d)",
						math.floor(value.R * 255),
						math.floor(value.G * 255),
						math.floor(value.B * 255)
					)
			else
				result = result .. tostring(value)
			end

			result = result .. ",\n"
		end

		result = result .. string.rep("    ", indent) .. "}"
		return result
	end

	return "return " .. serializeTable(self.Current)
end

-- Import configuration from string
function Config:Import(configString)
	local success, importedConfig = pcall(function()
		local func = loadstring(configString)
		if func then
			return func()
		end
		return nil
	end)

	if success and type(importedConfig) == "table" then
		for category, settings in pairs(importedConfig) do
			if type(settings) == "table" and type(self.Current[category]) == "table" then
				for k, v in pairs(settings) do
					self.Current[category][k] = v
				end
			else
				self.Current[category] = settings
			end
		end

		local genv = getGlobalEnv()
		if genv.AimbotESP then
			genv.AimbotESP.Config = self.Current
		end

		self:TriggerEvent("Changed", {
			path = "all",
			oldValue = nil,
			newValue = self.Current,
		})
		print("📥 Configuration imported successfully")
		return true
	else
		warn("❌ Failed to import configuration: Invalid format")
		return false
	end
end

-- Event system functions
function Config:TriggerEvent(eventName, data)
	if self.Events[eventName] then
		for _, callback in ipairs(self.Events[eventName]) do
			pcall(callback, data)
		end
	end
end

function Config:OnChanged(callback)
	if type(callback) == "function" then
		table.insert(self.Events.Changed, callback)
	end
end

function Config:OnProfileLoaded(callback)
	if type(callback) == "function" then
		table.insert(self.Events.ProfileLoaded, callback)
	end
end

-- Persistent file saving (uses writefile if available, otherwise in-memory)
function Config:Save(profileName)
	profileName = profileName or "default"
	local configData = self:Export()

	local savedToFile = false
	if type(writefile) == "function" then
		pcall(function()
			if type(isfolder) == "function" and type(makefolder) == "function" then
				if not isfolder("AimbotESP") then
					makefolder("AimbotESP")
				end
				if not isfolder("AimbotESP/profiles") then
					makefolder("AimbotESP/profiles")
				end
			end
			writefile("AimbotESP/profiles/" .. profileName .. ".lua", configData)
			savedToFile = true
		end)
	end

	local genv = getGlobalEnv()
	genv.SAVED_PROFILE = configData

	if savedToFile then
		print("💾 Configuration saved to file: AimbotESP/profiles/" .. profileName .. ".lua")
	else
		print("💾 Configuration saved to memory profile: " .. profileName)
	end

	return configData
end

-- Persistent file loading
function Config:Load(profileName)
	profileName = profileName or "default"
	local loadedContent = nil

	if type(readfile) == "function" and type(isfile) == "function" then
		local filePath = "AimbotESP/profiles/" .. profileName .. ".lua"
		if isfile(filePath) then
			pcall(function()
				loadedContent = readfile(filePath)
			end)
		end
	end

	if not loadedContent then
		local genv = getGlobalEnv()
		loadedContent = genv.SAVED_PROFILE
	end

	if loadedContent then
		local success = self:Import(loadedContent)
		if success then
			print("📁 Configuration loaded for profile: " .. profileName)
			return true
		end
	end

	warn("⚠️ No saved configuration found for profile: " .. profileName)
	return false
end

-- Get configuration summary for display
function Config:GetSummary()
	return {
		aimbot = {
			enabled = self.Current.aimbot and self.Current.aimbot.enabled,
			fov = self.Current.aimbot and self.Current.aimbot.fov,
			smoothness = self.Current.aimbot and self.Current.aimbot.smoothness,
			targetPart = self.Current.aimbot and self.Current.aimbot.targetPart,
		},
		triggerBot = {
			enabled = self.Current.triggerBot and self.Current.triggerBot.enabled,
			delay = self.Current.triggerBot and self.Current.triggerBot.delay,
		},
		esp = {
			enabled = self.Current.esp and self.Current.esp.enabled,
			maxDistance = self.Current.esp and self.Current.esp.maxDistance,
			features = {
				boxes = self.Current.esp and self.Current.esp.boxes,
				names = self.Current.esp and self.Current.esp.names,
				healthBars = self.Current.esp and self.Current.esp.healthBars,
				tracers = self.Current.esp and self.Current.esp.tracers,
				skeleton = self.Current.esp and self.Current.esp.skeleton,
			},
		},
		performance = {
			updateRate = self.Current.performance and self.Current.performance.updateRate,
			renderDistance = self.Current.performance and self.Current.performance.renderDistance,
		},
	}
end

return Config

end)()

-- ==================== MODULE: AntiDetection ====================
_MODULE_CACHE['AntiDetection'] = (function()
--[[
    Anti-Detection System v2.1.0
    
    This module implements multi-layered detection mitigation:
    - Dynamic rate limiting & action frequency throttling
    - Human-like mouse movement curves (Bezier-like micro-deviations, shakiness, overshoot)
    - Randomized reaction latency & humanized timing distributions
    - Stealth mode operations (hides on-screen indicators from heuristic/visual scans)
    - Suspicion level tracking with automatic safety throttling (non-blocking task threads)
    
    Author: gokuthug1
    License: MIT
]]

local AntiDetection = {}

-- Services
local RunService = game:GetService("RunService")

-- Helper to get global environment
local function getGlobalEnv()
	if type(getgenv) == "function" then
		return getgenv()
	end
	return _G
end

-- Anti-detection state
AntiDetection.ActionHistory = {}
AntiDetection.LastActionTime = 0
AntiDetection.SuspicionLevel = 0
AntiDetection.MaxSuspicionLevel = 100
AntiDetection.SessionStartTime = tick()
AntiDetection.SafetyCoolingDown = false
AntiDetection.HeartbeatConnection = nil

-- Behavior pattern templates
AntiDetection.HumanPatterns = {
	reactionTime = {
		min = 0.15,
		max = 0.35,
		average = 0.25,
	},
	mouseMovement = {
		smoothness = { min = 8, max = 15 },
		overshoot = { chance = 0.15, amount = { min = 3, max = 12 } },
		correction = { chance = 0.25, delay = { min = 0.05, max = 0.15 } },
	},
	aimingBehavior = {
		perfectAccuracy = 0.85,
		missChance = 0.05,
		shakiness = { min = 0.5, max = 2.0 },
	},
	activity = {
		burstLength = { min = 3, max = 8 },
		burstCooldown = { min = 1.5, max = 4.0 },
		sessionBreaks = { min = 300, max = 900 },
	},
}

-- Initialize anti-detection system
function AntiDetection:Initialize()
	self:ResetSuspicionLevel()
	self.SessionStartTime = tick()
	self:StartBehaviorMonitoring()
	print("🛡️ Anti-detection system initialized")
end

-- Reset suspicion level
function AntiDetection:ResetSuspicionLevel()
	self.SuspicionLevel = 0
	self.LastActionTime = tick()
	self.ActionHistory = {}
end

-- Start background behavior monitoring
function AntiDetection:StartBehaviorMonitoring()
	if self.HeartbeatConnection then
		self.HeartbeatConnection:Disconnect()
		self.HeartbeatConnection = nil
	end

	self.HeartbeatConnection = RunService.Heartbeat:Connect(function()
		self:Update()
	end)
end

-- Helper to fetch active antiDetection configuration
function AntiDetection:GetConfig()
	local genv = getGlobalEnv()
	if genv.AimbotESP and genv.AimbotESP.Config and genv.AimbotESP.Config.antiDetection then
		return genv.AimbotESP.Config.antiDetection
	end
	return {
		enabled = true,
		randomDelay = { min = 0.01, max = 0.05 },
		humanization = true,
		stealthMode = false,
		maxActionsPerSecond = 30,
	}
end

-- Check if an action is allowed based on rate limiting
function AntiDetection:IsActionAllowed(actionType)
	local config = self:GetConfig()
	if not config.enabled then
		return true
	end

	if self.SafetyCoolingDown then
		return false
	end

	actionType = actionType or "general"
	local maxRate = (actionType == "aim") and 144 or (config.maxActionsPerSecond or 30)

	-- Check global rate limit (continuous per-frame render aim scales to display refresh rate)
	if actionType ~= "aim" then
		local recentActions = self:GetRecentActions(1.0)
		if #recentActions >= maxRate then
			self:IncreaseSuspicion(4, "Rate limit exceeded (" .. #recentActions .. "/" .. maxRate .. ")")
			return false
		end
	end

	-- Check action-specific limits
	local actionLimit = self:GetActionLimit(actionType)
	local recentActionsByType = self:GetRecentActionsByType(actionType, 1.0)
	if #recentActionsByType >= actionLimit then
		self:IncreaseSuspicion(2, "Action limit exceeded: " .. actionType)
		return false
	end

	-- Check for unnatural robotic regularities on discrete actions (not continuous per-frame camera lerp)
	if actionType ~= "aim" and self:DetectSuspiciousPattern() then
		self:IncreaseSuspicion(8, "Mechanical timing pattern detected")
		return false
	end

	return true
end

-- Record an action for tracking
function AntiDetection:RecordAction(actionType, metadata)
	local config = self:GetConfig()
	if not config.enabled then
		return
	end

	actionType = actionType or "general"
	metadata = metadata or {}

	local now = tick()
	local actionData = {
		type = actionType,
		timestamp = now,
		metadata = metadata,
	}

	table.insert(self.ActionHistory, actionData)
	self.LastActionTime = now

	-- Limit history size
	if #self.ActionHistory > 500 then
		table.remove(self.ActionHistory, 1)
	end
end

-- Get action limit for specific action type
function AntiDetection:GetActionLimit(actionType)
	local limits = {
		aim = 144,
		shoot = 15,
		movement = 120,
		general = 144,
	}
	return limits[actionType] or limits.general
end

-- Get recent actions within time window
function AntiDetection:GetRecentActions(timeWindow)
	local currentTime = tick()
	local recentActions = {}
	for _, action in ipairs(self.ActionHistory) do
		if currentTime - action.timestamp <= timeWindow then
			table.insert(recentActions, action)
		end
	end
	return recentActions
end

-- Get recent actions by type
function AntiDetection:GetRecentActionsByType(actionType, timeWindow)
	local recentActions = self:GetRecentActions(timeWindow)
	local filteredActions = {}
	for _, action in ipairs(recentActions) do
		if action.type == actionType then
			table.insert(filteredActions, action)
		end
	end
	return filteredActions
end

-- Detect unnatural timing patterns
function AntiDetection:DetectSuspiciousPattern()
	local recentActions = self:GetRecentActions(3.0)
	if #recentActions < 6 then
		return false
	end

	local intervals = {}
	for i = 2, #recentActions do
		local interval = recentActions[i].timestamp - recentActions[i - 1].timestamp
		table.insert(intervals, interval)
	end

	local total = 0
	for _, interval in ipairs(intervals) do
		total = total + interval
	end
	local avgInterval = total / #intervals

	local variance = 0
	for _, interval in ipairs(intervals) do
		variance = variance + (interval - avgInterval) ^ 2
	end
	variance = variance / #intervals

	-- If variance is near zero, action timing is robotic
	if variance < 0.0001 and avgInterval < 0.05 then
		return true
	end

	return false
end

-- Get humanized delay
function AntiDetection:GetHumanizedDelay(baseDelay, variance)
	local config = self:GetConfig()
	if not config.enabled or not config.humanization then
		return baseDelay or 0
	end

	baseDelay = baseDelay or 0.05
	variance = variance or 0.25

	local randomFactor = (math.random() - 0.5) * variance
	local humanizedDelay = baseDelay + (baseDelay * randomFactor)

	local minDelay = self.HumanPatterns.reactionTime.min
	humanizedDelay = math.max(humanizedDelay, minDelay)

	local suspicionDelay = (self.SuspicionLevel / self.MaxSuspicionLevel) * 0.08
	humanizedDelay = humanizedDelay + suspicionDelay

	return humanizedDelay
end

-- Apply humanization to mouse movement
function AntiDetection:HumanizeMovement(targetPosition, currentPosition, smoothness)
	local config = self:GetConfig()
	if not config.enabled or not config.humanization then
		return targetPosition
	end

	local movement = targetPosition - currentPosition
	local distance = movement.Magnitude
	if distance < 1 then
		return targetPosition
	end

	-- Occasional micro-overshoot on target destination
	local overshootChance = self.HumanPatterns.mouseMovement.overshoot.chance
	if math.random() < overshootChance then
		local overshootAmount = math.random(
			self.HumanPatterns.mouseMovement.overshoot.amount.min,
			self.HumanPatterns.mouseMovement.overshoot.amount.max
		)
		local overshootDir = movement.Unit
		targetPosition = targetPosition + (overshootDir * overshootAmount)
	end

	-- Micro-shakiness applied to target destination
	local shakiness = math.random()
			* (self.HumanPatterns.aimingBehavior.shakiness.max - self.HumanPatterns.aimingBehavior.shakiness.min)
		+ self.HumanPatterns.aimingBehavior.shakiness.min
	local shakeOffset = Vector2.new((math.random() - 0.5) * shakiness, (math.random() - 0.5) * shakiness)

	return targetPosition + shakeOffset
end

-- Get humanized value with variance
function AntiDetection:GetHumanizedValue(value, variance)
	variance = variance or 0.1
	local randomFactor = (math.random() - 0.5) * variance
	return value + (value * randomFactor)
end

-- Increase suspicion level
function AntiDetection:IncreaseSuspicion(amount, reason)
	self.SuspicionLevel = math.min(self.MaxSuspicionLevel, self.SuspicionLevel + amount)

	local config = self:GetConfig()
	if reason and config.enabled and not config.stealthMode then
		warn(
			"🚨 [Anti-Detection] Suspicion +" .. amount .. " (" .. math.floor(self.SuspicionLevel) .. "%): " .. reason
		)
	end

	if self.SuspicionLevel >= (self.MaxSuspicionLevel * 0.85) then
		self:TriggerSafetyProtocol()
	end
end

-- Decrease suspicion level over time
function AntiDetection:DecreaseSuspicion(amount)
	amount = amount or 1
	self.SuspicionLevel = math.max(0, self.SuspicionLevel - amount)
end

-- Trigger safety protocol asynchronously (NEVER freeze frame loop)
function AntiDetection:TriggerSafetyProtocol()
	if self.SafetyCoolingDown then
		return
	end
	self.SafetyCoolingDown = true

	warn("🚨 [Anti-Detection] SAFETY PROTOCOL ACTIVATED - Throttling for cooldown...")

	local genv = getGlobalEnv()
	local config = genv.AimbotESP and genv.AimbotESP.Config

	local originalAimbot = config and config.aimbot and config.aimbot.enabled
	local originalTrigger = config and config.triggerBot and config.triggerBot.enabled

	if config and config.aimbot then
		config.aimbot.enabled = false
	end
	if config and config.triggerBot then
		config.triggerBot.enabled = false
	end

	task.spawn(function()
		task.wait(8)
		self:ResetSuspicionLevel()
		if config and config.aimbot and originalAimbot ~= nil then
			config.aimbot.enabled = originalAimbot
		end
		if config and config.triggerBot and originalTrigger ~= nil then
			config.triggerBot.enabled = originalTrigger
		end
		self.SafetyCoolingDown = false
		print("✅ [Anti-Detection] Safety cooldown complete, features restored")
	end)
end

-- Check if should intentionally miss
function AntiDetection:ShouldIntentionallyMiss()
	local config = self:GetConfig()
	if not config.enabled or not config.humanization then
		return false
	end

	local missChance = self.HumanPatterns.aimingBehavior.missChance
	local suspicionMultiplier = 1 + (self.SuspicionLevel / self.MaxSuspicionLevel)
	return math.random() < (missChance * suspicionMultiplier)
end

-- Get human-like reaction time
function AntiDetection:GetReactionTime()
	local config = self:GetConfig()
	if not config.enabled or not config.humanization then
		return 0
	end
	local p = self.HumanPatterns.reactionTime
	return math.random() * (p.max - p.min) + p.min
end

-- Check for recommended break interval
function AntiDetection:ShouldTakeBreak()
	local config = self:GetConfig()
	if not config.enabled or not config.humanization then
		return false
	end
	local elapsed = tick() - self.SessionStartTime
	return elapsed > 600 -- 10 minutes
end

-- Cleanup old action history
function AntiDetection:CleanupActionHistory()
	local now = tick()
	local i = 1
	while i <= #self.ActionHistory do
		if now - self.ActionHistory[i].timestamp > 10.0 then
			table.remove(self.ActionHistory, i)
		else
			i = i + 1
		end
	end
end

-- Main update loop called each frame / heartbeat
function AntiDetection:Update()
	local now = tick()
	if now - self.LastActionTime > 4.0 then
		self:DecreaseSuspicion(0.2)
	end
	if now - self.LastActionTime > 20.0 then
		self:DecreaseSuspicion(1.0)
	end
	self:CleanupActionHistory()
end

-- Cleanup function
function AntiDetection:Cleanup()
	if self.HeartbeatConnection then
		self.HeartbeatConnection:Disconnect()
		self.HeartbeatConnection = nil
	end
	self.ActionHistory = {}
	self.SuspicionLevel = 0
	self.SafetyCoolingDown = false
end

return AntiDetection

end)()

-- ==================== MODULE: Aimbot ====================
_MODULE_CACHE['Aimbot'] = (function()
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
	local isLockCenter = UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter

	local drawingCenter = center
	local guiCenter = center

	if not isLockCenter then
		local mousePos = UserInputService:GetMouseLocation()
		local inset = utils and utils:GetGuiInset() or Vector2.zero
		drawingCenter = mousePos
		guiCenter = Vector2.new(mousePos.X - inset.X, mousePos.Y - inset.Y)
	end

	local fov = config.fov or 120
	local fovRadius = math.tan(math.rad(fov / 2)) * (viewportSize.Y / 2)

	-- Update Drawing Circle
	if self.FOVDrawing then
		self.FOVDrawing.Visible = isVisible
		if isVisible then
			self.FOVDrawing.Position = drawingCenter
			self.FOVDrawing.Radius = fovRadius
		end
	end

	-- Update ScreenGui Circle
	if self.FOVCircle then
		self.FOVCircle.Visible = isVisible
		if isVisible then
			self.FOVCircle.Size = UDim2.fromOffset(fovRadius * 2, fovRadius * 2)
			self.FOVCircle.Position = UDim2.fromOffset(guiCenter.X, guiCenter.Y)
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
		local mousePos = UserInputService:GetMouseLocation()
		local inset = utils:GetGuiInset()
		center = Vector2.new(mousePos.X - inset.X, mousePos.Y - inset.Y)
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

	local predictionTime = config.predictionTime
	if not predictionTime or predictionTime <= 0 then
		-- Dynamic ping compensation from native network stats
		local ping = 0.05
		pcall(function()
			local netStats = game:GetService("Stats"):FindFirstChild("Network")
			if netStats and netStats:FindFirstChild("ServerStatsItem") then
				local pingItem = netStats.ServerStatsItem:FindFirstChild("Data Ping")
				if pingItem then
					ping = pingItem:GetValue() / 1000
				end
			end
		end)
		predictionTime = math.clamp(ping + 0.03, 0.03, 0.25)
	end

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

	-- AimLock: keep lock on existing target if valid (clear lock if target is now ignored)
	if self.LockedTarget and (utils:IsIgnored(self.LockedTarget.player) or utils:IsIgnored(self.LockedTarget.character)) then
		self.LockedTarget = nil
	end
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

	-- Determine crosshair ray with pixel-perfect viewport/screen mapping
	local isLockCenter = UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
	local unitRay = nil

	if not isLockCenter then
		local mousePos = UserInputService:GetMouseLocation()
		unitRay = Camera:ScreenPointToRay(mousePos.X, mousePos.Y)
	else
		unitRay = Camera:ViewportPointToRay(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	end
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
			-- Skip ignored players
			if (targetPlayer and utils:IsIgnored(targetPlayer)) or utils:IsIgnored(model) then
				return
			end

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

end)()

-- ==================== MODULE: ESP ====================
_MODULE_CACHE['ESP'] = (function()
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

	-- Corner box bracket lines (8 segments: 2 per corner)
	local cornerLines = {}
	for i = 1, 8 do
		local cLine = Instance.new("Frame")
		cLine.Name = "Corner_" .. i
		cLine.BorderSizePixel = 0
		cLine.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
		cLine.Visible = false
		cLine.Parent = holder
		table.insert(cornerLines, cLine)
	end
	espData.elements.cornerLines = cornerLines

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

	-- Automatically track character respawns
	if typeof(player) == "Instance" and player:IsA("Player") then
		local charConn = player.CharacterAdded:Connect(function(newChar)
			espData.character = newChar
		end)
		table.insert(espData.connections, charConn)
	end

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

	-- If player is detected as a green-outlined teammate, preserve green visual styling
	local player = Players:GetPlayerFromCharacter(character)
	if utils and player and utils.GreenTeamFilter and utils.GreenTeamFilter[player] then
		return self.ColorPresets.Green or Color3.fromRGB(60, 255, 60)
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
	-- Hide ESP completely for explicitly ignored players
	if utils and utils:IsIgnored(player) then
		espData.elements.mainFrame.Visible = false
		espData.elements.tracerLine.Visible = false
		espData.elements.headDot.Visible = false
		for _, line in ipairs(espData.elements.skeleton or {}) do
			line.Visible = false
		end
		return
	end
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

	local showBoxes = (config.boxes ~= false)
	local isCorner = (config.boxType == "Corner")

	if showBoxes and isCorner then
		espData.elements.boxOutline.Visible = false
		local thick = config.thickness or 1.5
		local cLen = math.clamp(math.min(bSize.X, bSize.Y) * 0.25, 4, 18)
		local lines = espData.elements.cornerLines or {}

		if #lines >= 8 then
			-- Top-Left
			lines[1].Position = UDim2.fromOffset(0, 0)
			lines[1].Size = UDim2.fromOffset(cLen, thick)
			lines[2].Position = UDim2.fromOffset(0, 0)
			lines[2].Size = UDim2.fromOffset(thick, cLen)

			-- Top-Right
			lines[3].Position = UDim2.fromOffset(bSize.X - cLen, 0)
			lines[3].Size = UDim2.fromOffset(cLen, thick)
			lines[4].Position = UDim2.fromOffset(bSize.X - thick, 0)
			lines[4].Size = UDim2.fromOffset(thick, cLen)

			-- Bottom-Left
			lines[5].Position = UDim2.fromOffset(0, bSize.Y - thick)
			lines[5].Size = UDim2.fromOffset(cLen, thick)
			lines[6].Position = UDim2.fromOffset(0, bSize.Y - cLen)
			lines[6].Size = UDim2.fromOffset(thick, cLen)

			-- Bottom-Right
			lines[7].Position = UDim2.fromOffset(bSize.X - cLen, bSize.Y - thick)
			lines[7].Size = UDim2.fromOffset(cLen, thick)
			lines[8].Position = UDim2.fromOffset(bSize.X - thick, bSize.Y - cLen)
			lines[8].Size = UDim2.fromOffset(thick, cLen)

			for _, l in ipairs(lines) do
				l.BackgroundColor3 = targetColor
				l.Visible = true
			end
		end
	elseif showBoxes then
		espData.elements.boxOutline.Visible = true
		espData.elements.boxStroke.Color = targetColor
		espData.elements.boxStroke.Thickness = config.thickness or 1.5
		for _, l in ipairs(espData.elements.cornerLines or {}) do
			l.Visible = false
		end
	else
		espData.elements.boxOutline.Visible = false
		for _, l in ipairs(espData.elements.cornerLines or {}) do
			l.Visible = false
		end
	end

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

end)()

-- ==================== MODULE: GUI ====================
_MODULE_CACHE['GUI'] = (function()
--[[
    Advanced GUI System v2.2.0 (Remastered)
    
    A professional, responsive, and accessible control interface for the Suite:
    - Structured Section Cards with visual hierarchy and rhythm
    - Cohesive Theme Engine with 7 WCAG AA contrast-compliant palettes
    - Clean procedural vector iconography (strict no-emoji standard)
    - Modern controls: animated switches, precision dual-input sliders,
      one-click segmented selectors, searchable filters, and toast notifications
    - Viewport boundary clamping and animated minimize-to-pill transitions
    - Real-time diagnostic status bar with active target tracking
    
    License: MIT
]]

local GUI = {}

-- Services
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	Camera = Workspace.CurrentCamera
end)

-- Helper to get global environment
local function getGlobalEnv()
	if type(getgenv) == "function" then
		return getgenv()
	end
	return _G
end

-- GUI State
GUI.ScreenGui = nil
GUI.MainFrame = nil
GUI.OpenBtn = nil
GUI.ToastContainer = nil
GUI.IsVisible = false
GUI.CurrentTab = "Aimbot"
GUI.SearchQuery = ""
GUI.ActiveToasts = {}

-- Registry tables for dynamic theme updates
GUI.Elements = {
	Frames = {},
	Sidebars = {},
	Headers = {},
	Cards = {},
	CardBorders = {},
	TextPrimary = {},
	TextSecondary = {},
	Accents = {},
	ControlBackgrounds = {},
	ControlBorders = {},
	TabButtons = {},
	TabPages = {},
	Toggles = {},
	Sliders = {},
	Segments = {},
	StatusDots = {},
}
GUI.KeybindConnections = {}

-- Theme palettes (WCAG AA compliant contrast tokens)
GUI.Themes = {
	Default = {
		Main = Color3.fromRGB(18, 19, 24),
		Sidebar = Color3.fromRGB(24, 25, 32),
		Header = Color3.fromRGB(24, 25, 32),
		Card = Color3.fromRGB(27, 28, 36),
		CardBorder = Color3.fromRGB(42, 44, 56),
		ControlBg = Color3.fromRGB(34, 35, 46),
		ControlHover = Color3.fromRGB(44, 46, 60),
		Accent = Color3.fromRGB(88, 101, 242),
		AccentHover = Color3.fromRGB(105, 118, 255),
		Text = Color3.fromRGB(242, 243, 245),
		TextSecondary = Color3.fromRGB(158, 162, 178),
		Border = Color3.fromRGB(48, 50, 64),
		Success = Color3.fromRGB(46, 204, 113),
		Danger = Color3.fromRGB(235, 60, 60),
		Warning = Color3.fromRGB(241, 196, 15),
	},
	Ruby = {
		Main = Color3.fromRGB(24, 16, 18),
		Sidebar = Color3.fromRGB(32, 20, 24),
		Header = Color3.fromRGB(32, 20, 24),
		Card = Color3.fromRGB(38, 24, 28),
		CardBorder = Color3.fromRGB(60, 36, 42),
		ControlBg = Color3.fromRGB(46, 28, 34),
		ControlHover = Color3.fromRGB(62, 38, 46),
		Accent = Color3.fromRGB(235, 60, 75),
		AccentHover = Color3.fromRGB(250, 80, 95),
		Text = Color3.fromRGB(245, 240, 242),
		TextSecondary = Color3.fromRGB(180, 155, 162),
		Border = Color3.fromRGB(65, 35, 42),
		Success = Color3.fromRGB(46, 204, 113),
		Danger = Color3.fromRGB(235, 60, 60),
		Warning = Color3.fromRGB(241, 196, 15),
	},
	Ocean = {
		Main = Color3.fromRGB(14, 22, 30),
		Sidebar = Color3.fromRGB(18, 28, 38),
		Header = Color3.fromRGB(18, 28, 38),
		Card = Color3.fromRGB(22, 34, 46),
		CardBorder = Color3.fromRGB(35, 54, 72),
		ControlBg = Color3.fromRGB(28, 44, 60),
		ControlHover = Color3.fromRGB(36, 56, 76),
		Accent = Color3.fromRGB(30, 160, 235),
		AccentHover = Color3.fromRGB(55, 180, 255),
		Text = Color3.fromRGB(240, 246, 250),
		TextSecondary = Color3.fromRGB(150, 180, 200),
		Border = Color3.fromRGB(40, 60, 80),
		Success = Color3.fromRGB(46, 204, 113),
		Danger = Color3.fromRGB(235, 60, 60),
		Warning = Color3.fromRGB(241, 196, 15),
	},
	Midnight = {
		Main = Color3.fromRGB(14, 12, 22),
		Sidebar = Color3.fromRGB(20, 17, 30),
		Header = Color3.fromRGB(20, 17, 30),
		Card = Color3.fromRGB(25, 21, 38),
		CardBorder = Color3.fromRGB(45, 38, 68),
		ControlBg = Color3.fromRGB(32, 27, 48),
		ControlHover = Color3.fromRGB(44, 38, 66),
		Accent = Color3.fromRGB(140, 95, 255),
		AccentHover = Color3.fromRGB(160, 120, 255),
		Text = Color3.fromRGB(245, 242, 252),
		TextSecondary = Color3.fromRGB(175, 165, 195),
		Border = Color3.fromRGB(50, 42, 75),
		Success = Color3.fromRGB(46, 204, 113),
		Danger = Color3.fromRGB(235, 60, 60),
		Warning = Color3.fromRGB(241, 196, 15),
	},
	Forest = {
		Main = Color3.fromRGB(14, 22, 16),
		Sidebar = Color3.fromRGB(18, 28, 20),
		Header = Color3.fromRGB(18, 28, 20),
		Card = Color3.fromRGB(22, 34, 25),
		CardBorder = Color3.fromRGB(36, 54, 40),
		ControlBg = Color3.fromRGB(28, 44, 32),
		ControlHover = Color3.fromRGB(36, 56, 42),
		Accent = Color3.fromRGB(46, 180, 88),
		AccentHover = Color3.fromRGB(62, 205, 108),
		Text = Color3.fromRGB(240, 248, 242),
		TextSecondary = Color3.fromRGB(155, 190, 165),
		Border = Color3.fromRGB(40, 62, 46),
		Success = Color3.fromRGB(46, 204, 113),
		Danger = Color3.fromRGB(235, 60, 60),
		Warning = Color3.fromRGB(241, 196, 15),
	},
	Light = {
		Main = Color3.fromRGB(244, 245, 248),
		Sidebar = Color3.fromRGB(235, 237, 242),
		Header = Color3.fromRGB(235, 237, 242),
		Card = Color3.fromRGB(255, 255, 255),
		CardBorder = Color3.fromRGB(218, 222, 230),
		ControlBg = Color3.fromRGB(228, 231, 238),
		ControlHover = Color3.fromRGB(218, 222, 230),
		Accent = Color3.fromRGB(24, 110, 240),
		AccentHover = Color3.fromRGB(15, 95, 220),
		Text = Color3.fromRGB(24, 27, 34),
		TextSecondary = Color3.fromRGB(92, 100, 114),
		Border = Color3.fromRGB(210, 215, 224),
		Success = Color3.fromRGB(34, 160, 88),
		Danger = Color3.fromRGB(220, 50, 50),
		Warning = Color3.fromRGB(210, 140, 10),
	},
	Blue = {
		Main = Color3.fromRGB(16, 24, 42),
		Sidebar = Color3.fromRGB(22, 34, 58),
		Header = Color3.fromRGB(22, 34, 58),
		Card = Color3.fromRGB(26, 40, 68),
		CardBorder = Color3.fromRGB(42, 64, 105),
		ControlBg = Color3.fromRGB(32, 50, 84),
		ControlHover = Color3.fromRGB(42, 64, 105),
		Accent = Color3.fromRGB(60, 125, 255),
		AccentHover = Color3.fromRGB(85, 145, 255),
		Text = Color3.fromRGB(242, 246, 255),
		TextSecondary = Color3.fromRGB(165, 185, 220),
		Border = Color3.fromRGB(45, 70, 115),
		Success = Color3.fromRGB(46, 204, 113),
		Danger = Color3.fromRGB(235, 60, 60),
		Warning = Color3.fromRGB(241, 196, 15),
	},
}

--[[------------------------------------------------------------------------------
    Core Helper Methods
--------------------------------------------------------------------------------]]

function GUI:GetConfigComponent()
	local genv = getGlobalEnv()
	if genv.AimbotESP and genv.AimbotESP.Components and genv.AimbotESP.Components.Config then
		return genv.AimbotESP.Components.Config
	end
	return nil
end

function GUI:GetActiveTheme()
	local cfg = self:GetConfigComponent()
	local themeName = (cfg and cfg:Get("world.theme")) or (cfg and cfg:Get("gui.theme")) or "Default"
	return self.Themes[themeName] or self.Themes.Default
end

local function createInstance(className, props, parent)
	local inst = Instance.new(className)
	local parentToSet = parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parentToSet = v
		else
			inst[k] = v
		end
	end
	if parentToSet then
		local ok = pcall(function()
			inst.Parent = parentToSet
		end)
		if not ok then
			-- Fallback to PlayerGui if CoreGui/parent is locked by executor identity
			pcall(function()
				local lp = Players.LocalPlayer
				local pg = lp and lp:FindFirstChildOfClass("PlayerGui")
				if pg then
					inst.Parent = pg
				end
			end)
		end
	end
	return inst
end

local function createCorner(radius, parent)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function createStroke(color, thickness, parent)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function createPadding(top, bottom, left, right, parent)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, top or 0)
	pad.PaddingBottom = UDim.new(0, bottom or 0)
	pad.PaddingLeft = UDim.new(0, left or 0)
	pad.PaddingRight = UDim.new(0, right or 0)
	pad.Parent = parent
	return pad
end

-- Procedural vector icon generator (strict no-emoji standard)
local function createVectorIcon(iconType, parent, size, color)
	local iconSize = size or 16
	local container = createInstance("Frame", {
		Name = iconType .. "Icon",
		Size = UDim2.fromOffset(iconSize, iconSize),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	if iconType == "crosshair" then
		local circle = createInstance("Frame", {
			Size = UDim2.fromOffset(iconSize - 4, iconSize - 4),
			Position = UDim2.fromOffset(2, 2),
			BackgroundTransparency = 1,
			Parent = container,
		})
		createCorner(iconSize, circle)
		createStroke(color, 1.2, circle)
		local dot = createInstance("Frame", {
			Size = UDim2.fromOffset(2, 2),
			Position = UDim2.new(0.5, -1, 0.5, -1),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = container,
		})
		createCorner(2, dot)
	elseif iconType == "trigger" then
		local barH = createInstance("Frame", {
			Size = UDim2.new(1, -4, 0, 2),
			Position = UDim2.new(0, 2, 0.5, -1),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = container,
		})
		local barV = createInstance("Frame", {
			Size = UDim2.new(0, 2, 1, -4),
			Position = UDim2.new(0.5, -1, 0, 2),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = container,
		})
	elseif iconType == "eye" then
		local frame = createInstance("Frame", {
			Size = UDim2.new(1, -2, 0.6, 0),
			Position = UDim2.new(0, 1, 0.2, 0),
			BackgroundTransparency = 1,
			Parent = container,
		})
		createCorner(6, frame)
		createStroke(color, 1.2, frame)
		local pupil = createInstance("Frame", {
			Size = UDim2.fromOffset(4, 4),
			Position = UDim2.new(0.5, -2, 0.5, -2),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = frame,
		})
		createCorner(4, pupil)
	elseif iconType == "world" then
		local grid = createInstance("Frame", {
			Size = UDim2.new(1, -4, 1, -4),
			Position = UDim2.fromOffset(2, 2),
			BackgroundTransparency = 1,
			Parent = container,
		})
		createCorner(3, grid)
		createStroke(color, 1.2, grid)
		local divider = createInstance("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 0.5, 0),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = grid,
		})
	elseif iconType == "shield" then
		local crest = createInstance("Frame", {
			Size = UDim2.new(0.8, 0, 0.9, 0),
			Position = UDim2.new(0.1, 0, 0.05, 0),
			BackgroundTransparency = 1,
			Parent = container,
		})
		createCorner(4, crest)
		createStroke(color, 1.2, crest)
	elseif iconType == "settings" then
		for i = 1, 3 do
			local line = createInstance("Frame", {
				Size = UDim2.new(1, -4, 0, 2),
				Position = UDim2.new(0, 2, 0, (i - 1) * 5 + 3),
				BackgroundColor3 = color,
				BorderSizePixel = 0,
				Parent = container,
			})
			local knot = createInstance("Frame", {
				Size = UDim2.fromOffset(3, 4),
				Position = UDim2.new(i == 2 and 0.6 or 0.25, 0, 0.5, -2),
				BackgroundColor3 = color,
				BorderSizePixel = 0,
				Parent = line,
			})
		end
	end

	return container
end

--[[------------------------------------------------------------------------------
    Toast Notification System
--------------------------------------------------------------------------------]]

function GUI:CreateToastContainer()
	if self.ToastContainer then
		self.ToastContainer:Destroy()
	end

	self.ToastContainer = createInstance("Frame", {
		Name = "ToastContainer",
		Size = UDim2.fromOffset(240, 260),
		Position = UDim2.new(1, -260, 0, 20),
		BackgroundTransparency = 1,
		ZIndex = 50,
		Parent = self.ScreenGui,
	})

	local layout = Instance.new("UIListLayout", self.ToastContainer)
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
end

function GUI:ShowToast(message, toastType, duration)
	if not self.ToastContainer then
		return
	end

	local theme = self:GetActiveTheme()
	local strokeColor = theme.Accent
	if toastType == "success" then
		strokeColor = theme.Success
	elseif toastType == "danger" or toastType == "error" then
		strokeColor = theme.Danger
	elseif toastType == "warning" then
		strokeColor = theme.Warning
	end

	local toast = createInstance("Frame", {
		Size = UDim2.new(1, 0, 0, 36),
		Position = UDim2.fromOffset(40, 0),
		BackgroundColor3 = theme.Header,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		ZIndex = 51,
		Parent = self.ToastContainer,
	})
	createCorner(6, toast)
	createStroke(strokeColor, 1.2, toast)

	local indicator = createInstance("Frame", {
		Size = UDim2.new(0, 4, 1, -12),
		Position = UDim2.new(0, 6, 0.5, -6),
		BackgroundColor3 = strokeColor,
		BorderSizePixel = 0,
		ZIndex = 52,
		Parent = toast,
	})
	createCorner(2, indicator)

	local label = createInstance("TextLabel", {
		Size = UDim2.new(1, -24, 1, 0),
		Position = UDim2.new(0, 16, 0, 0),
		BackgroundTransparency = 1,
		Text = message,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 52,
		Parent = toast,
	})

	-- Smooth slide-in
	toast.Position = UDim2.new(1, 40, 0, 0)
	TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0),
	}):Play()

	-- Auto-dismissal
	task.delay(duration or 2.5, function()
		if toast and toast.Parent then
			local fade = TweenService:Create(
				toast,
				TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
				{ Position = UDim2.new(1, 40, 0, 0), BackgroundTransparency = 1 }
			)
			fade:Play()
			fade.Completed:Connect(function()
				toast:Destroy()
			end)
		end
	end)
end

--[[------------------------------------------------------------------------------
    ScreenGui & Main Window Construction
--------------------------------------------------------------------------------]]

function GUI:CreateScreenGui()
	if self.ScreenGui then
		self.ScreenGui:Destroy()
	end

	local genv = getGlobalEnv()
	local utils = genv.AimbotESP and genv.AimbotESP.Components and genv.AimbotESP.Components.Utils
	local parent = utils and utils:GetSafeGuiParent() or game:GetService("CoreGui")

	self.ScreenGui = createInstance("ScreenGui", {
		Name = "AimbotESPGUI_V2",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = parent,
	})

	self:CreateToastContainer()
end

function GUI:CreateMainInterface()
	local theme = self:GetActiveTheme()

	-- Window Dimensions
	local winWidth = 600
	local winHeight = 440

	local mainFrame = createInstance("Frame", {
		Name = "MainFrame",
		Size = UDim2.fromOffset(winWidth, winHeight),
		Position = UDim2.new(0.5, -winWidth / 2, 0.5, -winHeight / 2),
		BackgroundColor3 = theme.Main,
		BorderSizePixel = 0,
		Active = true,
		ClipsDescendants = true,
		Parent = self.ScreenGui,
	})
	createCorner(8, mainFrame)
	local mainStroke = createStroke(theme.Border, 1.2, mainFrame)

	self.MainFrame = mainFrame
	self.Elements.MainStroke = mainStroke
	table.insert(self.Elements.Frames, mainFrame)

	-- Custom Background Image
	local bgImage = createInstance("ImageLabel", {
		Name = "BackgroundImage",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = "",
		ImageTransparency = 0.85,
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 0,
		Parent = mainFrame,
	})
	self.Elements.BackgroundImage = bgImage

	-- Sidebar Navigation
	local sidebarWidth = 160
	local sidebar = createInstance("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, sidebarWidth, 1, 0),
		Position = UDim2.fromScale(0, 0),
		BackgroundColor3 = theme.Sidebar,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = mainFrame,
	})
	createCorner(8, sidebar)
	table.insert(self.Elements.Sidebars, sidebar)
	self.Elements.Sidebar = sidebar

	-- Sidebar Brand / Logo Header
	local brandBox = createInstance("Frame", {
		Name = "BrandBox",
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = sidebar,
	})

	local brandTitle = createInstance("TextLabel", {
		Name = "BrandTitle",
		Size = UDim2.new(1, -20, 0, 22),
		Position = UDim2.new(0, 16, 0, 12),
		BackgroundTransparency = 1,
		Text = "APEX SUITE",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = theme.Accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
		Parent = brandBox,
	})
	table.insert(self.Elements.Accents, brandTitle)

	local brandSubtitle = createInstance("TextLabel", {
		Name = "BrandSubtitle",
		Size = UDim2.new(1, -20, 0, 14),
		Position = UDim2.new(0, 16, 0, 32),
		BackgroundTransparency = 1,
		Text = "System Configuration",
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextColor3 = theme.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
		Parent = brandBox,
	})
	table.insert(self.Elements.TextSecondary, brandSubtitle)

	-- Top Header Bar (Draggable & Window Controls)
	local headerBar = createInstance("Frame", {
		Name = "HeaderBar",
		Size = UDim2.new(1, -sidebarWidth, 0, 42),
		Position = UDim2.new(0, sidebarWidth, 0, 0),
		BackgroundColor3 = theme.Header,
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = mainFrame,
	})
	table.insert(self.Elements.Headers, headerBar)
	self.Elements.HeaderBar = headerBar

	-- Active Page Title Breadcrumb
	local pageTitle = createInstance("TextLabel", {
		Name = "PageTitle",
		Size = UDim2.new(1, -100, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = "AimBot Configuration",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 6,
		Parent = headerBar,
	})
	self.Elements.PageTitle = pageTitle
	table.insert(self.Elements.TextPrimary, pageTitle)

	-- Window Minimize & Close Action Buttons
	local minBtn = createInstance("TextButton", {
		Name = "MinBtn",
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.new(1, -56, 0.5, -12),
		BackgroundColor3 = theme.ControlBg,
		Text = "-",
		TextColor3 = theme.TextSecondary,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		ZIndex = 7,
		Parent = headerBar,
	})
	createCorner(4, minBtn)
	createStroke(theme.CardBorder, 1, minBtn)
	table.insert(self.Elements.ControlBackgrounds, minBtn)

	local closeBtn = createInstance("TextButton", {
		Name = "CloseBtn",
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.new(1, -28, 0.5, -12),
		BackgroundColor3 = theme.ControlBg,
		Text = "x",
		TextColor3 = theme.TextSecondary,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		ZIndex = 7,
		Parent = headerBar,
	})
	createCorner(4, closeBtn)
	createStroke(theme.CardBorder, 1, closeBtn)
	table.insert(self.Elements.ControlBackgrounds, closeBtn)

	-- Minimized floating Pill Button
	local openBtn = createInstance("TextButton", {
		Name = "OpenPillBtn",
		Size = UDim2.fromOffset(100, 32),
		Position = UDim2.new(1, -115, 0.5, -16),
		BackgroundColor3 = theme.Header,
		Text = "Open Menu",
		TextColor3 = theme.Accent,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		Visible = false,
		ZIndex = 20,
		Parent = self.ScreenGui,
	})
	createCorner(6, openBtn)
	createStroke(theme.Accent, 1.2, openBtn)
	self.OpenBtn = openBtn

	-- Minimize & Restore Animations
	local animTween = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

	minBtn.MouseButton1Click:Connect(function()
		local hideTween = TweenService:Create(mainFrame, animTween, {
			Position = UDim2.new(0.5, -winWidth / 2, 1.2, 0),
		})
		hideTween:Play()
		hideTween.Completed:Connect(function()
			mainFrame.Visible = false
			openBtn.Visible = true
			openBtn.Position = UDim2.new(1, 20, 0.5, -16)
			TweenService:Create(openBtn, animTween, { Position = UDim2.new(1, -115, 0.5, -16) }):Play()
		end)
	end)

	openBtn.MouseButton1Click:Connect(function()
		local hidePill = TweenService:Create(openBtn, animTween, { Position = UDim2.new(1, 20, 0.5, -16) })
		hidePill:Play()
		hidePill.Completed:Connect(function()
			openBtn.Visible = false
			mainFrame.Visible = true
			TweenService:Create(mainFrame, animTween, {
				Position = UDim2.new(0.5, -winWidth / 2, 0.5, -winHeight / 2),
			}):Play()
		end)
	end)

	closeBtn.MouseButton1Click:Connect(function()
		self:SetVisible(false)
	end)

	-- Tab Container in Sidebar
	local tabContainer = createInstance("Frame", {
		Name = "TabContainer",
		Size = UDim2.new(1, -16, 1, -65),
		Position = UDim2.new(0, 8, 0, 55),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = sidebar,
	})
	local tabLayout = Instance.new("UIListLayout", tabContainer)
	tabLayout.Padding = UDim.new(0, 3)
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	self.Elements.TabContainer = tabContainer

	-- Search Bar Header within Content Area
	local searchContainer = createInstance("Frame", {
		Name = "SearchContainer",
		Size = UDim2.new(1, -sidebarWidth - 20, 0, 30),
		Position = UDim2.new(0, sidebarWidth + 10, 0, 48),
		BackgroundColor3 = theme.Card,
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = mainFrame,
	})
	createCorner(5, searchContainer)
	local searchStroke = createStroke(theme.CardBorder, 1, searchContainer)
	table.insert(self.Elements.Cards, searchContainer)
	table.insert(self.Elements.CardBorders, searchStroke)

	local searchIcon = createInstance("TextLabel", {
		Size = UDim2.fromOffset(24, 30),
		BackgroundTransparency = 1,
		Text = ">",
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = theme.TextSecondary,
		ZIndex = 5,
		Parent = searchContainer,
	})
	table.insert(self.Elements.TextSecondary, searchIcon)

	local searchBox = createInstance("TextBox", {
		Name = "SearchBox",
		Size = UDim2.new(1, -54, 1, 0),
		Position = UDim2.fromOffset(24, 0),
		BackgroundTransparency = 1,
		PlaceholderText = "Search settings...",
		PlaceholderColor3 = theme.TextSecondary,
		Text = "",
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = theme.Text,
		ClearTextOnFocus = false,
		ZIndex = 5,
		Parent = searchContainer,
	})
	table.insert(self.Elements.TextPrimary, searchBox)

	local clearBtn = createInstance("TextButton", {
		Size = UDim2.fromOffset(20, 20),
		Position = UDim2.new(1, -24, 0.5, -10),
		BackgroundTransparency = 1,
		Text = "x",
		TextColor3 = theme.TextSecondary,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		Visible = false,
		ZIndex = 5,
		Parent = searchContainer,
	})

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local query = string.lower(searchBox.Text)
		self.SearchQuery = query
		clearBtn.Visible = #query > 0
		self:FilterControls(query)
	end)

	clearBtn.MouseButton1Click:Connect(function()
		searchBox.Text = ""
	end)

	-- Content Area for Tab Pages
	local contentArea = createInstance("Frame", {
		Name = "ContentArea",
		Size = UDim2.new(1, -sidebarWidth - 20, 1, -116),
		Position = UDim2.new(0, sidebarWidth + 10, 0, 84),
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = mainFrame,
	})
	self.Elements.ContentArea = contentArea
end

--[[------------------------------------------------------------------------------
    Tab Generation & Navigation
--------------------------------------------------------------------------------]]

function GUI:CreateTabs()
	local categories = {
		{ Id = "Aimbot", Name = "AimBot", Icon = "crosshair", Title = "AimBot & Trajectory Engine" },
		{ Id = "TriggerBot", Name = "TriggerBot", Icon = "trigger", Title = "Universal TriggerBot Controls" },
		{ Id = "Visuals", Name = "Visuals & ESP", Icon = "eye", Title = "ESP & Sensory Visualization" },
		{ Id = "World", Name = "World & Visuals", Icon = "world", Title = "Environment, Themes & Colors" },
		{ Id = "AntiCheat", Name = "Security & Stealth", Icon = "shield", Title = "Anti-Detection & Throttling" },
		{ Id = "Settings", Name = "Settings & Profiles", Icon = "settings", Title = "Configuration Profiles & Hotkeys" },
	}

	for idx, cat in ipairs(categories) do
		local theme = self:GetActiveTheme()

		local btn = createInstance("TextButton", {
			Name = cat.Id .. "TabBtn",
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = theme.Sidebar,
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = idx,
			ZIndex = 4,
			Parent = self.Elements.TabContainer,
		})
		createCorner(5, btn)

		-- Active indicator left bar
		local indicator = createInstance("Frame", {
			Name = "ActiveIndicator",
			Size = UDim2.new(0, 3, 0.6, 0),
			Position = UDim2.new(0, 4, 0.2, 0),
			BackgroundColor3 = theme.Accent,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 5,
			Parent = btn,
		})
		createCorner(2, indicator)
		table.insert(self.Elements.Accents, indicator)

		-- Vector icon
		local iconFrame = createVectorIcon(cat.Icon, btn, 14, theme.TextSecondary)
		iconFrame.Position = UDim2.new(0, 14, 0.5, -7)
		iconFrame.ZIndex = 5

		-- Tab Title Label
		local label = createInstance("TextLabel", {
			Name = "TabLabel",
			Size = UDim2.new(1, -38, 1, 0),
			Position = UDim2.new(0, 36, 0, 0),
			BackgroundTransparency = 1,
			Text = cat.Name,
			Font = Enum.Font.GothamMedium,
			TextSize = 11,
			TextColor3 = theme.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 5,
			Parent = btn,
		})

		self.Elements.TabButtons[cat.Id] = {
			Button = btn,
			Indicator = indicator,
			Label = label,
			Icon = iconFrame,
			Title = cat.Title,
		}

		-- Scrollable Page for Tab Content
		local page = createInstance("ScrollingFrame", {
			Name = cat.Id .. "Page",
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromScale(0, 0),
			BackgroundTransparency = 1,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = theme.CardBorder,
			Visible = false,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ZIndex = 4,
			Parent = self.Elements.ContentArea,
		})
		local listLayout = Instance.new("UIListLayout", page)
		listLayout.Padding = UDim.new(0, 8)
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		createPadding(2, 8, 2, 6, page)

		self.Elements.TabPages[cat.Id] = page

		btn.MouseButton1Click:Connect(function()
			self:SwitchTab(cat.Id)
		end)
	end

	-- Populate controls inside each tab
	self:PopulateAimbotTab()
	self:PopulateTriggerBotTab()
	self:PopulateVisualsTab()
	self:PopulateWorldTab()
	self:PopulateAntiCheatTab()
	self:PopulateSettingsTab()

	-- Activate first tab
	self:SwitchTab("Aimbot")
end

function GUI:SwitchTab(tabId)
	local theme = self:GetActiveTheme()
	self.CurrentTab = tabId

	for id, tabData in pairs(self.Elements.TabButtons) do
		local page = self.Elements.TabPages[id]
		local isCurrent = (id == tabId)

		if isCurrent then
			tabData.Button.BackgroundTransparency = 0
			tabData.Button.BackgroundColor3 = theme.Card
			tabData.Indicator.Visible = true
			tabData.Label.TextColor3 = theme.Text
			tabData.Label.Font = Enum.Font.GothamBold

			if self.Elements.PageTitle then
				self.Elements.PageTitle.Text = tabData.Title
			end

			if page then
				page.Visible = true
			end
		else
			tabData.Button.BackgroundTransparency = 1
			tabData.Indicator.Visible = false
			tabData.Label.TextColor3 = theme.TextSecondary
			tabData.Label.Font = Enum.Font.GothamMedium

			if page then
				page.Visible = false
			end
		end
	end

	-- Re-apply search filter on tab switch
	if #self.SearchQuery > 0 then
		self:FilterControls(self.SearchQuery)
	end
end

-- Filter controls across current tab based on search query
function GUI:FilterControls(query)
	local currentPage = self.Elements.TabPages[self.CurrentTab]
	if not currentPage then
		return
	end

	for _, child in ipairs(currentPage:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("Card$") then
			if #query == 0 then
				child.Visible = true
			else
				local match = false
				local titleLabel = child:FindFirstChild("CardTitle")
				if titleLabel and string.find(string.lower(titleLabel.Text), query, 1, true) then
					match = true
				end

				-- Check child control labels
				for _, sub in ipairs(child:GetDescendants()) do
					if sub:IsA("TextLabel") and string.find(string.lower(sub.Text), query, 1, true) then
						match = true
						break
					end
				end
				child.Visible = match
			end
		end
	end
end

--[[------------------------------------------------------------------------------
    Control Component Builders (Section Cards, Switches, Sliders, Segments)
--------------------------------------------------------------------------------]]

-- Section Card: Groups related controls with clear surface hierarchy
function GUI:CreateSectionCard(page, titleText, descText)
	local theme = self:GetActiveTheme()

	local card = createInstance("Frame", {
		Name = titleText:gsub("%s+", "") .. "Card",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.Card,
		BorderSizePixel = 0,
		Parent = page,
	})
	createCorner(6, card)
	local cardStroke = createStroke(theme.CardBorder, 1, card)
	createPadding(10, 10, 12, 12, card)

	local cardLayout = Instance.new("UIListLayout", card)
	cardLayout.Padding = UDim.new(0, 8)
	cardLayout.SortOrder = Enum.SortOrder.LayoutOrder

	table.insert(self.Elements.Cards, card)
	table.insert(self.Elements.CardBorders, cardStroke)

	-- Header Box
	local headerBox = createInstance("Frame", {
		Name = "HeaderBox",
		Size = UDim2.new(1, 0, 0, descText and 26 or 16),
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		Parent = card,
	})

	local titleLabel = createInstance("TextLabel", {
		Name = "CardTitle",
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		Text = string.upper(titleText),
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextColor3 = theme.Accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = headerBox,
	})
	table.insert(self.Elements.Accents, titleLabel)

	if descText then
		local descLabel = createInstance("TextLabel", {
			Name = "CardDesc",
			Size = UDim2.new(1, 0, 0, 12),
			Position = UDim2.fromOffset(0, 14),
			BackgroundTransparency = 1,
			Text = descText,
			Font = Enum.Font.Gotham,
			TextSize = 9,
			TextColor3 = theme.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = headerBox,
		})
		table.insert(self.Elements.TextSecondary, descLabel)
	end

	return card
end

-- Animated Switch / Toggle
function GUI:CreateToggle(card, labelText, descText, configPath, callback)
	local cfg = self:GetConfigComponent()
	local theme = self:GetActiveTheme()

	local frame = createInstance("Frame", {
		Size = UDim2.new(1, 0, 0, descText and 36 or 26),
		BackgroundTransparency = 1,
		Parent = card,
	})

	local textContainer = createInstance("Frame", {
		Size = UDim2.new(1, -48, 1, 0),
		BackgroundTransparency = 1,
		Parent = frame,
	})

	local label = createInstance("TextLabel", {
		Size = UDim2.new(1, 0, 0, 15),
		Position = UDim2.fromOffset(0, descText and 1 or 5),
		BackgroundTransparency = 1,
		Text = labelText,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = textContainer,
	})
	table.insert(self.Elements.TextPrimary, label)

	if descText then
		local desc = createInstance("TextLabel", {
			Size = UDim2.new(1, 0, 0, 12),
			Position = UDim2.fromOffset(0, 17),
			BackgroundTransparency = 1,
			Text = descText,
			Font = Enum.Font.Gotham,
			TextSize = 9,
			TextColor3 = theme.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = textContainer,
		})
		table.insert(self.Elements.TextSecondary, desc)
	end

	local toggleBtn = createInstance("TextButton", {
		Size = UDim2.fromOffset(38, 20),
		Position = UDim2.new(1, -38, 0.5, -10),
		BackgroundColor3 = theme.ControlBg,
		Text = "",
		AutoButtonColor = false,
		Parent = frame,
	})
	createCorner(10, toggleBtn)
	local toggleStroke = createStroke(theme.CardBorder, 1, toggleBtn)

	local circle = createInstance("Frame", {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, 3, 0.5, -7),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = toggleBtn,
	})
	createCorner(7, circle)

	local function updateVisual(state)
		local activeColor = self:GetActiveTheme().Accent
		local offColor = self:GetActiveTheme().ControlBg
		TweenService:Create(toggleBtn, TweenInfo.new(0.18), {
			BackgroundColor3 = state and activeColor or offColor,
		}):Play()
		TweenService:Create(circle, TweenInfo.new(0.18), {
			Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
		}):Play()
	end

	local initialState = cfg and cfg:Get(configPath) or false
	updateVisual(initialState)

	toggleBtn.MouseButton1Click:Connect(function()
		local current = cfg and cfg:Get(configPath) or false
		local newState = not current
		if cfg then
			cfg:Set(configPath, newState)
		end
		updateVisual(newState)
		if callback then
			callback(newState)
		end
	end)

	table.insert(self.Elements.Toggles, {
		Button = toggleBtn,
		Stroke = toggleStroke,
		ConfigPath = configPath,
		Update = updateVisual,
	})

	return frame
end

-- Precision Slider: Dual-input scrub/seek with bounds clamping and units
function GUI:CreateSlider(card, labelText, descText, configPath, minVal, maxVal, isDecimal, unit, callback)
	local cfg = self:GetConfigComponent()
	local theme = self:GetActiveTheme()

	local frame = createInstance("Frame", {
		Size = UDim2.new(1, 0, 0, descText and 46 or 38),
		BackgroundTransparency = 1,
		Parent = card,
	})

	local topRow = createInstance("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Parent = frame,
	})

	local label = createInstance("TextLabel", {
		Size = UDim2.new(1, -70, 1, 0),
		BackgroundTransparency = 1,
		Text = labelText,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = topRow,
	})
	table.insert(self.Elements.TextPrimary, label)

	local currentVal = cfg and cfg:Get(configPath) or minVal
	local valuePill = createInstance("TextLabel", {
		Size = UDim2.fromOffset(60, 16),
		Position = UDim2.new(1, -60, 0, 0),
		BackgroundColor3 = theme.ControlBg,
		Text = tostring(currentVal) .. (unit or ""),
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextColor3 = theme.Accent,
		Parent = topRow,
	})
	createCorner(3, valuePill)
	table.insert(self.Elements.ControlBackgrounds, valuePill)
	table.insert(self.Elements.Accents, valuePill)

	local sliderTrack = createInstance("TextButton", {
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.new(0, 0, 1, -8),
		BackgroundColor3 = theme.ControlBg,
		Text = "",
		AutoButtonColor = false,
		Parent = frame,
	})
	createCorner(3, sliderTrack)
	table.insert(self.Elements.ControlBackgrounds, sliderTrack)

	local initialPct = math.clamp((currentVal - minVal) / (maxVal - minVal), 0, 1)
	local sliderFill = createInstance("Frame", {
		Size = UDim2.new(initialPct, 0, 1, 0),
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Parent = sliderTrack,
	})
	createCorner(3, sliderFill)
	table.insert(self.Elements.Accents, sliderFill)

	local thumb = createInstance("Frame", {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.new(1, -6, 0.5, -6),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = sliderFill,
	})
	createCorner(6, thumb)

	local dragging = false
	local function updateSliderFromInput(input)
		local relX = input.Position.X - sliderTrack.AbsolutePosition.X
		local pct = math.clamp(relX / sliderTrack.AbsoluteSize.X, 0, 1)
		local rawVal = minVal + (pct * (maxVal - minVal))
		local finalVal = isDecimal and tonumber(string.format("%.2f", rawVal)) or math.floor(rawVal + 0.5)

		sliderFill.Size = UDim2.new(pct, 0, 1, 0)
		valuePill.Text = tostring(finalVal) .. (unit or "")

		if cfg then
			cfg:Set(configPath, finalVal)
		end
		if callback then
			callback(finalVal)
		end
	end

	sliderTrack.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			updateSliderFromInput(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			updateSliderFromInput(input)
		end
	end)

	table.insert(self.Elements.Sliders, {
		Fill = sliderFill,
		Pill = valuePill,
		ConfigPath = configPath,
		Min = minVal,
		Max = maxVal,
		Unit = unit,
	})

	return frame
end

-- Segmented Control: Replaces blind cyclers with visible, one-click choice buttons
function GUI:CreateSegmented(card, labelText, configPath, options, callback)
	local cfg = self:GetConfigComponent()
	local theme = self:GetActiveTheme()

	local frame = createInstance("Frame", {
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundTransparency = 1,
		Parent = card,
	})

	local label = createInstance("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Text = labelText,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	table.insert(self.Elements.TextPrimary, label)

	local group = createInstance("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.new(0, 0, 0, 20),
		BackgroundColor3 = theme.ControlBg,
		BorderSizePixel = 0,
		Parent = frame,
	})
	createCorner(4, group)
	table.insert(self.Elements.ControlBackgrounds, group)

	local btnCount = #options
	local buttons = {}
	local initialVal = tostring(cfg and cfg:Get(configPath) or options[1])

	local function updateSelection(selectedOpt)
		for opt, b in pairs(buttons) do
			local isSel = (opt == selectedOpt)
			local activeColor = self:GetActiveTheme().Accent
			local normColor = self:GetActiveTheme().ControlBg
			b.BackgroundColor3 = isSel and activeColor or normColor
			b.TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or self:GetActiveTheme().TextSecondary
		end
	end

	for i, opt in ipairs(options) do
		local optStr = tostring(opt)
		local optBtn = createInstance("TextButton", {
			Size = UDim2.new(1 / btnCount, -2, 1, -2),
			Position = UDim2.new((i - 1) / btnCount, 1, 0, 1),
			BackgroundColor3 = (optStr == initialVal) and theme.Accent or theme.ControlBg,
			Text = optStr,
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			TextColor3 = (optStr == initialVal) and Color3.fromRGB(255, 255, 255) or theme.TextSecondary,
			AutoButtonColor = false,
			Parent = group,
		})
		createCorner(3, optBtn)
		buttons[optStr] = optBtn

		optBtn.MouseButton1Click:Connect(function()
			if cfg then
				cfg:Set(configPath, opt)
			end
			updateSelection(optStr)
			if callback then
				callback(opt)
			end
		end)
	end

	table.insert(self.Elements.Segments, {
		Buttons = buttons,
		ConfigPath = configPath,
		Update = updateSelection,
	})

	return frame
end

-- Dropdown / Option Picker (for larger sets like Themes and Colors)
function GUI:CreateDropdown(card, labelText, configPath, options, callback)
	local cfg = self:GetConfigComponent()
	local theme = self:GetActiveTheme()

	local frame = createInstance("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		Parent = card,
	})

	local label = createInstance("TextLabel", {
		Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = labelText,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	table.insert(self.Elements.TextPrimary, label)

	local initial = tostring(cfg and cfg:Get(configPath) or options[1])
	local btn = createInstance("TextButton", {
		Size = UDim2.new(0.48, 0, 0, 24),
		Position = UDim2.new(0.52, 0, 0.5, -12),
		BackgroundColor3 = theme.ControlBg,
		Text = initial .. " v",
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextColor3 = theme.Text,
		AutoButtonColor = false,
		Parent = frame,
	})
	createCorner(4, btn)
	createStroke(theme.CardBorder, 1, btn)
	table.insert(self.Elements.ControlBackgrounds, btn)
	table.insert(self.Elements.TextPrimary, btn)

	btn.MouseButton1Click:Connect(function()
		local current = cfg and cfg:Get(configPath) or options[1]
		local idx = 1
		for i, opt in ipairs(options) do
			if tostring(opt) == tostring(current) then
				idx = i
				break
			end
		end
		local nextOpt = options[(idx % #options) + 1]
		btn.Text = tostring(nextOpt) .. " v"

		if cfg then
			cfg:Set(configPath, nextOpt)
		end
		if callback then
			callback(nextOpt)
		end
	end)

	return frame
end

-- Styled Text Input Box
function GUI:CreateTextInput(card, labelText, configPath, placeholder, callback)
	local cfg = self:GetConfigComponent()
	local theme = self:GetActiveTheme()

	local frame = createInstance("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		Parent = card,
	})

	local label = createInstance("TextLabel", {
		Size = UDim2.new(0.42, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = labelText,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	table.insert(self.Elements.TextPrimary, label)

	local initial = tostring(cfg and cfg:Get(configPath) or "")
	local box = createInstance("TextBox", {
		Size = UDim2.new(0.56, 0, 0, 24),
		Position = UDim2.new(0.44, 0, 0.5, -12),
		BackgroundColor3 = theme.ControlBg,
		Text = initial,
		PlaceholderText = placeholder or "Type here...",
		PlaceholderColor3 = theme.TextSecondary,
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextColor3 = theme.Text,
		ClearTextOnFocus = false,
		Parent = frame,
	})
	createCorner(4, box)
	local boxStroke = createStroke(theme.CardBorder, 1, box)
	table.insert(self.Elements.ControlBackgrounds, box)
	table.insert(self.Elements.TextPrimary, box)

	box.Focused:Connect(function()
		boxStroke.Color = self:GetActiveTheme().Accent
	end)

	box.FocusLost:Connect(function()
		boxStroke.Color = self:GetActiveTheme().CardBorder
		if cfg then
			cfg:Set(configPath, box.Text)
		end
		if callback then
			callback(box.Text)
		end
	end)

	return frame
end

-- Distinct Action Button: Primary (Accent), Secondary (Surface), Destructive (Danger)
function GUI:CreateActionButton(card, labelText, descText, btnText, variant, callback)
	local theme = self:GetActiveTheme()

	local frame = createInstance("Frame", {
		Size = UDim2.new(1, 0, 0, descText and 36 or 28),
		BackgroundTransparency = 1,
		Parent = card,
	})

	local textContainer = createInstance("Frame", {
		Size = UDim2.new(0.55, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = frame,
	})

	local label = createInstance("TextLabel", {
		Size = UDim2.new(1, 0, 0, 15),
		Position = UDim2.fromOffset(0, descText and 1 or 6),
		BackgroundTransparency = 1,
		Text = labelText,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = textContainer,
	})
	table.insert(self.Elements.TextPrimary, label)

	if descText then
		local desc = createInstance("TextLabel", {
			Size = UDim2.new(1, 0, 0, 12),
			Position = UDim2.fromOffset(0, 17),
			BackgroundTransparency = 1,
			Text = descText,
			Font = Enum.Font.Gotham,
			TextSize = 9,
			TextColor3 = theme.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = textContainer,
		})
		table.insert(self.Elements.TextSecondary, desc)
	end

	local btnBg = theme.Accent
	local btnTextCol = Color3.fromRGB(255, 255, 255)
	if variant == "secondary" then
		btnBg = theme.ControlBg
		btnTextCol = theme.Text
	elseif variant == "danger" then
		btnBg = theme.Danger
	end

	local btn = createInstance("TextButton", {
		Size = UDim2.new(0.42, 0, 0, 24),
		Position = UDim2.new(0.58, 0, 0.5, -12),
		BackgroundColor3 = btnBg,
		Text = btnText,
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextColor3 = btnTextCol,
		AutoButtonColor = true,
		Parent = frame,
	})
	createCorner(4, btn)

	if variant == "primary" then
		table.insert(self.Elements.Accents, btn)
	elseif variant == "secondary" then
		createStroke(theme.CardBorder, 1, btn)
		table.insert(self.Elements.ControlBackgrounds, btn)
	end

	btn.MouseButton1Click:Connect(function()
		if callback then
			callback()
		end
	end)

	return frame
end

--[[------------------------------------------------------------------------------
    Tab Population: Feature Set Organization into Cards
--------------------------------------------------------------------------------]]

function GUI:PopulateAimbotTab()
	local page = self.Elements.TabPages["Aimbot"]

	-- Card 1: Core Aim Engine
	local cardCore = self:CreateSectionCard(page, "Core Aim Engine", "Execution modes, snapping, and locking parameters")
	self:CreateToggle(cardCore, "Enable AimBot", "Master hardware and camera aimbot activation", "aimbot.enabled")
	self:CreateToggle(
		cardCore,
		"Aggressive Instant Snap",
		"Bypasses smoothing for instantaneous target acquisition",
		"aimbot.aggressiveMode"
	)
	self:CreateToggle(
		cardCore,
		"Sticky Aim Lock",
		"Maintains lock on current target until destroyed or occluded",
		"aimbot.aimLock"
	)
	self:CreateSegmented(
		cardCore,
		"Aim Execution Mode",
		"aimbot.aimMode",
		{ "Hybrid", "Camera", "Mouse" }
	)

	-- Card 2: Target Acquisition & Filters
	local cardAcq = self:CreateSectionCard(
		page,
		"Target Acquisition & Filters",
		"Part targeting, priority algorithms, and team isolation"
	)
	self:CreateSegmented(
		cardAcq,
		"Target Body Part",
		"aimbot.targetPart",
		{ "Head", "Torso", "Smart", "RootPart" },
		function(part)
			self:ShowToast("Target part set to: " .. tostring(part), "info")
		end
	)
	self:CreateSegmented(
		cardAcq,
		"Target Priority Mode",
		"aimbot.priorityMode",
		{ "Distance", "Health", "Threat", "Crosshair" }
	)
	self:CreateToggle(cardAcq, "Line-of-Sight Check", "Verifies raycast clearance before acquiring target", "aimbot.visibilityCheck")
	self:CreateToggle(cardAcq, "Team Filter Check", "Ignores players assigned to local player team", "aimbot.teamCheck")
	self:CreateToggle(cardAcq, "Target NPCs / Bots", "Acquires valid non-player humanoid characters", "aimbot.targetNPCs")

	-- Card 3: Dynamics & Tracking
	local cardDyn = self:CreateSectionCard(page, "Dynamics & Tracking", "Field-of-view limits, lerp smoothing, and trajectory prediction")
	self:CreateSlider(cardDyn, "Field of View (FOV)", nil, "aimbot.fov", 10, 180, false, " deg")
	self:CreateSlider(cardDyn, "Aim Smoothness", nil, "aimbot.smoothness", 1, 30, false, "x")
	self:CreateToggle(cardDyn, "Velocity Prediction", "Calculates target movement and velocity compensation", "aimbot.prediction")
	self:CreateToggle(cardDyn, "Display FOV Circle", "Renders field of view boundary circle", "aimbot.showFOV")
end

function GUI:PopulateTriggerBotTab()
	local page = self.Elements.TabPages["TriggerBot"]

	local cardTrigger = self:CreateSectionCard(
		page,
		"Automatic Trigger",
		"Fires instantly upon enemy crosshair alignment"
	)
	self:CreateToggle(cardTrigger, "Enable TriggerBot", "Master trigger activation", "triggerBot.enabled")
	self:CreateToggle(
		cardTrigger,
		"Require Equipped Tool",
		"Only triggers when holding a valid weapon or tool",
		"triggerBot.requireTool"
	)
	self:CreateToggle(cardTrigger, "Team Filter Check", "Prevents firing at teammates", "triggerBot.teamCheck")
	self:CreateToggle(cardTrigger, "Target NPCs / Bots", "Allows trigger detection on humanoid NPCs", "triggerBot.targetNPCs")

	local cardLimits = self:CreateSectionCard(page, "Timings & Distance", "Firing delays and operational distance boundaries")
	self:CreateSlider(cardLimits, "Trigger Delay", nil, "triggerBot.delay", 0.01, 0.50, true, "s")
	self:CreateSlider(cardLimits, "Maximum Distance", nil, "triggerBot.maxDistance", 100, 3000, false, " studs")
end

function GUI:PopulateVisualsTab()
	local page = self.Elements.TabPages["Visuals"]

	local cardFilter = self:CreateSectionCard(page, "Master Visuals & Filters", "Sensory perception activation and distance culling")
	self:CreateToggle(cardFilter, "Master ESP", "Master switch for all visual overlays", "esp.enabled")
	self:CreateToggle(cardFilter, "Render Teammates", "Visualizes friendly players", "esp.showTeammates")
	self:CreateToggle(cardFilter, "Target NPC Support", "Visualizes non-player humanoid entities", "esp.targetNPCs")
	self:CreateSlider(cardFilter, "Max Render Distance", nil, "esp.maxDistance", 100, 3000, false, " studs")

	local cardGeometry = self:CreateSectionCard(page, "Geometry & Character Rigs", "Projected boxes, skeletons, and head indicators")
	self:CreateToggle(cardGeometry, "Bounding Boxes", "Uninverting 3D-to-2D projected boxes", "esp.boxes")
	self:CreateSegmented(cardGeometry, "Bounding Box Style", "esp.boxType", { "2D", "Corner" })
	self:CreateToggle(cardGeometry, "Bone Skeletons", "Real-time joint tracking for R6 and R15 rigs", "esp.skeleton")
	self:CreateToggle(cardGeometry, "Precision Head Dot", "Precision marker placed on target heads", "esp.headDot")

	local cardTracers = self:CreateSectionCard(page, "Tracers & Snaplines", "Directional lines from viewport origin to target")
	self:CreateToggle(cardTracers, "Enable Tracers", "Draws snapline to tracked entities", "esp.tracers")
	self:CreateSegmented(cardTracers, "Tracer Origin", "esp.tracerOrigin", { "Bottom", "Center", "Top" })

	local cardInfo = self:CreateSectionCard(page, "HUD Information Overlays", "Health indicators, player names, and inventory status")
	self:CreateToggle(cardInfo, "Health Bars", "Vertical dynamic health bar indicator", "esp.healthBars")
	self:CreateToggle(cardInfo, "Numeric Health Text", "Displays numeric HP values", "esp.healthText")
	self:CreateToggle(cardInfo, "Player Names & Tags", "Displays user handle and display names", "esp.names")
	self:CreateToggle(cardInfo, "Distance Display", "Displays metric distance in studs", "esp.distance")
	self:CreateToggle(cardInfo, "Equipped Weapon Display", "Displays currently equipped weapon name", "esp.weapons")
end

function GUI:PopulateWorldTab()
	local page = self.Elements.TabPages["World"]

	local cardColors = self:CreateSectionCard(page, "Entity Color Presets", "Configures team and hostile color palettes")
	self:CreateDropdown(
		cardColors,
		"Hostile Entity Preset",
		"esp.enemyColor",
		{ "Red", "Green", "Blue", "Purple", "Yellow", "White" }
	)
	self:CreateDropdown(
		cardColors,
		"Friendly Team Preset",
		"esp.teamColor",
		{ "Blue", "Green", "Yellow", "Purple", "Red", "White" }
	)

	local cardXray = self:CreateSectionCard(page, "World X-Ray & Penetration", "Material transparency and map geometry penetration")
	self:CreateToggle(cardXray, "X-Ray Wall Penetration", "Makes occluding geometry translucent", "world.xrayEnabled")
	self:CreateSlider(cardXray, "X-Ray Opacity Factor", nil, "world.xrayOpacity", 0.1, 0.9, true)

	local cardTheme = self:CreateSectionCard(page, "Interface Customization", "Window theme tokens and custom wallpaper")
	local themes = { "Default", "Ruby", "Ocean", "Midnight", "Forest", "Light", "Blue" }
	self:CreateDropdown(cardTheme, "UI Theme Palette", "world.theme", themes, function(newTheme)
		self:ApplyTheme()
		self:ShowToast("Theme switched to: " .. tostring(newTheme), "info")
	end)

	self:CreateTextInput(
		cardTheme,
		"Custom Wallpaper (Asset/URL)",
		"world.bgImage",
		"rbxassetid:// or URL...",
		function(val)
			if val == "" then
				self.Elements.BackgroundImage.Image = ""
				return
			end
			local id = string.match(val, "%d+")
			if id and not string.find(val, "://") then
				self.Elements.BackgroundImage.Image = "rbxassetid://" .. id
			else
				self.Elements.BackgroundImage.Image = val
			end
		end
	)
	self:CreateSlider(
		cardTheme,
		"Wallpaper Transparency",
		nil,
		"world.bgTransparency",
		0,
		1,
		true,
		nil,
		function(val)
			self.Elements.BackgroundImage.ImageTransparency = val
		end
	)
end

function GUI:PopulateAntiCheatTab()
	local page = self.Elements.TabPages["AntiCheat"]

	local cardAnti = self:CreateSectionCard(
		page,
		"Anti-Detection Protocols",
		"Humanized input trajectories and security isolation"
	)
	self:CreateToggle(
		cardAnti,
		"Enable Anti-Detection",
		"Activates humanized motion curves and rate limiters",
		"antiDetection.enabled"
	)
	self:CreateToggle(
		cardAnti,
		"Humanized Mouse Curves",
		"Bezier trajectory and micro-jitter simulation",
		"antiDetection.humanization"
	)
	self:CreateToggle(
		cardAnti,
		"Stealth Mode",
		"Disables visible reticles for clean screen recordings",
		"antiDetection.stealthMode"
	)

	local cardThrottle = self:CreateSectionCard(
		page,
		"Input Throttling & Limits",
		"Rate limiting to bypass client heuristics"
	)
	self:CreateSlider(
		cardThrottle,
		"Max Actions Per Second",
		nil,
		"antiDetection.maxActionsPerSecond",
		10,
		60,
		false,
		"/s"
	)
	self:CreateToggle(
		cardThrottle,
		"Optimize Rendering Pipeline",
		"Throttles off-screen visual calculations",
		"performance.optimizeRendering"
	)
end

function GUI:PopulateSettingsTab()
	local page = self.Elements.TabPages["Settings"]
	local cfg = self:GetConfigComponent()

	local cardProfile = self:CreateSectionCard(
		page,
		"Profile Management",
		"Save, restore, or reset settings on persistent storage"
	)
	self:CreateActionButton(
		cardProfile,
		"Save Configuration Profile",
		"Writes current configuration to executor storage",
		"Save Profile",
		"primary",
		function()
			if cfg then
				cfg:Save("default")
				self:ShowToast("Configuration profile saved successfully", "success")
			end
		end
	)

	self:CreateActionButton(
		cardProfile,
		"Load Configuration Profile",
		"Restores configuration from saved profile",
		"Load Profile",
		"secondary",
		function()
			if cfg then
				cfg:Load("default")
				self:ApplyTheme()
				self:ShowToast("Configuration profile loaded successfully", "success")
			end
		end
	)

	self:CreateActionButton(
		cardProfile,
		"Restore Factory Defaults",
		"Resets all values to pristine default schema",
		"Reset Defaults",
		"danger",
		function()
			if cfg then
				cfg:Reset()
				self:ApplyTheme()
				self:ShowToast("All settings restored to factory defaults", "warning")
			end
		end
	)

	local cardLifecycle = self:CreateSectionCard(
		page,
		"Script Lifecycle",
		"Clean instance teardown and connection disconnection"
	)
	self:CreateActionButton(
		cardLifecycle,
		"Emergency Script Unload",
		"Disconnects all loops and unloads all GUI elements",
		"Unload Script",
		"danger",
		function()
			local genv = getGlobalEnv()
			if genv.AimbotESP and genv.AimbotESP.Unload then
				self:ShowToast("Unloading suite and restoring clean state...", "warning")
				task.wait(0.2)
				genv.AimbotESP:Unload()
			end
		end
	)

	local cardHotkeys = self:CreateSectionCard(
		page,
		"Centralized Hotkey Reference",
		"Keyboard shortcuts for instant feature toggling"
	)
	local hotkeys = {
		{ Key = "INSERT / RightShift", Action = "Toggle Configuration Menu" },
		{ Key = "F1", Action = "Toggle AimBot Master" },
		{ Key = "F2", Action = "Toggle ESP Visuals" },
		{ Key = "F3", Action = "Toggle Player Tracers" },
		{ Key = "F4", Action = "Cycle Aim Target Part" },
		{ Key = "DELETE", Action = "Emergency Disable All Features" },
	}

	for _, hk in ipairs(hotkeys) do
		local row = createInstance("Frame", {
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Parent = cardHotkeys,
		})
		local keyBadge = createInstance("TextLabel", {
			Size = UDim2.fromOffset(110, 18),
			BackgroundColor3 = self:GetActiveTheme().ControlBg,
			Text = hk.Key,
			Font = Enum.Font.GothamBold,
			TextSize = 9,
			TextColor3 = self:GetActiveTheme().Accent,
			Parent = row,
		})
		createCorner(3, keyBadge)
		table.insert(self.Elements.ControlBackgrounds, keyBadge)
		table.insert(self.Elements.Accents, keyBadge)

		local actionLabel = createInstance("TextLabel", {
			Size = UDim2.new(1, -120, 1, 0),
			Position = UDim2.fromOffset(118, 0),
			BackgroundTransparency = 1,
			Text = hk.Action,
			Font = Enum.Font.GothamMedium,
			TextSize = 10,
			TextColor3 = self:GetActiveTheme().TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		table.insert(self.Elements.TextSecondary, actionLabel)
	end
end

--[[------------------------------------------------------------------------------
    Real-Time Diagnostic Status Bar
--------------------------------------------------------------------------------]]

function GUI:CreateStatusBar()
	local theme = self:GetActiveTheme()

	local statusBar = createInstance("Frame", {
		Name = "StatusBar",
		Size = UDim2.new(1, -160, 0, 28),
		Position = UDim2.new(0, 160, 1, -28),
		BackgroundColor3 = theme.Header,
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = self.MainFrame,
	})
	table.insert(self.Elements.Headers, statusBar)

	local statusDot = createInstance("Frame", {
		Name = "StatusDot",
		Size = UDim2.fromOffset(8, 8),
		Position = UDim2.new(0, 12, 0.5, -4),
		BackgroundColor3 = theme.Success,
		BorderSizePixel = 0,
		ZIndex = 6,
		Parent = statusBar,
	})
	createCorner(4, statusDot)
	self.Elements.StatusDot = statusDot

	local statusText = createInstance("TextLabel", {
		Name = "StatusText",
		Size = UDim2.new(1, -30, 1, 0),
		Position = UDim2.new(0, 26, 0, 0),
		BackgroundTransparency = 1,
		Text = "Ready • AIM: OFF • TRIG: OFF • ESP: OFF",
		Font = Enum.Font.GothamMedium,
		TextSize = 10,
		TextColor3 = theme.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 6,
		Parent = statusBar,
	})
	self.Elements.StatusText = statusText
	table.insert(self.Elements.TextSecondary, statusText)
end

--[[------------------------------------------------------------------------------
    Dynamic Theming Engine (Ensures WCAG AA Contrast Compliance)
--------------------------------------------------------------------------------]]

function GUI:ApplyTheme()
	local theme = self:GetActiveTheme()

	if self.MainFrame then
		self.MainFrame.BackgroundColor3 = theme.Main
	end
	if self.Elements.MainStroke then
		self.Elements.MainStroke.Color = theme.Border
	end

	for _, frame in ipairs(self.Elements.Sidebars) do
		frame.BackgroundColor3 = theme.Sidebar
	end
	for _, frame in ipairs(self.Elements.Headers) do
		frame.BackgroundColor3 = theme.Header
	end
	for _, card in ipairs(self.Elements.Cards) do
		card.BackgroundColor3 = theme.Card
	end
	for _, stroke in ipairs(self.Elements.CardBorders) do
		stroke.Color = theme.CardBorder
	end
	for _, text in ipairs(self.Elements.TextPrimary) do
		text.TextColor3 = theme.Text
	end
	for _, text in ipairs(self.Elements.TextSecondary) do
		text.TextColor3 = theme.TextSecondary
	end

	for _, elem in ipairs(self.Elements.ControlBackgrounds) do
		elem.BackgroundColor3 = theme.ControlBg
	end

	for _, elem in ipairs(self.Elements.Accents) do
		if elem:IsA("TextLabel") or elem:IsA("TextButton") then
			elem.TextColor3 = theme.Accent
		elseif elem:IsA("Frame") then
			elem.BackgroundColor3 = theme.Accent
		end
	end

	-- Update toggles
	for _, t in ipairs(self.Elements.Toggles) do
		local cfg = self:GetConfigComponent()
		local state = cfg and cfg:Get(t.ConfigPath) or false
		t.Update(state)
		if t.Stroke then
			t.Stroke.Color = theme.CardBorder
		end
	end

	-- Update sliders
	for _, s in ipairs(self.Elements.Sliders) do
		local cfg = self:GetConfigComponent()
		local val = cfg and cfg:Get(s.ConfigPath) or s.Min
		local pct = math.clamp((val - s.Min) / (s.Max - s.Min), 0, 1)
		s.Fill.Size = UDim2.new(pct, 0, 1, 0)
		s.Fill.BackgroundColor3 = theme.Accent
		s.Pill.Text = tostring(val) .. (s.Unit or "")
		s.Pill.TextColor3 = theme.Accent
		s.Pill.BackgroundColor3 = theme.ControlBg
	end

	-- Update segmented controls
	for _, seg in ipairs(self.Elements.Segments) do
		local cfg = self:GetConfigComponent()
		local cur = tostring(cfg and cfg:Get(seg.ConfigPath) or "")
		seg.Update(cur)
	end

	-- Re-highlight current active tab button
	self:SwitchTab(self.CurrentTab)
end

--[[------------------------------------------------------------------------------
    Viewport Clamping & Dragging Setup
--------------------------------------------------------------------------------]]

function GUI:SetupDragging()
	local dragging = false
	local dragStart = nil
	local startPos = nil

	local header = self.Elements.HeaderBar or self.MainFrame
	header.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			dragStart = input.Position
			startPos = self.MainFrame.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local delta = input.Position - dragStart
			local winWidth = self.MainFrame.AbsoluteSize.X
			local winHeight = self.MainFrame.AbsoluteSize.Y
			local viewport = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)

			local newOffsetX = startPos.X.Offset + delta.X
			local newOffsetY = startPos.Y.Offset + delta.Y

			-- Screen boundary clamping to prevent window loss
			local screenPosX = (startPos.X.Scale * viewport.X) + newOffsetX
			local screenPosY = (startPos.Y.Scale * viewport.Y) + newOffsetY

			local clampedScreenX = math.clamp(screenPosX, 0, math.max(0, viewport.X - winWidth))
			local clampedScreenY = math.clamp(screenPosY, 0, math.max(0, viewport.Y - winHeight))

			self.MainFrame.Position = UDim2.fromOffset(clampedScreenX, clampedScreenY)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)
end

--[[------------------------------------------------------------------------------
    Centralized Hotkeys with Visual Toast Feedback
--------------------------------------------------------------------------------]]

function GUI:SetupHotkeys()
	for _, conn in ipairs(self.KeybindConnections) do
		conn:Disconnect()
	end
	self.KeybindConnections = {}

	local conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		local cfg = self:GetConfigComponent()
		local genv = getGlobalEnv()

		-- Menu Toggle: INSERT or RightShift
		if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightShift then
			self:SetVisible(not self.IsVisible)
		end

		-- Aimbot Toggle: F1
		if input.KeyCode == Enum.KeyCode.F1 and cfg then
			local state = cfg:Toggle("aimbot.enabled")
			self:ShowToast("AimBot toggled: " .. (state and "ON" or "OFF"), state and "success" or "info")
		end

		-- ESP Toggle: F2
		if input.KeyCode == Enum.KeyCode.F2 and cfg then
			local state = cfg:Toggle("esp.enabled")
			self:ShowToast("ESP toggled: " .. (state and "ON" or "OFF"), state and "success" or "info")
		end

		-- Tracers Toggle: F3
		if input.KeyCode == Enum.KeyCode.F3 and cfg then
			local state = cfg:Toggle("esp.tracers")
			self:ShowToast("Tracers toggled: " .. (state and "ON" or "OFF"), state and "success" or "info")
		end

		-- Target Part Cycle: F4 (Head -> Torso -> Smart -> RootPart)
		if input.KeyCode == Enum.KeyCode.F4 and cfg then
			local parts = { "Head", "Torso", "Smart", "HumanoidRootPart" }
			local current = cfg:Get("aimbot.targetPart") or "Head"
			local idx = 1
			for i, p in ipairs(parts) do
				if p == current then
					idx = i
					break
				end
			end
			local nextPart = parts[(idx % #parts) + 1]
			cfg:Set("aimbot.targetPart", nextPart)
			self:ShowToast("Target part cycled to: " .. nextPart, "info")
		end

		-- Emergency Kill Switch: DELETE
		if input.KeyCode == Enum.KeyCode.Delete then
			if genv.AimbotESP and genv.AimbotESP.State then
				genv.AimbotESP.State.EmergencyDisabled = not genv.AimbotESP.State.EmergencyDisabled
				local isEm = genv.AimbotESP.State.EmergencyDisabled
				if isEm then
					self:ShowToast("EMERGENCY KILL SWITCH ACTIVATED", "danger", 4.0)
				else
					self:ShowToast("Emergency kill switch deactivated", "success", 3.0)
				end
			end
		end
	end)

	table.insert(self.KeybindConnections, conn)
end

--[[------------------------------------------------------------------------------
    Visibility, Diagnostic Update & Lifecycle
--------------------------------------------------------------------------------]]

function GUI:SetVisible(visible)
	self.IsVisible = visible
	if self.MainFrame then
		self.MainFrame.Visible = visible
	end
	if not visible and self.OpenBtn then
		self.OpenBtn.Visible = false
	end
end

function GUI:UpdateStatus()
	if not self.Elements.StatusText then
		return
	end

	local genv = getGlobalEnv()
	local cfg = self:GetConfigComponent()
	local theme = self:GetActiveTheme()

	if genv.AimbotESP and genv.AimbotESP.State and genv.AimbotESP.State.EmergencyDisabled then
		self.Elements.StatusText.Text = "EMERGENCY DISABLED (Press DELETE to restore)"
		self.Elements.StatusText.TextColor3 = theme.Danger
		if self.Elements.StatusDot then
			self.Elements.StatusDot.BackgroundColor3 = theme.Danger
		end
		return
	end

	if self.Elements.StatusDot then
		self.Elements.StatusDot.BackgroundColor3 = theme.Success
	end

	local aimStatus = (cfg and cfg:Get("aimbot.enabled")) and "ON" or "OFF"
	local espStatus = (cfg and cfg:Get("esp.enabled")) and "ON" or "OFF"
	local trigStatus = (cfg and cfg:Get("triggerBot.enabled")) and "ON" or "OFF"

	local aimbotComp = genv.AimbotESP and genv.AimbotESP.Components and genv.AimbotESP.Components.Aimbot
	local targetInfo = aimbotComp and aimbotComp:GetCurrentTargetInfo()

	local statusStr = string.format("Ready • AIM: %s • TRIG: %s • ESP: %s", aimStatus, trigStatus, espStatus)
	if targetInfo then
		statusStr = statusStr .. string.format(" • Locked: %s [%dm]", targetInfo.name, targetInfo.distance)
	end

	self.Elements.StatusText.Text = statusStr
	self.Elements.StatusText.TextColor3 = theme.TextSecondary
end

function GUI:Update()
	if self.IsVisible then
		self:UpdateStatus()
	end
end

function GUI:Initialize()
	self:CreateScreenGui()
	self:CreateMainInterface()
	self:CreateTabs()
	self:CreateStatusBar()
	self:SetupDragging()
	self:SetupHotkeys()
	self:ApplyTheme()
	self:SetVisible(true)
	print("[GUI] APEX SUITE v2.2 initialized successfully")
end

function GUI:Cleanup()
	for _, conn in ipairs(self.KeybindConnections) do
		conn:Disconnect()
	end
	self.KeybindConnections = {}

	if self.ScreenGui then
		self.ScreenGui:Destroy()
		self.ScreenGui = nil
	end

	self.MainFrame = nil
	self.OpenBtn = nil
	self.ToastContainer = nil
	self.Elements = {
		Frames = {},
		Sidebars = {},
		Headers = {},
		Cards = {},
		CardBorders = {},
		TextPrimary = {},
		TextSecondary = {},
		Accents = {},
		ControlBackgrounds = {},
		ControlBorders = {},
		TabButtons = {},
		TabPages = {},
		Toggles = {},
		Sliders = {},
		Segments = {},
		StatusDots = {},
	}
	self.IsVisible = false
end

return GUI

end)()

local function loadModule(name, fileName)
	if _MODULE_CACHE and _MODULE_CACHE[name] then
		return _MODULE_CACHE[name]
	end
	error("Critical module [" .. tostring(name) .. "] missing from standalone bundle.")
	return nil
end

print("🚀 [AimbotESP] Initializing Suite v" .. genv.AimbotESP.Version .. " (Standalone Bundle)...")

-- 1. Load Utils
local Utils = loadModule("Utils", "utils.lua")
if not Utils then
	error("❌ Critical module [Utils] failed to load. Please verify your internet connection or script files.")
	return
end
genv.AimbotESP.Components.Utils = Utils

-- Expose the player ignore filter on the global namespace for easy runtime access
-- Usage: genv.AimbotESP.IgnoredPlayers["PlayerName"] = true  /  false
-- Or via helpers: genv.AimbotESP.Components.Utils:IgnorePlayer(player)
--                 genv.AimbotESP.Components.Utils:UnignorePlayer(player)
genv.AimbotESP.IgnoredPlayers = Utils.IgnoredPlayers  -- shared reference

-- 2. Load Config
local Config = loadModule("Config", "config.lua")
if not Config then
	error("❌ Critical module [Config] failed to load.")
	return
end
genv.AimbotESP.Components.Config = Config
Config:Initialize()
genv.AimbotESP.Config = Config.Current

-- 3. Load AntiDetection
local AntiDetection = loadModule("AntiDetection", "anti_detection.lua")
if AntiDetection then
	genv.AimbotESP.Components.AntiDetection = AntiDetection
	AntiDetection:Initialize()
end

-- 4. Load Aimbot
local Aimbot = loadModule("Aimbot", "aimbot.lua")
if Aimbot then
	genv.AimbotESP.Components.Aimbot = Aimbot
	Aimbot:Initialize()
end

-- 5. Load ESP
local ESP = loadModule("ESP", "esp.lua")
if ESP then
	genv.AimbotESP.Components.ESP = ESP
	ESP:Initialize()
end

-- 6. Load GUI
local GUI = loadModule("GUI", "gui.lua")
if GUI then
	genv.AimbotESP.Components.GUI = GUI
	GUI:Initialize()
end

--[[------------------------------------------------------------------------------
    Configuration Synchronizer & State Bridge
--------------------------------------------------------------------------------]]

Config:OnChanged(function(data)
	if data.path == "aimbot.enabled" then
		genv.AimbotESP.State.AimbotEnabled = data.newValue
	elseif data.path == "esp.enabled" then
		genv.AimbotESP.State.ESPEnabled = data.newValue
	end
end)

-- Initial state sync
genv.AimbotESP.State.AimbotEnabled = Config:Get("aimbot.enabled") or false
genv.AimbotESP.State.ESPEnabled = Config:Get("esp.enabled") or false

--[[------------------------------------------------------------------------------
    Primary Execution Loop (RenderStepped & Heartbeat)
--------------------------------------------------------------------------------]]

-- Counter to throttle the green-outline scan (runs every ~15 frames to reduce cost)
local _greenScanCounter = 0

local renderConn = RunService.RenderStepped:Connect(function()
	if genv.AimbotESP.State.EmergencyDisabled then
		return
	end

	-- Throttled green-outline scan (every 15 render steps ~4x per sec at 60fps)
	_greenScanCounter = _greenScanCounter + 1
	if _greenScanCounter >= 15 then
		_greenScanCounter = 0
		local utils = genv.AimbotESP.Components.Utils
		if utils then
			pcall(function() utils:ScanGreenOutlinePlayers() end)
		end
	end

	if Aimbot then
		Aimbot:Update()
	end
	if ESP then
		ESP:Update()
	end
	if GUI then
		GUI:Update()
	end
end)
table.insert(genv.AimbotESP.Connections, renderConn)

--[[------------------------------------------------------------------------------
    Graceful Unload & Emergency Reset
--------------------------------------------------------------------------------]]

function genv.AimbotESP:Unload()
	print("🧹 [AimbotESP] Unloading suite and restoring clean state...")

	for _, conn in ipairs(self.Connections) do
		pcall(function()
			conn:Disconnect()
		end)
	end
	self.Connections = {}

	if self.Components.Aimbot then
		pcall(function()
			self.Components.Aimbot:Cleanup()
		end)
	end
	if self.Components.ESP then
		pcall(function()
			self.Components.ESP:Cleanup()
		end)
	end
	if self.Components.GUI then
		pcall(function()
			self.Components.GUI:Cleanup()
		end)
	end
	if self.Components.AntiDetection then
		pcall(function()
			self.Components.AntiDetection:Cleanup()
		end)
	end

	self.ActiveNPCs = {}
	self.State.EmergencyDisabled = true
	self.Loaded = false
	genv.AIMBOT_ESP_LOADED = false
	genv.UltimateSuiteLoaded = false

	print("✅ [AimbotESP] Unload complete.")
end

--[[------------------------------------------------------------------------------
    Finalization
--------------------------------------------------------------------------------]]

genv.AimbotESP.Loaded = true
genv.AimbotESP.State.Initialized = true

print([[
======================================================
  🎯 AimBot & ESP Suite v2.1.0 Loaded Flawlessly!
  📋 Keybinds:
     • INSERT / Right-Shift : Toggle GUI Menu
     • F1                   : Toggle AimBot
     • F2                   : Toggle ESP
     • F3                   : Toggle Tracers
     • F4                   : Cycle Aim Part
     • DELETE               : Emergency Disable
======================================================
]])

return genv.AimbotESP
