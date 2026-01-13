--[[
    Advanced AimBot System v2.0.0
    
    This module handles all aimbot functionality including:
    - Target selection and prioritization
    - Smooth aiming with prediction
    - FOV limiting and visibility checks
    - Anti-detection measures
    
    Author: gokuthug1
    License: MIT
]]

local Aimbot = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- Local references
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera

-- Aimbot state
Aimbot.CurrentTarget = nil
Aimbot.IsAiming = false
Aimbot.LastShotTime = 0
Aimbot.FOVCircle = nil

-- Initialize aimbot system
function Aimbot:Initialize()
    self:CreateFOVCircle()
    self:SetupInputHandling()
    print("🎯 AimBot system initialized")
end

-- Create FOV circle for visualization
function Aimbot:CreateFOVCircle()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AimbotFOV"
    screenGui.Parent = game.CoreGui
    
    local circle = Instance.new("Frame")
    circle.Name = "FOVCircle"
    circle.BackgroundTransparency = 1
    circle.BorderSizePixel = 0
    circle.Parent = screenGui
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Thickness = 2
    stroke.Transparency = 0.7
    stroke.Parent = circle
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = circle
    
    self.FOVCircle = circle
    self:UpdateFOVCircle()
end

-- Update FOV circle position and size
function Aimbot:UpdateFOVCircle()
    if not self.FOVCircle then return end
    
    local config = getgenv().AimbotESP.Config.aimbot
    local screenSize = Camera.ViewportSize
    local centerX = screenSize.X / 2
    local centerY = screenSize.Y / 2
    
    -- Calculate circle size based on FOV
    local fovRadius = math.tan(math.rad(config.fov / 2)) * (screenSize.Y / 2)
    local circleSize = fovRadius * 2
    
    self.FOVCircle.Size = UDim2.new(0, circleSize, 0, circleSize)
    self.FOVCircle.Position = UDim2.new(0, centerX - fovRadius, 0, centerY - fovRadius)
    self.FOVCircle.Visible = config.enabled and not getgenv().AimbotESP.Config.antiDetection.stealthMode
end

-- Setup input handling for aim key
function Aimbot:SetupInputHandling()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        local config = getgenv().AimbotESP.Config.aimbot
        if input.UserInputType == config.aimKey and config.enabled then
            self.IsAiming = true
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        local config = getgenv().AimbotESP.Config.aimbot
        if input.UserInputType == config.aimKey then
            self.IsAiming = false
            self.CurrentTarget = nil
        end
    end)
end

-- Get the best target part for a character
function Aimbot:GetTargetPart(character, targetMode)
    targetMode = targetMode or "Head"
    
    if targetMode == "Head" then
        return character:FindFirstChild("Head")
    elseif targetMode == "Torso" then
        return character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    elseif targetMode == "Smart" then
        -- Smart targeting: prefer head if visible, otherwise torso
        local head = character:FindFirstChild("Head")
        local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
        
        if head then
            local utils = getgenv().AimbotESP.Components.Utils
            local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if rootPart and utils:HasLineOfSight(rootPart.Position, head.Position, {LocalPlayer.Character}) then
                return head
            end
        end
        
        return torso
    end
    
    return character:FindFirstChild("HumanoidRootPart")
end

-- Check if target is within FOV
function Aimbot:IsInFOV(targetPosition)
    local config = getgenv().AimbotESP.Config.aimbot
    local utils = getgenv().AimbotESP.Components.Utils
    
    local screenPos, onScreen = utils:WorldToScreen(targetPosition)
    if not onScreen then return false end
    
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local distance = (screenPos - screenCenter).Magnitude
    
    -- Calculate FOV radius in pixels
    local fovRadius = math.tan(math.rad(config.fov / 2)) * (Camera.ViewportSize.Y / 2)
    
    return distance <= fovRadius
end

-- Predict target position based on velocity
function Aimbot:PredictTargetPosition(targetPart, targetVelocity)
    local config = getgenv().AimbotESP.Config.aimbot
    if not config.prediction then
        return targetPart.Position
    end
    
    -- Simple prediction based on current velocity
    local predictionTime = 0.1 -- Adjust based on ping/latency
    return targetPart.Position + (targetVelocity * predictionTime)
end

-- Get target velocity
function Aimbot:GetTargetVelocity(character)
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        return humanoidRootPart.Velocity
    end
    return Vector3.new(0, 0, 0)
end

-- Find the best target
function Aimbot:FindBestTarget()
    local config = getgenv().AimbotESP.Config.aimbot
    local utils = getgenv().AimbotESP.Components.Utils
    
    if not config.enabled or getgenv().AimbotESP.State.EmergencyDisabled then
        return nil
    end
    
    local targets = utils:GetValidTargets()
    if #targets == 0 then return nil end
    
    -- Filter targets by FOV
    local fovTargets = {}
    for _, target in ipairs(targets) do
        local targetPart = self:GetTargetPart(target.character, config.targetPart)
        if targetPart and self:IsInFOV(targetPart.Position) then
            target.targetPart = targetPart
            table.insert(fovTargets, target)
        end
    end
    
    if #fovTargets == 0 then return nil end
    
    -- Sort by priority and return best target
    local sortedTargets = utils:SortTargetsByPriority(fovTargets, config.priorityMode)
    return sortedTargets[1]
end

-- Smooth aim to target
function Aimbot:AimAtTarget(target)
    if not target or not target.targetPart then return end
    
    local config = getgenv().AimbotESP.Config.aimbot
    local utils = getgenv().AimbotESP.Components.Utils
    local antiDetection = getgenv().AimbotESP.Components.AntiDetection
    
    -- Check rate limiting
    if not antiDetection:IsActionAllowed() then return end
    
    -- Get target position with prediction
    local targetVelocity = self:GetTargetVelocity(target.character)
    local predictedPosition = self:PredictTargetPosition(target.targetPart, targetVelocity)
    
    -- Convert to screen coordinates
    local targetScreenPos, onScreen = utils:WorldToScreen(predictedPosition)
    if not onScreen then return end
    
    -- Get current mouse position
    local currentMousePos = Vector2.new(Mouse.X, Mouse.Y)
    
    -- Apply humanization if enabled
    local finalTargetPos = antiDetection:HumanizeMovement(
        targetScreenPos, 
        currentMousePos, 
        config.smoothness
    )
    
    -- Move mouse smoothly
    local moveVector = finalTargetPos - currentMousePos
    local distance = moveVector.Magnitude
    
    if distance > 1 then -- Only move if significant distance
        local smoothFactor = math.min(1, (1 / config.smoothness) * (distance / 100))
        local newPosition = currentMousePos + (moveVector * smoothFactor)
        
        -- Apply the movement (this would need to be implemented based on the executor)
        -- mousemoverel(newPosition.X - currentMousePos.X, newPosition.Y - currentMousePos.Y)
        
        -- Record action for anti-detection
        antiDetection:RecordAction()
    end
end

-- Main update function
function Aimbot:Update()
    local config = getgenv().AimbotESP.Config.aimbot
    
    -- Update FOV circle
    self:UpdateFOVCircle()
    
    -- Only aim when conditions are met
    if not config.enabled or 
       not self.IsAiming or 
       getgenv().AimbotESP.State.EmergencyDisabled or
       not LocalPlayer.Character or
       not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        self.CurrentTarget = nil
        return
    end
    
    -- Find and aim at target
    local target = self:FindBestTarget()
    if target then
        self.CurrentTarget = target
        self:AimAtTarget(target)
    else
        self.CurrentTarget = nil
    end
end

-- Get current target info (for GUI display)
function Aimbot:GetCurrentTargetInfo()
    if self.CurrentTarget then
        return {
            name = self.CurrentTarget.player.Name,
            distance = math.floor(self.CurrentTarget.distance),
            health = math.floor(self.CurrentTarget.health)
        }
    end
    return nil
end

-- Cleanup function
function Aimbot:Cleanup()
    if self.FOVCircle and self.FOVCircle.Parent then
        self.FOVCircle.Parent:Destroy()
    end
    self.CurrentTarget = nil
    self.IsAiming = false
end

return Aimbot