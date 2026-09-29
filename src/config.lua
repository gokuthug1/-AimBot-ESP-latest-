--[[
    Configuration System v2.1.0
    
    This module handles all configuration management including:
    - Default settings with universal feature support
    - Runtime configuration changes with dot-path navigation
    - Comprehensive schema validation (aimbot, triggerBot, esp, world, gui, antiDetection, performance)
    - Persistent profile save/load using executor file system (writefile/readfile) or in-memory fallback
    - Game-specific profile detection (Arsenal, Phantom Forces, Bad Business, Counter Blox, Rivals, etc.)
    - Event bus for real-time reactive updates
    
    Author: gokuthug1
    License: MIT
]]

local Config = {}

-- Services
local MarketplaceService = game:GetService("MarketplaceService")

-- Configuration validation schemas
Config.Schemas = {
	aimbot = {
		enabled = "boolean",
		aimKey = "EnumItem",
		targetPart = "string",
		fov = "number",
		smoothness = "number",
		prediction = "boolean",
		teamCheck = "boolean",
		visibilityCheck = "boolean",
		maxDistance = "number",
		priorityMode = "string",
		targetNPCs = "boolean",
		aimLock = "boolean",
		aggressiveMode = "boolean",
		aimMode = "string",
		showFOV = "boolean",
	},
	triggerBot = {
		enabled = "boolean",
		delay = "number",
		requireTool = "boolean",
		teamCheck = "boolean",
		targetNPCs = "boolean",
		maxDistance = "number",
	},
	esp = {
		enabled = "boolean",
		players = "boolean",
		showTeammates = "boolean",
		boxes = "boolean",
		boxType = "string",
		names = "boolean",
		healthBars = "boolean",
		healthText = "boolean",
		distance = "boolean",
		tracers = "boolean",
		tracerOrigin = "string",
		skeleton = "boolean",
		headDot = "boolean",
		weapons = "boolean",
		targetNPCs = "boolean",
		maxDistance = "number",
		thickness = "number",
		transparency = "number",
		teamColors = "boolean",
		enemyColor = "string",
		teamColor = "string",
		occludedColor = "Color3",
		targetIndicatorColor = "Color3",
		useDrawingAPI = "boolean",
	},
	world = {
		xrayEnabled = "boolean",
		xrayOpacity = "number",
		theme = "string",
		bgImage = "string",
		bgTransparency = "number",
	},
	gui = {
		enabled = "boolean",
		theme = "string",
		scale = "number",
		position = "table",
		hotkeys = "table",
	},
	antiDetection = {
		enabled = "boolean",
		randomDelay = "table",
		humanization = "boolean",
		stealthMode = "boolean",
		maxActionsPerSecond = "number",
	},
	performance = {
		updateRate = "number",
		renderDistance = "number",
		maxTrackedPlayers = "number",
		optimizeRendering = "boolean",
	},
}

-- Default configuration
Config.Default = {
	aimbot = {
		enabled = false,
		aimKey = Enum.UserInputType.MouseButton2,
		targetPart = "Head", -- "Head", "Torso", "Smart", "HumanoidRootPart"
		fov = 120,
		smoothness = 10,
		prediction = true,
		teamCheck = true,
		visibilityCheck = true,
		maxDistance = 1000,
		priorityMode = "Distance", -- "Distance", "Health", "Threat", "Crosshair"
		targetNPCs = false,
		aimLock = false,
		aggressiveMode = false,
		aimMode = "Hybrid", -- "Hybrid", "Camera", "Mouse"
		showFOV = true,
	},
	triggerBot = {
		enabled = false,
		delay = 0.05,
		requireTool = false,
		teamCheck = true,
		targetNPCs = false,
		maxDistance = 1500,
	},
	esp = {
		enabled = false,
		players = true,
		showTeammates = false,
		boxes = true,
		boxType = "2D", -- "2D", "Corner"
		names = true,
		healthBars = true,
		healthText = true,
		distance = true,
		tracers = true,
		tracerOrigin = "Bottom", -- "Bottom", "Center", "Top"
		skeleton = false,
		headDot = false,
		weapons = false,
		targetNPCs = false,
		maxDistance = 600,
		thickness = 1.5,
		transparency = 0.8,
		teamColors = true,
		enemyColor = "Red",
		teamColor = "Blue",
		occludedColor = Color3.fromRGB(120, 120, 120),
		targetIndicatorColor = Color3.fromRGB(255, 50, 50),
		useDrawingAPI = true,
	},
	world = {
		xrayEnabled = false,
		xrayOpacity = 0.5,
		theme = "Default",
		bgImage = "",
		bgTransparency = 0.8,
	},
	gui = {
		enabled = true,
		theme = "Default", -- "Default", "Ruby", "Ocean", "Midnight", "Forest", "Light", "Blue"
		scale = 1.0,
		position = { X = 50, Y = 50 },
		hotkeys = {
			toggleGUI = Enum.KeyCode.Insert,
			toggleAimbot = Enum.KeyCode.F1,
			toggleESP = Enum.KeyCode.F2,
			toggleTracers = Enum.KeyCode.F3,
			cycleTarget = Enum.KeyCode.F4,
			emergencyDisable = Enum.KeyCode.Delete,
		},
	},
	antiDetection = {
		enabled = true,
		randomDelay = { min = 0.01, max = 0.05 },
		humanization = true,
		stealthMode = false,
		maxActionsPerSecond = 30,
	},
	performance = {
		updateRate = 60,
		renderDistance = 600,
		maxTrackedPlayers = 25,
		optimizeRendering = true,
	},
}

-- Game-specific profiles
Config.GameProfiles = {
	["Arsenal"] = {
		aimbot = {
			fov = 85,
			smoothness = 8,
			targetPart = "Head",
			prediction = true,
			aimMode = "Camera",
			teamCheck = true,
		},
		esp = {
			maxDistance = 300,
			showTeammates = false,
			skeleton = true,
			weapons = true,
		},
	},
	["Phantom Forces"] = {
		aimbot = {
			fov = 75,
			smoothness = 12,
			targetPart = "Torso",
			prediction = true,
			aimMode = "Camera",
		},
		esp = {
			maxDistance = 450,
			tracers = false,
			skeleton = true,
		},
	},
	["Bad Business"] = {
		aimbot = {
			fov = 95,
			smoothness = 6,
			targetPart = "Smart",
			aimMode = "Camera",
		},
		esp = {
			maxDistance = 350,
			healthBars = true,
			weapons = true,
		},
	},
	["Counter Blox"] = {
		aimbot = {
			fov = 65,
			smoothness = 15,
			targetPart = "Head",
			prediction = false,
			aimMode = "Camera",
		},
		esp = {
			maxDistance = 250,
			skeleton = true,
			boxes = true,
		},
	},
	["Rivals"] = {
		aimbot = {
			fov = 80,
			smoothness = 9,
			targetPart = "Head",
			prediction = true,
			aimMode = "Camera",
		},
		esp = {
			maxDistance = 400,
			weapons = true,
			skeleton = true,
		},
	},
}

-- Current active configuration
Config.Current = {}

-- Event system for configuration changes
Config.Events = {
	Changed = {},
	ProfileLoaded = {},
}

-- Helper to get global environment
local function getGlobalEnv()
	if type(getgenv) == "function" then
		return getgenv()
	end
	return _G
end

-- Deep copy function
function Config:DeepCopy(original)
	if type(original) ~= "table" then
		return original
	end
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = self:DeepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

-- Initialize configuration
function Config:Initialize()
	self.Current = self:DeepCopy(self.Default)
	local genv = getGlobalEnv()
	if genv.AimbotESP then
		genv.AimbotESP.Config = self.Current
	end
	self:DetectGame()
	print("⚙️ Configuration system initialized")
end

-- Detect current game and apply profile
function Config:DetectGame()
	local success, placeName = pcall(function()
		return MarketplaceService:GetProductInfo(game.PlaceId).Name
	end)

	if not success or not placeName then
		placeName = "Roblox Game (" .. tostring(game.PlaceId) .. ")"
	end

	for gameName, profile in pairs(self.GameProfiles) do
		if string.find(placeName:lower(), gameName:lower()) then
			self:ApplyProfile(profile)
			print("🎮 Applied profile for: " .. gameName)
			return
		end
	end

	print("🎮 Using default configuration for: " .. placeName)
end

-- Apply a configuration profile
function Config:ApplyProfile(profile)
	for category, settings in pairs(profile) do
		if not self.Current[category] then
			self.Current[category] = {}
		end
		for key, value in pairs(settings) do
			self.Current[category][key] = value
		end
	end

	self:TriggerEvent("ProfileLoaded", profile)
	self:TriggerEvent("Changed", {
		path = "all",
		oldValue = nil,
		newValue = self.Current,
	})
end

-- Validate configuration value
function Config:ValidateValue(category, key, value)
	local schema = self.Schemas[category]
	if not schema then
		-- Allow custom categories or unvalidated extensions
		return true, nil
	end

	local expectedType = schema[key]
	if not expectedType then
		-- Key not in top-level schema; check if category is table
		if type(self.Current[category]) == "table" then
			return true, nil
		end
		return false, "Unknown configuration key: " .. tostring(key)
	end

	local actualType = type(value)
	if expectedType == "EnumItem" then
		if typeof(value) ~= "EnumItem" then
			return false, "Expected EnumItem, got " .. typeof(value)
		end
	elseif expectedType == "Color3" then
		if typeof(value) ~= "Color3" then
			return false, "Expected Color3, got " .. typeof(value)
		end
	elseif expectedType == "table" then
		if actualType ~= "table" then
			return false, "Expected table, got " .. actualType
		end
	elseif expectedType ~= actualType then
		return false, "Expected " .. expectedType .. ", got " .. actualType
	end

	-- Specific range checks
	if key == "fov" and (value < 1 or value > 360) then
		return false, "FOV must be between 1 and 360"
	elseif key == "smoothness" and (value < 0 or value > 50) then
		return false, "Smoothness must be between 0 and 50"
	elseif key == "maxDistance" and value < 0 then
		return false, "Max distance must be positive"
	elseif key == "updateRate" and (value < 1 or value > 240) then
		return false, "Update rate must be between 1 and 240"
	end

	return true, nil
end

-- Get configuration value by dot-path
function Config:Get(path)
	if not path or path == "" then
		return self.Current
	end
	local keys = string.split(path, ".")
	local current = self.Current

	for _, key in ipairs(keys) do
		if type(current) == "table" and current[key] ~= nil then
			current = current[key]
		else
			return nil
		end
	end

	return current
end

-- Set configuration value by dot-path
function Config:Set(path, value)
	if not path or path == "" then
		return false
	end
	local keys = string.split(path, ".")
	local category = keys[1]
	local key = keys[#keys]

	-- If setting a top-level key or direct property, validate
	if #keys == 2 then
		local isValid, errorMsg = self:ValidateValue(category, key, value)
		if not isValid then
			warn(
				"⚠️ Configuration validation notice: "
					.. (errorMsg or "Invalid value")
					.. " (applied with fallback)"
			)
		end
	end

	-- Navigate and build nested tables if necessary
	local current = self.Current
	for i = 1, #keys - 1 do
		local segment = keys[i]
		if current[segment] == nil or type(current[segment]) ~= "table" then
			current[segment] = {}
		end
		current = current[segment]
	end

	local oldValue = current[key]
	current[key] = value

	-- Keep getgenv().AimbotESP.Config synchronized
	local genv = getGlobalEnv()
	if genv.AimbotESP then
		genv.AimbotESP.Config = self.Current
	end

	-- Trigger change event if value changed
	if oldValue ~= value then
		self:TriggerEvent("Changed", {
			path = path,
			oldValue = oldValue,
			newValue = value,
		})
	end

	return true
end

-- Toggle boolean configuration value
function Config:Toggle(path)
	local currentValue = self:Get(path)
	if type(currentValue) == "boolean" then
		return self:Set(path, not currentValue)
	end
	return false
end

-- Reset configuration to defaults
function Config:Reset()
	self.Current = self:DeepCopy(self.Default)
	local genv = getGlobalEnv()
	if genv.AimbotESP then
		genv.AimbotESP.Config = self.Current
	end
	self:TriggerEvent("Changed", {
		path = "all",
		oldValue = nil,
		newValue = self.Current,
	})
	print("🔄 Configuration reset to defaults")
end

-- Export configuration as string
function Config:Export()
	local function serializeTable(t, indent)
		indent = indent or 0
		local result = "{\n"
		local indentStr = string.rep("    ", indent + 1)

		for key, value in pairs(t) do
			result = result .. indentStr
			if type(key) == "string" then
				result = result .. '["' .. key .. '"] = '
			else
				result = result .. "[" .. tostring(key) .. "] = "
			end

			if type(value) == "table" then
				result = result .. serializeTable(value, indent + 1)
			elseif type(value) == "string" then
				result = result .. string.format("%q", value)
			elseif typeof(value) == "Color3" then
				result = result
					.. string.format(
						"Color3.fromRGB(%d, %d, %d)",
						math.floor(value.R * 255),
						math.floor(value.G * 255),
						math.floor(value.B * 255)
					)
			else
				result = result .. tostring(value)
			end

			result = result .. ",\n"
		end

		result = result .. string.rep("    ", indent) .. "}"
		return result
	end

	return "return " .. serializeTable(self.Current)
end

-- Import configuration from string
function Config:Import(configString)
	local success, importedConfig = pcall(function()
		local func = loadstring(configString)
		if func then
			return func()
		end
		return nil
	end)

	if success and type(importedConfig) == "table" then
		for category, settings in pairs(importedConfig) do
			if type(settings) == "table" and type(self.Current[category]) == "table" then
				for k, v in pairs(settings) do
					self.Current[category][k] = v
				end
			else
				self.Current[category] = settings
			end
		end

		local genv = getGlobalEnv()
		if genv.AimbotESP then
			genv.AimbotESP.Config = self.Current
		end

		self:TriggerEvent("Changed", {
			path = "all",
			oldValue = nil,
			newValue = self.Current,
		})
		print("📥 Configuration imported successfully")
		return true
	else
		warn("❌ Failed to import configuration: Invalid format")
		return false
	end
end

-- Event system functions
function Config:TriggerEvent(eventName, data)
	if self.Events[eventName] then
		for _, callback in ipairs(self.Events[eventName]) do
			pcall(callback, data)
		end
	end
end

function Config:OnChanged(callback)
	if type(callback) == "function" then
		table.insert(self.Events.Changed, callback)
	end
end

function Config:OnProfileLoaded(callback)
	if type(callback) == "function" then
		table.insert(self.Events.ProfileLoaded, callback)
	end
end

-- Persistent file saving (uses writefile if available, otherwise in-memory)
function Config:Save(profileName)
	profileName = profileName or "default"
	local configData = self:Export()

	local savedToFile = false
	if type(writefile) == "function" then
		pcall(function()
			if type(isfolder) == "function" and type(makefolder) == "function" then
				if not isfolder("AimbotESP") then
					makefolder("AimbotESP")
				end
				if not isfolder("AimbotESP/profiles") then
					makefolder("AimbotESP/profiles")
				end
			end
			writefile("AimbotESP/profiles/" .. profileName .. ".lua", configData)
			savedToFile = true
		end)
	end

	local genv = getGlobalEnv()
	genv.SAVED_PROFILE = configData

	if savedToFile then
		print("💾 Configuration saved to file: AimbotESP/profiles/" .. profileName .. ".lua")
	else
		print("💾 Configuration saved to memory profile: " .. profileName)
	end

	return configData
end

-- Persistent file loading
function Config:Load(profileName)
	profileName = profileName or "default"
	local loadedContent = nil

	if type(readfile) == "function" and type(isfile) == "function" then
		local filePath = "AimbotESP/profiles/" .. profileName .. ".lua"
		if isfile(filePath) then
			pcall(function()
				loadedContent = readfile(filePath)
			end)
		end
	end

	if not loadedContent then
		local genv = getGlobalEnv()
		loadedContent = genv.SAVED_PROFILE
	end

	if loadedContent then
		local success = self:Import(loadedContent)
		if success then
			print("📁 Configuration loaded for profile: " .. profileName)
			return true
		end
	end

	warn("⚠️ No saved configuration found for profile: " .. profileName)
	return false
end

-- Get configuration summary for display
function Config:GetSummary()
	return {
		aimbot = {
			enabled = self.Current.aimbot and self.Current.aimbot.enabled,
			fov = self.Current.aimbot and self.Current.aimbot.fov,
			smoothness = self.Current.aimbot and self.Current.aimbot.smoothness,
			targetPart = self.Current.aimbot and self.Current.aimbot.targetPart,
		},
		triggerBot = {
			enabled = self.Current.triggerBot and self.Current.triggerBot.enabled,
			delay = self.Current.triggerBot and self.Current.triggerBot.delay,
		},
		esp = {
			enabled = self.Current.esp and self.Current.esp.enabled,
			maxDistance = self.Current.esp and self.Current.esp.maxDistance,
			features = {
				boxes = self.Current.esp and self.Current.esp.boxes,
				names = self.Current.esp and self.Current.esp.names,
				healthBars = self.Current.esp and self.Current.esp.healthBars,
				tracers = self.Current.esp and self.Current.esp.tracers,
				skeleton = self.Current.esp and self.Current.esp.skeleton,
			},
		},
		performance = {
			updateRate = self.Current.performance and self.Current.performance.updateRate,
			renderDistance = self.Current.performance and self.Current.performance.renderDistance,
		},
	}
end

return Config
