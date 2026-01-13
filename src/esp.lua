--[[
    Advanced ESP System v2.0.0
    
    This module handles all ESP (Extra Sensory Perception) functionality including:
    - Player boxes and names
    - Health bars and distance indicators
    - Tracers and skeleton ESP
    - Team-based coloring
    - Performance optimization
    
    Author: gokuthug1
    License: MIT
]]

local ESP = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Local references
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ESP storage
ESP.PlayerESP = {}
ESP.ScreenGui = nil

-- Initialize ESP system
function ESP:Initialize()
    self:CreateScreenGui()
    self:SetupPlayerConnections()
    print("👁️ ESP system initialized")
end

-- Create main screen GUI
function ESP:CreateScreenGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ESPSystem"
    screenGui.Parent = game.CoreGui
    screenGui.ResetOnSpawn = false
    
    self.ScreenGui = screenGui
end

-- Setup player join/leave connections
function ESP:SetupPlayerConnections()
    -- Handle existing players
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            self:CreatePlayerESP(player)
        end
    end
    
    -- Handle new players
    Players.PlayerAdded:Connect(function(player)
        self:CreatePlayerESP(player)
    end)
    
    -- Handle leaving players
    Players.PlayerRemoving:Connect(function(player)
        self:RemovePlayerESP(player)
    end)
end

-- Create ESP elements for a player
function ESP:CreatePlayerESP(player)
    if self.PlayerESP[player] then return end
    
    local espData = {
        player = player,
        connections = {},
        elements = {}
    }
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "ESP_" .. player.Name
    mainFrame.BackgroundTransparency = 1
    mainFrame.Size = UDim2.new(0, 200, 0, 300)
    mainFrame.Position = UDim2.new(0, 0, 0, 0)
    mainFrame.Parent = self.ScreenGui
    espData.elements.mainFrame = mainFrame
    
    -- Create box outline
    local boxOutline = Instance.new("Frame")
    boxOutline.Name = "BoxOutline"
    boxOutline.BackgroundTransparency = 1
    boxOutline.BorderSizePixel = 0
    boxOutline.Size = UDim2.new(1, 0, 1, 0)
    boxOutline.Parent = mainFrame
    
    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = Color3.new(1, 1, 1)
    boxStroke.Thickness = 2
    boxStroke.Parent = boxOutline
    espData.elements.boxOutline = boxOutline
    espData.elements.boxStroke = boxStroke
    
    -- Create name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.Position = UDim2.new(0, 0, 0, -25)
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextScaled = true
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = mainFrame
    espData.elements.nameLabel = nameLabel
    
    -- Create distance label
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "DistanceLabel"
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Size = UDim2.new(1, 0, 0, 15)
    distanceLabel.Position = UDim2.new(0, 0, 1, 5)
    distanceLabel.Text = "0m"
    distanceLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    distanceLabel.TextScaled = true
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    distanceLabel.Font = Enum.Font.Gotham
    distanceLabel.Parent = mainFrame
    espData.elements.distanceLabel = distanceLabel
    
    -- Create health bar background
    local healthBarBG = Instance.new("Frame")
    healthBarBG.Name = "HealthBarBG"
    healthBarBG.BackgroundColor3 = Color3.new(0, 0, 0)
    healthBarBG.BorderSizePixel = 0
    healthBarBG.Size = UDim2.new(0, 4, 1, 0)
    healthBarBG.Position = UDim2.new(0, -8, 0, 0)
    healthBarBG.Parent = mainFrame
    espData.elements.healthBarBG = healthBarBG
    
    -- Create health bar
    local healthBar = Instance.new("Frame")
    healthBar.Name = "HealthBar"
    healthBar.BackgroundColor3 = Color3.new(0, 1, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Size = UDim2.new(1, 0, 1, 0)
    healthBar.Position = UDim2.new(0, 0, 0, 0)
    healthBar.Parent = healthBarBG
    espData.elements.healthBar = healthBar
    
    -- Create tracer line
    local tracerLine = Instance.new("Frame")
    tracerLine.Name = "TracerLine"
    tracerLine.BackgroundColor3 = Color3.new(1, 1, 1)
    tracerLine.BorderSizePixel = 0
    tracerLine.Size = UDim2.new(0, 2, 0, 1)
    tracerLine.AnchorPoint = Vector2.new(0, 0.5)
    tracerLine.Parent = self.ScreenGui
    espData.elements.tracerLine = tracerLine
    
    -- Store ESP data
    self.PlayerESP[player] = espData
end

-- Remove ESP elements for a player
function ESP:RemovePlayerESP(player)
    local espData = self.PlayerESP[player]
    if not espData then return end
    
    -- Disconnect all connections
    for _, connection in pairs(espData.connections) do
        if connection then
            connection:Disconnect()
        end
    end
    
    -- Remove GUI elements
    if espData.elements.mainFrame then
        espData.elements.mainFrame:Destroy()
    end
    if espData.elements.tracerLine then
        espData.elements.tracerLine:Destroy()
    end
    
    -- Clear from storage
    self.PlayerESP[player] = nil
end

-- Update ESP for a specific player
function ESP:UpdatePlayerESP(player, espData)
    local config = getgenv().AimbotESP.Config.esp
    local utils = getgenv().AimbotESP.Components.Utils
    
    if not config.enabled or 
       getgenv().AimbotESP.State.EmergencyDisabled or
       not utils:IsPlayerAlive(player) then
        espData.elements.mainFrame.Visible = false
        espData.elements.tracerLine.Visible = false
        return
    end
    
    local character = player.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    
    if not humanoidRootPart or not humanoid then
        espData.elements.mainFrame.Visible = false
        espData.elements.tracerLine.Visible = false
        return
    end
    
    -- Calculate distance
    local localRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localRootPart then return end
    
    local distance = utils:GetDistance(localRootPart.Position, humanoidRootPart.Position)
    
    -- Check max distance
    if distance > config.maxDistance then
        espData.elements.mainFrame.Visible = false
        espData.elements.tracerLine.Visible = false
        return
    end
    
    -- Check team filtering
    if config.teamColors and utils:IsTeammate(player) and not config.showTeammates then
        espData.elements.mainFrame.Visible = false
        espData.elements.tracerLine.Visible = false
        return
    end
    
    -- Get screen positions
    local headPos = character:FindFirstChild("Head")
    local rootPos = humanoidRootPart.Position
    
    if not headPos then return end
    
    local headScreenPos, headOnScreen = utils:WorldToScreen(headPos.Position + Vector3.new(0, 0.5, 0))
    local rootScreenPos, rootOnScreen = utils:WorldToScreen(rootPos - Vector3.new(0, 3, 0))
    
    if not headOnScreen or not rootOnScreen then
        espData.elements.mainFrame.Visible = false
        espData.elements.tracerLine.Visible = false
        return
    end
    
    -- Calculate box dimensions
    local boxHeight = math.abs(headScreenPos.Y - rootScreenPos.Y)
    local boxWidth = boxHeight * 0.6
    local boxX = headScreenPos.X - (boxWidth / 2)
    local boxY = headScreenPos.Y
    
    -- Update main frame
    espData.elements.mainFrame.Size = UDim2.new(0, boxWidth, 0, boxHeight)
    espData.elements.mainFrame.Position = UDim2.new(0, boxX, 0, boxY)
    espData.elements.mainFrame.Visible = config.boxes
    
    -- Update colors based on team
    local playerColor = config.teamColors and utils:GetTeamColor(player) or Color3.new(1, 1, 1)
    espData.elements.boxStroke.Color = playerColor
    espData.elements.nameLabel.TextColor3 = playerColor
    
    -- Update name label
    espData.elements.nameLabel.Visible = config.names
    espData.elements.nameLabel.Text = player.Name
    
    -- Update distance label
    espData.elements.distanceLabel.Visible = config.distance
    espData.elements.distanceLabel.Text = math.floor(distance) .. "m"
    
    -- Update health bar
    if config.healthBars then
        local healthPercent = (humanoid.Health / humanoid.MaxHealth)
        local healthColor = utils:GetHealthColor(healthPercent * 100)
        
        espData.elements.healthBarBG.Visible = true
        espData.elements.healthBar.Size = UDim2.new(1, 0, healthPercent, 0)
        espData.elements.healthBar.Position = UDim2.new(0, 0, 1 - healthPercent, 0)
        espData.elements.healthBar.BackgroundColor3 = healthColor
    else
        espData.elements.healthBarBG.Visible = false
    end
    
    -- Update tracer
    if config.tracers then
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        local targetPos = Vector2.new(boxX + boxWidth / 2, boxY + boxHeight)
        
        local distance2D = (targetPos - screenCenter).Magnitude
        local angle = math.atan2(targetPos.Y - screenCenter.Y, targetPos.X - screenCenter.X)
        
        espData.elements.tracerLine.Size = UDim2.new(0, distance2D, 0, 2)
        espData.elements.tracerLine.Position = UDim2.new(0, screenCenter.X, 0, screenCenter.Y)
        espData.elements.tracerLine.Rotation = math.deg(angle)
        espData.elements.tracerLine.BackgroundColor3 = playerColor
        espData.elements.tracerLine.Visible = true
    else
        espData.elements.tracerLine.Visible = false
    end
end

-- Main update function
function ESP:Update()
    local config = getgenv().AimbotESP.Config.esp
    
    if not config.enabled or getgenv().AimbotESP.State.EmergencyDisabled then
        self:DisableAll()
        return
    end
    
    -- Update each player's ESP
    for player, espData in pairs(self.PlayerESP) do
        if player and player.Parent then
            self:UpdatePlayerESP(player, espData)
        else
            -- Clean up disconnected players
            self:RemovePlayerESP(player)
        end
    end
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
        total = totalCount
    }
end

-- Cleanup function
function ESP:Cleanup()
    -- Remove all player ESP
    for player, _ in pairs(self.PlayerESP) do
        self:RemovePlayerESP(player)
    end
    
    -- Destroy screen GUI
    if self.ScreenGui then
        self.ScreenGui:Destroy()
        self.ScreenGui = nil
    end
end

return ESP