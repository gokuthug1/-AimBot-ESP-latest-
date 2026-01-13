--[[
    Advanced Configuration Example
    
    This example shows advanced configuration options and customization
    for experienced users who want maximum control.
]]

-- Load the main system
loadstring(game:HttpGet("https://raw.githubusercontent.com/gokuthug1/-AimBot-ESP-latest-/main/src/main.lua"))()

-- Wait for system to load
repeat wait() until getgenv().AimbotESP and getgenv().AimbotESP.Loaded

print("🔧 Loading Advanced Configuration...")

-- Get components
local config = getgenv().AimbotESP.Components.Config
local utils = getgenv().AimbotESP.Components.Utils

-- Advanced AimBot Configuration
local advancedAimbotConfig = {
    enabled = true,
    aimKey = Enum.UserInputType.MouseButton2, -- Right click
    targetPart = "Smart", -- Smart targeting
    fov = 75, -- Smaller, more realistic FOV
    smoothness = 12, -- Smooth but responsive
    prediction = true, -- Enable prediction
    teamCheck = true, -- Don't target teammates
    visibilityCheck = true, -- Only target visible players
    maxDistance = 800, -- 800 stud range
    priorityMode = "Health" -- Target lowest health first
}

-- Advanced ESP Configuration
local advancedESPConfig = {
    enabled = true,
    players = true,
    boxes = true,
    names = true,
    healthBars = true,
    distance = true,
    tracers = false, -- Disable tracers for stealth
    skeleton = true, -- Enable skeleton ESP
    teamColors = true,
    showTeammates = false, -- Hide teammate ESP
    maxDistance = 600,
    thickness = 2,
    transparency = 0.7 -- Slightly transparent
}

-- Advanced Anti-Detection Configuration
local advancedAntiDetectionConfig = {
    enabled = true,
    randomDelay = {min = 0.02, max = 0.08}, -- More randomness
    humanization = true,
    stealthMode = false, -- Keep visual indicators
    maxActionsPerSecond = 25 -- Conservative rate limit
}

-- Advanced Performance Configuration
local advancedPerformanceConfig = {
    updateRate = 75, -- 75 FPS update rate
    renderDistance = 600,
    maxTrackedPlayers = 15, -- Track fewer players for performance
    optimizeRendering = true
}

-- Advanced GUI Configuration
local advancedGUIConfig = {
    enabled = true,
    theme = "Blue", -- Blue theme
    scale = 1.1, -- Slightly larger GUI
    position = {X = 100, Y = 100}, -- Custom position
    hotkeys = {
        toggleGUI = Enum.KeyCode.Insert,
        toggleAimbot = Enum.KeyCode.F1,
        toggleESP = Enum.KeyCode.F2,
        toggleTracers = Enum.KeyCode.F3,
        cycleTarget = Enum.KeyCode.F4,
        emergencyDisable = Enum.KeyCode.Delete
    }
}

-- Apply all configurations
print("⚙️ Applying AimBot configuration...")
for key, value in pairs(advancedAimbotConfig) do
    config:Set("aimbot." .. key, value)
end

print("👁️ Applying ESP configuration...")
for key, value in pairs(advancedESPConfig) do
    config:Set("esp." .. key, value)
end

print("🛡️ Applying Anti-Detection configuration...")
for key, value in pairs(advancedAntiDetectionConfig) do
    config:Set("antiDetection." .. key, value)
end

print("⚡ Applying Performance configuration...")
for key, value in pairs(advancedPerformanceConfig) do
    config:Set("performance." .. key, value)
end

print("🖥️ Applying GUI configuration...")
for key, value in pairs(advancedGUIConfig) do
    config:Set("gui." .. key, value)
end

-- Game-specific optimizations
local function detectAndOptimizeForGame()
    local gameId = game.GameId
    local placeName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    
    print("🎮 Detected game: " .. placeName)
    
    -- Arsenal optimizations
    if string.find(placeName:lower(), "arsenal") then
        print("🎯 Applying Arsenal optimizations...")
        config:Set("aimbot.fov", 85)
        config:Set("aimbot.smoothness", 8)
        config:Set("aimbot.targetPart", "Head")
        config:Set("esp.maxDistance", 300)
        config:Set("antiDetection.maxActionsPerSecond", 30)
        
    -- Phantom Forces optimizations
    elseif string.find(placeName:lower(), "phantom") then
        print("👻 Applying Phantom Forces optimizations...")
        config:Set("aimbot.fov", 70)
        config:Set("aimbot.smoothness", 15)
        config:Set("aimbot.targetPart", "Torso")
        config:Set("esp.tracers", false) -- Tracers are risky in PF
        config:Set("antiDetection.stealthMode", true)
        
    -- Bad Business optimizations
    elseif string.find(placeName:lower(), "bad business") then
        print("💼 Applying Bad Business optimizations...")
        config:Set("aimbot.fov", 95)
        config:Set("aimbot.smoothness", 6)
        config:Set("aimbot.targetPart", "Smart")
        config:Set("esp.skeleton", false) -- Skeleton can be laggy
        
    -- Counter Blox optimizations
    elseif string.find(placeName:lower(), "counter") or string.find(placeName:lower(), "blox") then
        print("🔫 Applying Counter Blox optimizations...")
        config:Set("aimbot.fov", 65)
        config:Set("aimbot.smoothness", 18)
        config:Set("aimbot.prediction", false) -- Less prediction needed
        config:Set("esp.maxDistance", 250)
        config:Set("antiDetection.humanization", true)
    end
end

-- Apply game-specific optimizations
detectAndOptimizeForGame()

-- Advanced event handling
config:OnChanged(function(changeData)
    -- Log important configuration changes
    local importantSettings = {
        "aimbot.enabled",
        "esp.enabled",
        "antiDetection.enabled",
        "aimbot.fov",
        "aimbot.smoothness"
    }
    
    for _, setting in ipairs(importantSettings) do
        if changeData.path == setting then
            print(string.format("📝 %s changed: %s → %s", 
                  changeData.path, 
                  tostring(changeData.oldValue), 
                  tostring(changeData.newValue)))
            break
        end
    end
end)

-- Performance monitoring
local performanceMonitor = {
    lastCheck = tick(),
    frameCount = 0,
    avgFPS = 0
}

game:GetService("RunService").Heartbeat:Connect(function()
    performanceMonitor.frameCount = performanceMonitor.frameCount + 1
    local currentTime = tick()
    
    if currentTime - performanceMonitor.lastCheck >= 5 then -- Check every 5 seconds
        local fps = performanceMonitor.frameCount / (currentTime - performanceMonitor.lastCheck)
        performanceMonitor.avgFPS = fps
        performanceMonitor.frameCount = 0
        performanceMonitor.lastCheck = currentTime
        
        -- Auto-adjust performance settings based on FPS
        if fps < 30 then
            print("⚠️ Low FPS detected, reducing settings...")
            config:Set("performance.updateRate", 45)
            config:Set("esp.maxDistance", 300)
            config:Set("performance.maxTrackedPlayers", 10)
        elseif fps > 60 then
            print("✅ Good FPS, optimizing for quality...")
            config:Set("performance.updateRate", 90)
            config:Set("esp.maxDistance", 800)
            config:Set("performance.maxTrackedPlayers", 20)
        end
    end
end)

-- Custom target prioritization
local aimbot = getgenv().AimbotESP.Components.Aimbot
if aimbot then
    local originalFindBestTarget = aimbot.FindBestTarget
    aimbot.FindBestTarget = function(self)
        local targets = utils:GetValidTargets()
        
        if #targets == 0 then return nil end
        
        -- Custom scoring system
        for _, target in ipairs(targets) do
            local score = 0
            
            -- Distance factor (closer = higher score)
            score = score + (1000 - target.distance) / 10
            
            -- Health factor (lower health = higher score)
            score = score + (100 - target.health) / 2
            
            -- Visibility factor
            if utils:IsPlayerVisible(target.player) then
                score = score + 50
            end
            
            -- Movement factor (slower = higher score)
            local velocity = target.velocity.Magnitude
            score = score + (50 - math.min(velocity, 50))
            
            target.score = score
        end
        
        -- Sort by score (highest first)
        table.sort(targets, function(a, b) return a.score > b.score end)
        
        return targets[1]
    end
end

-- Advanced ESP customization
local esp = getgenv().AimbotESP.Components.ESP
if esp then
    -- Custom color scheme based on threat level
    local originalUpdatePlayerESP = esp.UpdatePlayerESP
    esp.UpdatePlayerESP = function(self, player, espData)
        originalUpdatePlayerESP(self, player, espData)
        
        if espData.elements.boxStroke and utils:IsPlayerAlive(player) then
            local distance = utils:GetDistance(
                game.Players.LocalPlayer.Character.HumanoidRootPart.Position,
                player.Character.HumanoidRootPart.Position
            )
            
            -- Color based on distance and threat
            local color
            if distance < 100 then
                color = Color3.new(1, 0, 0) -- Red for close/dangerous
            elseif distance < 300 then
                color = Color3.new(1, 0.5, 0) -- Orange for medium
            else
                color = Color3.new(0, 1, 0) -- Green for far
            end
            
            espData.elements.boxStroke.Color = color
        end
    end
end

-- Save configuration as profile
local function saveCurrentProfile()
    local profileData = config:Export()
    print("💾 Current configuration saved!")
    print("📋 Profile data length: " .. #profileData .. " characters")
    
    -- In a real implementation, you could save this to a file
    getgenv().SAVED_PROFILE = profileData
end

-- Load saved profile
local function loadSavedProfile()
    if getgenv().SAVED_PROFILE then
        local success = config:Import(getgenv().SAVED_PROFILE)
        if success then
            print("📁 Saved profile loaded successfully!")
        else
            warn("❌ Failed to load saved profile")
        end
    else
        warn("❌ No saved profile found")
    end
end

-- Expose profile functions
getgenv().SaveProfile = saveCurrentProfile
getgenv().LoadProfile = loadSavedProfile

print("✅ Advanced configuration complete!")
print("📊 Performance monitoring active")
print("🎯 Custom targeting system enabled")
print("🎨 Advanced ESP customization applied")
print("💾 Profile system ready (use SaveProfile() and LoadProfile())")

--[[
    Advanced Features Enabled:
    
    1. Game-specific optimizations
    2. Performance monitoring and auto-adjustment
    3. Custom target prioritization with scoring
    4. Advanced ESP color schemes
    5. Configuration change logging
    6. Profile save/load system
    7. Comprehensive anti-detection
    8. Optimized update rates
    
    Usage:
    - All standard hotkeys work (F1, F2, etc.)
    - System auto-adjusts based on performance
    - Custom colors show threat levels
    - Profiles can be saved/loaded with SaveProfile()/LoadProfile()
]]