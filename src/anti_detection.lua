--[[
    Anti-Detection System v2.0.0
    
    This module implements various anti-detection measures to avoid
    detection by anti-cheat systems:
    - Rate limiting and action throttling
    - Human-like behavior simulation
    - Randomized timing and patterns
    - Stealth mode operations
    
    Author: gokuthug1
    License: MIT
]]

local AntiDetection = {}

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Local references
local LocalPlayer = Players.LocalPlayer

-- Anti-detection state
AntiDetection.ActionHistory = {}
AntiDetection.LastActionTime = 0
AntiDetection.BehaviorPatterns = {}
AntiDetection.SuspicionLevel = 0
AntiDetection.MaxSuspicionLevel = 100

-- Behavior pattern templates
AntiDetection.HumanPatterns = {
    -- Reaction times (in seconds)
    reactionTime = {
        min = 0.15,
        max = 0.35,
        average = 0.25
    },
    
    -- Mouse movement characteristics
    mouseMovement = {
        smoothness = {min = 8, max = 15},
        overshoot = {chance = 0.15, amount = {min = 5, max = 15}},
        correction = {chance = 0.25, delay = {min = 0.05, max = 0.15}}
    },
    
    -- Aiming patterns
    aimingBehavior = {
        perfectAccuracy = 0.85, -- 85% accuracy ceiling
        missChance = 0.05, -- 5% intentional miss rate
        shakiness = {min = 0.5, max = 2.0}
    },
    
    -- Activity patterns
    activity = {
        burstLength = {min = 3, max = 8}, -- Actions in a burst
        burstCooldown = {min = 1.5, max = 4.0}, -- Time between bursts
        sessionBreaks = {min = 300, max = 900} -- Break every 5-15 minutes
    }
}

-- Initialize anti-detection system
function AntiDetection:Initialize()
    self:ResetSuspicionLevel()
    self:StartBehaviorMonitoring()
    print("🛡️ Anti-detection system initialized")
end

-- Reset suspicion level
function AntiDetection:ResetSuspicionLevel()
    self.SuspicionLevel = 0
    self.LastActionTime = tick()
    self.ActionHistory = {}
end

-- Start behavior monitoring
function AntiDetection:StartBehaviorMonitoring()
    -- Monitor for suspicious patterns
    RunService.Heartbeat:Connect(function()
        self:UpdateSuspicionLevel()
        self:CleanupActionHistory()
    end)
end

-- Check if an action is allowed based on rate limiting
function AntiDetection:IsActionAllowed(actionType)
    local config = getgenv().AimbotESP.Config.antiDetection
    if not config.enabled then return true end
    
    actionType = actionType or "general"
    local currentTime = tick()
    
    -- Check global rate limit
    local recentActions = self:GetRecentActions(1.0) -- Last 1 second
    if #recentActions >= config.maxActionsPerSecond then
        self:IncreaseSuspicion(5, "Rate limit exceeded")
        return false
    end
    
    -- Check action-specific limits
    local actionLimit = self:GetActionLimit(actionType)
    local recentActionsByType = self:GetRecentActionsByType(actionType, 1.0)
    
    if #recentActionsByType >= actionLimit then
        self:IncreaseSuspicion(3, "Action type limit exceeded: " .. actionType)
        return false
    end
    
    -- Check for suspicious patterns
    if self:DetectSuspiciousPattern() then
        self:IncreaseSuspicion(10, "Suspicious pattern detected")
        return false
    end
    
    return true
end

-- Record an action for tracking
function AntiDetection:RecordAction(actionType, metadata)
    local config = getgenv().AimbotESP.Config.antiDetection
    if not config.enabled then return end
    
    actionType = actionType or "general"
    metadata = metadata or {}
    
    local actionData = {
        type = actionType,
        timestamp = tick(),
        metadata = metadata
    }
    
    table.insert(self.ActionHistory, actionData)
    self.LastActionTime = actionData.timestamp
    
    -- Limit history size
    if #self.ActionHistory > 1000 then
        table.remove(self.ActionHistory, 1)
    end
end

-- Get action limit for specific action type
function AntiDetection:GetActionLimit(actionType)
    local limits = {
        aim = 20,
        shoot = 10,
        movement = 30,
        general = 25
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

-- Detect suspicious patterns
function AntiDetection:DetectSuspiciousPattern()
    local recentActions = self:GetRecentActions(5.0) -- Last 5 seconds
    
    if #recentActions < 5 then return false end
    
    -- Check for perfectly regular timing
    local intervals = {}
    for i = 2, #recentActions do
        local interval = recentActions[i].timestamp - recentActions[i-1].timestamp
        table.insert(intervals, interval)
    end
    
    -- Calculate variance in intervals
    local avgInterval = 0
    for _, interval in ipairs(intervals) do
        avgInterval = avgInterval + interval
    end
    avgInterval = avgInterval / #intervals
    
    local variance = 0
    for _, interval in ipairs(intervals) do
        variance = variance + (interval - avgInterval)^2
    end
    variance = variance / #intervals
    
    -- If variance is too low, it's suspicious (too regular)
    if variance < 0.001 then
        return true
    end
    
    -- Check for inhuman reaction times
    for _, action in ipairs(recentActions) do
        if action.metadata.reactionTime and action.metadata.reactionTime < 0.1 then
            return true
        end
    end
    
    return false
end

-- Get humanized delay
function AntiDetection:GetHumanizedDelay(baseDelay, variance)
    local config = getgenv().AimbotESP.Config.antiDetection
    if not config.enabled or not config.humanization then 
        return baseDelay or 0 
    end
    
    baseDelay = baseDelay or 0
    variance = variance or 0.3
    
    -- Add random variance
    local randomFactor = (math.random() - 0.5) * variance
    local humanizedDelay = baseDelay + (baseDelay * randomFactor)
    
    -- Ensure minimum human reaction time
    local minDelay = self.HumanPatterns.reactionTime.min
    humanizedDelay = math.max(humanizedDelay, minDelay)
    
    -- Add suspicion-based delay
    local suspicionDelay = (self.SuspicionLevel / self.MaxSuspicionLevel) * 0.1
    humanizedDelay = humanizedDelay + suspicionDelay
    
    return humanizedDelay
end

-- Apply humanization to mouse movement
function AntiDetection:HumanizeMovement(targetPosition, currentPosition, smoothness)
    local config = getgenv().AimbotESP.Config.antiDetection
    if not config.enabled or not config.humanization then 
        return targetPosition 
    end
    
    local utils = getgenv().AimbotESP.Components.Utils
    if not utils then return targetPosition end
    
    -- Calculate base movement
    local movement = targetPosition - currentPosition
    local distance = movement.Magnitude
    
    if distance < 1 then return targetPosition end
    
    -- Apply human-like smoothness variation
    local humanSmoothness = self:GetHumanizedValue(smoothness, 0.2)
    
    -- Add slight overshoot chance
    local overshootChance = self.HumanPatterns.mouseMovement.overshoot.chance
    if math.random() < overshootChance then
        local overshootAmount = math.random(
            self.HumanPatterns.mouseMovement.overshoot.amount.min,
            self.HumanPatterns.mouseMovement.overshoot.amount.max
        )
        local overshootDirection = movement.Unit
        targetPosition = targetPosition + (overshootDirection * overshootAmount)
    end
    
    -- Add micro-corrections (shakiness)
    local shakiness = math.random(
        self.HumanPatterns.aimingBehavior.shakiness.min,
        self.HumanPatterns.aimingBehavior.shakiness.max
    )
    
    local shakeOffset = Vector2.new(
        (math.random() - 0.5) * shakiness,
        (math.random() - 0.5) * shakiness
    )
    
    -- Apply smoothing with humanization
    local t = 1 / humanSmoothness
    local humanizedPosition = Vector2.new(
        utils:Lerp(currentPosition.X, targetPosition.X, t) + shakeOffset.X,
        utils:Lerp(currentPosition.Y, targetPosition.Y, t) + shakeOffset.Y
    )
    
    return humanizedPosition
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
    
    if reason and getgenv().AimbotESP.Config.antiDetection.enabled then
        -- In stealth mode, don't log suspicion increases
        if not getgenv().AimbotESP.Config.antiDetection.stealthMode then
            warn("🚨 Suspicion increased by " .. amount .. ": " .. reason)
        end
    end
    
    -- Auto-disable if suspicion gets too high
    if self.SuspicionLevel >= self.MaxSuspicionLevel * 0.8 then
        self:TriggerSafetyProtocol()
    end
end

-- Decrease suspicion level over time
function AntiDetection:DecreaseSuspicion(amount)
    amount = amount or 1
    self.SuspicionLevel = math.max(0, self.SuspicionLevel - amount)
end

-- Update suspicion level
function AntiDetection:UpdateSuspicionLevel()
    local currentTime = tick()
    
    -- Gradually decrease suspicion over time
    if currentTime - self.LastActionTime > 5.0 then
        self:DecreaseSuspicion(0.1)
    end
    
    -- Faster decrease during inactivity
    if currentTime - self.LastActionTime > 30.0 then
        self:DecreaseSuspicion(1.0)
    end
end

-- Trigger safety protocol when suspicion is too high
function AntiDetection:TriggerSafetyProtocol()
    warn("🚨 SAFETY PROTOCOL ACTIVATED - High suspicion detected!")
    
    -- Temporarily disable features
    getgenv().AimbotESP.Config.aimbot.enabled = false
    getgenv().AimbotESP.Config.esp.enabled = false
    
    -- Reset suspicion after cooldown
    task.wait(10)
    self:ResetSuspicionLevel()
    
    print("✅ Safety protocol cooldown complete")
end

-- Check if should intentionally miss
function AntiDetection:ShouldIntentionallyMiss()
    local config = getgenv().AimbotESP.Config.antiDetection
    if not config.enabled or not config.humanization then return false end
    
    local missChance = self.HumanPatterns.aimingBehavior.missChance
    
    -- Increase miss chance based on suspicion level
    local suspicionMultiplier = 1 + (self.SuspicionLevel / self.MaxSuspicionLevel)
    missChance = missChance * suspicionMultiplier
    
    return math.random() < missChance
end

-- Get human-like reaction time
function AntiDetection:GetReactionTime()
    local config = getgenv().AimbotESP.Config.antiDetection
    if not config.enabled or not config.humanization then return 0 end
    
    local patterns = self.HumanPatterns.reactionTime
    return math.random() * (patterns.max - patterns.min) + patterns.min
end

-- Simulate human-like breaks
function AntiDetection:ShouldTakeBreak()
    local config = getgenv().AimbotESP.Config.antiDetection
    if not config.enabled or not config.humanization then return false end
    
    local currentTime = tick()
    local sessionTime = currentTime - (self.SessionStartTime or currentTime)
    
    -- Take breaks every 5-15 minutes
    local breakInterval = math.random(
        self.HumanPatterns.activity.sessionBreaks.min,
        self.HumanPatterns.activity.sessionBreaks.max
    )
    
    return sessionTime > breakInterval
end

-- Cleanup old action history
function AntiDetection:CleanupActionHistory()
    local currentTime = tick()
    local maxAge = 300 -- Keep 5 minutes of history
    
    for i = #self.ActionHistory, 1, -1 do
        if currentTime - self.ActionHistory[i].timestamp > maxAge then
            table.remove(self.ActionHistory, i)
        else
            break -- History is sorted by time, so we can break early
        end
    end
end

-- Get anti-detection statistics
function AntiDetection:GetStats()
    local recentActions = self:GetRecentActions(60) -- Last minute
    local actionsByType = {}
    
    for _, action in ipairs(recentActions) do
        actionsByType[action.type] = (actionsByType[action.type] or 0) + 1
    end
    
    return {
        suspicionLevel = math.floor(self.SuspicionLevel),
        maxSuspicionLevel = self.MaxSuspicionLevel,
        recentActions = #recentActions,
        actionsByType = actionsByType,
        isEnabled = getgenv().AimbotESP.Config.antiDetection.enabled,
        humanizationEnabled = getgenv().AimbotESP.Config.antiDetection.humanization,
        stealthMode = getgenv().AimbotESP.Config.antiDetection.stealthMode
    }
end

-- Emergency disable all anti-detection
function AntiDetection:EmergencyDisable()
    local config = getgenv().AimbotESP.Config.antiDetection
    config.enabled = false
    config.humanization = false
    config.stealthMode = false
    
    self:ResetSuspicionLevel()
    warn("🚨 Anti-detection system emergency disabled!")
end

-- Re-enable anti-detection
function AntiDetection:Enable()
    local config = getgenv().AimbotESP.Config.antiDetection
    config.enabled = true
    config.humanization = true
    
    self:ResetSuspicionLevel()
    print("🛡️ Anti-detection system re-enabled")
end

-- Validate behavior patterns
function AntiDetection:ValidateBehavior(actionType, metadata)
    if not getgenv().AimbotESP.Config.antiDetection.enabled then return true end
    
    -- Check for inhuman precision
    if actionType == "aim" and metadata.accuracy and metadata.accuracy > 0.95 then
        self:IncreaseSuspicion(5, "Inhuman accuracy detected")
        return false
    end
    
    -- Check for inhuman speed
    if metadata.reactionTime and metadata.reactionTime < 0.1 then
        self:IncreaseSuspicion(8, "Inhuman reaction time detected")
        return false
    end
    
    -- Check for perfect consistency
    if metadata.consistency and metadata.consistency > 0.98 then
        self:IncreaseSuspicion(6, "Perfect consistency detected")
        return false
    end
    
    return true
end

return AntiDetection