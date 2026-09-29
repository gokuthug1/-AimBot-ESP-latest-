--[[----------------------------------------------------------------------------------
    Advanced AimBot & ESP Suite v2.1.0 (Universal Native Master)
    
    A sophisticated, modular AimBot, TriggerBot, and ESP system for Roblox:
    - Universal target selection, prediction, smoothing, and aim locking
    - Dual-engine visuals: Drawing API with ScreenGui fallback
    - Multi-mode aim: Camera CFrame (FPS/LockCenter), MouseMoveRel, and Hybrid
    - Advanced ESP: 2D Bounding Boxes, Midpoint Tracers, Skeletons, Health Bars, Head Dots
    - Multi-layered Anti-Detection: humanized Bezier movement, jitter, rate limiting, stealth mode
    - Next-gen UI with real-time themes, minimize-to-pill, and custom background image support
    - Centralized hotkeys: INSERT / RightShift (GUI), F1 (Aim), F2 (ESP), F3 (Tracers), F4 (Target), DELETE (Emergency)
    
    Author: gokuthug1
    License: MIT
------------------------------------------------------------------------------------]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	Camera = Workspace.CurrentCamera
end)

-- Universal Global Environment
local genv = (type(getgenv) == "function" and getgenv()) or _G

-- Prevent multiple simultaneous instances & handle clean reload
if genv.AimbotESP and genv.AimbotESP.Loaded then
	warn("⚠️ [AimbotESP] Previous instance detected. Performing clean reload...")
	if genv.AimbotESP.Unload then
		pcall(function()
			genv.AimbotESP:Unload()
		end)
	end
	task.wait(0.2)
end

-- Initialize Global Suite Namespace
genv.AimbotESP = {
	Version = "2.1.0",
	BuildDate = "2026-09-28",
	Loaded = false,
	Components = {},
	Config = {},
	State = {
		AimbotEnabled = false,
		ESPEnabled = false,
		GUIVisible = true,
		EmergencyDisabled = false,
		Initialized = false,
	},
	ActiveNPCs = {},
	Connections = {},
	Debug = {
		ErrorCount = 0,
		LastError = nil,
		StartTime = tick(),
	},
}

-- Backward compatibility aliases
genv.AIMBOT_ESP_LOADED = true
genv.UltimateSuiteLoaded = true

--[[------------------------------------------------------------------------------
    Active NPC Detection & Management
--------------------------------------------------------------------------------]]

local function registerNPC(descendant)
	if descendant:IsA("Humanoid") and descendant.Parent and descendant.Parent:IsA("Model") then
		local char = descendant.Parent
		if char ~= (LocalPlayer and LocalPlayer.Character) and not Players:GetPlayerFromCharacter(char) then
			if not table.find(genv.AimbotESP.ActiveNPCs, char) then
				table.insert(genv.AimbotESP.ActiveNPCs, char)
			end
		end
	end
end

for _, desc in ipairs(Workspace:GetDescendants()) do
	registerNPC(desc)
end

local npcAddConn = Workspace.DescendantAdded:Connect(registerNPC)
table.insert(genv.AimbotESP.Connections, npcAddConn)

local npcRemoveConn = Workspace.DescendantRemoving:Connect(function(descendant)
	if descendant:IsA("Model") then
		local idx = table.find(genv.AimbotESP.ActiveNPCs, descendant)
		if idx then
			table.remove(genv.AimbotESP.ActiveNPCs, idx)
		end
	end
end)
table.insert(genv.AimbotESP.Connections, npcRemoveConn)

--[[------------------------------------------------------------------------------
    Universal Multi-Tier Module Loader
    1. Local Filesystem (readfile / isfile)
    2. GitHub Raw (game:HttpGet)
    3. Standalone Embedded Fallbacks
--------------------------------------------------------------------------------]]

local GITHUB_REPO = "https://raw.githubusercontent.com/gokuthug1/-AimBot-ESP-latest-/main/src/"

local function loadModule(name, fileName)
	-- 1. Try local filesystem
	if type(readfile) == "function" and type(isfile) == "function" then
		local candidates = { "src/" .. fileName, fileName, "scripts/" .. fileName }
		for _, path in ipairs(candidates) do
			if isfile(path) then
				local content = nil
				pcall(function()
					content = readfile(path)
				end)
				if content and #content > 50 then
					local func = loadstring(content)
					if func then
						local ok, mod = pcall(func)
						if ok and mod then
							print("📦 Loaded module [" .. name .. "] from local file: " .. path)
							return mod
						end
					end
				end
			end
		end
	end

	-- 2. Try HTTP Get from GitHub raw
	if game.HttpGet then
		local url = GITHUB_REPO .. fileName
		local ok, content = pcall(function()
			return game:HttpGet(url)
		end)
		if ok and content and #content > 50 and not string.find(content, "404: Not Found") then
			local func = loadstring(content)
			if func then
				local modOk, mod = pcall(func)
				if modOk and mod then
					print("🌐 Loaded module [" .. name .. "] from GitHub: " .. fileName)
					return mod
				end
			end
		end
	end

	return nil
end

--[[------------------------------------------------------------------------------
    Component Resolution & Fallbacks
--------------------------------------------------------------------------------]]

print("🚀 [AimbotESP] Initializing Suite v" .. genv.AimbotESP.Version .. "...")

-- 1. Load Utils
local Utils = loadModule("Utils", "utils.lua")
if not Utils then
	error("❌ Critical module [Utils] failed to load. Please verify your internet connection or script files.")
	return
end
genv.AimbotESP.Components.Utils = Utils

-- 2. Load Config
local Config = loadModule("Config", "config.lua")
if not Config then
	error("❌ Critical module [Config] failed to load.")
	return
end
genv.AimbotESP.Components.Config = Config
Config:Initialize()
genv.AimbotESP.Config = Config.Current

-- 3. Load AntiDetection
local AntiDetection = loadModule("AntiDetection", "anti_detection.lua")
if AntiDetection then
	genv.AimbotESP.Components.AntiDetection = AntiDetection
	AntiDetection:Initialize()
end

-- 4. Load Aimbot
local Aimbot = loadModule("Aimbot", "aimbot.lua")
if Aimbot then
	genv.AimbotESP.Components.Aimbot = Aimbot
	Aimbot:Initialize()
end

-- 5. Load ESP
local ESP = loadModule("ESP", "esp.lua")
if ESP then
	genv.AimbotESP.Components.ESP = ESP
	ESP:Initialize()
end

-- 6. Load GUI
local GUI = loadModule("GUI", "gui.lua")
if GUI then
	genv.AimbotESP.Components.GUI = GUI
	GUI:Initialize()
end

--[[------------------------------------------------------------------------------
    Configuration Synchronizer & State Bridge
--------------------------------------------------------------------------------]]

Config:OnChanged(function(data)
	if data.path == "aimbot.enabled" then
		genv.AimbotESP.State.AimbotEnabled = data.newValue
	elseif data.path == "esp.enabled" then
		genv.AimbotESP.State.ESPEnabled = data.newValue
	end
end)

-- Initial state sync
genv.AimbotESP.State.AimbotEnabled = Config:Get("aimbot.enabled") or false
genv.AimbotESP.State.ESPEnabled = Config:Get("esp.enabled") or false

--[[------------------------------------------------------------------------------
    Primary Execution Loop (RenderStepped & Heartbeat)
--------------------------------------------------------------------------------]]

local renderConn = RunService.RenderStepped:Connect(function()
	if genv.AimbotESP.State.EmergencyDisabled then
		return
	end

	if Aimbot then
		Aimbot:Update()
	end
	if ESP then
		ESP:Update()
	end
	if GUI then
		GUI:Update()
	end
end)
table.insert(genv.AimbotESP.Connections, renderConn)

--[[------------------------------------------------------------------------------
    Graceful Unload & Emergency Reset
--------------------------------------------------------------------------------]]

function genv.AimbotESP:Unload()
	print("🧹 [AimbotESP] Unloading suite and restoring clean state...")

	for _, conn in ipairs(self.Connections) do
		pcall(function()
			conn:Disconnect()
		end)
	end
	self.Connections = {}

	if self.Components.Aimbot then
		pcall(function()
			self.Components.Aimbot:Cleanup()
		end)
	end
	if self.Components.ESP then
		pcall(function()
			self.Components.ESP:Cleanup()
		end)
	end
	if self.Components.GUI then
		pcall(function()
			self.Components.GUI:Cleanup()
		end)
	end
	if self.Components.AntiDetection then
		pcall(function()
			self.Components.AntiDetection:Cleanup()
		end)
	end

	self.ActiveNPCs = {}
	self.State.EmergencyDisabled = true
	self.Loaded = false
	genv.AIMBOT_ESP_LOADED = false
	genv.UltimateSuiteLoaded = false

	print("✅ [AimbotESP] Unload complete.")
end

--[[------------------------------------------------------------------------------
    Finalization
--------------------------------------------------------------------------------]]

genv.AimbotESP.Loaded = true
genv.AimbotESP.State.Initialized = true

print([[
======================================================
  🎯 AimBot & ESP Suite v2.1.0 Loaded Flawlessly!
  📋 Keybinds:
     • INSERT / Right-Shift : Toggle GUI Menu
     • F1                   : Toggle AimBot
     • F2                   : Toggle ESP
     • F3                   : Toggle Tracers
     • F4                   : Cycle Aim Part
     • DELETE               : Emergency Disable
======================================================
]])

return genv.AimbotESP
