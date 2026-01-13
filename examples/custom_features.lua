--[[
    Custom Features Example
    
    This example demonstrates how to create custom features and extend
    the AimBot & ESP system with your own functionality.
]]

-- Load the main system
loadstring(game:HttpGet("https://raw.githubusercontent.com/gokuthug1/-AimBot-ESP-latest-/main/src/main.lua"))()

-- Wait for system to load
repeat wait() until getgenv().AimbotESP and getgenv().AimbotESP.Loaded

print("🔧 Loading Custom Features...")

-- Get components
local config = getgenv().AimbotESP.Components.Config
local utils = getgenv().AimbotESP.Components.Utils
local aimbot = getgenv().AimbotESP.Components.Aimbot
local esp = getgenv().AimbotESP.Components.ESP

-- Custom Feature 1: Weapon Detection ESP
local WeaponESP = {
    enabled = true,
    weaponLabels = {}
}

function WeaponESP:CreateWeaponLabel(player, parentFrame)
    local weaponLabel = Instance.new("TextLabel")
    weaponLabel.Name = "WeaponLabel"
    weaponLabel.Size = UDim2.new(1, 0, 0, 15)
    weaponLabel.Position = UDim2.new(0, 0, 1, 25)
    weaponLabel.BackgroundTransparency = 1
    weaponLabel.Text = "No Weapon"
    weaponLabel.TextColor3 = Color3.new(1, 1, 0)
    weaponLabel.TextScaled = true
    weaponLabel.TextStrokeTransparency = 0
    weaponLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    weaponLabel.Font = Enum.Font.GothamBold
    weaponLabel.Parent = parentFrame
    
    self.weaponLabels[player] = weaponLabel
    return weaponLabel
end

function WeaponESP:UpdateWeaponDisplay(player)
    if not self.enabled or not self.weaponLabels[player] then return end
    
    local label = self.weaponLabels[player]
    
    if utils:IsPlayerAlive(player) then
        local character = player.Character
        local tool = character:FindFirstChildOfClass("Tool")
        
        if tool then
            label.Text = "🔫 " .. tool.Name
            label.TextColor3 = Color3.new(1, 0.5, 0) -- Orange for armed
            label.Visible = true
        else
            label.Text = "👤 Unarmed"
            label.TextColor3 = Color3.new(0.5, 1, 0.5) -- Light green for unarmed
            label.Visible = true
        end
    else
        label.Visible = false
    end
end

-- Hook into ESP system
local originalCreatePlayerESP = esp.CreatePlayerESP
esp.CreatePlayerESP = function(self, player)
    originalCreatePlayerESP(self, player)
    
    local espData = self.PlayerESP[player]
    if espData and espData.elements.mainFrame then
        WeaponESP:CreateWeaponLabel(player, espData.elements.mainFrame)
    end
end

local originalUpdatePlayerESP = esp.UpdatePlayerESP
esp.UpdatePlayerESP = function(self, player, espData)
    originalUpdatePlayerESP(self, player, espData)
    WeaponESP:UpdateWeaponDisplay(player)
end

-- Custom Feature 2: Smart Target Prediction
local SmartPredictor = {
    enabled = true,
    playerVelocityHistory = {},
    maxHistorySize = 10
}

function SmartPredictor:RecordVelocity(player, velocity)
    if not self.playerVelocityHistory[player] then
        self.playerVelocityHistory[player] = {}
    end
    
    local history = self.playerVelocityHistory[player]
    table.insert(history, {
        velocity = velocity,
        timestamp = tick()
    })
    
    -- Keep only recent history
    while #history > self.maxHistorySize do
        table.remove(history, 1)
    end
end

function SmartPredictor:PredictPosition(player, timeAhead)
    if not self.enabled or not self.playerVelocityHistory[player] then
        return nil
    end
    
    local history = self.playerVelocityHistory[player]
    if #history < 3 then return nil end
    
    -- Calculate average velocity
    local avgVelocity = Vector3.new(0, 0, 0)
    for _, record in ipairs(history) do
        avgVelocity = avgVelocity + record.velocity
    end
    avgVelocity = avgVelocity / #history
    
    -- Calculate acceleration
    local acceleration = Vector3.new(0, 0, 0)
    if #history >= 2 then
        local recent = history[#history].velocity
        local previous = history[#history - 1].velocity
        local timeDiff = history[#history].timestamp - history[#history - 1].timestamp
        acceleration = (recent - previous) / timeDiff
    end
    
    -- Predict position
    local currentPos = player.Character.HumanoidRootPart.Position
    local predictedPos = currentPos + (avgVelocity * timeAhead) + (0.5 * acceleration * timeAhead^2)
    
    return predictedPos
end

-- Update velocity tracking
game:GetService("RunService").Heartbeat:Connect(function()
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer and utils:IsPlayerAlive(player) then
            local velocity = player.Character.HumanoidRootPart.Velocity
            SmartPredictor:RecordVelocity(player, velocity)
        end
    end
end)

-- Custom Feature 3: Threat Assessment System
local ThreatAssessment = {
    enabled = true,
    threatLevels = {},
    threatFactors = {
        distance = 0.3,
        health = 0.2,
        weapon = 0.3,
        movement = 0.2
    }
}

function ThreatAssessment:CalculateThreatLevel(player)
    if not self.enabled or not utils:IsPlayerAlive(player) then
        return 0
    end
    
    local threat = 0
    local character = player.Character
    local humanoidRootPart = character.HumanoidRootPart
    local localPlayer = game.Players.LocalPlayer
    
    -- Distance factor (closer = more threatening)
    local distance = utils:GetDistance(
        localPlayer.Character.HumanoidRootPart.Position,
        humanoidRootPart.Position
    )
    local distanceThreat = math.max(0, 1 - (distance / 500)) -- Normalize to 0-1
    threat = threat + (distanceThreat * self.threatFactors.distance)
    
    -- Health factor (higher health = more threatening)
    local healthPercent = utils:GetHealthPercentage(player) / 100
    threat = threat + (healthPercent * self.threatFactors.health)
    
    -- Weapon factor (armed = more threatening)
    local tool = character:FindFirstChildOfClass("Tool")
    local weaponThreat = tool and 1 or 0.3
    threat = threat + (weaponThreat * self.threatFactors.weapon)
    
    -- Movement factor (faster = more threatening)
    local velocity = humanoidRootPart.Velocity.Magnitude
    local movementThreat = math.min(1, velocity / 50) -- Normalize to 0-1
    threat = threat + (movementThreat * self.threatFactors.movement)
    
    self.threatLevels[player] = threat
    return threat
end

function ThreatAssessment:GetThreatColor(threatLevel)
    if threatLevel > 0.8 then
        return Color3.new(1, 0, 0) -- Red - High threat
    elseif threatLevel > 0.6 then
        return Color3.new(1, 0.5, 0) -- Orange - Medium threat
    elseif threatLevel > 0.3 then
        return Color3.new(1, 1, 0) -- Yellow - Low threat
    else
        return Color3.new(0, 1, 0) -- Green - Minimal threat
    end
end

-- Update threat levels
game:GetService("RunService").Heartbeat:Connect(function()
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            ThreatAssessment:CalculateThreatLevel(player)
        end
    end
end)

-- Custom Feature 4: Auto-Dodge System
local AutoDodge = {
    enabled = false, -- Disabled by default as it's very obvious
    dodgeThreshold = 0.8, -- Threat level to trigger dodge
    lastDodgeTime = 0,
    dodgeCooldown = 2 -- Seconds between dodges
}

function AutoDodge:ShouldDodge()
    if not self.enabled then return false end
    
    local currentTime = tick()
    if currentTime - self.lastDodgeTime < self.dodgeCooldown then
        return false
    end
    
    -- Check for high-threat players nearby
    for player, threatLevel in pairs(ThreatAssessment.threatLevels) do
        if threatLevel > self.dodgeThreshold then
            local distance = utils:GetDistance(
                game.Players.LocalPlayer.Character.HumanoidRootPart.Position,
                player.Character.HumanoidRootPart.Position
            )
            
            if distance < 100 then -- Very close
                return true
            end
        end
    end
    
    return false
end

function AutoDodge:PerformDodge()
    local humanoid = game.Players.LocalPlayer.Character.Humanoid
    
    -- Random dodge direction
    local directions = {
        Vector3.new(1, 0, 0),   -- Right
        Vector3.new(-1, 0, 0),  -- Left
        Vector3.new(0, 0, 1),   -- Forward
        Vector3.new(0, 0, -1)   -- Backward
    }
    
    local randomDirection = directions[math.random(#directions)]
    humanoid:Move(randomDirection)
    
    -- Jump occasionally
    if math.random() < 0.3 then
        humanoid.Jump = true
    end
    
    self.lastDodgeTime = tick()
    print("🏃 Auto-dodge activated!")
end

-- Custom Feature 5: Statistics Tracker
local StatsTracker = {
    enabled = true,
    stats = {
        sessionStart = tick(),
        shotsAttempted = 0,
        hitsLanded = 0,
        targetsAcquired = 0,
        averageDistance = 0,
        longestShot = 0,
        favoriteTarget = nil,
        targetCounts = {}
    }
}

function StatsTracker:RecordShot(hit, distance, target)
    if not self.enabled then return end
    
    self.stats.shotsAttempted = self.stats.shotsAttempted + 1
    
    if hit then
        self.stats.hitsLanded = self.stats.hitsLanded + 1
    end
    
    if distance then
        self.stats.averageDistance = (self.stats.averageDistance + distance) / 2
        if distance > self.stats.longestShot then
            self.stats.longestShot = distance
        end
    end
    
    if target then
        self.stats.targetCounts[target.Name] = (self.stats.targetCounts[target.Name] or 0) + 1
        
        -- Update favorite target
        local maxCount = 0
        for playerName, count in pairs(self.stats.targetCounts) do
            if count > maxCount then
                maxCount = count
                self.stats.favoriteTarget = playerName
            end
        end
    end
end

function StatsTracker:GetAccuracy()
    if self.stats.shotsAttempted == 0 then return 0 end
    return (self.stats.hitsLanded / self.stats.shotsAttempted) * 100
end

function StatsTracker:GetSessionTime()
    return tick() - self.stats.sessionStart
end

function StatsTracker:PrintStats()
    local sessionTime = self:GetSessionTime()
    local accuracy = self:GetAccuracy()
    
    print("📊 Session Statistics:")
    print("⏱️ Session Time: " .. math.floor(sessionTime / 60) .. "m " .. math.floor(sessionTime % 60) .. "s")
    print("🎯 Accuracy: " .. string.format("%.1f%%", accuracy))
    print("📈 Shots: " .. self.stats.hitsLanded .. "/" .. self.stats.shotsAttempted)
    print("📏 Average Distance: " .. string.format("%.1f", self.stats.averageDistance) .. " studs")
    print("🏆 Longest Shot: " .. string.format("%.1f", self.stats.longestShot) .. " studs")
    if self.stats.favoriteTarget then
        print("🎯 Favorite Target: " .. self.stats.favoriteTarget)
    end
end

-- Custom Feature 6: Voice Alerts (Text-to-Speech simulation)
local VoiceAlerts = {
    enabled = false, -- Disabled by default
    lastAlert = 0,
    alertCooldown = 3
}

function VoiceAlerts:PlayAlert(message)
    if not self.enabled then return end
    
    local currentTime = tick()
    if currentTime - self.lastAlert < self.alertCooldown then
        return
    end
    
    -- Simulate TTS with chat message
    print("🔊 ALERT: " .. message)
    self.lastAlert = currentTime
end

-- Integration with existing systems
local originalFindBestTarget = aimbot.FindBestTarget
aimbot.FindBestTarget = function(self)
    -- Use threat assessment for targeting
    if ThreatAssessment.enabled then
        local targets = utils:GetValidTargets()
        
        if #targets > 0 then
            -- Sort by threat level
            table.sort(targets, function(a, b)
                local threatA = ThreatAssessment.threatLevels[a.player] or 0
                local threatB = ThreatAssessment.threatLevels[b.player] or 0
                return threatA > threatB
            end)
            
            local bestTarget = targets[1]
            
            -- Voice alert for high-threat targets
            local threatLevel = ThreatAssessment.threatLevels[bestTarget.player] or 0
            if threatLevel > 0.8 then
                VoiceAlerts:PlayAlert("High threat target acquired: " .. bestTarget.player.Name)
            end
            
            return bestTarget
        end
    end
    
    -- Fall back to original logic
    return originalFindBestTarget(self)
end

-- Auto-dodge integration
game:GetService("RunService").Heartbeat:Connect(function()
    if AutoDodge:ShouldDodge() then
        AutoDodge:PerformDodge()
    end
end)

-- Custom GUI for features
local function createCustomGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CustomFeatures"
    screenGui.Parent = game.CoreGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 300)
    frame.Position = UDim2.new(1, -260, 0, 10)
    frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🔧 Custom Features"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    local yOffset = 40
    
    -- Feature toggles
    local features = {
        {"Weapon ESP", WeaponESP, "enabled"},
        {"Smart Prediction", SmartPredictor, "enabled"},
        {"Threat Assessment", ThreatAssessment, "enabled"},
        {"Auto Dodge", AutoDodge, "enabled"},
        {"Stats Tracker", StatsTracker, "enabled"},
        {"Voice Alerts", VoiceAlerts, "enabled"}
    }
    
    for _, feature in ipairs(features) do
        local featureName, featureObj, property = feature[1], feature[2], feature[3]
        
        local toggle = Instance.new("TextButton")
        toggle.Size = UDim2.new(1, -20, 0, 25)
        toggle.Position = UDim2.new(0, 10, 0, yOffset)
        toggle.BackgroundColor3 = featureObj[property] and Color3.new(0, 0.8, 0) or Color3.new(0.8, 0, 0)
        toggle.BorderSizePixel = 0
        toggle.Text = featureName .. ": " .. (featureObj[property] and "ON" or "OFF")
        toggle.TextColor3 = Color3.new(1, 1, 1)
        toggle.TextScaled = true
        toggle.Font = Enum.Font.Gotham
        toggle.Parent = frame
        
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 4)
        toggleCorner.Parent = toggle
        
        toggle.MouseButton1Click:Connect(function()
            featureObj[property] = not featureObj[property]
            toggle.BackgroundColor3 = featureObj[property] and Color3.new(0, 0.8, 0) or Color3.new(0.8, 0, 0)
            toggle.Text = featureName .. ": " .. (featureObj[property] and "ON" or "OFF")
        end)
        
        yOffset = yOffset + 35
    end
    
    -- Stats button
    local statsButton = Instance.new("TextButton")
    statsButton.Size = UDim2.new(1, -20, 0, 25)
    statsButton.Position = UDim2.new(0, 10, 0, yOffset)
    statsButton.BackgroundColor3 = Color3.new(0, 0.5, 1)
    statsButton.BorderSizePixel = 0
    statsButton.Text = "📊 Show Stats"
    statsButton.TextColor3 = Color3.new(1, 1, 1)
    statsButton.TextScaled = true
    statsButton.Font = Enum.Font.Gotham
    statsButton.Parent = frame
    
    local statsCorner = Instance.new("UICorner")
    statsCorner.CornerRadius = UDim.new(0, 4)
    statsCorner.Parent = statsButton
    
    statsButton.MouseButton1Click:Connect(function()
        StatsTracker:PrintStats()
    end)
    
    return screenGui
end

-- Create custom GUI
local customGUI = createCustomGUI()

-- Hotkey to toggle custom GUI
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F5 then
        customGUI.Enabled = not customGUI.Enabled
    end
end)

print("✅ Custom Features Loaded!")
print("🎮 Features Available:")
print("   🔫 Weapon Detection ESP")
print("   🧠 Smart Target Prediction")
print("   ⚠️ Threat Assessment System")
print("   🏃 Auto-Dodge (Use with caution!)")
print("   📊 Statistics Tracker")
print("   🔊 Voice Alerts")
print("📋 Press F5 to toggle Custom Features GUI")
print("📊 Use 'Show Stats' button to view session statistics")

--[[
    Custom Features Summary:
    
    1. Weapon Detection ESP - Shows what weapon each player is holding
    2. Smart Target Prediction - Advanced movement prediction using velocity history
    3. Threat Assessment System - Calculates threat levels based on multiple factors
    4. Auto-Dodge System - Automatically dodges high-threat players (VERY OBVIOUS)
    5. Statistics Tracker - Tracks accuracy, shots, distances, and favorite targets
    6. Voice Alerts - Text alerts for high-threat situations
    
    All features can be toggled individually through the custom GUI (F5 key).
    
    Warning: Some features like Auto-Dodge are very obvious and should be used
    with extreme caution or not at all in competitive environments.
]]