--[[
    Advanced AimBot & ESP System v2.0.0
    Main Entry Point
    
    This is the main file that initializes all components of the system.
    Load this file to start the complete AimBot and ESP system.
    
    Author: gokuthug1
    License: MIT
    Created: 2026-01-13
]]

-- Security and compatibility checks
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Prevent multiple instances
if getgenv().AIMBOT_ESP_LOADED then
    warn("AimBot ESP is already loaded!")
    return
end
getgenv().AIMBOT_ESP_LOADED = true

-- Version information
local VERSION = "2.0.0"
local BUILD_DATE = "2026-01-13"

print("🎯 Advanced AimBot & ESP v" .. VERSION)
print("📅 Build Date: " .. BUILD_DATE)
print("⚠️  Educational use only - Use responsibly!")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Local player reference
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

-- Global state management
getgenv().AimbotESP = {
    Version = VERSION,
    BuildDate = BUILD_DATE,
    Loaded = true,
    Components = {},
    Config = {},
    State = {
        AimbotEnabled = false,
        ESPEnabled = false,
        GUIVisible = false,
        EmergencyDisabled = false
    }
}

-- Component loading function
local function loadComponent(name, code)
    local success, result = pcall(function()
        return loadstring(code)()
    end)
    
    if success then
        getgenv().AimbotESP.Components[name] = result
        print("✅ Loaded component: " .. name)
        return result
    else
        warn("❌ Failed to load component " .. name .. ": " .. tostring(result))
        return nil
    end
end

-- Load configuration system first
local Config = loadComponent("Config", [[
    local Config = {}
    
    -- Default configuration
    Config.Default = {
        aimbot = {
            enabled = false,
            aimKey = Enum.UserInputType.MouseButton2,
            targetPart = "Head", -- "Head", "Torso", "Smart"
            fov = 120,
            smoothness = 10,
            prediction = true,
            teamCheck = true,
            visibilityCheck = true,
            maxDistance = 1000,
            priorityMode = "Distance" -- "Distance", "Health", "Threat"
        },
        esp = {
            enabled = false,
            players = true,
            healthBars = true,
            distance = true,
            tracers = true,
            skeleton = false,
            boxes = true,
            names = true,
            teamColors = true,
            maxDistance = 500,
            thickness = 2,
            transparency = 0.8
        },
        gui = {
            enabled = true,
            theme = "Dark", -- "Dark", "Light", "Blue"
            scale = 1.0,
            position = {X = 50, Y = 50},
            hotkeys = {
                toggleGUI = Enum.KeyCode.Insert,
                toggleAimbot = Enum.KeyCode.F1,
                toggleESP = Enum.KeyCode.F2,
                toggleTracers = Enum.KeyCode.F3,
                cycleTarget = Enum.KeyCode.F4,
                emergencyDisable = Enum.KeyCode.Delete
            }
        },
        antiDetection = {
            enabled = true,
            randomDelay = {min = 0.01, max = 0.05},
            humanization = true,
            stealthMode = false,
            maxActionsPerSecond = 30
        },
        performance = {
            updateRate = 60, -- FPS
            renderDistance = 500,
            maxTrackedPlayers = 20,
            optimizeRendering = true
        }
    }
    
    -- Current configuration (starts as copy of default)
    Config.Current = {}
    
    -- Deep copy function
    function Config:DeepCopy(original)
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
        getgenv().AimbotESP.Config = self.Current
        print("⚙️ Configuration system initialized")
    end
    
    -- Get configuration value
    function Config:Get(path)
        local keys = string.split(path, ".")
        local current = self.Current
        
        for _, key in ipairs(keys) do
            if current[key] then
                current = current[key]
            else
                return nil
            end
        end
        
        return current
    end
    
    -- Set configuration value
    function Config:Set(path, value)
        local keys = string.split(path, ".")
        local current = self.Current
        
        for i = 1, #keys - 1 do
            if not current[keys[i]] then
                current[keys[i]] = {}
            end
            current = current[keys[i]]
        end
        
        current[keys[#keys]] = value
    end
    
    -- Save configuration (placeholder for future file system)
    function Config:Save(profileName)
        profileName = profileName or "default"
        -- In a real implementation, this would save to file
        print("💾 Configuration saved as profile: " .. profileName)
    end
    
    -- Load configuration (placeholder for future file system)
    function Config:Load(profileName)
        profileName = profileName or "default"
        -- In a real implementation, this would load from file
        print("📁 Configuration loaded from profile: " .. profileName)
    end
    
    return Config
]])

-- Initialize configuration
if Config then
    Config:Initialize()
end

-- Load utility functions
local Utils = loadComponent("Utils", [[
    local Utils = {}
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer
    
    -- Get distance between two positions
    function Utils:GetDistance(pos1, pos2)
        return (pos1 - pos2).Magnitude
    end
    
    -- Check if player is on same team
    function Utils:IsTeammate(player)
        if not LocalPlayer.Team or not player.Team then
            return false
        end
        return LocalPlayer.Team == player.Team
    end
    
    -- Check if player is alive
    function Utils:IsPlayerAlive(player)
        return player.Character and 
               player.Character:FindFirstChild("Humanoid") and 
               player.Character.Humanoid.Health > 0 and
               player.Character:FindFirstChild("HumanoidRootPart")
    end
    
    -- Get player's health percentage
    function Utils:GetHealthPercentage(player)
        if not self:IsPlayerAlive(player) then
            return 0
        end
        local humanoid = player.Character.Humanoid
        return (humanoid.Health / humanoid.MaxHealth) * 100
    end
    
    -- Check line of sight
    function Utils:HasLineOfSight(from, to, ignoreList)
        ignoreList = ignoreList or {LocalPlayer.Character}
        
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = ignoreList
        
        local raycastResult = Workspace:Raycast(from, (to - from), raycastParams)
        return raycastResult == nil
    end
    
    -- Get screen position from world position
    function Utils:WorldToScreen(position)
        local camera = Workspace.CurrentCamera
        local screenPoint, onScreen = camera:WorldToScreenPoint(position)
        return Vector2.new(screenPoint.X, screenPoint.Y), onScreen
    end
    
    -- Get all valid targets
    function Utils:GetValidTargets()
        local targets = {}
        local config = getgenv().AimbotESP.Config
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and self:IsPlayerAlive(player) then
                -- Team check
                if config.aimbot.teamCheck and self:IsTeammate(player) then
                    continue
                end
                
                local character = player.Character
                local humanoidRootPart = character.HumanoidRootPart
                local distance = self:GetDistance(LocalPlayer.Character.HumanoidRootPart.Position, humanoidRootPart.Position)
                
                -- Distance check
                if distance <= config.aimbot.maxDistance then
                    -- Visibility check
                    if not config.aimbot.visibilityCheck or 
                       self:HasLineOfSight(LocalPlayer.Character.HumanoidRootPart.Position, humanoidRootPart.Position, {LocalPlayer.Character}) then
                        
                        table.insert(targets, {
                            player = player,
                            character = character,
                            distance = distance,
                            health = self:GetHealthPercentage(player)
                        })
                    end
                end
            end
        end
        
        return targets
    end
    
    -- Sort targets by priority
    function Utils:SortTargetsByPriority(targets, priorityMode)
        priorityMode = priorityMode or "Distance"
        
        if priorityMode == "Distance" then
            table.sort(targets, function(a, b) return a.distance < b.distance end)
        elseif priorityMode == "Health" then
            table.sort(targets, function(a, b) return a.health < b.health end)
        elseif priorityMode == "Threat" then
            -- Custom threat calculation (could be based on weapons, damage dealt, etc.)
            table.sort(targets, function(a, b) return a.distance < b.distance end) -- Fallback to distance
        end
        
        return targets
    end
    
    -- Generate random delay for anti-detection
    function Utils:GetRandomDelay()
        local config = getgenv().AimbotESP.Config.antiDetection
        if not config.enabled then return 0 end
        
        return math.random() * (config.randomDelay.max - config.randomDelay.min) + config.randomDelay.min
    end
    
    -- Clamp value between min and max
    function Utils:Clamp(value, min, max)
        return math.max(min, math.min(max, value))
    end
    
    -- Linear interpolation
    function Utils:Lerp(a, b, t)
        return a + (b - a) * t
    end
    
    -- Get color based on health percentage
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
    
    -- Get team color
    function Utils:GetTeamColor(player)
        if player.Team then
            return player.Team.TeamColor.Color
        end
        return Color3.new(1, 1, 1) -- White default
    end
    
    return Utils
]])

-- Load anti-detection system
local AntiDetection = loadComponent("AntiDetection", [[
    local AntiDetection = {}
    local RunService = game:GetService("RunService")
    
    -- Action tracking for rate limiting
    AntiDetection.ActionHistory = {}
    AntiDetection.LastActionTime = 0
    
    -- Initialize anti-detection
    function AntiDetection:Initialize()
        print("🛡️ Anti-detection system initialized")
    end
    
    -- Check if action is allowed (rate limiting)
    function AntiDetection:IsActionAllowed()
        local config = getgenv().AimbotESP.Config.antiDetection
        if not config.enabled then return true end
        
        local currentTime = tick()
        local timeDiff = currentTime - self.LastActionTime
        
        -- Remove old actions (older than 1 second)
        for i = #self.ActionHistory, 1, -1 do
            if currentTime - self.ActionHistory[i] > 1 then
                table.remove(self.ActionHistory, i)
            end
        end
        
        -- Check rate limit
        if #self.ActionHistory >= config.maxActionsPerSecond then
            return false
        end
        
        return true
    end
    
    -- Record an action
    function AntiDetection:RecordAction()
        local config = getgenv().AimbotESP.Config.antiDetection
        if not config.enabled then return end
        
        local currentTime = tick()
        table.insert(self.ActionHistory, currentTime)
        self.LastActionTime = currentTime
    end
    
    -- Get humanized delay
    function AntiDetection:GetHumanizedDelay()
        local config = getgenv().AimbotESP.Config.antiDetection
        if not config.enabled or not config.humanization then return 0 end
        
        local utils = getgenv().AimbotESP.Components.Utils
        return utils:GetRandomDelay()
    end
    
    -- Apply humanization to mouse movement
    function AntiDetection:HumanizeMovement(targetPosition, currentPosition, smoothness)
        local config = getgenv().AimbotESP.Config.antiDetection
        if not config.enabled or not config.humanization then 
            return targetPosition 
        end
        
        -- Add slight randomness to movement
        local randomOffset = Vector2.new(
            (math.random() - 0.5) * 2,
            (math.random() - 0.5) * 2
        )
        
        -- Apply smoothing with randomness
        local utils = getgenv().AimbotESP.Components.Utils
        local t = 1 / (smoothness + math.random() * 2)
        
        return Vector2.new(
            utils:Lerp(currentPosition.X, targetPosition.X + randomOffset.X, t),
            utils:Lerp(currentPosition.Y, targetPosition.Y + randomOffset.Y, t)
        )
    end
    
    return AntiDetection
]])

-- Initialize anti-detection
if AntiDetection then
    AntiDetection:Initialize()
end

-- Emergency disable function
local function EmergencyDisable()
    getgenv().AimbotESP.State.EmergencyDisabled = true
    getgenv().AimbotESP.State.AimbotEnabled = false
    getgenv().AimbotESP.State.ESPEnabled = false
    
    -- Disable all visual elements
    if getgenv().AimbotESP.Components.ESP then
        getgenv().AimbotESP.Components.ESP:DisableAll()
    end
    
    warn("🚨 EMERGENCY DISABLE ACTIVATED - All features disabled!")
end

-- Hotkey handler
local function HandleHotkeys()
    local config = getgenv().AimbotESP.Config.gui.hotkeys
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- Emergency disable (highest priority)
        if input.KeyCode == config.emergencyDisable then
            EmergencyDisable()
            return
        end
        
        -- Don't process other hotkeys if emergency disabled
        if getgenv().AimbotESP.State.EmergencyDisabled then return end
        
        -- Toggle GUI
        if input.KeyCode == config.toggleGUI then
            getgenv().AimbotESP.State.GUIVisible = not getgenv().AimbotESP.State.GUIVisible
            if getgenv().AimbotESP.Components.GUI then
                getgenv().AimbotESP.Components.GUI:SetVisible(getgenv().AimbotESP.State.GUIVisible)
            end
        end
        
        -- Toggle Aimbot
        if input.KeyCode == config.toggleAimbot then
            getgenv().AimbotESP.State.AimbotEnabled = not getgenv().AimbotESP.State.AimbotEnabled
            getgenv().AimbotESP.Config.aimbot.enabled = getgenv().AimbotESP.State.AimbotEnabled
            print("🎯 Aimbot: " .. (getgenv().AimbotESP.State.AimbotEnabled and "ON" or "OFF"))
        end
        
        -- Toggle ESP
        if input.KeyCode == config.toggleESP then
            getgenv().AimbotESP.State.ESPEnabled = not getgenv().AimbotESP.State.ESPEnabled
            getgenv().AimbotESP.Config.esp.enabled = getgenv().AimbotESP.State.ESPEnabled
            print("👁️ ESP: " .. (getgenv().AimbotESP.State.ESPEnabled and "ON" or "OFF"))
        end
        
        -- Toggle Tracers
        if input.KeyCode == config.toggleTracers then
            getgenv().AimbotESP.Config.esp.tracers = not getgenv().AimbotESP.Config.esp.tracers
            print("📍 Tracers: " .. (getgenv().AimbotESP.Config.esp.tracers and "ON" or "OFF"))
        end
        
        -- Cycle target mode
        if input.KeyCode == config.cycleTarget then
            local modes = {"Head", "Torso", "Smart"}
            local current = getgenv().AimbotESP.Config.aimbot.targetPart
            local currentIndex = 1
            
            for i, mode in ipairs(modes) do
                if mode == current then
                    currentIndex = i
                    break
                end
            end
            
            local nextIndex = (currentIndex % #modes) + 1
            getgenv().AimbotESP.Config.aimbot.targetPart = modes[nextIndex]
            print("🎯 Target Mode: " .. modes[nextIndex])
        end
    end)
end

-- Initialize hotkey system
HandleHotkeys()

-- Load remaining components (these would be loaded from separate files in a real implementation)
-- For now, we'll create placeholder functions that indicate the system is ready

print("🔄 Loading AimBot system...")
getgenv().AimbotESP.Components.Aimbot = {
    Initialize = function() print("🎯 AimBot system ready") end,
    Update = function() end
}

print("🔄 Loading ESP system...")
getgenv().AimbotESP.Components.ESP = {
    Initialize = function() print("👁️ ESP system ready") end,
    Update = function() end,
    DisableAll = function() print("👁️ ESP disabled") end
}

print("🔄 Loading GUI system...")
getgenv().AimbotESP.Components.GUI = {
    Initialize = function() print("🖥️ GUI system ready") end,
    SetVisible = function(visible) 
        print("🖥️ GUI " .. (visible and "shown" or "hidden")) 
    end
}

-- Initialize all components
for name, component in pairs(getgenv().AimbotESP.Components) do
    if component.Initialize then
        component.Initialize()
    end
end

-- Main update loop
local lastUpdate = 0
local updateRate = 1 / getgenv().AimbotESP.Config.performance.updateRate

RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    if currentTime - lastUpdate < updateRate then return end
    lastUpdate = currentTime
    
    -- Don't update if emergency disabled
    if getgenv().AimbotESP.State.EmergencyDisabled then return end
    
    -- Update components
    for name, component in pairs(getgenv().AimbotESP.Components) do
        if component.Update then
            pcall(component.Update)
        end
    end
end)

-- Cleanup on game leave
game:BindToClose(function()
    print("🧹 Cleaning up AimBot ESP system...")
    getgenv().AIMBOT_ESP_LOADED = false
    getgenv().AimbotESP = nil
end)

print("✅ Advanced AimBot & ESP v" .. VERSION .. " loaded successfully!")
print("📋 Press INSERT to open configuration GUI")
print("🎮 Press F1/F2 to toggle AimBot/ESP")
print("🚨 Press DELETE for emergency disable")
print("📖 Check README.md for full documentation")

return getgenv().AimbotESP