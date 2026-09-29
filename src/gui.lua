--[[
    Advanced GUI System v2.2.0 (Remastered)
    
    A professional, responsive, and accessible control interface for the Suite:
    - Structured Section Cards with visual hierarchy and rhythm
    - Cohesive Theme Engine with 7 WCAG AA contrast-compliant palettes
    - Clean procedural vector iconography (strict no-emoji standard)
    - Modern controls: animated switches, precision dual-input sliders,
      one-click segmented selectors, searchable filters, and toast notifications
    - Viewport boundary clamping and animated minimize-to-pill transitions
    - Real-time diagnostic status bar with active target tracking
    
    License: MIT
]]

local GUI = {}

-- Services
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	Camera = Workspace.CurrentCamera
end)

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
GUI.ToastContainer = nil
GUI.IsVisible = false
GUI.CurrentTab = "Aimbot"
GUI.SearchQuery = ""
GUI.ActiveToasts = {}

-- Registry tables for dynamic theme updates
GUI.Elements = {
	Frames = {},
	Sidebars = {},
	Headers = {},
	Cards = {},
	CardBorders = {},
	TextPrimary = {},
	TextSecondary = {},
	Accents = {},
	ControlBackgrounds = {},
	ControlBorders = {},
	TabButtons = {},
	TabPages = {},
	Toggles = {},
	Sliders = {},
	Segments = {},
	StatusDots = {},
}
GUI.KeybindConnections = {}

-- Theme palettes (WCAG AA compliant contrast tokens)
GUI.Themes = {
	Default = {
		Main = Color3.fromRGB(18, 19, 24),
		Sidebar = Color3.fromRGB(24, 25, 32),
		Header = Color3.fromRGB(24, 25, 32),
		Card = Color3.fromRGB(27, 28, 36),
		CardBorder = Color3.fromRGB(42, 44, 56),
		ControlBg = Color3.fromRGB(34, 35, 46),
		ControlHover = Color3.fromRGB(44, 46, 60),
		Accent = Color3.fromRGB(88, 101, 242),
		AccentHover = Color3.fromRGB(105, 118, 255),
		Text = Color3.fromRGB(242, 243, 245),
		TextSecondary = Color3.fromRGB(158, 162, 178),
		Border = Color3.fromRGB(48, 50, 64),
		Success = Color3.fromRGB(46, 204, 113),
		Danger = Color3.fromRGB(235, 60, 60),
		Warning = Color3.fromRGB(241, 196, 15),
	},
	Ruby = {
		Main = Color3.fromRGB(24, 16, 18),
		Sidebar = Color3.fromRGB(32, 20, 24),
		Header = Color3.fromRGB(32, 20, 24),
		Card = Color3.fromRGB(38, 24, 28),
		CardBorder = Color3.fromRGB(60, 36, 42),
		ControlBg = Color3.fromRGB(46, 28, 34),
		ControlHover = Color3.fromRGB(62, 38, 46),
		Accent = Color3.fromRGB(235, 60, 75),
		AccentHover = Color3.fromRGB(250, 80, 95),
		Text = Color3.fromRGB(245, 240, 242),
		TextSecondary = Color3.fromRGB(180, 155, 162),
		Border = Color3.fromRGB(65, 35, 42),
		Success = Color3.fromRGB(46, 204, 113),
		Danger = Color3.fromRGB(235, 60, 60),
		Warning = Color3.fromRGB(241, 196, 15),
	},
	Ocean = {
		Main = Color3.fromRGB(14, 22, 30),
		Sidebar = Color3.fromRGB(18, 28, 38),
		Header = Color3.fromRGB(18, 28, 38),
		Card = Color3.fromRGB(22, 34, 46),
		CardBorder = Color3.fromRGB(35, 54, 72),
		ControlBg = Color3.fromRGB(28, 44, 60),
		ControlHover = Color3.fromRGB(36, 56, 76),
		Accent = Color3.fromRGB(30, 160, 235),
		AccentHover = Color3.fromRGB(55, 180, 255),
		Text = Color3.fromRGB(240, 246, 250),
		TextSecondary = Color3.fromRGB(150, 180, 200),
		Border = Color3.fromRGB(40, 60, 80),
		Success = Color3.fromRGB(46, 204, 113),
		Danger = Color3.fromRGB(235, 60, 60),
		Warning = Color3.fromRGB(241, 196, 15),
	},
	Midnight = {
		Main = Color3.fromRGB(14, 12, 22),
		Sidebar = Color3.fromRGB(20, 17, 30),
		Header = Color3.fromRGB(20, 17, 30),
		Card = Color3.fromRGB(25, 21, 38),
		CardBorder = Color3.fromRGB(45, 38, 68),
		ControlBg = Color3.fromRGB(32, 27, 48),
		ControlHover = Color3.fromRGB(44, 38, 66),
		Accent = Color3.fromRGB(140, 95, 255),
		AccentHover = Color3.fromRGB(160, 120, 255),
		Text = Color3.fromRGB(245, 242, 252),
		TextSecondary = Color3.fromRGB(175, 165, 195),
		Border = Color3.fromRGB(50, 42, 75),
		Success = Color3.fromRGB(46, 204, 113),
		Danger = Color3.fromRGB(235, 60, 60),
		Warning = Color3.fromRGB(241, 196, 15),
	},
	Forest = {
		Main = Color3.fromRGB(14, 22, 16),
		Sidebar = Color3.fromRGB(18, 28, 20),
		Header = Color3.fromRGB(18, 28, 20),
		Card = Color3.fromRGB(22, 34, 25),
		CardBorder = Color3.fromRGB(36, 54, 40),
		ControlBg = Color3.fromRGB(28, 44, 32),
		ControlHover = Color3.fromRGB(36, 56, 42),
		Accent = Color3.fromRGB(46, 180, 88),
		AccentHover = Color3.fromRGB(62, 205, 108),
		Text = Color3.fromRGB(240, 248, 242),
		TextSecondary = Color3.fromRGB(155, 190, 165),
		Border = Color3.fromRGB(40, 62, 46),
		Success = Color3.fromRGB(46, 204, 113),
		Danger = Color3.fromRGB(235, 60, 60),
		Warning = Color3.fromRGB(241, 196, 15),
	},
	Light = {
		Main = Color3.fromRGB(244, 245, 248),
		Sidebar = Color3.fromRGB(235, 237, 242),
		Header = Color3.fromRGB(235, 237, 242),
		Card = Color3.fromRGB(255, 255, 255),
		CardBorder = Color3.fromRGB(218, 222, 230),
		ControlBg = Color3.fromRGB(228, 231, 238),
		ControlHover = Color3.fromRGB(218, 222, 230),
		Accent = Color3.fromRGB(24, 110, 240),
		AccentHover = Color3.fromRGB(15, 95, 220),
		Text = Color3.fromRGB(24, 27, 34),
		TextSecondary = Color3.fromRGB(92, 100, 114),
		Border = Color3.fromRGB(210, 215, 224),
		Success = Color3.fromRGB(34, 160, 88),
		Danger = Color3.fromRGB(220, 50, 50),
		Warning = Color3.fromRGB(210, 140, 10),
	},
	Blue = {
		Main = Color3.fromRGB(16, 24, 42),
		Sidebar = Color3.fromRGB(22, 34, 58),
		Header = Color3.fromRGB(22, 34, 58),
		Card = Color3.fromRGB(26, 40, 68),
		CardBorder = Color3.fromRGB(42, 64, 105),
		ControlBg = Color3.fromRGB(32, 50, 84),
		ControlHover = Color3.fromRGB(42, 64, 105),
		Accent = Color3.fromRGB(60, 125, 255),
		AccentHover = Color3.fromRGB(85, 145, 255),
		Text = Color3.fromRGB(242, 246, 255),
		TextSecondary = Color3.fromRGB(165, 185, 220),
		Border = Color3.fromRGB(45, 70, 115),
		Success = Color3.fromRGB(46, 204, 113),
		Danger = Color3.fromRGB(235, 60, 60),
		Warning = Color3.fromRGB(241, 196, 15),
	},
}

--[[------------------------------------------------------------------------------
    Core Helper Methods
--------------------------------------------------------------------------------]]

function GUI:GetConfigComponent()
	local genv = getGlobalEnv()
	if genv.AimbotESP and genv.AimbotESP.Components and genv.AimbotESP.Components.Config then
		return genv.AimbotESP.Components.Config
	end
	return nil
end

function GUI:GetActiveTheme()
	local cfg = self:GetConfigComponent()
	local themeName = (cfg and cfg:Get("world.theme")) or (cfg and cfg:Get("gui.theme")) or "Default"
	return self.Themes[themeName] or self.Themes.Default
end

local function createInstance(className, props, parent)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function createCorner(radius, parent)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function createStroke(color, thickness, parent)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function createPadding(top, bottom, left, right, parent)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, top or 0)
	pad.PaddingBottom = UDim.new(0, bottom or 0)
	pad.PaddingLeft = UDim.new(0, left or 0)
	pad.PaddingRight = UDim.new(0, right or 0)
	pad.Parent = parent
	return pad
end

-- Procedural vector icon generator (strict no-emoji standard)
local function createVectorIcon(iconType, parent, size, color)
	local iconSize = size or 16
	local container = createInstance("Frame", {
		Name = iconType .. "Icon",
		Size = UDim2.fromOffset(iconSize, iconSize),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	if iconType == "crosshair" then
		local circle = createInstance("Frame", {
			Size = UDim2.fromOffset(iconSize - 4, iconSize - 4),
			Position = UDim2.fromOffset(2, 2),
			BackgroundTransparency = 1,
			Parent = container,
		})
		createCorner(iconSize, circle)
		createStroke(color, 1.2, circle)
		local dot = createInstance("Frame", {
			Size = UDim2.fromOffset(2, 2),
			Position = UDim2.new(0.5, -1, 0.5, -1),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = container,
		})
		createCorner(2, dot)
	elseif iconType == "trigger" then
		local barH = createInstance("Frame", {
			Size = UDim2.new(1, -4, 0, 2),
			Position = UDim2.new(0, 2, 0.5, -1),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = container,
		})
		local barV = createInstance("Frame", {
			Size = UDim2.new(0, 2, 1, -4),
			Position = UDim2.new(0.5, -1, 0, 2),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = container,
		})
	elseif iconType == "eye" then
		local frame = createInstance("Frame", {
			Size = UDim2.new(1, -2, 0.6, 0),
			Position = UDim2.new(0, 1, 0.2, 0),
			BackgroundTransparency = 1,
			Parent = container,
		})
		createCorner(6, frame)
		createStroke(color, 1.2, frame)
		local pupil = createInstance("Frame", {
			Size = UDim2.fromOffset(4, 4),
			Position = UDim2.new(0.5, -2, 0.5, -2),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = frame,
		})
		createCorner(4, pupil)
	elseif iconType == "world" then
		local grid = createInstance("Frame", {
			Size = UDim2.new(1, -4, 1, -4),
			Position = UDim2.fromOffset(2, 2),
			BackgroundTransparency = 1,
			Parent = container,
		})
		createCorner(3, grid)
		createStroke(color, 1.2, grid)
		local divider = createInstance("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 0.5, 0),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Parent = grid,
		})
	elseif iconType == "shield" then
		local crest = createInstance("Frame", {
			Size = UDim2.new(0.8, 0, 0.9, 0),
			Position = UDim2.new(0.1, 0, 0.05, 0),
			BackgroundTransparency = 1,
			Parent = container,
		})
		createCorner(4, crest)
		createStroke(color, 1.2, crest)
	elseif iconType == "settings" then
		for i = 1, 3 do
			local line = createInstance("Frame", {
				Size = UDim2.new(1, -4, 0, 2),
				Position = UDim2.new(0, 2, 0, (i - 1) * 5 + 3),
				BackgroundColor3 = color,
				BorderSizePixel = 0,
				Parent = container,
			})
			local knot = createInstance("Frame", {
				Size = UDim2.fromOffset(3, 4),
				Position = UDim2.new(i == 2 and 0.6 or 0.25, 0, 0.5, -2),
				BackgroundColor3 = color,
				BorderSizePixel = 0,
				Parent = line,
			})
		end
	end

	return container
end

--[[------------------------------------------------------------------------------
    Toast Notification System
--------------------------------------------------------------------------------]]

function GUI:CreateToastContainer()
	if self.ToastContainer then
		self.ToastContainer:Destroy()
	end

	self.ToastContainer = createInstance("Frame", {
		Name = "ToastContainer",
		Size = UDim2.fromOffset(240, 260),
		Position = UDim2.new(1, -260, 0, 20),
		BackgroundTransparency = 1,
		ZIndex = 50,
		Parent = self.ScreenGui,
	})

	local layout = Instance.new("UIListLayout", self.ToastContainer)
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
end

function GUI:ShowToast(message, toastType, duration)
	if not self.ToastContainer then
		return
	end

	local theme = self:GetActiveTheme()
	local strokeColor = theme.Accent
	if toastType == "success" then
		strokeColor = theme.Success
	elseif toastType == "danger" or toastType == "error" then
		strokeColor = theme.Danger
	elseif toastType == "warning" then
		strokeColor = theme.Warning
	end

	local toast = createInstance("Frame", {
		Size = UDim2.new(1, 0, 0, 36),
		Position = UDim2.fromOffset(40, 0),
		BackgroundColor3 = theme.Header,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		ZIndex = 51,
		Parent = self.ToastContainer,
	})
	createCorner(6, toast)
	createStroke(strokeColor, 1.2, toast)

	local indicator = createInstance("Frame", {
		Size = UDim2.new(0, 4, 1, -12),
		Position = UDim2.new(0, 6, 0.5, -6),
		BackgroundColor3 = strokeColor,
		BorderSizePixel = 0,
		ZIndex = 52,
		Parent = toast,
	})
	createCorner(2, indicator)

	local label = createInstance("TextLabel", {
		Size = UDim2.new(1, -24, 1, 0),
		Position = UDim2.new(0, 16, 0, 0),
		BackgroundTransparency = 1,
		Text = message,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 52,
		Parent = toast,
	})

	-- Smooth slide-in
	toast.Position = UDim2.new(1, 40, 0, 0)
	TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0),
	}):Play()

	-- Auto-dismissal
	task.delay(duration or 2.5, function()
		if toast and toast.Parent then
			local fade = TweenService:Create(
				toast,
				TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
				{ Position = UDim2.new(1, 40, 0, 0), BackgroundTransparency = 1 }
			)
			fade:Play()
			fade.Completed:Connect(function()
				toast:Destroy()
			end)
		end
	end)
end

--[[------------------------------------------------------------------------------
    ScreenGui & Main Window Construction
--------------------------------------------------------------------------------]]

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

	self:CreateToastContainer()
end

function GUI:CreateMainInterface()
	local theme = self:GetActiveTheme()

	-- Window Dimensions
	local winWidth = 600
	local winHeight = 440

	local mainFrame = createInstance("Frame", {
		Name = "MainFrame",
		Size = UDim2.fromOffset(winWidth, winHeight),
		Position = UDim2.new(0.5, -winWidth / 2, 0.5, -winHeight / 2),
		BackgroundColor3 = theme.Main,
		BorderSizePixel = 0,
		Active = true,
		ClipsDescendants = true,
		Parent = self.ScreenGui,
	})
	createCorner(8, mainFrame)
	local mainStroke = createStroke(theme.Border, 1.2, mainFrame)

	self.MainFrame = mainFrame
	self.Elements.MainStroke = mainStroke
	table.insert(self.Elements.Frames, mainFrame)

	-- Custom Background Image
	local bgImage = createInstance("ImageLabel", {
		Name = "BackgroundImage",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = "",
		ImageTransparency = 0.85,
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 0,
		Parent = mainFrame,
	})
	self.Elements.BackgroundImage = bgImage

	-- Sidebar Navigation
	local sidebarWidth = 160
	local sidebar = createInstance("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, sidebarWidth, 1, 0),
		Position = UDim2.fromScale(0, 0),
		BackgroundColor3 = theme.Sidebar,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = mainFrame,
	})
	createCorner(8, sidebar)
	table.insert(self.Elements.Sidebars, sidebar)
	self.Elements.Sidebar = sidebar

	-- Sidebar Brand / Logo Header
	local brandBox = createInstance("Frame", {
		Name = "BrandBox",
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = sidebar,
	})

	local brandTitle = createInstance("TextLabel", {
		Name = "BrandTitle",
		Size = UDim2.new(1, -20, 0, 22),
		Position = UDim2.new(0, 16, 0, 12),
		BackgroundTransparency = 1,
		Text = "APEX SUITE",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = theme.Accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
		Parent = brandBox,
	})
	table.insert(self.Elements.Accents, brandTitle)

	local brandSubtitle = createInstance("TextLabel", {
		Name = "BrandSubtitle",
		Size = UDim2.new(1, -20, 0, 14),
		Position = UDim2.new(0, 16, 0, 32),
		BackgroundTransparency = 1,
		Text = "System Configuration",
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextColor3 = theme.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 4,
		Parent = brandBox,
	})
	table.insert(self.Elements.TextSecondary, brandSubtitle)

	-- Top Header Bar (Draggable & Window Controls)
	local headerBar = createInstance("Frame", {
		Name = "HeaderBar",
		Size = UDim2.new(1, -sidebarWidth, 0, 42),
		Position = UDim2.new(0, sidebarWidth, 0, 0),
		BackgroundColor3 = theme.Header,
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = mainFrame,
	})
	table.insert(self.Elements.Headers, headerBar)
	self.Elements.HeaderBar = headerBar

	-- Active Page Title Breadcrumb
	local pageTitle = createInstance("TextLabel", {
		Name = "PageTitle",
		Size = UDim2.new(1, -100, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = "AimBot Configuration",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 6,
		Parent = headerBar,
	})
	self.Elements.PageTitle = pageTitle
	table.insert(self.Elements.TextPrimary, pageTitle)

	-- Window Minimize & Close Action Buttons
	local minBtn = createInstance("TextButton", {
		Name = "MinBtn",
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.new(1, -56, 0.5, -12),
		BackgroundColor3 = theme.ControlBg,
		Text = "-",
		TextColor3 = theme.TextSecondary,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		ZIndex = 7,
		Parent = headerBar,
	})
	createCorner(4, minBtn)
	createStroke(theme.CardBorder, 1, minBtn)
	table.insert(self.Elements.ControlBackgrounds, minBtn)

	local closeBtn = createInstance("TextButton", {
		Name = "CloseBtn",
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.new(1, -28, 0.5, -12),
		BackgroundColor3 = theme.ControlBg,
		Text = "x",
		TextColor3 = theme.TextSecondary,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		ZIndex = 7,
		Parent = headerBar,
	})
	createCorner(4, closeBtn)
	createStroke(theme.CardBorder, 1, closeBtn)
	table.insert(self.Elements.ControlBackgrounds, closeBtn)

	-- Minimized floating Pill Button
	local openBtn = createInstance("TextButton", {
		Name = "OpenPillBtn",
		Size = UDim2.fromOffset(100, 32),
		Position = UDim2.new(1, -115, 0.5, -16),
		BackgroundColor3 = theme.Header,
		Text = "Open Menu",
		TextColor3 = theme.Accent,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		Visible = false,
		ZIndex = 20,
		Parent = self.ScreenGui,
	})
	createCorner(6, openBtn)
	createStroke(theme.Accent, 1.2, openBtn)
	self.OpenBtn = openBtn

	-- Minimize & Restore Animations
	local animTween = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

	minBtn.MouseButton1Click:Connect(function()
		local hideTween = TweenService:Create(mainFrame, animTween, {
			Position = UDim2.new(0.5, -winWidth / 2, 1.2, 0),
		})
		hideTween:Play()
		hideTween.Completed:Connect(function()
			mainFrame.Visible = false
			openBtn.Visible = true
			openBtn.Position = UDim2.new(1, 20, 0.5, -16)
			TweenService:Create(openBtn, animTween, { Position = UDim2.new(1, -115, 0.5, -16) }):Play()
		end)
	end)

	openBtn.MouseButton1Click:Connect(function()
		local hidePill = TweenService:Create(openBtn, animTween, { Position = UDim2.new(1, 20, 0.5, -16) })
		hidePill:Play()
		hidePill.Completed:Connect(function()
			openBtn.Visible = false
			mainFrame.Visible = true
			TweenService:Create(mainFrame, animTween, {
				Position = UDim2.new(0.5, -winWidth / 2, 0.5, -winHeight / 2),
			}):Play()
		end)
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
	tabLayout.Padding = UDim.new(0, 3)
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	self.Elements.TabContainer = tabContainer

	-- Search Bar Header within Content Area
	local searchContainer = createInstance("Frame", {
		Name = "SearchContainer",
		Size = UDim2.new(1, -sidebarWidth - 20, 0, 30),
		Position = UDim2.new(0, sidebarWidth + 10, 0, 48),
		BackgroundColor3 = theme.Card,
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = mainFrame,
	})
	createCorner(5, searchContainer)
	local searchStroke = createStroke(theme.CardBorder, 1, searchContainer)
	table.insert(self.Elements.Cards, searchContainer)
	table.insert(self.Elements.CardBorders, searchStroke)

	local searchIcon = createInstance("TextLabel", {
		Size = UDim2.fromOffset(24, 30),
		BackgroundTransparency = 1,
		Text = ">",
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = theme.TextSecondary,
		ZIndex = 5,
		Parent = searchContainer,
	})
	table.insert(self.Elements.TextSecondary, searchIcon)

	local searchBox = createInstance("TextBox", {
		Name = "SearchBox",
		Size = UDim2.new(1, -54, 1, 0),
		Position = UDim2.fromOffset(24, 0),
		BackgroundTransparency = 1,
		PlaceholderText = "Search settings...",
		PlaceholderColor3 = theme.TextSecondary,
		Text = "",
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = theme.Text,
		ClearTextOnFocus = false,
		ZIndex = 5,
		Parent = searchContainer,
	})
	table.insert(self.Elements.TextPrimary, searchBox)

	local clearBtn = createInstance("TextButton", {
		Size = UDim2.fromOffset(20, 20),
		Position = UDim2.new(1, -24, 0.5, -10),
		BackgroundTransparency = 1,
		Text = "x",
		TextColor3 = theme.TextSecondary,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		Visible = false,
		ZIndex = 5,
		Parent = searchContainer,
	})

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local query = string.lower(searchBox.Text)
		self.SearchQuery = query
		clearBtn.Visible = #query > 0
		self:FilterControls(query)
	end)

	clearBtn.MouseButton1Click:Connect(function()
		searchBox.Text = ""
	end)

	-- Content Area for Tab Pages
	local contentArea = createInstance("Frame", {
		Name = "ContentArea",
		Size = UDim2.new(1, -sidebarWidth - 20, 1, -116),
		Position = UDim2.new(0, sidebarWidth + 10, 0, 84),
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = mainFrame,
	})
	self.Elements.ContentArea = contentArea
end

--[[------------------------------------------------------------------------------
    Tab Generation & Navigation
--------------------------------------------------------------------------------]]

function GUI:CreateTabs()
	local categories = {
		{ Id = "Aimbot", Name = "AimBot", Icon = "crosshair", Title = "AimBot & Trajectory Engine" },
		{ Id = "TriggerBot", Name = "TriggerBot", Icon = "trigger", Title = "Universal TriggerBot Controls" },
		{ Id = "Visuals", Name = "Visuals & ESP", Icon = "eye", Title = "ESP & Sensory Visualization" },
		{ Id = "World", Name = "World & Visuals", Icon = "world", Title = "Environment, Themes & Colors" },
		{ Id = "AntiCheat", Name = "Security & Stealth", Icon = "shield", Title = "Anti-Detection & Throttling" },
		{ Id = "Settings", Name = "Settings & Profiles", Icon = "settings", Title = "Configuration Profiles & Hotkeys" },
	}

	for idx, cat in ipairs(categories) do
		local theme = self:GetActiveTheme()

		local btn = createInstance("TextButton", {
			Name = cat.Id .. "TabBtn",
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = theme.Sidebar,
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = idx,
			ZIndex = 4,
			Parent = self.Elements.TabContainer,
		})
		createCorner(5, btn)

		-- Active indicator left bar
		local indicator = createInstance("Frame", {
			Name = "ActiveIndicator",
			Size = UDim2.new(0, 3, 0.6, 0),
			Position = UDim2.new(0, 4, 0.2, 0),
			BackgroundColor3 = theme.Accent,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 5,
			Parent = btn,
		})
		createCorner(2, indicator)
		table.insert(self.Elements.Accents, indicator)

		-- Vector icon
		local iconFrame = createVectorIcon(cat.Icon, btn, 14, theme.TextSecondary)
		iconFrame.Position = UDim2.new(0, 14, 0.5, -7)
		iconFrame.ZIndex = 5

		-- Tab Title Label
		local label = createInstance("TextLabel", {
			Name = "TabLabel",
			Size = UDim2.new(1, -38, 1, 0),
			Position = UDim2.new(0, 36, 0, 0),
			BackgroundTransparency = 1,
			Text = cat.Name,
			Font = Enum.Font.GothamMedium,
			TextSize = 11,
			TextColor3 = theme.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 5,
			Parent = btn,
		})

		self.Elements.TabButtons[cat.Id] = {
			Button = btn,
			Indicator = indicator,
			Label = label,
			Icon = iconFrame,
			Title = cat.Title,
		}

		-- Scrollable Page for Tab Content
		local page = createInstance("ScrollingFrame", {
			Name = cat.Id .. "Page",
			Size = UDim2.fromScale(1, 1),
			Position = UDim2.fromScale(0, 0),
			BackgroundTransparency = 1,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = theme.CardBorder,
			Visible = false,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ZIndex = 4,
			Parent = self.Elements.ContentArea,
		})
		local listLayout = Instance.new("UIListLayout", page)
		listLayout.Padding = UDim.new(0, 8)
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		createPadding(2, 8, 2, 6, page)

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

function GUI:SwitchTab(tabId)
	local theme = self:GetActiveTheme()
	self.CurrentTab = tabId

	for id, tabData in pairs(self.Elements.TabButtons) do
		local page = self.Elements.TabPages[id]
		local isCurrent = (id == tabId)

		if isCurrent then
			tabData.Button.BackgroundTransparency = 0
			tabData.Button.BackgroundColor3 = theme.Card
			tabData.Indicator.Visible = true
			tabData.Label.TextColor3 = theme.Text
			tabData.Label.Font = Enum.Font.GothamBold

			if self.Elements.PageTitle then
				self.Elements.PageTitle.Text = tabData.Title
			end

			if page then
				page.Visible = true
			end
		else
			tabData.Button.BackgroundTransparency = 1
			tabData.Indicator.Visible = false
			tabData.Label.TextColor3 = theme.TextSecondary
			tabData.Label.Font = Enum.Font.GothamMedium

			if page then
				page.Visible = false
			end
		end
	end

	-- Re-apply search filter on tab switch
	if #self.SearchQuery > 0 then
		self:FilterControls(self.SearchQuery)
	end
end

-- Filter controls across current tab based on search query
function GUI:FilterControls(query)
	local currentPage = self.Elements.TabPages[self.CurrentTab]
	if not currentPage then
		return
	end

	for _, child in ipairs(currentPage:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("Card$") then
			if #query == 0 then
				child.Visible = true
			else
				local match = false
				local titleLabel = child:FindFirstChild("CardTitle")
				if titleLabel and string.find(string.lower(titleLabel.Text), query, 1, true) then
					match = true
				end

				-- Check child control labels
				for _, sub in ipairs(child:GetDescendants()) do
					if sub:IsA("TextLabel") and string.find(string.lower(sub.Text), query, 1, true) then
						match = true
						break
					end
				end
				child.Visible = match
			end
		end
	end
end

--[[------------------------------------------------------------------------------
    Control Component Builders (Section Cards, Switches, Sliders, Segments)
--------------------------------------------------------------------------------]]

-- Section Card: Groups related controls with clear surface hierarchy
function GUI:CreateSectionCard(page, titleText, descText)
	local theme = self:GetActiveTheme()

	local card = createInstance("Frame", {
		Name = titleText:gsub("%s+", "") .. "Card",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.Card,
		BorderSizePixel = 0,
		Parent = page,
	})
	createCorner(6, card)
	local cardStroke = createStroke(theme.CardBorder, 1, card)
	createPadding(10, 10, 12, 12, card)

	local cardLayout = Instance.new("UIListLayout", card)
	cardLayout.Padding = UDim.new(0, 8)
	cardLayout.SortOrder = Enum.SortOrder.LayoutOrder

	table.insert(self.Elements.Cards, card)
	table.insert(self.Elements.CardBorders, cardStroke)

	-- Header Box
	local headerBox = createInstance("Frame", {
		Name = "HeaderBox",
		Size = UDim2.new(1, 0, 0, descText and 26 or 16),
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		Parent = card,
	})

	local titleLabel = createInstance("TextLabel", {
		Name = "CardTitle",
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		Text = string.upper(titleText),
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextColor3 = theme.Accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = headerBox,
	})
	table.insert(self.Elements.Accents, titleLabel)

	if descText then
		local descLabel = createInstance("TextLabel", {
			Name = "CardDesc",
			Size = UDim2.new(1, 0, 0, 12),
			Position = UDim2.fromOffset(0, 14),
			BackgroundTransparency = 1,
			Text = descText,
			Font = Enum.Font.Gotham,
			TextSize = 9,
			TextColor3 = theme.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = headerBox,
		})
		table.insert(self.Elements.TextSecondary, descLabel)
	end

	return card
end

-- Animated Switch / Toggle
function GUI:CreateToggle(card, labelText, descText, configPath, callback)
	local cfg = self:GetConfigComponent()
	local theme = self:GetActiveTheme()

	local frame = createInstance("Frame", {
		Size = UDim2.new(1, 0, 0, descText and 36 or 26),
		BackgroundTransparency = 1,
		Parent = card,
	})

	local textContainer = createInstance("Frame", {
		Size = UDim2.new(1, -48, 1, 0),
		BackgroundTransparency = 1,
		Parent = frame,
	})

	local label = createInstance("TextLabel", {
		Size = UDim2.new(1, 0, 0, 15),
		Position = UDim2.fromOffset(0, descText and 1 or 5),
		BackgroundTransparency = 1,
		Text = labelText,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = textContainer,
	})
	table.insert(self.Elements.TextPrimary, label)

	if descText then
		local desc = createInstance("TextLabel", {
			Size = UDim2.new(1, 0, 0, 12),
			Position = UDim2.fromOffset(0, 17),
			BackgroundTransparency = 1,
			Text = descText,
			Font = Enum.Font.Gotham,
			TextSize = 9,
			TextColor3 = theme.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = textContainer,
		})
		table.insert(self.Elements.TextSecondary, desc)
	end

	local toggleBtn = createInstance("TextButton", {
		Size = UDim2.fromOffset(38, 20),
		Position = UDim2.new(1, -38, 0.5, -10),
		BackgroundColor3 = theme.ControlBg,
		Text = "",
		AutoButtonColor = false,
		Parent = frame,
	})
	createCorner(10, toggleBtn)
	local toggleStroke = createStroke(theme.CardBorder, 1, toggleBtn)

	local circle = createInstance("Frame", {
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0, 3, 0.5, -7),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = toggleBtn,
	})
	createCorner(7, circle)

	local function updateVisual(state)
		local activeColor = self:GetActiveTheme().Accent
		local offColor = self:GetActiveTheme().ControlBg
		TweenService:Create(toggleBtn, TweenInfo.new(0.18), {
			BackgroundColor3 = state and activeColor or offColor,
		}):Play()
		TweenService:Create(circle, TweenInfo.new(0.18), {
			Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
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

	table.insert(self.Elements.Toggles, {
		Button = toggleBtn,
		Stroke = toggleStroke,
		ConfigPath = configPath,
		Update = updateVisual,
	})

	return frame
end

-- Precision Slider: Dual-input scrub/seek with bounds clamping and units
function GUI:CreateSlider(card, labelText, descText, configPath, minVal, maxVal, isDecimal, unit, callback)
	local cfg = self:GetConfigComponent()
	local theme = self:GetActiveTheme()

	local frame = createInstance("Frame", {
		Size = UDim2.new(1, 0, 0, descText and 46 or 38),
		BackgroundTransparency = 1,
		Parent = card,
	})

	local topRow = createInstance("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Parent = frame,
	})

	local label = createInstance("TextLabel", {
		Size = UDim2.new(1, -70, 1, 0),
		BackgroundTransparency = 1,
		Text = labelText,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = topRow,
	})
	table.insert(self.Elements.TextPrimary, label)

	local currentVal = cfg and cfg:Get(configPath) or minVal
	local valuePill = createInstance("TextLabel", {
		Size = UDim2.fromOffset(60, 16),
		Position = UDim2.new(1, -60, 0, 0),
		BackgroundColor3 = theme.ControlBg,
		Text = tostring(currentVal) .. (unit or ""),
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextColor3 = theme.Accent,
		Parent = topRow,
	})
	createCorner(3, valuePill)
	table.insert(self.Elements.ControlBackgrounds, valuePill)
	table.insert(self.Elements.Accents, valuePill)

	local sliderTrack = createInstance("TextButton", {
		Size = UDim2.new(1, 0, 0, 6),
		Position = UDim2.new(0, 0, 1, -8),
		BackgroundColor3 = theme.ControlBg,
		Text = "",
		AutoButtonColor = false,
		Parent = frame,
	})
	createCorner(3, sliderTrack)
	table.insert(self.Elements.ControlBackgrounds, sliderTrack)

	local initialPct = math.clamp((currentVal - minVal) / (maxVal - minVal), 0, 1)
	local sliderFill = createInstance("Frame", {
		Size = UDim2.new(initialPct, 0, 1, 0),
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Parent = sliderTrack,
	})
	createCorner(3, sliderFill)
	table.insert(self.Elements.Accents, sliderFill)

	local thumb = createInstance("Frame", {
		Size = UDim2.fromOffset(12, 12),
		Position = UDim2.new(1, -6, 0.5, -6),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = sliderFill,
	})
	createCorner(6, thumb)

	local dragging = false
	local function updateSliderFromInput(input)
		local relX = input.Position.X - sliderTrack.AbsolutePosition.X
		local pct = math.clamp(relX / sliderTrack.AbsoluteSize.X, 0, 1)
		local rawVal = minVal + (pct * (maxVal - minVal))
		local finalVal = isDecimal and tonumber(string.format("%.2f", rawVal)) or math.floor(rawVal + 0.5)

		sliderFill.Size = UDim2.new(pct, 0, 1, 0)
		valuePill.Text = tostring(finalVal) .. (unit or "")

		if cfg then
			cfg:Set(configPath, finalVal)
		end
		if callback then
			callback(finalVal)
		end
	end

	sliderTrack.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			updateSliderFromInput(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			updateSliderFromInput(input)
		end
	end)

	table.insert(self.Elements.Sliders, {
		Fill = sliderFill,
		Pill = valuePill,
		ConfigPath = configPath,
		Min = minVal,
		Max = maxVal,
		Unit = unit,
	})

	return frame
end

-- Segmented Control: Replaces blind cyclers with visible, one-click choice buttons
function GUI:CreateSegmented(card, labelText, configPath, options, callback)
	local cfg = self:GetConfigComponent()
	local theme = self:GetActiveTheme()

	local frame = createInstance("Frame", {
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundTransparency = 1,
		Parent = card,
	})

	local label = createInstance("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Text = labelText,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	table.insert(self.Elements.TextPrimary, label)

	local group = createInstance("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		Position = UDim2.new(0, 0, 0, 20),
		BackgroundColor3 = theme.ControlBg,
		BorderSizePixel = 0,
		Parent = frame,
	})
	createCorner(4, group)
	table.insert(self.Elements.ControlBackgrounds, group)

	local btnCount = #options
	local buttons = {}
	local initialVal = tostring(cfg and cfg:Get(configPath) or options[1])

	local function updateSelection(selectedOpt)
		for opt, b in pairs(buttons) do
			local isSel = (opt == selectedOpt)
			local activeColor = self:GetActiveTheme().Accent
			local normColor = self:GetActiveTheme().ControlBg
			b.BackgroundColor3 = isSel and activeColor or normColor
			b.TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or self:GetActiveTheme().TextSecondary
		end
	end

	for i, opt in ipairs(options) do
		local optStr = tostring(opt)
		local optBtn = createInstance("TextButton", {
			Size = UDim2.new(1 / btnCount, -2, 1, -2),
			Position = UDim2.new((i - 1) / btnCount, 1, 0, 1),
			BackgroundColor3 = (optStr == initialVal) and theme.Accent or theme.ControlBg,
			Text = optStr,
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			TextColor3 = (optStr == initialVal) and Color3.fromRGB(255, 255, 255) or theme.TextSecondary,
			AutoButtonColor = false,
			Parent = group,
		})
		createCorner(3, optBtn)
		buttons[optStr] = optBtn

		optBtn.MouseButton1Click:Connect(function()
			if cfg then
				cfg:Set(configPath, opt)
			end
			updateSelection(optStr)
			if callback then
				callback(opt)
			end
		end)
	end

	table.insert(self.Elements.Segments, {
		Buttons = buttons,
		ConfigPath = configPath,
		Update = updateSelection,
	})

	return frame
end

-- Dropdown / Option Picker (for larger sets like Themes and Colors)
function GUI:CreateDropdown(card, labelText, configPath, options, callback)
	local cfg = self:GetConfigComponent()
	local theme = self:GetActiveTheme()

	local frame = createInstance("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		Parent = card,
	})

	local label = createInstance("TextLabel", {
		Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = labelText,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	table.insert(self.Elements.TextPrimary, label)

	local initial = tostring(cfg and cfg:Get(configPath) or options[1])
	local btn = createInstance("TextButton", {
		Size = UDim2.new(0.48, 0, 0, 24),
		Position = UDim2.new(0.52, 0, 0.5, -12),
		BackgroundColor3 = theme.ControlBg,
		Text = initial .. " v",
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextColor3 = theme.Text,
		AutoButtonColor = false,
		Parent = frame,
	})
	createCorner(4, btn)
	createStroke(theme.CardBorder, 1, btn)
	table.insert(self.Elements.ControlBackgrounds, btn)
	table.insert(self.Elements.TextPrimary, btn)

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
		btn.Text = tostring(nextOpt) .. " v"

		if cfg then
			cfg:Set(configPath, nextOpt)
		end
		if callback then
			callback(nextOpt)
		end
	end)

	return frame
end

-- Styled Text Input Box
function GUI:CreateTextInput(card, labelText, configPath, placeholder, callback)
	local cfg = self:GetConfigComponent()
	local theme = self:GetActiveTheme()

	local frame = createInstance("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		Parent = card,
	})

	local label = createInstance("TextLabel", {
		Size = UDim2.new(0.42, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = labelText,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	table.insert(self.Elements.TextPrimary, label)

	local initial = tostring(cfg and cfg:Get(configPath) or "")
	local box = createInstance("TextBox", {
		Size = UDim2.new(0.56, 0, 0, 24),
		Position = UDim2.new(0.44, 0, 0.5, -12),
		BackgroundColor3 = theme.ControlBg,
		Text = initial,
		PlaceholderText = placeholder or "Type here...",
		PlaceholderColor3 = theme.TextSecondary,
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextColor3 = theme.Text,
		ClearTextOnFocus = false,
		Parent = frame,
	})
	createCorner(4, box)
	local boxStroke = createStroke(theme.CardBorder, 1, box)
	table.insert(self.Elements.ControlBackgrounds, box)
	table.insert(self.Elements.TextPrimary, box)

	box.Focused:Connect(function()
		boxStroke.Color = self:GetActiveTheme().Accent
	end)

	box.FocusLost:Connect(function()
		boxStroke.Color = self:GetActiveTheme().CardBorder
		if cfg then
			cfg:Set(configPath, box.Text)
		end
		if callback then
			callback(box.Text)
		end
	end)

	return frame
end

-- Distinct Action Button: Primary (Accent), Secondary (Surface), Destructive (Danger)
function GUI:CreateActionButton(card, labelText, descText, btnText, variant, callback)
	local theme = self:GetActiveTheme()

	local frame = createInstance("Frame", {
		Size = UDim2.new(1, 0, 0, descText and 36 or 28),
		BackgroundTransparency = 1,
		Parent = card,
	})

	local textContainer = createInstance("Frame", {
		Size = UDim2.new(0.55, 0, 1, 0),
		BackgroundTransparency = 1,
		Parent = frame,
	})

	local label = createInstance("TextLabel", {
		Size = UDim2.new(1, 0, 0, 15),
		Position = UDim2.fromOffset(0, descText and 1 or 6),
		BackgroundTransparency = 1,
		Text = labelText,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = textContainer,
	})
	table.insert(self.Elements.TextPrimary, label)

	if descText then
		local desc = createInstance("TextLabel", {
			Size = UDim2.new(1, 0, 0, 12),
			Position = UDim2.fromOffset(0, 17),
			BackgroundTransparency = 1,
			Text = descText,
			Font = Enum.Font.Gotham,
			TextSize = 9,
			TextColor3 = theme.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = textContainer,
		})
		table.insert(self.Elements.TextSecondary, desc)
	end

	local btnBg = theme.Accent
	local btnTextCol = Color3.fromRGB(255, 255, 255)
	if variant == "secondary" then
		btnBg = theme.ControlBg
		btnTextCol = theme.Text
	elseif variant == "danger" then
		btnBg = theme.Danger
	end

	local btn = createInstance("TextButton", {
		Size = UDim2.new(0.42, 0, 0, 24),
		Position = UDim2.new(0.58, 0, 0.5, -12),
		BackgroundColor3 = btnBg,
		Text = btnText,
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextColor3 = btnTextCol,
		AutoButtonColor = true,
		Parent = frame,
	})
	createCorner(4, btn)

	if variant == "primary" then
		table.insert(self.Elements.Accents, btn)
	elseif variant == "secondary" then
		createStroke(theme.CardBorder, 1, btn)
		table.insert(self.Elements.ControlBackgrounds, btn)
	end

	btn.MouseButton1Click:Connect(function()
		if callback then
			callback()
		end
	end)

	return frame
end

--[[------------------------------------------------------------------------------
    Tab Population: Feature Set Organization into Cards
--------------------------------------------------------------------------------]]

function GUI:PopulateAimbotTab()
	local page = self.Elements.TabPages["Aimbot"]

	-- Card 1: Core Aim Engine
	local cardCore = self:CreateSectionCard(page, "Core Aim Engine", "Execution modes, snapping, and locking parameters")
	self:CreateToggle(cardCore, "Enable AimBot", "Master hardware and camera aimbot activation", "aimbot.enabled")
	self:CreateToggle(
		cardCore,
		"Aggressive Instant Snap",
		"Bypasses smoothing for instantaneous target acquisition",
		"aimbot.aggressiveMode"
	)
	self:CreateToggle(
		cardCore,
		"Sticky Aim Lock",
		"Maintains lock on current target until destroyed or occluded",
		"aimbot.aimLock"
	)
	self:CreateSegmented(
		cardCore,
		"Aim Execution Mode",
		"aimbot.aimMode",
		{ "Hybrid", "Camera", "Mouse" }
	)

	-- Card 2: Target Acquisition & Filters
	local cardAcq = self:CreateSectionCard(
		page,
		"Target Acquisition & Filters",
		"Part targeting, priority algorithms, and team isolation"
	)
	self:CreateSegmented(
		cardAcq,
		"Target Body Part",
		"aimbot.targetPart",
		{ "Head", "Torso", "Smart", "RootPart" },
		function(part)
			self:ShowToast("Target part set to: " .. tostring(part), "info")
		end
	)
	self:CreateSegmented(
		cardAcq,
		"Target Priority Mode",
		"aimbot.priorityMode",
		{ "Distance", "Health", "Threat", "Crosshair" }
	)
	self:CreateToggle(cardAcq, "Line-of-Sight Check", "Verifies raycast clearance before acquiring target", "aimbot.visibilityCheck")
	self:CreateToggle(cardAcq, "Team Filter Check", "Ignores players assigned to local player team", "aimbot.teamCheck")
	self:CreateToggle(cardAcq, "Target NPCs / Bots", "Acquires valid non-player humanoid characters", "aimbot.targetNPCs")

	-- Card 3: Dynamics & Tracking
	local cardDyn = self:CreateSectionCard(page, "Dynamics & Tracking", "Field-of-view limits, lerp smoothing, and trajectory prediction")
	self:CreateSlider(cardDyn, "Field of View (FOV)", nil, "aimbot.fov", 10, 180, false, " deg")
	self:CreateSlider(cardDyn, "Aim Smoothness", nil, "aimbot.smoothness", 1, 30, false, "x")
	self:CreateToggle(cardDyn, "Velocity Prediction", "Calculates target movement and velocity compensation", "aimbot.prediction")
	self:CreateToggle(cardDyn, "Display FOV Circle", "Renders field of view boundary circle", "aimbot.showFOV")
end

function GUI:PopulateTriggerBotTab()
	local page = self.Elements.TabPages["TriggerBot"]

	local cardTrigger = self:CreateSectionCard(
		page,
		"Automatic Trigger",
		"Fires instantly upon enemy crosshair alignment"
	)
	self:CreateToggle(cardTrigger, "Enable TriggerBot", "Master trigger activation", "triggerBot.enabled")
	self:CreateToggle(
		cardTrigger,
		"Require Equipped Tool",
		"Only triggers when holding a valid weapon or tool",
		"triggerBot.requireTool"
	)
	self:CreateToggle(cardTrigger, "Team Filter Check", "Prevents firing at teammates", "triggerBot.teamCheck")
	self:CreateToggle(cardTrigger, "Target NPCs / Bots", "Allows trigger detection on humanoid NPCs", "triggerBot.targetNPCs")

	local cardLimits = self:CreateSectionCard(page, "Timings & Distance", "Firing delays and operational distance boundaries")
	self:CreateSlider(cardLimits, "Trigger Delay", nil, "triggerBot.delay", 0.01, 0.50, true, "s")
	self:CreateSlider(cardLimits, "Maximum Distance", nil, "triggerBot.maxDistance", 100, 3000, false, " studs")
end

function GUI:PopulateVisualsTab()
	local page = self.Elements.TabPages["Visuals"]

	local cardFilter = self:CreateSectionCard(page, "Master Visuals & Filters", "Sensory perception activation and distance culling")
	self:CreateToggle(cardFilter, "Master ESP", "Master switch for all visual overlays", "esp.enabled")
	self:CreateToggle(cardFilter, "Render Teammates", "Visualizes friendly players", "esp.showTeammates")
	self:CreateToggle(cardFilter, "Target NPC Support", "Visualizes non-player humanoid entities", "esp.targetNPCs")
	self:CreateSlider(cardFilter, "Max Render Distance", nil, "esp.maxDistance", 100, 3000, false, " studs")

	local cardGeometry = self:CreateSectionCard(page, "Geometry & Character Rigs", "Projected boxes, skeletons, and head indicators")
	self:CreateToggle(cardGeometry, "Bounding Boxes", "Uninverting 3D-to-2D projected boxes", "esp.boxes")
	self:CreateSegmented(cardGeometry, "Bounding Box Style", "esp.boxType", { "2D", "Corner" })
	self:CreateToggle(cardGeometry, "Bone Skeletons", "Real-time joint tracking for R6 and R15 rigs", "esp.skeleton")
	self:CreateToggle(cardGeometry, "Precision Head Dot", "Precision marker placed on target heads", "esp.headDot")

	local cardTracers = self:CreateSectionCard(page, "Tracers & Snaplines", "Directional lines from viewport origin to target")
	self:CreateToggle(cardTracers, "Enable Tracers", "Draws snapline to tracked entities", "esp.tracers")
	self:CreateSegmented(cardTracers, "Tracer Origin", "esp.tracerOrigin", { "Bottom", "Center", "Top" })

	local cardInfo = self:CreateSectionCard(page, "HUD Information Overlays", "Health indicators, player names, and inventory status")
	self:CreateToggle(cardInfo, "Health Bars", "Vertical dynamic health bar indicator", "esp.healthBars")
	self:CreateToggle(cardInfo, "Numeric Health Text", "Displays numeric HP values", "esp.healthText")
	self:CreateToggle(cardInfo, "Player Names & Tags", "Displays user handle and display names", "esp.names")
	self:CreateToggle(cardInfo, "Distance Display", "Displays metric distance in studs", "esp.distance")
	self:CreateToggle(cardInfo, "Equipped Weapon Display", "Displays currently equipped weapon name", "esp.weapons")
end

function GUI:PopulateWorldTab()
	local page = self.Elements.TabPages["World"]

	local cardColors = self:CreateSectionCard(page, "Entity Color Presets", "Configures team and hostile color palettes")
	self:CreateDropdown(
		cardColors,
		"Hostile Entity Preset",
		"esp.enemyColor",
		{ "Red", "Green", "Blue", "Purple", "Yellow", "White" }
	)
	self:CreateDropdown(
		cardColors,
		"Friendly Team Preset",
		"esp.teamColor",
		{ "Blue", "Green", "Yellow", "Purple", "Red", "White" }
	)

	local cardXray = self:CreateSectionCard(page, "World X-Ray & Penetration", "Material transparency and map geometry penetration")
	self:CreateToggle(cardXray, "X-Ray Wall Penetration", "Makes occluding geometry translucent", "world.xrayEnabled")
	self:CreateSlider(cardXray, "X-Ray Opacity Factor", nil, "world.xrayOpacity", 0.1, 0.9, true)

	local cardTheme = self:CreateSectionCard(page, "Interface Customization", "Window theme tokens and custom wallpaper")
	local themes = { "Default", "Ruby", "Ocean", "Midnight", "Forest", "Light", "Blue" }
	self:CreateDropdown(cardTheme, "UI Theme Palette", "world.theme", themes, function(newTheme)
		self:ApplyTheme()
		self:ShowToast("Theme switched to: " .. tostring(newTheme), "info")
	end)

	self:CreateTextInput(
		cardTheme,
		"Custom Wallpaper (Asset/URL)",
		"world.bgImage",
		"rbxassetid:// or URL...",
		function(val)
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
		end
	)
	self:CreateSlider(
		cardTheme,
		"Wallpaper Transparency",
		nil,
		"world.bgTransparency",
		0,
		1,
		true,
		nil,
		function(val)
			self.Elements.BackgroundImage.ImageTransparency = val
		end
	)
end

function GUI:PopulateAntiCheatTab()
	local page = self.Elements.TabPages["AntiCheat"]

	local cardAnti = self:CreateSectionCard(
		page,
		"Anti-Detection Protocols",
		"Humanized input trajectories and security isolation"
	)
	self:CreateToggle(
		cardAnti,
		"Enable Anti-Detection",
		"Activates humanized motion curves and rate limiters",
		"antiDetection.enabled"
	)
	self:CreateToggle(
		cardAnti,
		"Humanized Mouse Curves",
		"Bezier trajectory and micro-jitter simulation",
		"antiDetection.humanization"
	)
	self:CreateToggle(
		cardAnti,
		"Stealth Mode",
		"Disables visible reticles for clean screen recordings",
		"antiDetection.stealthMode"
	)

	local cardThrottle = self:CreateSectionCard(
		page,
		"Input Throttling & Limits",
		"Rate limiting to bypass client heuristics"
	)
	self:CreateSlider(
		cardThrottle,
		"Max Actions Per Second",
		nil,
		"antiDetection.maxActionsPerSecond",
		10,
		60,
		false,
		"/s"
	)
	self:CreateToggle(
		cardThrottle,
		"Optimize Rendering Pipeline",
		"Throttles off-screen visual calculations",
		"performance.optimizeRendering"
	)
end

function GUI:PopulateSettingsTab()
	local page = self.Elements.TabPages["Settings"]
	local cfg = self:GetConfigComponent()

	local cardProfile = self:CreateSectionCard(
		page,
		"Profile Management",
		"Save, restore, or reset settings on persistent storage"
	)
	self:CreateActionButton(
		cardProfile,
		"Save Configuration Profile",
		"Writes current configuration to executor storage",
		"Save Profile",
		"primary",
		function()
			if cfg then
				cfg:Save("default")
				self:ShowToast("Configuration profile saved successfully", "success")
			end
		end
	)

	self:CreateActionButton(
		cardProfile,
		"Load Configuration Profile",
		"Restores configuration from saved profile",
		"Load Profile",
		"secondary",
		function()
			if cfg then
				cfg:Load("default")
				self:ApplyTheme()
				self:ShowToast("Configuration profile loaded successfully", "success")
			end
		end
	)

	self:CreateActionButton(
		cardProfile,
		"Restore Factory Defaults",
		"Resets all values to pristine default schema",
		"Reset Defaults",
		"danger",
		function()
			if cfg then
				cfg:Reset()
				self:ApplyTheme()
				self:ShowToast("All settings restored to factory defaults", "warning")
			end
		end
	)

	local cardLifecycle = self:CreateSectionCard(
		page,
		"Script Lifecycle",
		"Clean instance teardown and connection disconnection"
	)
	self:CreateActionButton(
		cardLifecycle,
		"Emergency Script Unload",
		"Disconnects all loops and unloads all GUI elements",
		"Unload Script",
		"danger",
		function()
			local genv = getGlobalEnv()
			if genv.AimbotESP and genv.AimbotESP.Unload then
				self:ShowToast("Unloading suite and restoring clean state...", "warning")
				task.wait(0.2)
				genv.AimbotESP:Unload()
			end
		end
	)

	local cardHotkeys = self:CreateSectionCard(
		page,
		"Centralized Hotkey Reference",
		"Keyboard shortcuts for instant feature toggling"
	)
	local hotkeys = {
		{ Key = "INSERT / RightShift", Action = "Toggle Configuration Menu" },
		{ Key = "F1", Action = "Toggle AimBot Master" },
		{ Key = "F2", Action = "Toggle ESP Visuals" },
		{ Key = "F3", Action = "Toggle Player Tracers" },
		{ Key = "F4", Action = "Cycle Aim Target Part" },
		{ Key = "DELETE", Action = "Emergency Disable All Features" },
	}

	for _, hk in ipairs(hotkeys) do
		local row = createInstance("Frame", {
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Parent = cardHotkeys,
		})
		local keyBadge = createInstance("TextLabel", {
			Size = UDim2.fromOffset(110, 18),
			BackgroundColor3 = self:GetActiveTheme().ControlBg,
			Text = hk.Key,
			Font = Enum.Font.GothamBold,
			TextSize = 9,
			TextColor3 = self:GetActiveTheme().Accent,
			Parent = row,
		})
		createCorner(3, keyBadge)
		table.insert(self.Elements.ControlBackgrounds, keyBadge)
		table.insert(self.Elements.Accents, keyBadge)

		local actionLabel = createInstance("TextLabel", {
			Size = UDim2.new(1, -120, 1, 0),
			Position = UDim2.fromOffset(118, 0),
			BackgroundTransparency = 1,
			Text = hk.Action,
			Font = Enum.Font.GothamMedium,
			TextSize = 10,
			TextColor3 = self:GetActiveTheme().TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		table.insert(self.Elements.TextSecondary, actionLabel)
	end
end

--[[------------------------------------------------------------------------------
    Real-Time Diagnostic Status Bar
--------------------------------------------------------------------------------]]

function GUI:CreateStatusBar()
	local theme = self:GetActiveTheme()

	local statusBar = createInstance("Frame", {
		Name = "StatusBar",
		Size = UDim2.new(1, -160, 0, 28),
		Position = UDim2.new(0, 160, 1, -28),
		BackgroundColor3 = theme.Header,
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = self.MainFrame,
	})
	table.insert(self.Elements.Headers, statusBar)

	local statusDot = createInstance("Frame", {
		Name = "StatusDot",
		Size = UDim2.fromOffset(8, 8),
		Position = UDim2.new(0, 12, 0.5, -4),
		BackgroundColor3 = theme.Success,
		BorderSizePixel = 0,
		ZIndex = 6,
		Parent = statusBar,
	})
	createCorner(4, statusDot)
	self.Elements.StatusDot = statusDot

	local statusText = createInstance("TextLabel", {
		Name = "StatusText",
		Size = UDim2.new(1, -30, 1, 0),
		Position = UDim2.new(0, 26, 0, 0),
		BackgroundTransparency = 1,
		Text = "Ready • AIM: OFF • TRIG: OFF • ESP: OFF",
		Font = Enum.Font.GothamMedium,
		TextSize = 10,
		TextColor3 = theme.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 6,
		Parent = statusBar,
	})
	self.Elements.StatusText = statusText
	table.insert(self.Elements.TextSecondary, statusText)
end

--[[------------------------------------------------------------------------------
    Dynamic Theming Engine (Ensures WCAG AA Contrast Compliance)
--------------------------------------------------------------------------------]]

function GUI:ApplyTheme()
	local theme = self:GetActiveTheme()

	if self.MainFrame then
		self.MainFrame.BackgroundColor3 = theme.Main
	end
	if self.Elements.MainStroke then
		self.Elements.MainStroke.Color = theme.Border
	end

	for _, frame in ipairs(self.Elements.Sidebars) do
		frame.BackgroundColor3 = theme.Sidebar
	end
	for _, frame in ipairs(self.Elements.Headers) do
		frame.BackgroundColor3 = theme.Header
	end
	for _, card in ipairs(self.Elements.Cards) do
		card.BackgroundColor3 = theme.Card
	end
	for _, stroke in ipairs(self.Elements.CardBorders) do
		stroke.Color = theme.CardBorder
	end
	for _, text in ipairs(self.Elements.TextPrimary) do
		text.TextColor3 = theme.Text
	end
	for _, text in ipairs(self.Elements.TextSecondary) do
		text.TextColor3 = theme.TextSecondary
	end

	for _, elem in ipairs(self.Elements.ControlBackgrounds) do
		elem.BackgroundColor3 = theme.ControlBg
	end

	for _, elem in ipairs(self.Elements.Accents) do
		if elem:IsA("TextLabel") or elem:IsA("TextButton") then
			elem.TextColor3 = theme.Accent
		elseif elem:IsA("Frame") then
			elem.BackgroundColor3 = theme.Accent
		end
	end

	-- Update toggles
	for _, t in ipairs(self.Elements.Toggles) do
		local cfg = self:GetConfigComponent()
		local state = cfg and cfg:Get(t.ConfigPath) or false
		t.Update(state)
		if t.Stroke then
			t.Stroke.Color = theme.CardBorder
		end
	end

	-- Update sliders
	for _, s in ipairs(self.Elements.Sliders) do
		local cfg = self:GetConfigComponent()
		local val = cfg and cfg:Get(s.ConfigPath) or s.Min
		local pct = math.clamp((val - s.Min) / (s.Max - s.Min), 0, 1)
		s.Fill.Size = UDim2.new(pct, 0, 1, 0)
		s.Fill.BackgroundColor3 = theme.Accent
		s.Pill.Text = tostring(val) .. (s.Unit or "")
		s.Pill.TextColor3 = theme.Accent
		s.Pill.BackgroundColor3 = theme.ControlBg
	end

	-- Update segmented controls
	for _, seg in ipairs(self.Elements.Segments) do
		local cfg = self:GetConfigComponent()
		local cur = tostring(cfg and cfg:Get(seg.ConfigPath) or "")
		seg.Update(cur)
	end

	-- Re-highlight current active tab button
	self:SwitchTab(self.CurrentTab)
end

--[[------------------------------------------------------------------------------
    Viewport Clamping & Dragging Setup
--------------------------------------------------------------------------------]]

function GUI:SetupDragging()
	local dragging = false
	local dragStart = nil
	local startPos = nil

	local header = self.Elements.HeaderBar or self.MainFrame
	header.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			dragStart = input.Position
			startPos = self.MainFrame.Position
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local delta = input.Position - dragStart
			local winWidth = self.MainFrame.AbsoluteSize.X
			local winHeight = self.MainFrame.AbsoluteSize.Y
			local viewport = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)

			local newOffsetX = startPos.X.Offset + delta.X
			local newOffsetY = startPos.Y.Offset + delta.Y

			-- Screen boundary clamping to prevent window loss
			local screenPosX = (startPos.X.Scale * viewport.X) + newOffsetX
			local screenPosY = (startPos.Y.Scale * viewport.Y) + newOffsetY

			local clampedScreenX = math.clamp(screenPosX, 0, math.max(0, viewport.X - winWidth))
			local clampedScreenY = math.clamp(screenPosY, 0, math.max(0, viewport.Y - winHeight))

			self.MainFrame.Position = UDim2.fromOffset(clampedScreenX, clampedScreenY)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)
end

--[[------------------------------------------------------------------------------
    Centralized Hotkeys with Visual Toast Feedback
--------------------------------------------------------------------------------]]

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

		-- Menu Toggle: INSERT or RightShift
		if input.KeyCode == Enum.KeyCode.Insert or input.KeyCode == Enum.KeyCode.RightShift then
			self:SetVisible(not self.IsVisible)
		end

		-- Aimbot Toggle: F1
		if input.KeyCode == Enum.KeyCode.F1 and cfg then
			local state = cfg:Toggle("aimbot.enabled")
			self:ShowToast("AimBot toggled: " .. (state and "ON" or "OFF"), state and "success" or "info")
		end

		-- ESP Toggle: F2
		if input.KeyCode == Enum.KeyCode.F2 and cfg then
			local state = cfg:Toggle("esp.enabled")
			self:ShowToast("ESP toggled: " .. (state and "ON" or "OFF"), state and "success" or "info")
		end

		-- Tracers Toggle: F3
		if input.KeyCode == Enum.KeyCode.F3 and cfg then
			local state = cfg:Toggle("esp.tracers")
			self:ShowToast("Tracers toggled: " .. (state and "ON" or "OFF"), state and "success" or "info")
		end

		-- Target Part Cycle: F4 (Head -> Torso -> Smart -> RootPart)
		if input.KeyCode == Enum.KeyCode.F4 and cfg then
			local parts = { "Head", "Torso", "Smart", "RootPart" }
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
			self:ShowToast("Target part cycled to: " .. nextPart, "info")
		end

		-- Emergency Kill Switch: DELETE
		if input.KeyCode == Enum.KeyCode.Delete then
			if genv.AimbotESP and genv.AimbotESP.State then
				genv.AimbotESP.State.EmergencyDisabled = not genv.AimbotESP.State.EmergencyDisabled
				local isEm = genv.AimbotESP.State.EmergencyDisabled
				if isEm then
					self:ShowToast("EMERGENCY KILL SWITCH ACTIVATED", "danger", 4.0)
				else
					self:ShowToast("Emergency kill switch deactivated", "success", 3.0)
				end
			end
		end
	end)

	table.insert(self.KeybindConnections, conn)
end

--[[------------------------------------------------------------------------------
    Visibility, Diagnostic Update & Lifecycle
--------------------------------------------------------------------------------]]

function GUI:SetVisible(visible)
	self.IsVisible = visible
	if self.MainFrame then
		self.MainFrame.Visible = visible
	end
	if not visible and self.OpenBtn then
		self.OpenBtn.Visible = false
	end
end

function GUI:UpdateStatus()
	if not self.Elements.StatusText then
		return
	end

	local genv = getGlobalEnv()
	local cfg = self:GetConfigComponent()
	local theme = self:GetActiveTheme()

	if genv.AimbotESP and genv.AimbotESP.State and genv.AimbotESP.State.EmergencyDisabled then
		self.Elements.StatusText.Text = "EMERGENCY DISABLED (Press DELETE to restore)"
		self.Elements.StatusText.TextColor3 = theme.Danger
		if self.Elements.StatusDot then
			self.Elements.StatusDot.BackgroundColor3 = theme.Danger
		end
		return
	end

	if self.Elements.StatusDot then
		self.Elements.StatusDot.BackgroundColor3 = theme.Success
	end

	local aimStatus = (cfg and cfg:Get("aimbot.enabled")) and "ON" or "OFF"
	local espStatus = (cfg and cfg:Get("esp.enabled")) and "ON" or "OFF"
	local trigStatus = (cfg and cfg:Get("triggerBot.enabled")) and "ON" or "OFF"

	local aimbotComp = genv.AimbotESP and genv.AimbotESP.Components and genv.AimbotESP.Components.Aimbot
	local targetInfo = aimbotComp and aimbotComp:GetCurrentTargetInfo()

	local statusStr = string.format("Ready • AIM: %s • TRIG: %s • ESP: %s", aimStatus, trigStatus, espStatus)
	if targetInfo then
		statusStr = statusStr .. string.format(" • Locked: %s [%dm]", targetInfo.name, targetInfo.distance)
	end

	self.Elements.StatusText.Text = statusStr
	self.Elements.StatusText.TextColor3 = theme.TextSecondary
end

function GUI:Update()
	if self.IsVisible then
		self:UpdateStatus()
	end
end

function GUI:Initialize()
	self:CreateScreenGui()
	self:CreateMainInterface()
	self:CreateTabs()
	self:CreateStatusBar()
	self:SetupDragging()
	self:SetupHotkeys()
	self:ApplyTheme()
	self:SetVisible(true)
	print("[GUI] APEX SUITE v2.2 initialized successfully")
end

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
	self.ToastContainer = nil
	self.Elements = {
		Frames = {},
		Sidebars = {},
		Headers = {},
		Cards = {},
		CardBorders = {},
		TextPrimary = {},
		TextSecondary = {},
		Accents = {},
		ControlBackgrounds = {},
		ControlBorders = {},
		TabButtons = {},
		TabPages = {},
		Toggles = {},
		Sliders = {},
		Segments = {},
		StatusDots = {},
	}
	self.IsVisible = false
end

return GUI
