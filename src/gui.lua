--[[
    Advanced GUI System v2.1.0
    
    This module handles the modern user interface:
    - Sleek multi-tab layout (Aimbot, TriggerBot, Visuals, World & Colors, Anti-Detection, Settings)
    - Animated minimize-to-pill & open transitions
    - Dynamic theme engine (Default, Ruby, Ocean, Midnight, Forest, Light, Blue)
    - Custom background image & opacity controls
    - Interactive controls: animated toggles, sliders, dropdown cyclers, text inputs, action buttons
    - Real-time status bar with target tracking & performance indicators
    - Centralized hotkey listener (INSERT, RightShift, F1, F2, F3, F4, DELETE)
    
    Author: gokuthug1
    License: MIT
]]

local GUI = {}

-- Services
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Helper to get global environment
local function getGlobalEnv()
	if type(getgenv) == "function" then
		return getgenv()
	end
	return _G
end

-- GUI State
GUI.ScreenGui = nil
GUI.MainFrame = nil
GUI.OpenBtn = nil
GUI.IsVisible = false
GUI.CurrentTab = "Aimbot"
GUI.Elements = {
	TabButtons = {},
	TabPages = {},
	Accents = {},
	MainFrames = {},
	Controls = {},
}
GUI.KeybindConnections = {}

-- Theme palettes
GUI.Themes = {
	Default = {
		Main = Color3.fromRGB(20, 20, 26),
		Header = Color3.fromRGB(28, 28, 36),
		Accent = Color3.fromRGB(90, 110, 255),
		Text = Color3.fromRGB(255, 255, 255),
		TextSecondary = Color3.fromRGB(180, 180, 195),
		Stroke = Color3.fromRGB(45, 45, 60),
	},
	Ruby = {
		Main = Color3.fromRGB(26, 16, 18),
		Header = Color3.fromRGB(36, 20, 24),
		Accent = Color3.fromRGB(235, 60, 75),
		Text = Color3.fromRGB(255, 255, 255),
		TextSecondary = Color3.fromRGB(200, 175, 180),
		Stroke = Color3.fromRGB(60, 35, 40),
	},
	Ocean = {
		Main = Color3.fromRGB(14, 24, 34),
		Header = Color3.fromRGB(20, 34, 48),
		Accent = Color3.fromRGB(50, 160, 240),
		Text = Color3.fromRGB(255, 255, 255),
		TextSecondary = Color3.fromRGB(170, 195, 215),
		Stroke = Color3.fromRGB(35, 55, 75),
	},
	Midnight = {
		Main = Color3.fromRGB(12, 12, 18),
		Header = Color3.fromRGB(18, 18, 26),
		Accent = Color3.fromRGB(140, 95, 255),
		Text = Color3.fromRGB(255, 255, 255),
		TextSecondary = Color3.fromRGB(185, 175, 210),
		Stroke = Color3.fromRGB(40, 35, 55),
	},
	Forest = {
		Main = Color3.fromRGB(15, 24, 18),
		Header = Color3.fromRGB(22, 34, 26),
		Accent = Color3.fromRGB(60, 190, 95),
		Text = Color3.fromRGB(255, 255, 255),
		TextSecondary = Color3.fromRGB(175, 200, 180),
		Stroke = Color3.fromRGB(35, 55, 40),
	},
	Light = {
		Main = Color3.fromRGB(240, 242, 245),
		Header = Color3.fromRGB(255, 255, 255),
		Accent = Color3.fromRGB(0, 120, 255),
		Text = Color3.fromRGB(20, 20, 25),
		TextSecondary = Color3.fromRGB(100, 105, 115),
		Stroke = Color3.fromRGB(215, 220, 230),
	},
	Blue = {
		Main = Color3.fromRGB(16, 26, 46),
		Header = Color3.fromRGB(24, 38, 66),
		Accent = Color3.fromRGB(65, 125, 255),
		Text = Color3.fromRGB(255, 255, 255),
		TextSecondary = Color3.fromRGB(180, 195, 225),
		Stroke = Color3.fromRGB(40, 60, 95),
	},
}

-- Initialize GUI system
function GUI:Initialize()
	self:CreateScreenGui()
	self:CreateMainInterface()
	self:CreateTabs()
	self:CreateStatusBar()
	self:SetupDragging()
	self:SetupHotkeys()
	self:ApplyTheme()
	self:SetVisible(true)
	print("🖥️ GUI system initialized")
end

-- Helper to get Config component
function GUI:GetConfigComponent()
	local genv = getGlobalEnv()
	if genv.AimbotESP and genv.AimbotESP.Components and genv.AimbotESP.Components.Config then
		return genv.AimbotESP.Components.Config
	end
	return nil
end

-- Helper to get active theme table
function GUI:GetActiveTheme()
	local cfg = self:GetConfigComponent()
	local themeName = (cfg and cfg:Get("world.theme")) or (cfg and cfg:Get("gui.theme")) or "Default"
	return self.Themes[themeName] or self.Themes.Default
end

-- Helper to create GUI instance with properties
local function createInstance(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	return inst
end

-- Create main ScreenGui
function GUI:CreateScreenGui()
	if self.ScreenGui then
		self.ScreenGui:Destroy()
	end

	local genv = getGlobalEnv()
	local utils = genv.AimbotESP and genv.AimbotESP.Components and genv.AimbotESP.Components.Utils
	local parent = utils and utils:GetSafeGuiParent() or game:GetService("CoreGui")

	self.ScreenGui = createInstance("ScreenGui", {
		Name = "AimbotESPGUI_V2",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = parent,
	})
end

-- Create Main Window Frame & Structure
function GUI:CreateMainInterface()
	local theme = self:GetActiveTheme()

	local mainFrame = createInstance("Frame", {
		Name = "MainFrame",
		Size = UDim2.fromOffset(540, 400),
		Position = UDim2.new(0.5, -270, 0.5, -200),
		BackgroundColor3 = theme.Main,
		BorderSizePixel = 0,
		Active = true,
		ClipsDescendants = true,
		Parent = self.ScreenGui,
	})
	local corner = Instance.new("UICorner", mainFrame)
	corner.CornerRadius = UDim.new(0, 10)

	local stroke = createInstance("UIStroke", {
		Color = theme.Stroke,
		Thickness = 1.5,
		Parent = mainFrame,
	})
	self.Elements.MainStroke = stroke
	table.insert(self.Elements.MainFrames, mainFrame)
	self.MainFrame = mainFrame

	-- Custom Background Image Frame
	local bgImage = createInstance("ImageLabel", {
		Name = "BackgroundImage",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = "",
		ImageTransparency = 0.8,
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 0,
		Parent = mainFrame,
	})
	self.Elements.BackgroundImage = bgImage

	-- Sidebar Container
	local sidebar = createInstance("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 150, 1, 0),
		Position = UDim2.fromScale(0, 0),
		BackgroundColor3 = theme.Header,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = mainFrame,
	})
	Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 10)
	table.insert(self.Elements.MainFrames, sidebar)
	self.Elements.Sidebar = sidebar

	-- Sidebar seam cover
	local seam = createInstance("Frame", {
		Size = UDim2.new(0, 12, 1, 0),
		Position = UDim2.new(1, -10, 0, 0),
		BackgroundColor3 = theme.Header,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = sidebar,
	})
	table.insert(self.Elements.MainFrames, seam)

	-- Title / Logo Label
	local title = createInstance("TextLabel", {
		Name = "Title",
		Size = UDim2.new(1, -10, 0, 50),
		Position = UDim2.new(0, 15, 0, 0),
		BackgroundTransparency = 1,
		Text = "🎯 SUITE v2.1",
		Font = Enum.Font.GothamBold,
		TextSize = 15,
		TextColor3 = theme.Accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
		Parent = sidebar,
	})
	table.insert(self.Elements.Accents, title)

	-- Top Header Controls (Minimize & Close buttons)
	local headerBar = createInstance("Frame", {
		Name = "HeaderBar",
		Size = UDim2.new(1, -150, 0, 40),
		Position = UDim2.new(0, 150, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = mainFrame,
	})
	self.Elements.HeaderBar = headerBar

	local closeBtn = createInstance("TextButton", {
		Name = "CloseBtn",
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(1, -36, 0, 8),
		BackgroundColor3 = Color3.fromRGB(230, 60, 60),
		Text = "✕",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		ZIndex = 6,
		Parent = headerBar,
	})
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

	local minBtn = createInstance("TextButton", {
		Name = "MinBtn",
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(1, -68, 0, 8),
		BackgroundColor3 = Color3.fromRGB(55, 55, 65),
		Text = "—",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		ZIndex = 6,
		Parent = headerBar,
	})
	Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

	-- Minimized floating Open Button
	local openBtn = createInstance("TextButton", {
		Name = "OpenPillBtn",
		Size = UDim2.fromOffset(85, 36),
		Position = UDim2.new(1, -95, 0.5, -18),
		BackgroundColor3 = theme.Header,
		Text = "🎯 Open",
		TextColor3 = theme.Accent,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		Visible = false,
		ZIndex = 20,
		Parent = self.ScreenGui,
	})
	Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 8)
	local openStroke = Instance.new("UIStroke", openBtn)
	openStroke.Color = theme.Stroke
	table.insert(self.Elements.MainFrames, openBtn)
	table.insert(self.Elements.Accents, openBtn)
	self.OpenBtn = openBtn

	-- Minimize animation
	local animTween = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

	minBtn.MouseButton1Click:Connect(function()
		TweenService:Create(mainFrame, animTween, { Position = UDim2.new(0.5, -270, 1.5, 0) }):Play()
		task.wait(0.25)
		mainFrame.Visible = false
		openBtn.Visible = true
		openBtn.Position = UDim2.new(1, 20, 0.5, -18)
		TweenService:Create(openBtn, animTween, { Position = UDim2.new(1, -95, 0.5, -18) }):Play()
	end)

	openBtn.MouseButton1Click:Connect(function()
		TweenService:Create(openBtn, animTween, { Position = UDim2.new(1, 20, 0.5, -18) }):Play()
		task.wait(0.25)
		openBtn.Visible = false
		mainFrame.Visible = true
		TweenService:Create(mainFrame, animTween, { Position = UDim2.new(0.5, -270, 0.5, -200) }):Play()
	end)

	closeBtn.MouseButton1Click:Connect(function()
		self:SetVisible(false)
	end)

	-- Tab Container in Sidebar
	local tabContainer = createInstance("Frame", {
		Name = "TabContainer",
		Size = UDim2.new(1, -16, 1, -65),
		Position = UDim2.new(0, 8, 0, 55),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = sidebar,
	})
	local tabLayout = Instance.new("UIListLayout", tabContainer)
	tabLayout.Padding = UDim.new(0, 4)
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	self.Elements.TabContainer = tabContainer

	-- Content Area for Pages
	local contentArea = createInstance("Frame", {
		Name = "ContentArea",
		Size = UDim2.new(1, -165, 1, -75),
		Position = UDim2.new(0, 155, 0, 40),
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = mainFrame,
	})
	self.Elements.ContentArea = contentArea
end

-- Create Tabs & Category Pages
function GUI:CreateTabs()
	local categories = {
		{ Id = "Aimbot", Name = "🎯 AimBot" },
		{ Id = "TriggerBot", Name = "⚡ TriggerBot" },
		{ Id = "Visuals", Name = "👁️ Visuals / ESP" },
		{ Id = "World", Name = "🎨 Colors & World" },
		{ Id = "AntiCheat", Name = "🛡️ Anti-Cheat" },
		{ Id = "Settings", Name = "⚙️ Settings & Info" },
	}

	for idx, cat in ipairs(categories) do
		local btn = createInstance("TextButton", {
			Name = cat.Id .. "TabBtn",
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = self:GetActiveTheme().Header,
			Text = "  " .. cat.Name,
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextColor3 = Color3.fromRGB(170, 170, 185),
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = idx,
			ZIndex = 4,
			Parent = self.Elements.TabContainer,
		})
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		self.Elements.TabButtons[cat.Id] = btn
		table.insert(self.Elements.MainFrames, btn)

		-- Scrollable Page for Tab Content
		local page = createInstance("ScrollingFrame", {
			Name = cat.Id .. "Page",
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromScale(0, 0),
			BackgroundTransparency = 1,
			ScrollBarThickness = 4,
			Visible = false,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ZIndex = 4,
			Parent = self.Elements.ContentArea,
		})
		local listLayout = Instance.new("UIListLayout", page)
		listLayout.Padding = UDim.new(0, 6)
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		self.Elements.TabPages[cat.Id] = page

		btn.MouseButton1Click:Connect(function()
			self:SwitchTab(cat.Id)
		end)
	end

	-- Populate controls inside each tab
	self:PopulateAimbotTab()
	self:PopulateTriggerBotTab()
	self:PopulateVisualsTab()
	self:PopulateWorldTab()
	self:PopulateAntiCheatTab()
	self:PopulateSettingsTab()

	-- Activate first tab
	self:SwitchTab("Aimbot")
end

-- Switch active tab
function GUI:SwitchTab(tabId)
	local theme = self:GetActiveTheme()
	self.CurrentTab = tabId

	for id, btn in pairs(self.Elements.TabButtons) do
		local page = self.Elements.TabPages[id]
		if id == tabId then
			btn.BackgroundColor3 = theme.Accent
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			if page then
				page.Visible = true
			end
		else
			btn.BackgroundColor3 = theme.Header
			btn.TextColor3 = Color3.fromRGB(170, 170, 185)
			if page then
				page.Visible = false
			end
		end
	end
end

--[[------------------------------------------------------------------------------
    Control Component Builders (Toggles, Sliders, Dropdowns, Inputs, Buttons)
--------------------------------------------------------------------------------]]

function GUI:CreateToggle(page, labelText, configPath, callback)
	local cfg = self:GetConfigComponent()
	local theme = self:GetActiveTheme()

	local frame = createInstance("Frame", {
		Size = UDim2.new(1, -10, 0, 32),
		BackgroundTransparency = 1,
		Parent = page,
	})

	createInstance("TextLabel", {
		Size = UDim2.new(1, -55, 1, 0),
		BackgroundTransparency = 1,
		Text = labelText,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(225, 225, 230),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})

	local toggleBtn = createInstance("TextButton", {
		Size = UDim2.fromOffset(42, 22),
		Position = UDim2.new(1, -45, 0.5, -11),
		BackgroundColor3 = Color3.fromRGB(40, 40, 50),
		Text = "",
		Parent = frame,
	})
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)

	local circle = createInstance("Frame", {
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(0, 3, 0.5, -8),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Parent = toggleBtn,
	})
	Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

	local function updateVisual(state)
		local activeColor = theme.Accent
		local offColor = Color3.fromRGB(40, 40, 50)
		TweenService:Create(toggleBtn, TweenInfo.new(0.2), {
			BackgroundColor3 = state and activeColor or offColor,
		}):Play()
		TweenService:Create(circle, TweenInfo.new(0.2), {
			Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
		}):Play()
	end

	local initialState = cfg and cfg:Get(configPath) or false
	updateVisual(initialState)

	toggleBtn.MouseButton1Click:Connect(function()
		local current = cfg and cfg:Get(configPath) or false
		local newState = not current
		if cfg then
			cfg:Set(configPath, newState)
		end
		updateVisual(newState)
		if callback then
			callback(newState)
		end
	end)

	table.insert(self.Elements.Accents, {
		Element = toggleBtn,
		ConfigPath = configPath,
		Type = "Toggle",
		Update = updateVisual,
	})
	return frame
end

function GUI:CreateSlider(page, labelText, configPath, minVal, maxVal, isDecimal, callback)
	local cfg = self:GetConfigComponent()
	local theme = self:GetActiveTheme()

	local frame = createInstance("Frame", {
		Size = UDim2.new(1, -10, 0, 44),
		BackgroundTransparency = 1,
		Parent = page,
	})

	createInstance("TextLabel", {
		Size = UDim2.new(1, -60, 0, 20),
		BackgroundTransparency = 1,
		Text = labelText,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(225, 225, 230),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})

	local valueLabel = createInstance("TextLabel", {
		Size = UDim2.new(0, 60, 0, 20),
		Position = UDim2.new(1, -60, 0, 0),
		BackgroundTransparency = 1,
		Text = tostring(cfg and cfg:Get(configPath) or minVal),
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = frame,
	})

	local sliderBg = createInstance("TextButton", {
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.new(0, 0, 1, -10),
		BackgroundColor3 = Color3.fromRGB(40, 40, 52),
		Text = "",
		Parent = frame,
	})
	Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)

	local initialVal = cfg and cfg:Get(configPath) or minVal
	local initialPct = math.clamp((initialVal - minVal) / (maxVal - minVal), 0, 1)

	local sliderFill = createInstance("Frame", {
		Size = UDim2.new(initialPct, 0, 1, 0),
		BackgroundColor3 = theme.Accent,
		Parent = sliderBg,
	})
	Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)
	table.insert(self.Elements.Accents, sliderFill)

	local dragging = false
	sliderBg.InputBegan:Connect(function(input)
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
			local relX = input.Position.X - sliderBg.AbsolutePosition.X
			local pct = math.clamp(relX / sliderBg.AbsoluteSize.X, 0, 1)
			local rawVal = minVal + (pct * (maxVal - minVal))
			local finalVal = isDecimal and tonumber(string.format("%.2f", rawVal)) or math.floor(rawVal + 0.5)

			sliderFill.Size = UDim2.new(pct, 0, 1, 0)
			valueLabel.Text = tostring(finalVal)

			if cfg then
				cfg:Set(configPath, finalVal)
			end
			if callback then
				callback(finalVal)
			end
		end
	end)

	return frame
end

function GUI:CreateDropdown(page, labelText, configPath, options, callback)
	local cfg = self:GetConfigComponent()
	local theme = self:GetActiveTheme()

	local frame = createInstance("Frame", {
		Size = UDim2.new(1, -10, 0, 32),
		BackgroundTransparency = 1,
		Parent = page,
	})

	createInstance("TextLabel", {
		Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = labelText,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(225, 225, 230),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})

	local initial = tostring(cfg and cfg:Get(configPath) or options[1])
	local btn = createInstance("TextButton", {
		Size = UDim2.new(0.48, 0, 0, 26),
		Position = UDim2.new(0.52, 0, 0.5, -13),
		BackgroundColor3 = theme.Accent,
		Text = initial,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Parent = frame,
	})
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
	table.insert(self.Elements.Accents, btn)

	btn.MouseButton1Click:Connect(function()
		local current = cfg and cfg:Get(configPath) or options[1]
		local idx = 1
		for i, opt in ipairs(options) do
			if tostring(opt) == tostring(current) then
				idx = i
				break
			end
		end
		local nextOpt = options[(idx % #options) + 1]
		btn.Text = tostring(nextOpt)

		if cfg then
			cfg:Set(configPath, nextOpt)
		end
		if callback then
			callback(nextOpt)
		end
	end)

	return frame
end

function GUI:CreateTextInput(page, labelText, configPath, placeholder, callback)
	local cfg = self:GetConfigComponent()
	local theme = self:GetActiveTheme()

	local frame = createInstance("Frame", {
		Size = UDim2.new(1, -10, 0, 32),
		BackgroundTransparency = 1,
		Parent = page,
	})

	createInstance("TextLabel", {
		Size = UDim2.new(0.45, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = labelText,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(225, 225, 230),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})

	local initial = tostring(cfg and cfg:Get(configPath) or "")
	local box = createInstance("TextBox", {
		Size = UDim2.new(0.53, 0, 0, 26),
		Position = UDim2.new(0.47, 0, 0.5, -13),
		BackgroundColor3 = theme.Header,
		Text = initial,
		PlaceholderText = placeholder or "Type here...",
		PlaceholderColor3 = Color3.fromRGB(130, 130, 145),
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		ClearTextOnFocus = false,
		Parent = frame,
	})
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
	table.insert(self.Elements.MainFrames, box)

	box.FocusLost:Connect(function()
		if cfg then
			cfg:Set(configPath, box.Text)
		end
		if callback then
			callback(box.Text)
		end
	end)

	return frame
end

function GUI:CreateActionButton(page, labelText, btnText, callback)
	local theme = self:GetActiveTheme()

	local frame = createInstance("Frame", {
		Size = UDim2.new(1, -10, 0, 34),
		BackgroundTransparency = 1,
		Parent = page,
	})

	createInstance("TextLabel", {
		Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = labelText,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(225, 225, 230),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})

	local btn = createInstance("TextButton", {
		Size = UDim2.new(0.48, 0, 0, 28),
		Position = UDim2.new(0.52, 0, 0.5, -14),
		BackgroundColor3 = theme.Accent,
		Text = btnText,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Parent = frame,
	})
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
	table.insert(self.Elements.Accents, btn)

	btn.MouseButton1Click:Connect(function()
		if callback then
			callback()
		end
	end)

	return frame
end

--[[------------------------------------------------------------------------------
    Page Population Functions
--------------------------------------------------------------------------------]]

function GUI:PopulateAimbotTab()
	local page = self.Elements.TabPages["Aimbot"]
	self:CreateToggle(page, "Enable AimBot", "aimbot.enabled")
	self:CreateToggle(page, "Aggressive Mode (Instant Snap)", "aimbot.aggressiveMode")
	self:CreateToggle(page, "Aim Lock (Sticky Target)", "aimbot.aimLock")
	self:CreateDropdown(page, "Aim Mode", "aimbot.aimMode", { "Hybrid", "Camera", "Mouse" })
	self:CreateDropdown(page, "Target Body Part", "aimbot.targetPart", { "Head", "Torso", "Smart", "HumanoidRootPart" })
	self:CreateDropdown(page, "Target Priority", "aimbot.priorityMode", { "Distance", "Health", "Threat", "Crosshair" })
	self:CreateToggle(page, "Show FOV Circle", "aimbot.showFOV")
	self:CreateToggle(page, "Visibility Check", "aimbot.visibilityCheck")
	self:CreateToggle(page, "Team Check", "aimbot.teamCheck")
	self:CreateToggle(page, "Target NPCs", "aimbot.targetNPCs")
	self:CreateSlider(page, "Field of View (Degrees)", "aimbot.fov", 10, 180, false)
	self:CreateSlider(page, "Aim Smoothness", "aimbot.smoothness", 1, 30, false)
	self:CreateToggle(page, "Movement Prediction", "aimbot.prediction")
end

function GUI:PopulateTriggerBotTab()
	local page = self.Elements.TabPages["TriggerBot"]
	self:CreateToggle(page, "Enable TriggerBot", "triggerBot.enabled")
	self:CreateToggle(page, "Require Equipped Tool", "triggerBot.requireTool")
	self:CreateToggle(page, "Team Check", "triggerBot.teamCheck")
	self:CreateToggle(page, "Target NPCs", "triggerBot.targetNPCs")
	self:CreateSlider(page, "Trigger Delay (s)", "triggerBot.delay", 0.01, 0.5, true)
	self:CreateSlider(page, "Max Trigger Range (studs)", "triggerBot.maxDistance", 100, 3000, false)
end

function GUI:PopulateVisualsTab()
	local page = self.Elements.TabPages["Visuals"]
	self:CreateToggle(page, "Master ESP", "esp.enabled")
	self:CreateToggle(page, "Show Teammates", "esp.showTeammates")
	self:CreateToggle(page, "2D Bounding Boxes", "esp.boxes")
	self:CreateToggle(page, "Bone Skeletons (R6/R15)", "esp.skeleton")
	self:CreateToggle(page, "Player Tracers", "esp.tracers")
	self:CreateDropdown(page, "Tracer Origin", "esp.tracerOrigin", { "Bottom", "Center", "Top" })
	self:CreateToggle(page, "Head Dot", "esp.headDot")
	self:CreateToggle(page, "Health Bars", "esp.healthBars")
	self:CreateToggle(page, "Health Text Numbers", "esp.healthText")
	self:CreateToggle(page, "Names & Tags", "esp.names")
	self:CreateToggle(page, "Distance Display", "esp.distance")
	self:CreateToggle(page, "Equipped Weapon Text", "esp.weapons")
	self:CreateToggle(page, "Target NPC ESP", "esp.targetNPCs")
	self:CreateSlider(page, "Max ESP Distance", "esp.maxDistance", 100, 3000, false)
end

function GUI:PopulateWorldTab()
	local page = self.Elements.TabPages["World"]
	self:CreateDropdown(
		page,
		"Enemy Color Preset",
		"esp.enemyColor",
		{ "Red", "Green", "Blue", "Purple", "Yellow", "White" }
	)
	self:CreateDropdown(
		page,
		"Team Color Preset",
		"esp.teamColor",
		{ "Blue", "Green", "Yellow", "Purple", "Red", "White" }
	)
	self:CreateToggle(page, "X-Ray (Wall Transparency)", "world.xrayEnabled")
	self:CreateSlider(page, "X-Ray Opacity", "world.xrayOpacity", 0.1, 0.9, true)

	local themes = { "Default", "Ruby", "Ocean", "Midnight", "Forest", "Light", "Blue" }
	self:CreateDropdown(page, "UI Theme Palette", "world.theme", themes, function()
		self:ApplyTheme()
	end)

	self:CreateTextInput(page, "BG Image (Asset/URL)", "world.bgImage", "Paste Asset ID or URL...", function(val)
		if val == "" then
			self.Elements.BackgroundImage.Image = ""
			return
		end
		local id = string.match(val, "%d+")
		if id and not string.find(val, "://") then
			self.Elements.BackgroundImage.Image = "rbxassetid://" .. id
		else
			self.Elements.BackgroundImage.Image = val
		end
	end)

	self:CreateSlider(page, "BG Image Transparency", "world.bgTransparency", 0, 1, true, function(val)
		self.Elements.BackgroundImage.ImageTransparency = val
	end)
end

function GUI:PopulateAntiCheatTab()
	local page = self.Elements.TabPages["AntiCheat"]
	self:CreateToggle(page, "Enable Anti-Detection", "antiDetection.enabled")
	self:CreateToggle(page, "Humanized Mouse Movement", "antiDetection.humanization")
	self:CreateToggle(page, "Stealth Mode (Hides Reticles)", "antiDetection.stealthMode")
	self:CreateSlider(page, "Max Actions Per Second", "antiDetection.maxActionsPerSecond", 10, 60, false)
end

function GUI:PopulateSettingsTab()
	local page = self.Elements.TabPages["Settings"]
	local cfg = self:GetConfigComponent()

	self:CreateActionButton(page, "Save Profile to Disk", "Save Profile", function()
		if cfg then
			cfg:Save("default")
		end
	end)

	self:CreateActionButton(page, "Load Saved Profile", "Load Profile", function()
		if cfg then
			cfg:Load("default")
		end
	end)

	self:CreateActionButton(page, "Restore Factory Defaults", "Reset All", function()
		if cfg then
			cfg:Reset()
		end
	end)

	self:CreateActionButton(page, "Emergency Clean Unload", "Unload Script", function()
		local genv = getGlobalEnv()
		if genv.AimbotESP and genv.AimbotESP.Unload then
			genv.AimbotESP:Unload()
		end
	end)

	local infoLabel = createInstance("TextLabel", {
		Size = UDim2.new(1, -10, 0, 160),
		BackgroundTransparency = 1,
		Text = [[🎯 AimBot & ESP Suite v2.1.0

⌨️ Hotkey Controls:
• INSERT / Right-Shift: Toggle GUI
• F1: Toggle AimBot
• F2: Toggle ESP
• F3: Toggle Tracers
• F4: Cycle Aim Target Part
• DELETE: Emergency Disable

🛡️ Designed with native executor compatibility, anti-detection throttling, and drawing fallbacks.]],
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(185, 185, 200),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = page,
	})
	self.Elements.InfoLabel = infoLabel
end

-- Create Status Bar at bottom
function GUI:CreateStatusBar()
	local theme = self:GetActiveTheme()

	local statusBar = createInstance("Frame", {
		Name = "StatusBar",
		Size = UDim2.new(1, -150, 0, 26),
		Position = UDim2.new(0, 150, 1, -26),
		BackgroundColor3 = theme.Header,
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = self.MainFrame,
	})
	table.insert(self.Elements.MainFrames, statusBar)

	local statusText = createInstance("TextLabel", {
		Name = "StatusText",
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		Text = "Ready • AimBot: OFF • ESP: OFF",
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = theme.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 6,
		Parent = statusBar,
	})
	self.Elements.StatusText = statusText
end

-- Apply selected theme to all UI elements
function GUI:ApplyTheme()
	local theme = self:GetActiveTheme()

	if self.MainFrame then
		self.MainFrame.BackgroundColor3 = theme.Main
	end
	if self.Elements.MainStroke then
		self.Elements.MainStroke.Color = theme.Stroke
	end

	for _, frame in ipairs(self.Elements.MainFrames) do
		if frame ~= self.MainFrame then
			frame.BackgroundColor3 = theme.Header
		end
	end

	for _, elem in ipairs(self.Elements.Accents) do
		if type(elem) == "table" and elem.Type == "Toggle" then
			local cfg = self:GetConfigComponent()
			local state = cfg and cfg:Get(elem.ConfigPath) or false
			elem.Update(state)
		elseif typeof(elem) == "Instance" then
			if elem:IsA("TextLabel") or elem:IsA("TextButton") then
				if elem.Name == "Title" or elem == self.OpenBtn then
					elem.TextColor3 = theme.Accent
				elseif
					elem.BackgroundColor3 ~= Color3.fromRGB(230, 60, 60)
					and elem.BackgroundColor3 ~= Color3.fromRGB(55, 55, 65)
				then
					elem.BackgroundColor3 = theme.Accent
				end
			elseif elem:IsA("Frame") then
				elem.BackgroundColor3 = theme.Accent
			end
		end
	end

	if self.Elements.TabButtons[self.CurrentTab] then
		self.Elements.TabButtons[self.CurrentTab].BackgroundColor3 = theme.Accent
	end
end

-- Centralized Hotkey Listener (INSERT, RightShift, F1, F2, F3, F4, DELETE)
function GUI:SetupHotkeys()
	for _, conn in ipairs(self.KeybindConnections) do
		conn:Disconnect()
	end
	self.KeybindConnections = {}

	local conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		local cfg = self:GetConfigComponent()
		local genv = getGlobalEnv()

		-- GUI Toggle: INSERT or RightShift
		if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightShift then
			self:SetVisible(not self.IsVisible)
		end

		-- Aimbot Toggle: F1
		if input.KeyCode == Enum.KeyCode.F1 and cfg then
			local state = cfg:Toggle("aimbot.enabled")
			print("🎯 AimBot toggled: " .. (state and "ON" or "OFF"))
		end

		-- ESP Toggle: F2
		if input.KeyCode == Enum.KeyCode.F2 and cfg then
			local state = cfg:Toggle("esp.enabled")
			print("👁️ ESP toggled: " .. (state and "ON" or "OFF"))
		end

		-- Tracers Toggle: F3
		if input.KeyCode == Enum.KeyCode.F3 and cfg then
			local state = cfg:Toggle("esp.tracers")
			print("📍 Tracers toggled: " .. (state and "ON" or "OFF"))
		end

		-- Target Part Cycle: F4 (Head -> Torso -> Smart -> HumanoidRootPart)
		if input.KeyCode == Enum.KeyCode.F4 and cfg then
			local parts = { "Head", "Torso", "Smart", "HumanoidRootPart" }
			local current = cfg:Get("aimbot.targetPart") or "Head"
			local idx = 1
			for i, p in ipairs(parts) do
				if p == current then
					idx = i
					break
				end
			end
			local nextPart = parts[(idx % #parts) + 1]
			cfg:Set("aimbot.targetPart", nextPart)
			print("🎯 Target part cycled to: " .. nextPart)
		end

		-- Emergency Disable: DELETE
		if input.KeyCode == Enum.KeyCode.Delete then
			if genv.AimbotESP and genv.AimbotESP.State then
				genv.AimbotESP.State.EmergencyDisabled = not genv.AimbotESP.State.EmergencyDisabled
				local isEm = genv.AimbotESP.State.EmergencyDisabled
				warn(isEm and "🚨 EMERGENCY DISABLE ACTIVATED" or "✅ Emergency disable deactivated")
			end
		end
	end)

	table.insert(self.KeybindConnections, conn)
end

-- Draggable title bar setup
function GUI:SetupDragging()
	local dragging = false
	local dragStart = nil
	local startPos = nil

	local header = self.Elements.HeaderBar or self.MainFrame
	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = self.MainFrame.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			self.MainFrame.Position =
				UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
end

-- Set GUI Visibility
function GUI:SetVisible(visible)
	self.IsVisible = visible
	if self.MainFrame then
		self.MainFrame.Visible = visible
	end
	if not visible and self.OpenBtn then
		self.OpenBtn.Visible = false
	end
end

-- Update Status Bar
function GUI:UpdateStatus()
	if not self.Elements.StatusText then
		return
	end

	local genv = getGlobalEnv()
	local cfg = self:GetConfigComponent()

	if genv.AimbotESP and genv.AimbotESP.State and genv.AimbotESP.State.EmergencyDisabled then
		self.Elements.StatusText.Text = "🚨 EMERGENCY DISABLED (Press DELETE to re-enable)"
		self.Elements.StatusText.TextColor3 = Color3.fromRGB(255, 60, 60)
		return
	end

	local aimStatus = (cfg and cfg:Get("aimbot.enabled")) and "ON" or "OFF"
	local espStatus = (cfg and cfg:Get("esp.enabled")) and "ON" or "OFF"
	local trigStatus = (cfg and cfg:Get("triggerBot.enabled")) and "ON" or "OFF"

	local aimbotComp = genv.AimbotESP and genv.AimbotESP.Components and genv.AimbotESP.Components.Aimbot
	local targetInfo = aimbotComp and aimbotComp:GetCurrentTargetInfo()

	local statusStr = string.format("Ready • Aim: %s • Trig: %s • ESP: %s", aimStatus, trigStatus, espStatus)
	if targetInfo then
		statusStr = statusStr .. string.format(" • Locked: %s [%dm]", targetInfo.name, targetInfo.distance)
	end

	self.Elements.StatusText.Text = statusStr
	self.Elements.StatusText.TextColor3 = self:GetActiveTheme().TextSecondary
end

-- Main update loop
function GUI:Update()
	if self.IsVisible then
		self:UpdateStatus()
	end
end

-- Cleanup function
function GUI:Cleanup()
	for _, conn in ipairs(self.KeybindConnections) do
		conn:Disconnect()
	end
	self.KeybindConnections = {}

	if self.ScreenGui then
		self.ScreenGui:Destroy()
		self.ScreenGui = nil
	end

	self.MainFrame = nil
	self.OpenBtn = nil
	self.Elements = {
		TabButtons = {},
		TabPages = {},
		Accents = {},
		MainFrames = {},
		Controls = {},
	}
	self.IsVisible = false
end

return GUI
