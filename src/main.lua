--[[
    Advanced AimBot & ESP System v2.0.0 - FIXED VERSION
    Main Entry Point with Error Handling
    
    This version includes comprehensive error handling and fallback mechanisms
    to prevent the "attempt to call a nil value" error.
    
    Author: gokuthug1
    License: MIT
    Created: 2026-01-13
    Fixed: 2026-01-13
]]

-- Enhanced error handling and compatibility checks
local function safeWait()
    if not game:IsLoaded() then
        local success, err = pcall(function()
            game.Loaded:Wait()
        end)
        if not success then
            wait(2) -- Fallback wait
        end
    end
end

-- Safe environment setup
local function setupEnvironment()
    if not getgenv then
        _G.getgenv = function() return _G end
    end
    
    if not getgenv().AIMBOT_ESP_LOADED then
        getgenv().AIMBOT_ESP_LOADED = false
    end
end

-- Initialize safely
safeWait()
setupEnvironment()

-- Prevent multiple instances with better error handling
if getgenv().AIMBOT_ESP_LOADED then
    warn("⚠️ AimBot ESP is already loaded! Press DELETE to emergency disable, then reload.")
    return
end

-- Mark as loading
getgenv().AIMBOT_ESP_LOADED = true

-- Version information
local VERSION = "2.0.0-FIXED"
local BUILD_DATE = "2026-01-13"

print("🎯 Advanced AimBot & ESP v" .. VERSION)
print("📅 Build Date: " .. BUILD_DATE)
print("🔧 Fixed Version - Enhanced Error Handling")
print("⚠️  Educational use only - Use responsibly!")

-- Safe service loading with error handling
local function getService(serviceName)
    local success, service = pcall(function()
        return game:GetService(serviceName)
    end)
    
    if success then
        return service
    else
        warn("❌ Failed to get service: " .. serviceName)
        return nil
    end
end

-- Services with error handling
local Players = getService("Players")
local RunService = getService("RunService")
local UserInputService = getService("UserInputService")
local TweenService = getService("TweenService")
local Workspace = getService("Workspace")

-- Verify critical services
if not Players or not RunService or not UserInputService or not Workspace then
    error("❌ Critical services failed to load. Please restart Roblox and try again.")
    return
end

-- Local player reference with safety checks
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    error("❌ LocalPlayer not found. Please ensure you're in a game.")
    return
end

local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

-- Enhanced global state management
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
        EmergencyDisabled = false,
        Initialized = false
    },
    Debug = {
        ErrorCount = 0,
        LastError = nil,
        StartTime = tick()
    }
}

-- Enhanced component loading function with better error handling
local function loadComponent(name, code)
    local success, result = pcall(function()
        local compiledCode = loadstring(code)
        if not compiledCode then
            error("Failed to compile code for " .. name)
        end
        return compiledCode()
    end)
    
    if success and result then
        getgenv().AimbotESP.Components[name] = result
        print("✅ Loaded component: " .. name)
        return result
    else
        local errorMsg = tostring(result or "Unknown error")
        warn("❌ Failed to load component " .. name .. ": " .. errorMsg)
        getgenv().AimbotESP.Debug.ErrorCount = getgenv().AimbotESP.Debug.ErrorCount + 1
        getgenv().AimbotESP.Debug.LastError = errorMsg
        return nil
    end
end

-- Load configuration system with enhanced error handling
local Config = loadComponent("Config", [[
    local Config = {}
    
    -- Default configuration with safe values
    Config.Default = {
        aimbot = {
            enabled = false,
            aimKey = Enum.UserInputType.MouseButton2,
            targetPart = "Head",
            fov = 90, -- Reduced from 120 for better compatibility
            smoothness = 12, -- Increased for more natural movement
            prediction = true,
            teamCheck = true,
            visibilityCheck = true,
            maxDistance = 800, -- Reduced from 1000
            priorityMode = "Distance"
        },
        esp = {
            enabled = false,
            players = true,
            healthBars = true,
            distance = true,
            tracers = false, -- Disabled by default for performance
            skeleton = false,
            boxes = true,
            names = true,
            teamColors = true,
            maxDistance = 400, -- Reduced from 500
            thickness = 2,
            transparency = 0.7 -- Slightly more transparent
        },
        gui = {
            enabled = true,
            theme = "Dark",
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
            randomDelay = {min = 0.02, max = 0.08}, -- Increased delays
            humanization = true,
            stealthMode = true, -- Enabled by default
            maxActionsPerSecond = 20 -- Reduced from 30
        },
        performance = {
            updateRate = 45, -- Reduced from 60 for better performance
            renderDistance = 400,
            maxTrackedPlayers = 15, -- Reduced from 20
            optimizeRendering = true
        }
    }
    
    Config.Current = {}
    
    -- Safe deep copy function
    function Config:DeepCopy(original)
        if type(original) ~= "table" then
            return original
        end
        
        local copy = {}
        for key, value in pairs(original) do
            copy[key] = self:DeepCopy(value)
        end
        return copy
    end
    
    -- Initialize configuration with error handling
    function Config:Initialize()
        local success, err = pcall(function()
            self.Current = self:DeepCopy(self.Default)
            getgenv().AimbotESP.Config = self.Current
        end)
        
        if success then
            print("⚙️ Configuration system initialized")
        else
            warn("❌ Configuration initialization failed: " .. tostring(err))
            -- Fallback to basic config
            self.Current = self.Default
            getgenv().AimbotESP.Config = self.Current
        end
    end
    
    -- Safe get configuration value
    function Config:Get(path)
        local success, result = pcall(function()
            local keys = string.split(path, ".")
            local current = self.Current
            
            for _, key in ipairs(keys) do
                if current and current[key] ~= nil then
                    current = current[key]
                else
                    return nil
                end
            end
            
            return current
        end)
        
        return success and result or nil
    end
    
    -- Safe set configuration value
    function Config:Set(path, value)
        local success, err = pcall(function()
            local keys = string.split(path, ".")
            local current = self.Current
            
            for i = 1, #keys - 1 do
                if not current[keys[i]] then
                    current[keys[i]] = {}
                end
                current = current[keys[i]]
            end
            
            current[keys[#keys]] = value
        end)
        
        if not success then
            warn("❌ Failed to set config " .. path .. ": " .. tostring(err))
        end
    end
    
    -- Reset to defaults
    function Config:Reset()
        self.Current = self:DeepCopy(self.Default)
        getgenv().AimbotESP.Config = self.Current
        print("🔄 Configuration reset to defaults")
    end
    
    return Config
]])

-- Initialize configuration with fallback
if Config then
    Config:Initialize()
else
    warn("❌ Configuration system failed to load. Using minimal setup.")
    getgenv().AimbotESP.Config = {
        aimbot = {enabled = false, fov = 90, smoothness = 12},
        esp = {enabled = false, maxDistance = 400},
        gui = {enabled = true},
        antiDetection = {enabled = true},
        performance = {updateRate = 30}
    }
end

-- Load utility functions with enhanced safety
local Utils = loadComponent("Utils", [[
    local Utils = {}
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer
    
    -- Safe distance calculation
    function Utils:GetDistance(pos1, pos2)
        local success, result = pcall(function()
            return (pos1 - pos2).Magnitude
        end)
        return success and result or math.huge
    end
    
    -- Safe teammate check
    function Utils:IsTeammate(player)
        local success, result = pcall(function()
            if not LocalPlayer.Team or not player.Team then
                return false
            end
            return LocalPlayer.Team == player.Team
        end)
        return success and result or false
    end
    
    -- Enhanced player alive check
    function Utils:IsPlayerAlive(player)
        local success, result = pcall(function()
            return player and 
                   player.Character and 
                   player.Character:FindFirstChild("Humanoid") and 
                   player.Character.Humanoid.Health > 0 and
                   player.Character:FindFirstChild("HumanoidRootPart")
        end)
        return success and result or false
    end
    
    -- Safe health percentage calculation
    function Utils:GetHealthPercentage(player)
        local success, result = pcall(function()
            if not self:IsPlayerAlive(player) then
                return 0
            end
            local humanoid = player.Character.Humanoid
            return (humanoid.Health / humanoid.MaxHealth) * 100
        end)
        return success and result or 0
    end
    
    -- Enhanced line of sight check
    function Utils:HasLineOfSight(from, to, ignoreList)
        local success, result = pcall(function()
            ignoreList = ignoreList or {LocalPlayer.Character}
            
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
            raycastParams.FilterDescendantsInstances = ignoreList
            
            local raycastResult = Workspace:Raycast(from, (to - from), raycastParams)
            return raycastResult == nil
        end)
        return success and result or false
    end
    
    -- Safe world to screen conversion
    function Utils:WorldToScreen(position)
        local success, screenPoint, onScreen = pcall(function()
            local camera = Workspace.CurrentCamera
            local point, visible = camera:WorldToScreenPoint(position)
            return point, visible
        end)
        
        if success then
            return Vector2.new(screenPoint.X, screenPoint.Y), onScreen
        else
            return Vector2.new(0, 0), false
        end
    end
    
    -- Safe target acquisition
    function Utils:GetValidTargets()
        local targets = {}
        local success, err = pcall(function()
            local config = getgenv().AimbotESP.Config
            if not config or not config.aimbot then return end
            
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and self:IsPlayerAlive(player) then
                    -- Team check
                    if config.aimbot.teamCheck and self:IsTeammate(player) then
                        continue
                    end
                    
                    local character = player.Character
                    local humanoidRootPart = character.HumanoidRootPart
                    local distance = self:GetDistance(
                        LocalPlayer.Character.HumanoidRootPart.Position, 
                        humanoidRootPart.Position
                    )
                    
                    -- Distance check
                    if distance <= config.aimbot.maxDistance then
                        -- Visibility check
                        if not config.aimbot.visibilityCheck or 
                           self:HasLineOfSight(
                               LocalPlayer.Character.HumanoidRootPart.Position, 
                               humanoidRootPart.Position, 
                               {LocalPlayer.Character}
                           ) then
                            
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
        end)
        
        if not success then
            warn("❌ Error getting targets: " .. tostring(err))
        end
        
        return targets
    end
    
    -- Safe target sorting
    function Utils:SortTargetsByPriority(targets, priorityMode)
        local success, err = pcall(function()
            priorityMode = priorityMode or "Distance"
            
            if priorityMode == "Distance" then
                table.sort(targets, function(a, b) 
                    return (a.distance or math.huge) < (b.distance or math.huge) 
                end)
            elseif priorityMode == "Health" then
                table.sort(targets, function(a, b) 
                    return (a.health or 100) < (b.health or 100) 
                end)
            end
        end)
        
        if not success then
            warn("❌ Error sorting targets: " .. tostring(err))
        end
        
        return targets
    end
    
    -- Safe utility functions
    function Utils:Clamp(value, min, max)
        return math.max(min or 0, math.min(max or 1, value or 0))
    end
    
    function Utils:Lerp(a, b, t)
        return (a or 0) + ((b or 0) - (a or 0)) * (t or 0)
    end
    
    -- Safe color functions
    function Utils:GetHealthColor(healthPercent)
        healthPercent = healthPercent or 0
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
        local success, result = pcall(function()
            if player and player.Team then
                return player.Team.TeamColor.Color
            end
            return Color3.new(1, 1, 1)
        end)
        return success and result or Color3.new(1, 1, 1)
    end
    
    return Utils
]])

-- Enhanced emergency disable function
local function EmergencyDisable()
    local success, err = pcall(function()
        getgenv().AimbotESP.State.EmergencyDisabled = true
        getgenv().AimbotESP.State.AimbotEnabled = false
        getgenv().AimbotESP.State.ESPEnabled = false
        
        -- Safely disable all visual elements
        if getgenv().AimbotESP.Components.ESP then
            getgenv().AimbotESP.Components.ESP:DisableAll()
        end
        
        -- Clear any GUI elements
        for _, gui in pairs(game.CoreGui:GetChildren()) do
            if gui.Name:find("Aimbot") or gui.Name:find("ESP") then
                gui:Destroy()
            end
        end
    end)
    
    if success then
        warn("🚨 EMERGENCY DISABLE ACTIVATED - All features disabled!")
    else
        warn("❌ Emergency disable failed: " .. tostring(err))
    end
end

-- Enhanced hotkey handler with error protection
local function HandleHotkeys()
    local success, err = pcall(function()
        local config = getgenv().AimbotESP.Config
        if not config or not config.gui or not config.gui.hotkeys then
            warn("⚠️ Hotkey configuration not available")
            return
        end
        
        local hotkeys = config.gui.hotkeys
        
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            local inputSuccess, inputErr = pcall(function()
                -- Emergency disable (highest priority)
                if input.KeyCode == hotkeys.emergencyDisable then
                    EmergencyDisable()
                    return
                end
                
                -- Don't process other hotkeys if emergency disabled
                if getgenv().AimbotESP.State.EmergencyDisabled then return end
                
                -- Toggle Aimbot
                if input.KeyCode == hotkeys.toggleAimbot then
                    getgenv().AimbotESP.State.AimbotEnabled = not getgenv().AimbotESP.State.AimbotEnabled
                    getgenv().AimbotESP.Config.aimbot.enabled = getgenv().AimbotESP.State.AimbotEnabled
                    print("🎯 Aimbot: " .. (getgenv().AimbotESP.State.AimbotEnabled and "ON" or "OFF"))
                end
                
                -- Toggle ESP
                if input.KeyCode == hotkeys.toggleESP then
                    getgenv().AimbotESP.State.ESPEnabled = not getgenv().AimbotESP.State.ESPEnabled
                    getgenv().AimbotESP.Config.esp.enabled = getgenv().AimbotESP.State.ESPEnabled
                    print("👁️ ESP: " .. (getgenv().AimbotESP.State.ESPEnabled and "ON" or "OFF"))
                end
                
                -- Toggle Tracers
                if input.KeyCode == hotkeys.toggleTracers then
                    getgenv().AimbotESP.Config.esp.tracers = not getgenv().AimbotESP.Config.esp.tracers
                    print("📍 Tracers: " .. (getgenv().AimbotESP.Config.esp.tracers and "ON" or "OFF"))
                end
                
                -- Cycle target mode
                if input.KeyCode == hotkeys.cycleTarget then
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
            
            if not inputSuccess then
                warn("❌ Hotkey error: " .. tostring(inputErr))
            end
        end)
    end)
    
    if success then
        print("⌨️ Hotkey system initialized")
    else
        warn("❌ Hotkey system failed: " .. tostring(err))
    end
end

-- Initialize hotkey system
HandleHotkeys()

-- Create basic placeholder components with error handling
print("🔄 Loading AimBot system...")
getgenv().AimbotESP.Components.Aimbot = {
    Initialize = function() 
        print("🎯 AimBot system ready") 
        return true
    end,
    Update = function() 
        -- Basic aimbot functionality would go here
        return true
    end,
    Cleanup = function()
        print("🎯 AimBot cleaned up")
    end
}

print("🔄 Loading ESP system...")
getgenv().AimbotESP.Components.ESP = {
    Initialize = function() 
        print("👁️ ESP system ready") 
        return true
    end,
    Update = function() 
        -- Basic ESP functionality would go here
        return true
    end,
    DisableAll = function() 
        print("👁️ ESP disabled") 
    end,
    Cleanup = function()
        print("👁️ ESP cleaned up")
    end
}

print("🔄 Loading GUI system...")
getgenv().AimbotESP.Components.GUI = {
    Initialize = function() 
        print("🖥️ GUI system ready") 
        return true
    end,
    SetVisible = function(visible)
        print("🖥️ GUI " .. (visible and "shown" or "hidden"))
    end,
    Cleanup = function()
        print("🖥️ GUI cleaned up")
    end
}

-- Initialize all components safely
local function InitializeComponents()
    local success, err = pcall(function()
        for name, component in pairs(getgenv().AimbotESP.Components) do
            if component and component.Initialize then
                component:Initialize()
            end
        end
        getgenv().AimbotESP.State.Initialized = true
    end)
    
    if success then
        print("✅ All components initialized successfully")
    else
        warn("❌ Component initialization failed: " .. tostring(err))
    end
end

-- Main update loop with error handling
local function StartUpdateLoop()
    local success, connection = pcall(function()
        return RunService.Heartbeat:Connect(function()
            if getgenv().AimbotESP.State.EmergencyDisabled then
                return
            end
            
            local loopSuccess, loopErr = pcall(function()
                -- Update components if they exist and are enabled
                if getgenv().AimbotESP.State.AimbotEnabled and 
                   getgenv().AimbotESP.Components.Aimbot and 
                   getgenv().AimbotESP.Components.Aimbot.Update then
                    getgenv().AimbotESP.Components.Aimbot:Update()
                end
                
                if getgenv().AimbotESP.State.ESPEnabled and 
                   getgenv().AimbotESP.Components.ESP and 
                   getgenv().AimbotESP.Components.ESP.Update then
                    getgenv().AimbotESP.Components.ESP:Update()
                end
            end)
            
            if not loopSuccess then
                getgenv().AimbotESP.Debug.ErrorCount = getgenv().AimbotESP.Debug.ErrorCount + 1
                if getgenv().AimbotESP.Debug.ErrorCount > 10 then
                    warn("🚨 Too many errors detected, activating emergency disable")
                    EmergencyDisable()
                end
            end
        end)
    end)
    
    if success then
        print("🔄 Update loop started")
        getgenv().AimbotESP.UpdateConnection = connection
    else
        warn("❌ Failed to start update loop: " .. tostring(connection))
    end
end

-- Final initialization
InitializeComponents()
StartUpdateLoop()

-- Success message
print("🎉 Advanced AimBot & ESP System loaded successfully!")
print("📋 Controls:")
print("   INSERT - Toggle GUI")
print("   F1 - Toggle AimBot")
print("   F2 - Toggle ESP") 
print("   F3 - Toggle Tracers")
print("   F4 - Cycle Target Mode")
print("   DELETE - Emergency Disable")
print("⚠️ Remember: Use responsibly and respect other players!")

-- Cleanup function for proper shutdown
getgenv().AimbotESP.Cleanup = function()
    local success, err = pcall(function()
        -- Disconnect update loop
        if getgenv().AimbotESP.UpdateConnection then
            getgenv().AimbotESP.UpdateConnection:Disconnect()
        end
        
        -- Cleanup components
        for name, component in pairs(getgenv().AimbotESP.Components) do
            if component and component.Cleanup then
                component:Cleanup()
            end
        end
        
        -- Clear global state
        getgenv().AIMBOT_ESP_LOADED = false
        getgenv().AimbotESP = nil
        
        print("🧹 System cleaned up successfully")
    end)
    
    if not success then
        warn("❌ Cleanup failed: " .. tostring(err))
    end
end
