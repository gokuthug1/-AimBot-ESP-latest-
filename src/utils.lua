--[[
    Utility Functions v2.0.0
    
    This module provides common utility functions used throughout the system:
    - Mathematical calculations
    - Player validation and filtering
    - Screen/world coordinate conversions
    - Color and visual helpers
    
    Author: gokuthug1
    License: MIT
]]

local Utils = {}

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Local references
local LocalPlayer = Players.LocalPlayer

-- Mathematical utilities
function Utils:GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

function Utils:GetDistance2D(pos1, pos2)
    local diff = pos1 - pos2
    return math.sqrt(diff.X^2 + diff.Z^2)
end

function Utils:Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

function Utils:Lerp(a, b, t)
    return a + (b - a) * t
end

function Utils:Round(number, decimals)
    decimals = decimals or 0
    local mult = 10^decimals
    return math.floor(number * mult + 0.5) / mult
end

function Utils:AngleBetween(pos1, pos2)
    local diff = pos2 - pos1
    return math.atan2(diff.Z, diff.X)
end

-- Player validation functions
function Utils:IsTeammate(player)
    if not LocalPlayer.Team or not player.Team then
        return false
    end
    return LocalPlayer.Team == player.Team
end

function Utils:IsPlayerAlive(player)
    return player.Character and 
           player.Character:FindFirstChild("Humanoid") and 
           player.Character.Humanoid.Health > 0 and
           player.Character:FindFirstChild("HumanoidRootPart")
end

function Utils:GetHealthPercentage(player)
    if not self:IsPlayerAlive(player) then
        return 0
    end
    local humanoid = player.Character.Humanoid
    return (humanoid.Health / humanoid.MaxHealth) * 100
end

function Utils:IsPlayerVisible(player, fromPosition)
    if not self:IsPlayerAlive(player) then
        return false
    end
    
    local character = player.Character
    local humanoidRootPart = character.HumanoidRootPart
    
    return self:HasLineOfSight(fromPosition or LocalPlayer.Character.HumanoidRootPart.Position, 
                              humanoidRootPart.Position, 
                              {LocalPlayer.Character})
end

-- Line of sight checking
function Utils:HasLineOfSight(from, to, ignoreList)
    ignoreList = ignoreList or {LocalPlayer.Character}
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = ignoreList
    
    local direction = (to - from)
    local raycastResult = Workspace:Raycast(from, direction, raycastParams)
    
    return raycastResult == nil
end

-- Screen/world coordinate conversion
function Utils:WorldToScreen(position)
    local camera = Workspace.CurrentCamera
    local screenPoint, onScreen = camera:WorldToScreenPoint(position)
    return Vector2.new(screenPoint.X, screenPoint.Y), onScreen
end

function Utils:ScreenToWorld(screenPosition, distance)
    local camera = Workspace.CurrentCamera
    local ray = camera:ScreenPointToRay(screenPosition.X, screenPosition.Y)
    return ray.Origin + (ray.Direction * distance)
end

function Utils:GetScreenCenter()
    local camera = Workspace.CurrentCamera
    local viewportSize = camera.ViewportSize
    return Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
end

function Utils:IsOnScreen(position, margin)
    margin = margin or 0
    local screenPos, onScreen = self:WorldToScreen(position)
    
    if not onScreen then return false end
    
    local camera = Workspace.CurrentCamera
    local viewportSize = camera.ViewportSize
    
    return screenPos.X >= -margin and screenPos.X <= viewportSize.X + margin and
           screenPos.Y >= -margin and screenPos.Y <= viewportSize.Y + margin
end

-- Target filtering and sorting
function Utils:GetValidTargets()
    local targets = {}
    local config = getgenv().AimbotESP.Config
    local localCharacter = LocalPlayer.Character
    
    if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") then
        return targets
    end
    
    local localPosition = localCharacter.HumanoidRootPart.Position
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and self:IsPlayerAlive(player) then
            -- Team check
            if config.aimbot.teamCheck and self:IsTeammate(player) then
                continue
            end
            
            local character = player.Character
            local humanoidRootPart = character.HumanoidRootPart
            local distance = self:GetDistance(localPosition, humanoidRootPart.Position)
            
            -- Distance check
            if distance <= config.aimbot.maxDistance then
                -- Visibility check
                if not config.aimbot.visibilityCheck or 
                   self:HasLineOfSight(localPosition, humanoidRootPart.Position, {localCharacter}) then
                    
                    table.insert(targets, {
                        player = player,
                        character = character,
                        distance = distance,
                        health = self:GetHealthPercentage(player),
                        position = humanoidRootPart.Position,
                        velocity = humanoidRootPart.Velocity
                    })
                end
            end
        end
    end
    
    return targets
end

function Utils:SortTargetsByPriority(targets, priorityMode)
    priorityMode = priorityMode or "Distance"
    
    if priorityMode == "Distance" then
        table.sort(targets, function(a, b) return a.distance < b.distance end)
    elseif priorityMode == "Health" then
        table.sort(targets, function(a, b) return a.health < b.health end)
    elseif priorityMode == "Threat" then
        -- Custom threat calculation
        table.sort(targets, function(a, b)
            local threatA = self:CalculateThreatLevel(a)
            local threatB = self:CalculateThreatLevel(b)
            return threatA > threatB
        end)
    end
    
    return targets
end

function Utils:CalculateThreatLevel(target)
    -- Simple threat calculation based on distance and health
    local distanceFactor = math.max(0, 1 - (target.distance / 500)) -- Closer = more threat
    local healthFactor = target.health / 100 -- Higher health = more threat
    local velocityFactor = math.min(1, target.velocity.Magnitude / 50) -- Faster = more threat
    
    return (distanceFactor * 0.5) + (healthFactor * 0.3) + (velocityFactor * 0.2)
end

-- Color utilities
function Utils:GetHealthColor(healthPercent)
    if healthPercent > 75 then
        return Color3.new(0, 1, 0) -- Green
    elseif healthPercent > 50 then
        return Color3.new(1, 1, 0) -- Yellow
    elseif healthPercent > 25 then
        return Color3.new(1, 0.5, 0) -- Orange
    else
        return Color3.new(1, 0, 0) -- Red
    end
end

function Utils:GetTeamColor(player)
    if player.Team then
        return player.Team.TeamColor.Color
    end
    return Color3.new(1, 1, 1) -- White default
end

function Utils:GetDistanceColor(distance, maxDistance)
    local ratio = math.min(1, distance / maxDistance)
    
    if ratio < 0.3 then
        return Color3.new(1, 0, 0) -- Red (close)
    elseif ratio < 0.6 then
        return Color3.new(1, 1, 0) -- Yellow (medium)
    else
        return Color3.new(0, 1, 0) -- Green (far)
    end
end

function Utils:HSVtoRGB(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    
    local imod = i % 6
    if imod == 0 then
        r, g, b = v, t, p
    elseif imod == 1 then
        r, g, b = q, v, p
    elseif imod == 2 then
        r, g, b = p, v, t
    elseif imod == 3 then
        r, g, b = p, q, v
    elseif imod == 4 then
        r, g, b = t, p, v
    elseif imod == 5 then
        r, g, b = v, p, q
    end
    
    return Color3.new(r, g, b)
end

-- Anti-detection utilities
function Utils:GetRandomDelay()
    local config = getgenv().AimbotESP.Config.antiDetection
    if not config.enabled then return 0 end
    
    return math.random() * (config.randomDelay.max - config.randomDelay.min) + config.randomDelay.min
end

function Utils:AddRandomOffset(position, maxOffset)
    maxOffset = maxOffset or 2
    return position + Vector3.new(
        (math.random() - 0.5) * maxOffset,
        (math.random() - 0.5) * maxOffset,
        (math.random() - 0.5) * maxOffset
    )
end

function Utils:HumanizeValue(value, variance)
    variance = variance or 0.1
    local offset = (math.random() - 0.5) * variance * value
    return value + offset
end

-- Performance utilities
function Utils:Throttle(func, delay)
    local lastCall = 0
    return function(...)
        local now = tick()
        if now - lastCall >= delay then
            lastCall = now
            return func(...)
        end
    end
end

function Utils:Debounce(func, delay)
    local timer = nil
    return function(...)
        local args = {...}
        if timer then
            timer:Disconnect()
        end
        timer = task.wait(delay)
        func(unpack(args))
    end
end

-- String utilities
function Utils:FormatNumber(number, suffix)
    suffix = suffix or ""
    
    if number >= 1000000 then
        return string.format("%.1fM%s", number / 1000000, suffix)
    elseif number >= 1000 then
        return string.format("%.1fK%s", number / 1000, suffix)
    else
        return string.format("%.0f%s", number, suffix)
    end
end

function Utils:FormatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    
    if hours > 0 then
        return string.format("%02d:%02d:%02d", hours, minutes, secs)
    else
        return string.format("%02d:%02d", minutes, secs)
    end
end

-- Validation utilities
function Utils:ValidateConfig(config, schema)
    for key, expectedType in pairs(schema) do
        local value = config[key]
        
        if value == nil then
            return false, "Missing required key: " .. key
        end
        
        if expectedType == "EnumItem" then
            if typeof(value) ~= "EnumItem" then
                return false, "Expected EnumItem for " .. key .. ", got " .. typeof(value)
            end
        elseif type(value) ~= expectedType then
            return false, "Expected " .. expectedType .. " for " .. key .. ", got " .. type(value)
        end
    end
    
    return true, nil
end

-- Geometry utilities
function Utils:GetBoundingBox(character)
    if not character then return nil end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    
    if not humanoidRootPart or not head then return nil end
    
    local rootPosition = humanoidRootPart.Position
    local headPosition = head.Position
    
    -- Calculate approximate bounding box
    local size = Vector3.new(4, 6, 2) -- Approximate character size
    local min = rootPosition - (size / 2)
    local max = rootPosition + (size / 2)
    
    -- Adjust for head position
    max = Vector3.new(max.X, math.max(max.Y, headPosition.Y + 1), max.Z)
    
    return {
        min = min,
        max = max,
        center = (min + max) / 2,
        size = max - min
    }
end

function Utils:PointInBox(point, box)
    return point.X >= box.min.X and point.X <= box.max.X and
           point.Y >= box.min.Y and point.Y <= box.max.Y and
           point.Z >= box.min.Z and point.Z <= box.max.Z
end

-- Debug utilities
function Utils:DrawDebugLine(from, to, color, duration)
    color = color or Color3.new(1, 0, 0)
    duration = duration or 1
    
    local part = Instance.new("Part")
    part.Name = "DebugLine"
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.Neon
    part.BrickColor = BrickColor.new(color)
    part.Size = Vector3.new(0.1, 0.1, (to - from).Magnitude)
    part.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -part.Size.Z / 2)
    part.Parent = Workspace
    
    game:GetService("Debris"):AddItem(part, duration)
    
    return part
end

function Utils:DrawDebugSphere(position, radius, color, duration)
    color = color or Color3.new(0, 1, 0)
    duration = duration or 1
    radius = radius or 1
    
    local part = Instance.new("Part")
    part.Name = "DebugSphere"
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.ForceField
    part.BrickColor = BrickColor.new(color)
    part.Shape = Enum.PartType.Ball
    part.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
    part.Position = position
    part.Parent = Workspace
    
    game:GetService("Debris"):AddItem(part, duration)
    
    return part
end

-- Statistics tracking
Utils.Stats = {
    targetsFound = 0,
    shotsAttempted = 0,
    hitsLanded = 0,
    averageDistance = 0,
    sessionStartTime = tick()
}

function Utils:UpdateStats(targetCount, shotAttempted, hitLanded, distance)
    self.Stats.targetsFound = targetCount or self.Stats.targetsFound
    
    if shotAttempted then
        self.Stats.shotsAttempted = self.Stats.shotsAttempted + 1
    end
    
    if hitLanded then
        self.Stats.hitsLanded = self.Stats.hitsLanded + 1
    end
    
    if distance then
        -- Simple moving average
        self.Stats.averageDistance = (self.Stats.averageDistance + distance) / 2
    end
end

function Utils:GetStats()
    local sessionTime = tick() - self.Stats.sessionStartTime
    local accuracy = self.Stats.shotsAttempted > 0 and 
                    (self.Stats.hitsLanded / self.Stats.shotsAttempted * 100) or 0
    
    return {
        targetsFound = self.Stats.targetsFound,
        shotsAttempted = self.Stats.shotsAttempted,
        hitsLanded = self.Stats.hitsLanded,
        accuracy = self:Round(accuracy, 1),
        averageDistance = self:Round(self.Stats.averageDistance, 1),
        sessionTime = self:FormatTime(sessionTime)
    }
end

function Utils:ResetStats()
    self.Stats = {
        targetsFound = 0,
        shotsAttempted = 0,
        hitsLanded = 0,
        averageDistance = 0,
        sessionStartTime = tick()
    }
end

return Utils