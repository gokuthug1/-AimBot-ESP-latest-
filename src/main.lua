--[[----------------------------------------------------------------------------------
    Script:         AimBot+ESP v5.8 (Custom BG & TriggerBot Overhaul)
    Description:    Perfected TriggerBot, Custom BG URL, Flawless GUI ESP.
    Keybinds:       Right-Shift (Hide UI), X (Uninstall)
------------------------------------------------------------------------------------]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local genv = getgenv and getgenv() or _G
if genv.UltimateSuiteLoaded then return end
genv.UltimateSuiteLoaded = true

local CoreGui = game:GetService("CoreGui")
local uiParent = pcall(function() return gethui() end) and gethui() or pcall(function() return CoreGui.RobloxGui end) and CoreGui.RobloxGui or CoreGui

for _, gui in ipairs(uiParent:GetChildren()) do
    if gui.Name == "UltimateSuiteGui_V5" then gui:Destroy() end
end

--[[------------------------------------------------------------------------------
    [1] CONFIGURATION
--------------------------------------------------------------------------------]]
local Config = {
    AimbotEnabled = false, AggressiveMode = false, AimKey = Enum.UserInputType.MouseButton2,
    AimPart = "Head", AimSmoothing = 0.5, FOVSize = 150, ShowFOV = true, Prediction = 0.1,
    VisibilityCheck = true, TeamCheck = true, AimLock = false, TargetNPCs = false,

    TriggerBotEnabled = false, TriggerDelay = 0.05, RequireToolForTrigger = false,

    ESPEnabled = false, SmartESP = false, MaxDistance = 1500, ShowBoxes = true,
    ShowTracers = false, TracerOrigin = "Bottom", ShowHealth = true, ShowNames = true,
    ShowWeapon = false, ShowHeadDot = false, ShowSkeleton = false,

    EnemyColorPreset = "Red", TeamColorPreset = "Blue", OccludedColor = Color3.fromRGB(120, 120, 120),
    TargetIndicatorColor = Color3.fromRGB(255, 50, 50),

    XRayEnabled = false, XRayOpacity = 0.5,
    Theme = "Default", BgImage = "", BgImageTransparency = 0.8,
}

local ColorPresets = {
    Red = Color3.fromRGB(255, 60, 60), Green = Color3.fromRGB(60, 255, 60), Blue = Color3.fromRGB(60, 120, 255),
    Purple = Color3.fromRGB(170, 80, 255), Yellow = Color3.fromRGB(255, 255, 60), White = Color3.fromRGB(255, 255, 255)
}
local ColorOrder = {"Red", "Green", "Blue", "Purple", "Yellow", "White"}
local TracerOrigins = {"Bottom", "Center", "Top"}

local Themes = {
    Default = { Main = Color3.fromRGB(20, 20, 25), Header = Color3.fromRGB(30, 30, 35), Accent = Color3.fromRGB(90, 100, 255) },
    Ruby = { Main = Color3.fromRGB(25, 15, 15), Header = Color3.fromRGB(35, 20, 20), Accent = Color3.fromRGB(220, 60, 60) },
    Ocean = { Main = Color3.fromRGB(15, 25, 35), Header = Color3.fromRGB(20, 35, 50), Accent = Color3.fromRGB(60, 140, 220) },
    Midnight = { Main = Color3.fromRGB(10, 10, 15), Header = Color3.fromRGB(15, 15, 20), Accent = Color3.fromRGB(130, 90, 255) },
    Forest = { Main = Color3.fromRGB(15, 25, 15), Header = Color3.fromRGB(20, 35, 20), Accent = Color3.fromRGB(60, 180, 80) }
}
local ThemeOrder = {"Default", "Ruby", "Ocean", "Midnight", "Forest"}

local ESP_Cache = {}
local XRay_Cache = {}
local ActiveNPCs = {}
local Connections = {}
local isAiming = false
local lockedTarget = nil
local lastTrigger = 0
local UI_Elements = { Accents = {}, MainFrames = {} }

local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude
RayParams.IgnoreWater = true

--[[------------------------------------------------------------------------------
    [2] UTILITIES
--------------------------------------------------------------------------------]]
local function isVisible(targetPart, character)
    if not targetPart or not character then return false end
    RayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    local result = Workspace:Raycast(Camera.CFrame.Position, targetPart.Position - Camera.CFrame.Position, RayParams)
    return not result or result.Instance:IsDescendantOf(character)
end

local function getBoundingBox(character)
    local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart

if not root then return nil, nil end
    local _, onScreen = Camera:WorldToViewportPoint(root.Position)
    if not onScreen then return nil, nil end

    local cframe, size = character:GetBoundingBox()
    local x, y, z = size.X/2, size.Y/2, size.Z/2
    local corners = {
        cframe * CFrame.new(x, y, z), cframe * CFrame.new(-x, y, z), cframe * CFrame.new(x, -y, z), cframe * CFrame.new(-x, -y, z),
        cframe * CFrame.new(x, y, -z), cframe * CFrame.new(-x, y, -z), cframe * CFrame.new(x, -y, -z), cframe * CFrame.new(-x, -y, -z)
    }
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local visibleCorners = 0

    for _, corner in ipairs(corners) do
        local screenPos, vis = Camera:WorldToViewportPoint(corner.Position)
        if vis then visibleCorners = visibleCorners + 1 end
        if screenPos.X < minX then minX = screenPos.X end
        if screenPos.Y < minY then minY = screenPos.Y end
        if screenPos.X > maxX then maxX = screenPos.X end
        if screenPos.Y > maxY then maxY = screenPos.Y end
    end

    if visibleCorners > 0 then return Vector2.new(minX, minY), Vector2.new(maxX - minX, maxY - minY) end
    return nil, nil
end

local function CreateDrawInfo(className, props)
    local inst = Instance.new(className)
    for k, v in pairs(props) do inst[k] = v end
    return inst
end

local function drawLine(frame, p1, p2, color)
    local dist = (p2 - p1).Magnitude
    if dist < 1 then frame.Visible = false return end
    frame.Size = UDim2.fromOffset(dist, 1.5)
    frame.Position = UDim2.fromOffset((p1.X + p2.X) / 2, (p1.Y + p2.Y) / 2)
    frame.Rotation = math.deg(math.atan2(p2.Y - p1.Y, p2.X - p1.X))
    frame.BackgroundColor3 = color
    frame.Visible = true
end

local function checkNPC(v)
    if v:IsA("Humanoid") and v.Parent:IsA("Model") then
        local char = v.Parent
        if char ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(char) then
            if not table.find(ActiveNPCs, char) then table.insert(ActiveNPCs, char) end
        end
    end
end
task.spawn(function() for _, v in ipairs(Workspace:GetDescendants()) do checkNPC(v) end end)
table.insert(Connections, Workspace.DescendantAdded:Connect(checkNPC))

local function ClearESPFor(character)
    if ESP_Cache[character] then ESP_Cache[character].Holder:Destroy(); ESP_Cache[character] = nil end
end

--[[------------------------------------------------------------------------------
    [3] UI FRAMEWORK
--------------------------------------------------------------------------------]]
local UI = {}
UI.ScreenGui = CreateDrawInfo("ScreenGui", { Name = "UltimateSuiteGui_V5", ResetOnSpawn = false, IgnoreGuiInset = true, Parent = uiParent })
local ESPFolder = CreateDrawInfo("Folder", { Name = "ESPFolder", Parent = UI.ScreenGui })

local MainFrame = CreateDrawInfo("Frame", { Size = UDim2.fromOffset(520, 380), Position = UDim2.new(0.5, -260, 0.5, -190), BackgroundColor3 = Themes.Default.Main, Active = true, Draggable = true, ClipsDescendants = true, Parent = UI.ScreenGui })
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local MainStroke = CreateDrawInfo("UIStroke", { Color = Color3.fromRGB(40, 40, 50), Parent = MainFrame })
table.insert(UI_Elements.MainFrames, MainFrame)

local BgImageFrame = CreateDrawInfo("ImageLabel", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Image = "", ImageTransparency = Config.BgImageTransparency, ScaleType = Enum.ScaleType.Crop, ZIndex = 0, Parent = MainFrame })

local Sidebar = CreateDrawInfo("Frame", { Size = UDim2.new(0, 140, 1, 0), BackgroundColor3 = Themes.Default.Header, Parent = MainFrame })
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 8)
local SidebarCover = CreateDrawInfo("Frame", { Size = UDim2.new(0, 10, 1, 0), Position = UDim2.new(1, -10, 0, 0), BackgroundColor3 = Themes.Default.Header, BorderSizePixel = 0, Parent = Sidebar })
table.insert(UI_Elements.MainFrames, Sidebar); table.insert(UI_Elements.MainFrames, SidebarCover)

local Title = CreateDrawInfo("TextLabel", { Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, Text = "  SUITE V5.8", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Themes.Default.Accent, TextXAlignment = Enum.TextXAlignment.Left, Parent = Sidebar })
table.insert(UI_Elements.Accents, Title)

local CloseBtn = CreateDrawInfo("TextButton", { Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -34, 0, 10), BackgroundColor3 = Color3.fromRGB(220, 50, 50), Text = "X", TextColor3 = Color3.fromRGB(255,255,255), Font = Enum.Font.GothamBold, Parent = MainFrame })
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local MinimizeBtn = CreateDrawInfo("TextButton", { Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -64, 0, 10), BackgroundColor3 = Color3.fromRGB(60, 60, 70), Text = "-", TextColor3 = Color3.fromRGB(255,255,255), Font = Enum.Font.GothamBold, Parent = MainFrame })
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 6)

local OpenBtn = CreateDrawInfo("TextButton", { Size = UDim2.fromOffset(80, 40), Position = UDim2.new(1, -100, 0.5, -20), BackgroundColor3 = Themes.Default.Header, Text = "Open", TextColor3 = Themes.Default.Accent, Font = Enum.Font.GothamBold, TextSize = 14, Visible = false, Parent = UI.ScreenGui })
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", OpenBtn).Color = Color3.fromRGB(40, 40, 50)
table.insert(UI_Elements.MainFrames, OpenBtn)

local AnimTween = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

MinimizeBtn.MouseButton1Click:Connect(function()
    TweenService:Create(MainFrame, AnimTween, {Position = UDim2.new(0.5, -260, 1.5, 0)}):Play()
    task.wait(0.3); MainFrame.Visible = false; OpenBtn.Visible = true; OpenBtn.Position = UDim2.new(1, 20, 0.5, -20)
    TweenService:Create(OpenBtn, AnimTween, {Position = UDim2.new(1, -100, 0.5, -20)}):Play()
end)

OpenBtn.MouseButton1Click:Connect(function()
    TweenService:Create(OpenBtn, AnimTween, {Position = UDim2.new(1, 20, 0.5, -20)}):Play()
    task.wait(0.3); OpenBtn.Visible = false; MainFrame.Visible = true
    TweenService:Create(MainFrame, AnimTween, {Position = UDim2.new(0.5, -260, 0.5, -190)}):Play()
end)

CloseBtn.MouseButton1Click:Connect(function()
    for _, conn in ipairs(Connections) do conn:Disconnect() end
    for char, _ in pairs(ESP_Cache) do ClearESPFor(char) end
    UI.ScreenGui:Destroy(); genv.UltimateSuiteLoaded = false
end)

local TabContainer = CreateDrawInfo("Frame", { Size = UDim2.new(1, 0, 1, -50), Position = UDim2.new(0, 0, 0, 50), BackgroundTransparency = 1, Parent = Sidebar })
Instance.new("UIListLayout", TabContainer).Padding = UDim.new(0, 5)

local PagesContainer = CreateDrawInfo("Frame", { Size = UDim2.new(1, -140, 1, -40), Position = UDim2.new(0, 140, 0, 40), BackgroundTransparency = 1, Parent = MainFrame })
local ActiveTabBtn, ActivePage = nil, nil

local function switchTab(Btn, Page)
    if ActiveTabBtn then TweenService:Create(ActiveTabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Config.Theme].Header, TextColor3 = Color3.fromRGB(150, 150, 150)}):Play(); ActivePage.Visible = false end
    ActiveTabBtn = Btn; ActivePage = Page; TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Themes[Config.Theme].Accent, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play(); Page.Visible = true
end

function UI:CreateTab(name)
    local Btn = CreateDrawInfo("TextButton", { Size = UDim2.new(1, -10, 0, 35), Position = UDim2.new(0, 5, 0, 0), BackgroundColor3 = Themes.Default.Header, Text = name, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = Color3.fromRGB(150, 150, 150), Parent = TabContainer })
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6); table.insert(UI_Elements.MainFrames, Btn)
    local Page = CreateDrawInfo("ScrollingFrame", { Size = UDim2.new(1, -20, 1, -10), Position = UDim2.new(0, 10, 0, 5), BackgroundTransparency = 1, ScrollBarThickness = 4, Visible = false, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = PagesContainer })
    Instance.new("UIListLayout", Page).Padding = UDim.new(0, 10)
    Btn.MouseButton1Click:Connect(function() switchTab(Btn, Page) end); if not ActiveTabBtn then switchTab(Btn, Page) end
    return Page
end

function UI:CreateToggle(page, text, configKey, callback)
    local Frame = CreateDrawInfo("Frame", { Size = UDim2.new(1, -15, 0, 30), BackgroundTransparency = 1, Parent = page })
    CreateDrawInfo("TextLabel", { Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Color3.fromRGB(220, 220, 220), TextXAlignment = Enum.TextXAlignment.Left, Parent = Frame })

local Btn = CreateDrawInfo("TextButton", { Size = UDim2.new(0, 40, 0, 20), Position = UDim2.new(1, -40, 0.5, -10), BackgroundColor3 = Color3.fromRGB(40, 40, 45), Text = "", Parent = Frame })
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(1, 0)
    local Circle = CreateDrawInfo("Frame", { Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Parent = Btn })
    Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)
    local function updateToggle()
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Config[configKey] and Themes[Config.Theme].Accent or Color3.fromRGB(40, 40, 45)}):Play()
        TweenService:Create(Circle, TweenInfo.new(0.2), {Position = Config[configKey] and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
    end
    Btn.MouseButton1Click:Connect(function() Config[configKey] = not Config[configKey]; updateToggle(); if callback then callback(Config[configKey]) end end)
    updateToggle(); table.insert(UI_Elements.Accents, {Btn = Btn, StateKey = configKey})
end

function UI:CreateSlider(page, text, configKey, min, max, isDecimal, callback)
    local Frame = CreateDrawInfo("Frame", { Size = UDim2.new(1, -15, 0, 40), BackgroundTransparency = 1, Parent = page })
    CreateDrawInfo("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Color3.fromRGB(220, 220, 220), TextXAlignment = Enum.TextXAlignment.Left, Parent = Frame })
    local ValueLabel = CreateDrawInfo("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = tostring(Config[configKey]), Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Color3.fromRGB(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Right, Parent = Frame })
    local SliderBg = CreateDrawInfo("TextButton", { Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 1, -10), BackgroundColor3 = Color3.fromRGB(40, 40, 45), Text = "", Parent = Frame })
    Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(1, 0)
    local SliderFill = CreateDrawInfo("Frame", { Size = UDim2.new((Config[configKey]-min)/(max-min), 0, 1, 0), BackgroundColor3 = Themes[Config.Theme].Accent, Parent = SliderBg })
    Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0); table.insert(UI_Elements.Accents, SliderFill)
    local dragging = false
    SliderBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pct = math.clamp((input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
            local val = min + (pct * (max - min))
            if not isDecimal then val = math.floor(val) end
            Config[configKey] = isDecimal and tonumber(string.format("%.2f", val)) or val
            SliderFill.Size = UDim2.new(pct, 0, 1, 0); ValueLabel.Text = tostring(Config[configKey])
            if callback then callback(Config[configKey]) end
        end
    end)
end

function UI:CreateCycler(page, text, configKey, options, callback)
    local Frame = CreateDrawInfo("Frame", { Size = UDim2.new(1, -15, 0, 30), BackgroundTransparency = 1, Parent = page })
    CreateDrawInfo("TextLabel", { Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Color3.fromRGB(220, 220, 220), TextXAlignment = Enum.TextXAlignment.Left, Parent = Frame })
    local Btn = CreateDrawInfo("TextButton", { Size = UDim2.new(0.5, 0, 0, 24), Position = UDim2.new(0.5, 0, 0.5, -12), BackgroundColor3 = Themes[Config.Theme].Accent, Text = tostring(Config[configKey]), Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(255,255,255), Parent = Frame })
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4); table.insert(UI_Elements.Accents, Btn)
    Btn.MouseButton1Click:Connect(function()
        local idx = table.find(options, Config[configKey]) or 1; Config[configKey] = options[(idx % #options) + 1]

Btn.Text = tostring(Config[configKey]); if callback then callback(Config[configKey]) end
    end)
end

function UI:CreateTextInput(page, text, configKey, placeholder, callback)
    local Frame = CreateDrawInfo("Frame", { Size = UDim2.new(1, -15, 0, 30), BackgroundTransparency = 1, Parent = page })
    CreateDrawInfo("TextLabel", { Size = UDim2.new(0.4, 0, 1, 0), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Color3.fromRGB(220, 220, 220), TextXAlignment = Enum.TextXAlignment.Left, Parent = Frame })
    local TextBox = CreateDrawInfo("TextBox", { Size = UDim2.new(0.6, 0, 0, 24), Position = UDim2.new(0.4, 0, 0.5, -12), BackgroundColor3 = Themes[Config.Theme].Header, Text = tostring(Config[configKey]), PlaceholderText = placeholder, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Color3.fromRGB(255,255,255), ClearTextOnFocus = false, Parent = Frame })
    Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 4)
    table.insert(UI_Elements.MainFrames, TextBox)

    TextBox.FocusLost:Connect(function()
        Config[configKey] = TextBox.Text
        if callback then callback(Config[configKey]) end
    end)
end

function UI:UpdateTheme()
    local t = Themes[Config.Theme]
    for _, frame in ipairs(UI_Elements.MainFrames) do frame.BackgroundColor3 = (frame == MainFrame) and t.Main or t.Header end
    for _, elem in ipairs(UI_Elements.Accents) do
        if type(elem) == "table" then if Config[elem.StateKey] then elem.Btn.BackgroundColor3 = t.Accent end
        elseif elem:IsA("TextLabel") then elem.TextColor3 = t.Accent
        else elem.BackgroundColor3 = t.Accent end
    end
    if ActiveTabBtn then ActiveTabBtn.BackgroundColor3 = t.Accent end; OpenBtn.TextColor3 = t.Accent
end

local FOVCircle = CreateDrawInfo("Frame", { Size = UDim2.fromOffset(Config.FOVSize * 2, Config.FOVSize * 2), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Parent = UI.ScreenGui })
Instance.new("UICorner", FOVCircle).CornerRadius = UDim.new(1, 0); Instance.new("UIStroke", FOVCircle).Color = Color3.fromRGB(255, 255, 255)

local TargetIndicator = CreateDrawInfo("ImageLabel", { Size = UDim2.fromOffset(40, 40), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Image = "rbxassetid://286214217", ImageColor3 = Config.TargetIndicatorColor, ZIndex = 10, Visible = false, Parent = UI.ScreenGui })

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end; if input.KeyCode == Enum.KeyCode.RightShift then MainFrame.Visible = not MainFrame.Visible end
    if input.UserInputType == Config.AimKey then isAiming = true end
end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Config.AimKey then isAiming = false; lockedTarget = nil end end)

-- UI Setup
local AimTab = UI:CreateTab("Aimbot")
UI:CreateToggle(AimTab, "Enable Aimbot", "AimbotEnabled")
UI:CreateToggle(AimTab, "Aggressive Mode", "AggressiveMode")
UI:CreateToggle(AimTab, "Aim Lock", "AimLock")
UI:CreateCycler(AimTab, "Aim Part", "AimPart", {"Head", "HumanoidRootPart"})
UI:CreateToggle(AimTab, "Show FOV Circle", "ShowFOV")
UI:CreateToggle(AimTab, "Visibility Check", "VisibilityCheck")
UI:CreateToggle(AimTab, "Team Check", "TeamCheck")
UI:CreateToggle(AimTab, "Target NPCs", "TargetNPCs")
UI:CreateSlider(AimTab, "FOV Size", "FOVSize", 50, 600, false)
UI:CreateSlider(AimTab, "Smoothness", "AimSmoothing", 0.1, 1, true)

local TrigTab = UI:CreateTab("TriggerBot")
UI:CreateToggle(TrigTab, "Enable TriggerBot", "TriggerBotEnabled")
UI:CreateToggle(TrigTab, "Require Tool to Fire", "RequireToolForTrigger")
UI:CreateSlider(TrigTab, "Trigger Delay", "TriggerDelay", 0.01, 0.5, true)

local ESPTab = UI:CreateTab("Visuals")
UI:CreateToggle(ESPTab, "Master ESP", "ESPEnabled")
UI:CreateToggle(ESPTab, "Smart ESP Filter", "SmartESP")
UI:CreateSlider(ESPTab, "Max Distance", "MaxDistance", 100, 5000, false)
UI:CreateToggle(ESPTab, "Bounding Boxes", "ShowBoxes")
UI:CreateToggle(ESPTab, "Skeleton", "ShowSkeleton")
UI:CreateToggle(ESPTab, "Snaplines", "ShowTracers")
UI:CreateCycler(ESPTab, "Tracer Origin", "TracerOrigin", TracerOrigins)
UI:CreateToggle(ESPTab, "Head Dot", "ShowHeadDot")
UI:CreateToggle(ESPTab, "Health Bars", "ShowHealth")
UI:CreateToggle(ESPTab, "Names / Info", "ShowNames")
UI:CreateToggle(ESPTab, "Weapon Text", "ShowWeapon")

local WorldTab = UI:CreateTab("Colors & World")
UI:CreateCycler(WorldTab, "Enemy Color", "EnemyColorPreset", ColorOrder)
UI:CreateCycler(WorldTab, "Team Color", "TeamColorPreset", ColorOrder)
UI:CreateToggle(WorldTab, "Enable X-Ray (See Walls)", "XRayEnabled", function(state)
    task.spawn(function()
        for _, part in ipairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") and not part:FindFirstAncestorOfClass("Model") then
                if state then if not XRay_Cache[part] then XRay_Cache[part] = {Transparency = part.Transparency, Material = part.Material} end
                    part.Transparency = Config.XRayOpacity; part.Material = Enum.Material.SmoothPlastic
                elseif XRay_Cache[part] then part.Transparency = XRay_Cache[part].Transparency; part.Material = XRay_Cache[part].Material; XRay_Cache[part] = nil end
            end
        end
    end)
end)
UI:CreateSlider(WorldTab, "X-Ray Opacity", "XRayOpacity", 0, 1, true, function(val)
    if Config.XRayEnabled then for part, _ in pairs(XRay_Cache) do if part and part.Parent then part.Transparency = val end end end
end)
UI:CreateCycler(WorldTab, "UI Theme", "Theme", ThemeOrder, function() UI:UpdateTheme() end)

-- Added Background Image URL/ID TextBox
UI:CreateTextInput(WorldTab, "BG Image (ID/URL)", "BgImage", "Paste Asset ID...", function(val)
    if val == "" then 
        BgImageFrame.Image = "" 
        return 
    end
    -- Extract Numbers if it's just an ID
    local id = string.match(val, "%d+")
    if id then
        BgImageFrame.Image = "rbxassetid://" .. id
    else
        BgImageFrame.Image = val
    end
end)
UI:CreateSlider(WorldTab, "Bg Transparency", "BgImageTransparency", 0, 1, true, function(val) BgImageFrame.ImageTransparency = val end)

--[[------------------------------------------------------------------------------
    [4] CORE LOGIC
--------------------------------------------------------------------------------]]
local function GetTargets()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character.Parent and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then table.insert(t, p.Character) end
    end
    if Config.TargetNPCs then
        local i = 1
        while i <= #ActiveNPCs do
            local npc = ActiveNPCs[i]
            if npc and npc.Parent and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then table.insert(t, npc); i = i + 1
            else table.remove(ActiveNPCs, i) end
        end
    end
    return t
end

for _, p in ipairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function() if lockedTarget and Players:GetPlayerFromCharacter(lockedTarget) == p then lockedTarget = nil end end)
end

local function ManageESP(targetChar)
    if not ESP_Cache[targetChar] then
        local holder = CreateDrawInfo("Frame", { BackgroundTransparency = 1, Parent = ESPFolder })
        local box = CreateDrawInfo("Frame", { BackgroundTransparency = 1, ZIndex = 2, Parent = holder })
        local boxStroke = Instance.new("UIStroke", box); boxStroke.Thickness = 1.5
        local healthBg = CreateDrawInfo("Frame", { BackgroundColor3 = Color3.fromRGB(0,0,0), BorderSizePixel = 0, ZIndex = 3, Parent = holder })
        local healthFill = CreateDrawInfo("Frame", { BackgroundColor3 = Color3.fromRGB(50, 255, 50), BorderSizePixel = 0, ZIndex = 4, Parent = healthBg })
        local textLabel = CreateDrawInfo("TextLabel", { BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(255,255,255), ZIndex = 5, Parent = holder })
        local tracer = CreateDrawInfo("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 1, Parent = holder })
        local headDot = CreateDrawInfo("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(4, 4), ZIndex = 5, Parent = holder })
        Instance.new("UICorner", headDot).CornerRadius = UDim.new(1, 0)
        local skeleton = {}
        for i = 1, 15 do table.insert(skeleton, CreateDrawInfo("Frame", { ZIndex = 2, Parent = holder })) end
        ESP_Cache[targetChar] = { Holder = holder, Box = box, BoxStroke = boxStroke, HBg = healthBg, HFill = healthFill, Text = textLabel, Tracer = tracer, HeadDot = headDot, Skeleton = skeleton }
    end

    local esp = ESP_Cache[targetChar]
    local hum = targetChar:FindFirstChild("Humanoid")

local root = targetChar:FindFirstChild("HumanoidRootPart") or targetChar.PrimaryPart
    local head = targetChar:FindFirstChild("Head")

    if not Config.ESPEnabled or not hum or not root or not targetChar.Parent or hum.Health <= 0 then 
        esp.Holder.Visible = false 
        return 
    end

    local dist = (Camera.CFrame.Position - root.Position).Magnitude
    if Config.SmartESP and dist > Config.MaxDistance then 
        esp.Holder.Visible = false 
        return 
    end

    local bPos, bSize = getBoundingBox(targetChar)
    if not bPos then 
        esp.Holder.Visible = false 
        return 
    end

    local p = Players:GetPlayerFromCharacter(targetChar)
    local isTeammate = Config.TeamCheck and p and p.Team ~= nil and p.Team == LocalPlayer.Team
    local color = isVisible(root, targetChar) and (isTeammate and ColorPresets[Config.TeamColorPreset] or ColorPresets[Config.EnemyColorPreset]) or Config.OccludedColor

    esp.Holder.Visible = true
    esp.Box.Visible = Config.ShowBoxes
    esp.Box.Position = UDim2.fromOffset(bPos.X, bPos.Y)
    esp.Box.Size = UDim2.fromOffset(bSize.X, bSize.Y)
    esp.BoxStroke.Color = color

    esp.HBg.Visible = Config.ShowHealth
    if Config.ShowHealth then
        local hpRatio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
        esp.HBg.Position = UDim2.fromOffset(bPos.X - 6, bPos.Y); esp.HBg.Size = UDim2.fromOffset(4, bSize.Y)
        esp.HFill.Size = UDim2.new(1, 0, hpRatio, 0); esp.HFill.Position = UDim2.new(0, 0, 1 - hpRatio, 0); esp.HFill.BackgroundColor3 = Color3.fromRGB(255 - (hpRatio*255), hpRatio*255, 0)
    end

    esp.Text.Visible = Config.ShowNames or Config.ShowWeapon
    if esp.Text.Visible then
        local txt = (p and p.DisplayName or targetChar.Name) .. "\n[" .. math.floor(dist) .. "m]"
        if Config.ShowWeapon then local tool = targetChar:FindFirstChildOfClass("Tool"); txt = txt .. "\n" .. (tool and tool.Name or "Unarmed") end
        esp.Text.Text = txt; esp.Text.Position = UDim2.fromOffset(bPos.X + bSize.X + 5, bPos.Y); esp.Text.TextColor3 = color; esp.Text.TextXAlignment = Enum.TextXAlignment.Left
    end

    esp.Tracer.Visible = Config.ShowTracers
    if Config.ShowTracers then
        local start = Config.TracerOrigin == "Bottom" and Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y) or Config.TracerOrigin == "Center" and Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2) or Vector2.new(Camera.ViewportSize.X/2, 0)
        drawLine(esp.Tracer, start, Vector2.new(bPos.X + bSize.X/2, bPos.Y + bSize.Y), color)
    end

    if head and Config.ShowHeadDot then
        local headPos, hVis = Camera:WorldToViewportPoint(head.Position); esp.HeadDot.Visible = hVis
        if hVis then esp.HeadDot.Position = UDim2.fromOffset(headPos.X, headPos.Y); esp.HeadDot.BackgroundColor3 = color end
    else esp.HeadDot.Visible = false end

    for _, line in pairs(esp.Skeleton) do line.Visible = false end
    if Config.ShowSkeleton then
        local joints = hum.RigType == Enum.HumanoidRigType.R15 and {{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightUpperArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightUpperLeg","RightFoot"}} or {{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
        for i, pair in ipairs(joints) do
            local p1, p2 = targetChar:FindFirstChild(pair[1]), targetChar:FindFirstChild(pair[2])
            if p1 and p2 then
                local pos1, vis1 = Camera:WorldToViewportPoint(p1.Position); local pos2, vis2 = Camera:WorldToViewportPoint(p2.Position)
                if vis1 or vis2 then drawLine(esp.Skeleton[i], Vector2.new(pos1.X, pos1.Y), Vector2.new(pos2.X, pos2.Y), color) end
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = Config.ShowFOV and Config.AimbotEnabled
    if FOVCircle.Visible then FOVCircle.Size = UDim2.fromOffset(Config.FOVSize * 2, Config.FOVSize * 2) end

    local targets = GetTargets()
    local processedTargets = {}

    for _, char in ipairs(targets) do 
        ManageESP(char)

processedTargets[char] = true
    end

    for char, espData in pairs(ESP_Cache) do 
        if not processedTargets[char] then
            espData.Holder.Visible = false
        end
        if not char or not char.Parent then 
            ClearESPFor(char) 
        end 
    end

    local currentTarget = nil
    if Config.AimbotEnabled and isAiming then
        local mousePos = UserInputService:GetMouseLocation() - Vector2.new(0, 36)
        if Config.AimLock and lockedTarget and lockedTarget.Parent and lockedTarget:FindFirstChild("Humanoid") and lockedTarget.Humanoid.Health > 0 then
            currentTarget = lockedTarget
        else
            local closest, maxDist = nil, Config.FOVSize
            for _, char in ipairs(targets) do
                local targetPart = char:FindFirstChild(Config.AimPart) or char.PrimaryPart
                if targetPart then
                    local p = Players:GetPlayerFromCharacter(char)
                    if not (Config.TeamCheck and p and p.Team == LocalPlayer.Team) then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                        if onScreen then
                            local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                            if dist < maxDist and (not Config.VisibilityCheck or isVisible(targetPart, char)) then maxDist = dist; closest = char end
                        end
                    end
                end
            end
            currentTarget = closest; lockedTarget = currentTarget
        end
        if currentTarget then
            local tPart = currentTarget:FindFirstChild(Config.AimPart)
            if tPart then
                local predicted = tPart.Position + (tPart.AssemblyLinearVelocity * Config.Prediction)
                if Config.AggressiveMode then Camera.CFrame = CFrame.new(Camera.CFrame.Position, predicted)
                else Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, predicted), Config.AimSmoothing) end
            end
        end
    end
    if currentTarget and isAiming then
        local tPart = currentTarget:FindFirstChild(Config.AimPart)
        if tPart then local pos, vis = Camera:WorldToViewportPoint(tPart.Position); TargetIndicator.Visible = vis; if vis then TargetIndicator.Position = UDim2.fromOffset(pos.X, pos.Y) end end
    else TargetIndicator.Visible = false end

    -- Perfected TriggerBot v4 (Invisible Hitbox & Universal Weapon support)
    if Config.TriggerBotEnabled and (tick() - lastTrigger) >= Config.TriggerDelay then
        local character = LocalPlayer.Character

        -- Check if user wants Triggerbot to ONLY work when holding a standard Roblox "Tool"
        local currentTool = character and character:FindFirstChildOfClass("Tool")
        if Config.RequireToolForTrigger and not currentTool then
            return -- Abort trigger if strict mode is enabled and no tool is held
        end

        local mousePos = UserInputService:GetMouseLocation()
        local rayX, rayY = mousePos.X, mousePos.Y - 36

        -- If mouse is locked to center (FPS games / Shift Lock)
        if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
            rayX, rayY = Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2
        end

        local unitRay = Camera:ViewportPointToRay(rayX, rayY)
        RayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}

        -- Cast ray 5000 studs outwards
        local hit = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 5000, RayParams)

        if hit and hit.Instance then
            local hitPart = hit.Instance

            -- Locate the Character Model (Supports parts deep inside Accessories or Hitbox parts)
            local model = hitPart:FindFirstAncestorOfClass("Model")
            if not model then 
                local acc = hitPart:FindFirstAncestorOfClass("Accessory")
                if acc then model = acc.Parent end
            end

            if model then
                local humanoid = model:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local isValidTarget = false
                    local targetPlayer = Players:GetPlayerFromCharacter(model)

                    if targetPlayer then

if targetPlayer ~= LocalPlayer then
                            if Config.TeamCheck and targetPlayer.Team ~= nil and targetPlayer.Team == LocalPlayer.Team then
                                isValidTarget = false
                            else
                                isValidTarget = true
                            end
                        end
                    elseif Config.TargetNPCs and table.find(ActiveNPCs, model) then
                        isValidTarget = true
                    end

                    if isValidTarget then
                        lastTrigger = tick()

                        -- Attempt to trigger the Tool directly if it exists
                        if currentTool then currentTool:Activate() end

                        -- Execute simulated click for FPS games or custom gun scripts
                        task.spawn(function()
                            -- Use Exploit Click Functions if supported
                            if type(mouse1click) == "function" then
                                mouse1click()
                            elseif type(mouse1press) == "function" and type(mouse1release) == "function" then
                                mouse1press()
                                task.wait(0.015)
                                mouse1release()
                            else
                                -- Fallback standard input manager simulation
                                local cx, cy = math.floor(mousePos.X), math.floor(mousePos.Y)
                                if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
                                    cx, cy = math.floor(Camera.ViewportSize.X / 2), math.floor(Camera.ViewportSize.Y / 2)
                                end

                                VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
                                task.wait(0.015)
                                VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
                            end
                        end)
                    end
                end
            end
        end
    end
end)

