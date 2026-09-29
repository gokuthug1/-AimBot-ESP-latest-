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
	local maxRate = config.maxActionsPerSecond or 30

	-- Check global rate limit
	local recentActions = self:GetRecentActions(1.0)
	if #recentActions >= maxRate then
		self:IncreaseSuspicion(4, "Rate limit exceeded (" .. #recentActions .. "/" .. maxRate .. ")")
		return false
	end

	-- Check action-specific limits
	local actionLimit = self:GetActionLimit(actionType)
	local recentActionsByType = self:GetRecentActionsByType(actionType, 1.0)
	if #recentActionsByType >= actionLimit then
		self:IncreaseSuspicion(2, "Action limit exceeded: " .. actionType)
		return false
	end

	-- Check for unnatural robotic regularities
	if self:DetectSuspiciousPattern() then
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
		aim = 25,
		shoot = 12,
		movement = 35,
		general = 30,
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

	local humanSmoothness = math.max(1, self:GetHumanizedValue(smoothness or 10, 0.2))

	-- Occasional micro-overshoot
	local overshootChance = self.HumanPatterns.mouseMovement.overshoot.chance
	if math.random() < overshootChance then
		local overshootAmount = math.random(
			self.HumanPatterns.mouseMovement.overshoot.amount.min,
			self.HumanPatterns.mouseMovement.overshoot.amount.max
		)
		local overshootDir = movement.Unit
		targetPosition = targetPosition + (overshootDir * overshootAmount)
	end

	-- Micro-shakiness
	local shakiness = math.random()
			* (self.HumanPatterns.aimingBehavior.shakiness.max - self.HumanPatterns.aimingBehavior.shakiness.min)
		+ self.HumanPatterns.aimingBehavior.shakiness.min
	local shakeOffset = Vector2.new((math.random() - 0.5) * shakiness, (math.random() - 0.5) * shakiness)

	local t = 1 / humanSmoothness
	local lerpX = currentPosition.X + (targetPosition.X - currentPosition.X) * t
	local lerpY = currentPosition.Y + (targetPosition.Y - currentPosition.Y) * t

	return Vector2.new(lerpX + shakeOffset.X, lerpY + shakeOffset.Y)
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
