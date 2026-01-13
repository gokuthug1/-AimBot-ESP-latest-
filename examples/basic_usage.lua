--[[
    Basic Usage Example
    
    This example demonstrates the simplest way to use the AimBot & ESP system.
    Perfect for beginners who want to get started quickly.
]]

-- Load the main system
loadstring(game:HttpGet("https://raw.githubusercontent.com/gokuthug1/-AimBot-ESP-latest-/main/src/main.lua"))()

-- Wait for system to load
repeat wait() until getgenv().AimbotESP and getgenv().AimbotESP.Loaded

print("🎯 AimBot & ESP System Loaded!")
print("📋 Basic Controls:")
print("   INSERT - Open GUI")
print("   F1 - Toggle AimBot")
print("   F2 - Toggle ESP")
print("   DELETE - Emergency Disable")

-- Get configuration component
local config = getgenv().AimbotESP.Components.Config

-- Basic AimBot setup
config:Set("aimbot.enabled", true)
config:Set("aimbot.fov", 90)           -- 90 degree field of view
config:Set("aimbot.smoothness", 10)    -- Smooth aiming
config:Set("aimbot.targetPart", "Head") -- Target head for precision

-- Basic ESP setup
config:Set("esp.enabled", true)
config:Set("esp.boxes", true)          -- Show player boxes
config:Set("esp.names", true)          -- Show player names
config:Set("esp.healthBars", true)     -- Show health bars
config:Set("esp.distance", true)       -- Show distance
config:Set("esp.maxDistance", 400)     -- ESP range: 400 studs

-- Enable anti-detection for safety
config:Set("antiDetection.enabled", true)
config:Set("antiDetection.humanization", true)

print("✅ Basic configuration applied!")
print("🎮 You're ready to play!")

--[[
    Usage Instructions:
    1. Join any supported Roblox game
    2. Execute this script
    3. Press F1 to enable AimBot
    4. Press F2 to enable ESP
    5. Hold Right Mouse Button to aim
    6. Press INSERT to open settings GUI
]]