--[[
    GUI System v2.0.0
    
    This module handles the user interface including:
    - Configuration panels
    - Real-time status display
    - Theme management
    - Interactive controls
    
    Author: gokuthug1
    License: MIT
]]

local GUI = {}

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Local references
local LocalPlayer = Players.LocalPlayer

-- GUI state
GUI.ScreenGui = nil
GUI.MainFrame = nil
GUI.IsVisible = false
GUI.CurrentTab = "Aimbot"
GUI.Elements = {}

-- Theme colors
GUI.Themes = {
    Dark = {
        Background = Color3.fromRGB(25, 25, 25),
        Secondary = Color3.fromRGB(35, 35, 35),
        Accent = Color3.fromRGB(0, 162, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(200, 200, 200),
        Success = Color3.fromRGB(46, 204, 113),
        Warning = Color3.fromRGB(241, 196, 15),
        Error = Color3.fromRGB(231, 76, 60)
    },
    Light = {
        Background = Color3.fromRGB(240, 240, 240),
        Secondary = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(0, 123, 255),
        Text = Color3.fromRGB(33, 37, 41),
        TextSecondary = Color3.fromRGB(108, 117, 125),
        Success = Color3.fromRGB(40, 167, 69),
        Warning = Color3.fromRGB(255, 193, 7),
        Error = Color3.fromRGB(220, 53, 69)
    },
    Blue = {
        Background = Color3.fromRGB(13, 27, 42),
        Secondary = Color3.fromRGB(27, 38, 59),
        Accent = Color3.fromRGB(65, 105, 225),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(176, 196, 222),
        Success = Color3.fromRGB(32, 178, 170),
        Warning = Color3.fromRGB(255, 215, 0),
        Error = Color3.fromRGB(220, 20, 60)
    }
}

-- Initialize GUI system
function GUI:Initialize()
    self:CreateScreenGui()
    self:CreateMainFrame()
    self:CreateTabs()
    self:CreateStatusBar()
    self:SetupDragging()
    self:ApplyTheme()
    print("🖥️ GUI system initialized")
end

-- Create main screen GUI
function GUI:CreateScreenGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AimbotESPGUI"
    screenGui.Parent = game.CoreGui
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    self.ScreenGui = screenGui
end

-- Create main frame
function GUI:CreateMainFrame()
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 500, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = false -- We'll handle dragging manually
    mainFrame.Visible = false
    mainFrame.Parent = self.ScreenGui
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Add drop shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxasset://textures/ui/Controls/DropShadow.png"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.Size = UDim2.new(1, 47, 1, 47)
    shadow.Position = UDim2.new(0, -23, 0, -23)
    shadow.ZIndex = mainFrame.ZIndex - 1
    shadow.Parent = mainFrame
    
    self.MainFrame = mainFrame
    
    -- Create title bar
    self:CreateTitleBar()
end

-- Create title bar
function GUI:CreateTitleBar()
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = self.MainFrame
    
    -- Title bar corner radius
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    -- Fix bottom corners
    local bottomFix = Instance.new("Frame")
    bottomFix.Size = UDim2.new(1, 0, 0, 8)
    bottomFix.Position = UDim2.new(0, 0, 1, -8)
    bottomFix.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    bottomFix.BorderSizePixel = 0
    bottomFix.Parent = titleBar
    
    -- Title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Size = UDim2.new(1, -100, 1, 0)
    titleText.Position = UDim2.new(0, 15, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "🎯 Advanced AimBot & ESP v2.0.0"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextScaled = true
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Font = Enum.Font.GothamBold
    titleText.Parent = titleBar
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeButton
    
    -- Close button functionality
    closeButton.MouseButton1Click:Connect(function()
        self:SetVisible(false)
    end)
    
    self.Elements.titleBar = titleBar
    self.Elements.closeButton = closeButton
end

-- Create tab system
function GUI:CreateTabs()
    -- Tab container
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(1, 0, 0, 35)
    tabContainer.Position = UDim2.new(0, 0, 0, 45)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = self.MainFrame
    
    -- Tab buttons
    local tabs = {"Aimbot", "ESP", "Settings", "Info"}
    local tabButtons = {}
    
    for i, tabName in ipairs(tabs) do
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabName .. "Tab"
        tabButton.Size = UDim2.new(1/#tabs, -2, 1, 0)
        tabButton.Position = UDim2.new((i-1)/#tabs, 1, 0, 0)
        tabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        tabButton.BorderSizePixel = 0
        tabButton.Text = tabName
        tabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
        tabButton.TextScaled = true
        tabButton.Font = Enum.Font.Gotham
        tabButton.Parent = tabContainer
        
        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 4)
        tabCorner.Parent = tabButton
        
        tabButtons[tabName] = tabButton
        
        -- Tab click handler
        tabButton.MouseButton1Click:Connect(function()
            self:SwitchTab(tabName)
        end)
    end
    
    -- Content area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -20, 1, -120)
    contentArea.Position = UDim2.new(0, 10, 0, 85)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = self.MainFrame
    
    self.Elements.tabContainer = tabContainer
    self.Elements.tabButtons = tabButtons
    self.Elements.contentArea = contentArea
    
    -- Create tab content
    self:CreateTabContent()
    self:SwitchTab("Aimbot")
end

-- Create content for each tab
function GUI:CreateTabContent()
    -- Aimbot tab
    self:CreateAimbotTab()
    
    -- ESP tab
    self:CreateESPTab()
    
    -- Settings tab
    self:CreateSettingsTab()
    
    -- Info tab
    self:CreateInfoTab()
end

-- Create aimbot configuration tab
function GUI:CreateAimbotTab()
    local aimbotFrame = Instance.new("ScrollingFrame")
    aimbotFrame.Name = "AimbotFrame"
    aimbotFrame.Size = UDim2.new(1, 0, 1, 0)
    aimbotFrame.Position = UDim2.new(0, 0, 0, 0)
    aimbotFrame.BackgroundTransparency = 1
    aimbotFrame.BorderSizePixel = 0
    aimbotFrame.ScrollBarThickness = 6
    aimbotFrame.CanvasSize = UDim2.new(0, 0, 0, 400)
    aimbotFrame.Visible = false
    aimbotFrame.Parent = self.Elements.contentArea
    
    local yOffset = 0
    
    -- Enable toggle
    local enableToggle = self:CreateToggle("Enable Aimbot", "aimbot.enabled", aimbotFrame, yOffset)
    yOffset = yOffset + 40
    
    -- FOV slider
    local fovSlider = self:CreateSlider("Field of View", "aimbot.fov", 10, 180, aimbotFrame, yOffset)
    yOffset = yOffset + 60
    
    -- Smoothness slider
    local smoothSlider = self:CreateSlider("Smoothness", "aimbot.smoothness", 1, 50, aimbotFrame, yOffset)
    yOffset = yOffset + 60
    
    -- Target part dropdown
    local targetDropdown = self:CreateDropdown("Target Part", "aimbot.targetPart", {"Head", "Torso", "Smart"}, aimbotFrame, yOffset)
    yOffset = yOffset + 40
    
    -- Prediction toggle
    local predictionToggle = self:CreateToggle("Prediction", "aimbot.prediction", aimbotFrame, yOffset)
    yOffset = yOffset + 40
    
    -- Team check toggle
    local teamToggle = self:CreateToggle("Team Check", "aimbot.teamCheck", aimbotFrame, yOffset)
    yOffset = yOffset + 40
    
    -- Visibility check toggle
    local visibilityToggle = self:CreateToggle("Visibility Check", "aimbot.visibilityCheck", aimbotFrame, yOffset)
    
    self.Elements.aimbotFrame = aimbotFrame
end

-- Create ESP configuration tab
function GUI:CreateESPTab()
    local espFrame = Instance.new("ScrollingFrame")
    espFrame.Name = "ESPFrame"
    espFrame.Size = UDim2.new(1, 0, 1, 0)
    espFrame.Position = UDim2.new(0, 0, 0, 0)
    espFrame.BackgroundTransparency = 1
    espFrame.BorderSizePixel = 0
    espFrame.ScrollBarThickness = 6
    espFrame.CanvasSize = UDim2.new(0, 0, 0, 500)
    espFrame.Visible = false
    espFrame.Parent = self.Elements.contentArea
    
    local yOffset = 0
    
    -- Enable toggle
    local enableToggle = self:CreateToggle("Enable ESP", "esp.enabled", espFrame, yOffset)
    yOffset = yOffset + 40
    
    -- Feature toggles
    local features = {
        {"Player Boxes", "esp.boxes"},
        {"Player Names", "esp.names"},
        {"Health Bars", "esp.healthBars"},
        {"Distance", "esp.distance"},
        {"Tracers", "esp.tracers"},
        {"Team Colors", "esp.teamColors"}
    }
    
    for _, feature in ipairs(features) do
        local toggle = self:CreateToggle(feature[1], feature[2], espFrame, yOffset)
        yOffset = yOffset + 40
    end
    
    -- Max distance slider
    local distanceSlider = self:CreateSlider("Max Distance", "esp.maxDistance", 50, 1000, espFrame, yOffset)
    
    self.Elements.espFrame = espFrame
end

-- Create settings tab
function GUI:CreateSettingsTab()
    local settingsFrame = Instance.new("ScrollingFrame")
    settingsFrame.Name = "SettingsFrame"
    settingsFrame.Size = UDim2.new(1, 0, 1, 0)
    settingsFrame.Position = UDim2.new(0, 0, 0, 0)
    settingsFrame.BackgroundTransparency = 1
    settingsFrame.BorderSizePixel = 0
    settingsFrame.ScrollBarThickness = 6
    settingsFrame.CanvasSize = UDim2.new(0, 0, 0, 400)
    settingsFrame.Visible = false
    settingsFrame.Parent = self.Elements.contentArea
    
    local yOffset = 0
    
    -- Anti-detection toggle
    local antiDetectionToggle = self:CreateToggle("Anti-Detection", "antiDetection.enabled", settingsFrame, yOffset)
    yOffset = yOffset + 40
    
    -- Stealth mode toggle
    local stealthToggle = self:CreateToggle("Stealth Mode", "antiDetection.stealthMode", settingsFrame, yOffset)
    yOffset = yOffset + 40
    
    -- Update rate slider
    local updateSlider = self:CreateSlider("Update Rate (FPS)", "performance.updateRate", 10, 120, settingsFrame, yOffset)
    yOffset = yOffset + 60
    
    -- Theme dropdown
    local themeDropdown = self:CreateDropdown("Theme", "gui.theme", {"Dark", "Light", "Blue"}, settingsFrame, yOffset)
    
    self.Elements.settingsFrame = settingsFrame
end

-- Create info tab
function GUI:CreateInfoTab()
    local infoFrame = Instance.new("Frame")
    infoFrame.Name = "InfoFrame"
    infoFrame.Size = UDim2.new(1, 0, 1, 0)
    infoFrame.Position = UDim2.new(0, 0, 0, 0)
    infoFrame.BackgroundTransparency = 1
    infoFrame.Visible = false
    infoFrame.Parent = self.Elements.contentArea
    
    -- Info text
    local infoText = Instance.new("TextLabel")
    infoText.Size = UDim2.new(1, 0, 1, 0)
    infoText.Position = UDim2.new(0, 0, 0, 0)
    infoText.BackgroundTransparency = 1
    infoText.Text = [[🎯 Advanced AimBot & ESP v2.0.0

⚠️ EDUCATIONAL USE ONLY ⚠️

This tool is designed for learning purposes and security research. Using it in games may violate Terms of Service and result in account bans.

🎮 Hotkeys:
• INSERT - Toggle GUI
• F1 - Toggle AimBot
• F2 - Toggle ESP
• F3 - Toggle Tracers
• F4 - Cycle Target Mode
• DELETE - Emergency Disable

📊 Current Status:
• Players Tracked: 0
• ESP Elements: 0
• Performance: Good

🛡️ Anti-Detection:
• Humanization: Active
• Rate Limiting: Active
• Stealth Mode: Inactive

Use responsibly and respect others!]]
    infoText.TextColor3 = Color3.fromRGB(200, 200, 200)
    infoText.TextScaled = false
    infoText.TextSize = 14
    infoText.TextXAlignment = Enum.TextXAlignment.Left
    infoText.TextYAlignment = Enum.TextYAlignment.Top
    infoText.Font = Enum.Font.Gotham
    infoText.Parent = infoFrame
    
    self.Elements.infoFrame = infoFrame
    self.Elements.infoText = infoText
end

-- Create status bar
function GUI:CreateStatusBar()
    local statusBar = Instance.new("Frame")
    statusBar.Name = "StatusBar"
    statusBar.Size = UDim2.new(1, 0, 0, 25)
    statusBar.Position = UDim2.new(0, 0, 1, -25)
    statusBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    statusBar.BorderSizePixel = 0
    statusBar.Parent = self.MainFrame
    
    -- Status bar corner radius
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 8)
    statusCorner.Parent = statusBar
    
    -- Fix top corners
    local topFix = Instance.new("Frame")
    topFix.Size = UDim2.new(1, 0, 0, 8)
    topFix.Position = UDim2.new(0, 0, 0, 0)
    topFix.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    topFix.BorderSizePixel = 0
    topFix.Parent = statusBar
    
    -- Status text
    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(1, -10, 1, 0)
    statusText.Position = UDim2.new(0, 5, 0, 0)
    statusText.BackgroundTransparency = 1
    statusText.Text = "Ready • AimBot: OFF • ESP: OFF"
    statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusText.TextScaled = true
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.Font = Enum.Font.Gotham
    statusText.Parent = statusBar
    
    self.Elements.statusBar = statusBar
    self.Elements.statusText = statusText
end

-- Helper function to create toggle
function GUI:CreateToggle(text, configPath, parent, yOffset)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.Position = UDim2.new(0, 0, 0, yOffset)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.Parent = frame
    
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 50, 0, 20)
    toggle.Position = UDim2.new(1, -55, 0, 5)
    toggle.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    toggle.BorderSizePixel = 0
    toggle.Text = "OFF"
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.TextScaled = true
    toggle.Font = Enum.Font.GothamBold
    toggle.Parent = frame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 10)
    toggleCorner.Parent = toggle
    
    -- Toggle functionality
    local function updateToggle()
        local config = getgenv().AimbotESP.Components.Config
        local value = config:Get(configPath)
        
        if value then
            toggle.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            toggle.Text = "ON"
        else
            toggle.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
            toggle.Text = "OFF"
        end
    end
    
    toggle.MouseButton1Click:Connect(function()
        local config = getgenv().AimbotESP.Components.Config
        config:Toggle(configPath)
        updateToggle()
    end)
    
    -- Initial update
    updateToggle()
    
    return frame
end

-- Helper function to create slider
function GUI:CreateSlider(text, configPath, minValue, maxValue, parent, yOffset)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.Position = UDim2.new(0, 0, 0, yOffset)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. minValue
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.Parent = frame
    
    local sliderBG = Instance.new("Frame")
    sliderBG.Size = UDim2.new(1, 0, 0, 6)
    sliderBG.Position = UDim2.new(0, 0, 0, 30)
    sliderBG.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sliderBG.BorderSizePixel = 0
    sliderBG.Parent = frame
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 3)
    sliderCorner.Parent = sliderBG
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(0.5, 0, 1, 0)
    sliderFill.Position = UDim2.new(0, 0, 0, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBG
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = sliderFill
    
    -- Slider functionality
    local function updateSlider()
        local config = getgenv().AimbotESP.Components.Config
        local value = config:Get(configPath) or minValue
        local percentage = (value - minValue) / (maxValue - minValue)
        
        sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
        label.Text = text .. ": " .. math.floor(value)
    end
    
    local dragging = false
    
    sliderBG.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mouse = LocalPlayer:GetMouse()
            local relativeX = mouse.X - sliderBG.AbsolutePosition.X
            local percentage = math.clamp(relativeX / sliderBG.AbsoluteSize.X, 0, 1)
            local value = minValue + (percentage * (maxValue - minValue))
            
            local config = getgenv().AimbotESP.Components.Config
            config:Set(configPath, math.floor(value))
            updateSlider()
        end
    end)
    
    -- Initial update
    updateSlider()
    
    return frame
end

-- Helper function to create dropdown
function GUI:CreateDropdown(text, configPath, options, parent, yOffset)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.Position = UDim2.new(0, 0, 0, yOffset)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.Parent = frame
    
    local dropdown = Instance.new("TextButton")
    dropdown.Size = UDim2.new(0.45, 0, 1, 0)
    dropdown.Position = UDim2.new(0.55, 0, 0, 0)
    dropdown.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    dropdown.BorderSizePixel = 0
    dropdown.Text = options[1]
    dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdown.TextScaled = true
    dropdown.Font = Enum.Font.Gotham
    dropdown.Parent = frame
    
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 4)
    dropdownCorner.Parent = dropdown
    
    -- Dropdown functionality
    local currentIndex = 1
    
    dropdown.MouseButton1Click:Connect(function()
        currentIndex = (currentIndex % #options) + 1
        dropdown.Text = options[currentIndex]
        
        local config = getgenv().AimbotESP.Components.Config
        config:Set(configPath, options[currentIndex])
    end)
    
    return frame
end

-- Switch between tabs
function GUI:SwitchTab(tabName)
    self.CurrentTab = tabName
    
    -- Hide all tab content
    for name, frame in pairs({
        Aimbot = self.Elements.aimbotFrame,
        ESP = self.Elements.espFrame,
        Settings = self.Elements.settingsFrame,
        Info = self.Elements.infoFrame
    }) do
        if frame then
            frame.Visible = false
        end
    end
    
    -- Show selected tab
    local selectedFrame = ({
        Aimbot = self.Elements.aimbotFrame,
        ESP = self.Elements.espFrame,
        Settings = self.Elements.settingsFrame,
        Info = self.Elements.infoFrame
    })[tabName]
    
    if selectedFrame then
        selectedFrame.Visible = true
    end
    
    -- Update tab button colors
    for name, button in pairs(self.Elements.tabButtons) do
        if name == tabName then
            button.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            button.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end
end

-- Setup dragging functionality
function GUI:SetupDragging()
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    self.Elements.titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = self.MainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            self.MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- Apply theme
function GUI:ApplyTheme()
    local config = getgenv().AimbotESP.Config
    local themeName = config and config.gui.theme or "Dark"
    local theme = self.Themes[themeName] or self.Themes.Dark
    
    if self.MainFrame then
        self.MainFrame.BackgroundColor3 = theme.Background
    end
    
    if self.Elements.titleBar then
        self.Elements.titleBar.BackgroundColor3 = theme.Secondary
    end
    
    if self.Elements.statusBar then
        self.Elements.statusBar.BackgroundColor3 = theme.Secondary
    end
end

-- Set GUI visibility
function GUI:SetVisible(visible)
    self.IsVisible = visible
    if self.MainFrame then
        self.MainFrame.Visible = visible
    end
    
    if visible then
        self:UpdateStatus()
    end
end

-- Update status bar
function GUI:UpdateStatus()
    if not self.Elements.statusText then return end
    
    local aimbotStatus = getgenv().AimbotESP.State.AimbotEnabled and "ON" or "OFF"
    local espStatus = getgenv().AimbotESP.State.ESPEnabled and "ON" or "OFF"
    
    local statusText = string.format("Ready • AimBot: %s • ESP: %s", aimbotStatus, espStatus)
    
    if getgenv().AimbotESP.State.EmergencyDisabled then
        statusText = "🚨 EMERGENCY DISABLED"
    end
    
    self.Elements.statusText.Text = statusText
end

-- Main update function
function GUI:Update()
    if self.IsVisible then
        self:UpdateStatus()
        
        -- Update info tab with real-time data
        if self.CurrentTab == "Info" and self.Elements.infoText then
            local espStats = getgenv().AimbotESP.Components.ESP and 
                           getgenv().AimbotESP.Components.ESP:GetStats() or {visible = 0, total = 0}
            
            local targetInfo = getgenv().AimbotESP.Components.Aimbot and
                             getgenv().AimbotESP.Components.Aimbot:GetCurrentTargetInfo()
            
            local infoText = [[🎯 Advanced AimBot & ESP v2.0.0

⚠️ EDUCATIONAL USE ONLY ⚠️

This tool is designed for learning purposes and security research. Using it in games may violate Terms of Service and result in account bans.

🎮 Hotkeys:
• INSERT - Toggle GUI
• F1 - Toggle AimBot
• F2 - Toggle ESP
• F3 - Toggle Tracers
• F4 - Cycle Target Mode
• DELETE - Emergency Disable

📊 Current Status:
• Players Tracked: ]] .. espStats.total .. [[

• ESP Elements: ]] .. espStats.visible .. [[

• Performance: Good]]

            if targetInfo then
                infoText = infoText .. "\n• Current Target: " .. targetInfo.name .. " (" .. targetInfo.distance .. "m)"
            end

            infoText = infoText .. [[


🛡️ Anti-Detection:
• Humanization: ]] .. (getgenv().AimbotESP.Config.antiDetection.humanization and "Active" or "Inactive") .. [[

• Rate Limiting: ]] .. (getgenv().AimbotESP.Config.antiDetection.enabled and "Active" or "Inactive") .. [[

• Stealth Mode: ]] .. (getgenv().AimbotESP.Config.antiDetection.stealthMode and "Active" or "Inactive") .. [[


Use responsibly and respect others!]]
            
            self.Elements.infoText.Text = infoText
        end
    end
end

-- Cleanup function
function GUI:Cleanup()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
        self.ScreenGui = nil
    end
    
    self.MainFrame = nil
    self.Elements = {}
    self.IsVisible = false
end

return GUI