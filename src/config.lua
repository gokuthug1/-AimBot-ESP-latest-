--[[
    Configuration System v2.0.0
    
    This module handles all configuration management including:
    - Default settings
    - Runtime configuration changes
    - Profile management
    - Validation and type checking
    
    Author: gokuthug1
    License: MIT
]]

local Config = {}

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
        priorityMode = "string"
    },
    esp = {
        enabled = "boolean",
        players = "boolean",
        healthBars = "boolean",
        distance = "boolean",
        tracers = "boolean",
        skeleton = "boolean",
        boxes = "boolean",
        names = "boolean",
        teamColors = "boolean",
        maxDistance = "number",
        thickness = "number",
        transparency = "number"
    },
    gui = {
        enabled = "boolean",
        theme = "string",
        scale = "number",
        position = "table"
    },
    antiDetection = {
        enabled = "boolean",
        randomDelay = "table",
        humanization = "boolean",
        stealthMode = "boolean",
        maxActionsPerSecond = "number"
    },
    performance = {
        updateRate = "number",
        renderDistance = "number",
        maxTrackedPlayers = "number",
        optimizeRendering = "boolean"
    }
}

-- Default configuration
Config.Default = {
    aimbot = {
        enabled = false,
        aimKey = Enum.UserInputType.MouseButton2,
        targetPart = "Head", -- "Head", "Torso", "Smart"
        fov = 120,
        smoothness = 10,
        prediction = true,
        teamCheck = true,
        visibilityCheck = true,
        maxDistance = 1000,
        priorityMode = "Distance" -- "Distance", "Health", "Threat"
    },
    esp = {
        enabled = false,
        players = true,
        healthBars = true,
        distance = true,
        tracers = true,
        skeleton = false,
        boxes = true,
        names = true,
        teamColors = true,
        showTeammates = false,
        maxDistance = 500,
        thickness = 2,
        transparency = 0.8
    },
    gui = {
        enabled = true,
        theme = "Dark", -- "Dark", "Light", "Blue"
        scale = 1.0,
        position = {X = 50, Y = 50},
        hotkeys = {
            toggleGUI = Enum.KeyCode.Insert,
            toggleAimbot = Enum.KeyCode.F1,
            toggleESP = Enum.KeyCode.F2,
            toggleTracers = Enum.KeyCode.F3,
            cycleTarget = Enum.KeyCode.F4,
            emergencyDisable = Enum.KeyCode.Delete
        }
    },
    antiDetection = {
        enabled = true,
        randomDelay = {min = 0.01, max = 0.05},
        humanization = true,
        stealthMode = false,
        maxActionsPerSecond = 30
    },
    performance = {
        updateRate = 60, -- FPS
        renderDistance = 500,
        maxTrackedPlayers = 20,
        optimizeRendering = true
    }
}

-- Game-specific profiles
Config.GameProfiles = {
    ["Arsenal"] = {
        aimbot = {
            fov = 90,
            smoothness = 8,
            targetPart = "Head",
            prediction = true
        },
        esp = {
            maxDistance = 300,
            showTeammates = false
        }
    },
    ["Phantom Forces"] = {
        aimbot = {
            fov = 80,
            smoothness = 12,
            targetPart = "Torso",
            prediction = true
        },
        esp = {
            maxDistance = 400,
            tracers = false
        }
    },
    ["Bad Business"] = {
        aimbot = {
            fov = 100,
            smoothness = 6,
            targetPart = "Smart"
        },
        esp = {
            maxDistance = 350,
            healthBars = true
        }
    },
    ["Counter Blox"] = {
        aimbot = {
            fov = 70,
            smoothness = 15,
            targetPart = "Head",
            prediction = false
        },
        esp = {
            maxDistance = 250,
            skeleton = true
        }
    }
}

-- Current configuration (starts as copy of default)
Config.Current = {}

-- Event system for configuration changes
Config.Events = {
    Changed = {},
    ProfileLoaded = {}
}

-- Deep copy function
function Config:DeepCopy(original)
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
    self:DetectGame()
    print("⚙️ Configuration system initialized")
end

-- Detect current game and apply profile
function Config:DetectGame()
    local gameId = game.GameId
    local placeName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    
    -- Try to match game name to profile
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
        if self.Current[category] then
            for key, value in pairs(settings) do
                self.Current[category][key] = value
            end
        end
    end
    
    self:TriggerEvent("ProfileLoaded", profile)
end

-- Validate configuration value
function Config:ValidateValue(category, key, value)
    local schema = self.Schemas[category]
    if not schema or not schema[key] then
        return false, "Unknown configuration key"
    end
    
    local expectedType = schema[key]
    local actualType = type(value)
    
    if expectedType == "EnumItem" then
        return typeof(value) == "EnumItem", "Expected EnumItem, got " .. typeof(value)
    elseif expectedType ~= actualType then
        return false, "Expected " .. expectedType .. ", got " .. actualType
    end
    
    -- Additional validation for specific keys
    if key == "fov" and (value < 1 or value > 180) then
        return false, "FOV must be between 1 and 180"
    elseif key == "smoothness" and (value < 1 or value > 50) then
        return false, "Smoothness must be between 1 and 50"
    elseif key == "maxDistance" and value < 0 then
        return false, "Max distance must be positive"
    elseif key == "updateRate" and (value < 1 or value > 240) then
        return false, "Update rate must be between 1 and 240"
    end
    
    return true, nil
end

-- Get configuration value
function Config:Get(path)
    local keys = string.split(path, ".")
    local current = self.Current
    
    for _, key in ipairs(keys) do
        if current[key] ~= nil then
            current = current[key]
        else
            return nil
        end
    end
    
    return current
end

-- Set configuration value
function Config:Set(path, value)
    local keys = string.split(path, ".")
    local category = keys[1]
    local key = keys[#keys]
    
    -- Validate the value
    local isValid, errorMsg = self:ValidateValue(category, key, value)
    if not isValid then
        warn("Configuration validation failed: " .. errorMsg)
        return false
    end
    
    -- Navigate to the parent table
    local current = self.Current
    for i = 1, #keys - 1 do
        if not current[keys[i]] then
            current[keys[i]] = {}
        end
        current = current[keys[i]]
    end
    
    -- Store old value for change detection
    local oldValue = current[key]
    current[key] = value
    
    -- Trigger change event
    if oldValue ~= value then
        self:TriggerEvent("Changed", {
            path = path,
            oldValue = oldValue,
            newValue = value
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
    self:TriggerEvent("Changed", {
        path = "all",
        oldValue = nil,
        newValue = self.Current
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
                result = result .. '"' .. value .. '"'
            elseif typeof(value) == "EnumItem" then
                result = result .. tostring(value)
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
    local success, config = pcall(function()
        return loadstring(configString)()
    end)
    
    if success and type(config) == "table" then
        self.Current = config
        self:TriggerEvent("Changed", {
            path = "all",
            oldValue = nil,
            newValue = self.Current
        })
        print("📥 Configuration imported successfully")
        return true
    else
        warn("Failed to import configuration: Invalid format")
        return false
    end
end

-- Event system functions
function Config:TriggerEvent(eventName, data)
    if self.Events[eventName] then
        for _, callback in pairs(self.Events[eventName]) do
            pcall(callback, data)
        end
    end
end

function Config:OnChanged(callback)
    table.insert(self.Events.Changed, callback)
end

function Config:OnProfileLoaded(callback)
    table.insert(self.Events.ProfileLoaded, callback)
end

-- Save configuration (placeholder for future file system)
function Config:Save(profileName)
    profileName = profileName or "default"
    -- In a real implementation, this would save to file
    local configData = self:Export()
    print("💾 Configuration saved as profile: " .. profileName)
    print("📋 Config data length: " .. #configData .. " characters")
    return configData
end

-- Load configuration (placeholder for future file system)
function Config:Load(profileName)
    profileName = profileName or "default"
    -- In a real implementation, this would load from file
    print("📁 Configuration loaded from profile: " .. profileName)
    return true
end

-- Get configuration summary for display
function Config:GetSummary()
    return {
        aimbot = {
            enabled = self.Current.aimbot.enabled,
            fov = self.Current.aimbot.fov,
            smoothness = self.Current.aimbot.smoothness,
            targetPart = self.Current.aimbot.targetPart
        },
        esp = {
            enabled = self.Current.esp.enabled,
            maxDistance = self.Current.esp.maxDistance,
            features = {
                boxes = self.Current.esp.boxes,
                names = self.Current.esp.names,
                healthBars = self.Current.esp.healthBars,
                tracers = self.Current.esp.tracers
            }
        },
        performance = {
            updateRate = self.Current.performance.updateRate,
            renderDistance = self.Current.performance.renderDistance
        }
    }
end

return Config