# Troubleshooting Guide

This guide helps you resolve common issues and problems with the Advanced AimBot & ESP system.

## 📋 Table of Contents

- [Quick Diagnostics](#quick-diagnostics)
- [Installation Issues](#installation-issues)
- [AimBot Problems](#aimbot-problems)
- [ESP Issues](#esp-issues)
- [GUI Problems](#gui-problems)
- [Performance Issues](#performance-issues)
- [Compatibility Problems](#compatibility-problems)
- [Error Messages](#error-messages)
- [Advanced Troubleshooting](#advanced-troubleshooting)

## 🔍 Quick Diagnostics

Before diving into specific issues, try these quick diagnostic steps:

### Basic Checks
1. **Verify the script is loaded**: Look for the welcome message in console
2. **Check hotkeys**: Press `INSERT` to see if GUI appears
3. **Test basic functions**: Try `F1` (AimBot) and `F2` (ESP)
4. **Emergency reset**: Press `DELETE` to disable everything and start fresh

### System Status Check
```lua
-- Run this in your executor to check system status
print("System Status:")
print("Loaded:", getgenv().AIMBOT_ESP_LOADED)
print("AimBot:", getgenv().AimbotESP.State.AimbotEnabled)
print("ESP:", getgenv().AimbotESP.State.ESPEnabled)
print("Emergency:", getgenv().AimbotESP.State.EmergencyDisabled)
```

## 🚀 Installation Issues

### Script Not Loading

#### Symptoms
- No welcome message appears
- Console shows no output
- GUI doesn't appear when pressing `INSERT`

#### Solutions

**Check Executor Injection**
1. Ensure your executor is properly injected into Roblox
2. Try reinjecting the executor
3. Restart both Roblox and the executor

**Verify Script Source**
1. Make sure you're using the correct loadstring:
   ```lua
   loadstring(game:HttpGet("https://raw.githubusercontent.com/gokuthug1/-AimBot-ESP-latest-/main/src/main.lua"))()
   ```
2. Check your internet connection
3. Try downloading and running the script locally

**Executor Compatibility**
- **Synapse X**: Should work perfectly
- **KRNL**: May need to disable some features
- **JJSploit**: Limited compatibility, try basic features only

### "Already Loaded" Error

#### Symptoms
- Message: "AimBot ESP is already loaded!"
- Script won't start

#### Solutions
1. Press `DELETE` key to emergency disable
2. Wait 5 seconds
3. Reload the script
4. If persistent, restart Roblox

### HTTP Errors

#### Symptoms
- "HTTP 404" or "HTTP 403" errors
- "Unable to cast string" errors

#### Solutions
1. Check if your executor supports `HttpGet`
2. Verify the GitHub repository is accessible
3. Try using a VPN if blocked in your region
4. Use the manual installation method instead

## 🎯 AimBot Problems

### AimBot Not Aiming

#### Symptoms
- No automatic aiming occurs
- FOV circle not visible
- Holding aim key does nothing

#### Diagnostic Steps
1. **Check if AimBot is enabled**:
   - Press `F1` to toggle
   - Look for "AimBot: ON" message
   - Check GUI toggle in AimBot tab

2. **Verify aim key**:
   - Default is Right Mouse Button
   - Try different keys in settings
   - Ensure key isn't bound to other functions

3. **Check FOV settings**:
   - FOV might be too restrictive (try 120°)
   - Increase FOV in GUI or use this command:
     ```lua
     getgenv().AimbotESP.Components.Config:Set("aimbot.fov", 120)
     ```

4. **Verify targets are available**:
   - Ensure there are enemy players nearby
   - Check team settings (disable team check if needed)
   - Verify visibility check isn't too strict

#### Common Solutions

**FOV Too Small**
```lua
-- Increase FOV to 120 degrees
getgenv().AimbotESP.Components.Config:Set("aimbot.fov", 120)
```

**Team Check Issues**
```lua
-- Disable team check to target everyone
getgenv().AimbotESP.Components.Config:Set("aimbot.teamCheck", false)
```

**Visibility Problems**
```lua
-- Disable visibility check for testing
getgenv().AimbotESP.Components.Config:Set("aimbot.visibilityCheck", false)
```

### Aiming Too Fast/Slow

#### Symptoms
- Aim snaps instantly (too obvious)
- Aim moves too slowly (ineffective)

#### Solutions

**Too Fast (Obvious)**
```lua
-- Increase smoothness for more natural movement
getgenv().AimbotESP.Components.Config:Set("aimbot.smoothness", 15)
```

**Too Slow (Ineffective)**
```lua
-- Decrease smoothness for faster aiming
getgenv().AimbotESP.Components.Config:Set("aimbot.smoothness", 5)
```

**Recommended Smoothness Values**:
- **1-3**: Instant (very obvious)
- **4-8**: Fast but noticeable
- **9-15**: Natural human-like
- **16-25**: Slow and smooth
- **25+**: Very slow

### Targeting Wrong Players

#### Symptoms
- Aims at teammates
- Targets players behind walls
- Ignores closer enemies

#### Solutions

**Targeting Teammates**
```lua
-- Enable team check
getgenv().AimbotESP.Components.Config:Set("aimbot.teamCheck", true)
```

**Targeting Through Walls**
```lua
-- Enable visibility check
getgenv().AimbotESP.Components.Config:Set("aimbot.visibilityCheck", true)
```

**Wrong Priority**
```lua
-- Change priority mode to distance
getgenv().AimbotESP.Components.Config:Set("aimbot.priorityMode", "Distance")
```

## 👁️ ESP Issues

### ESP Not Visible

#### Symptoms
- No player boxes, names, or tracers appear
- ESP seems to be enabled but nothing shows

#### Diagnostic Steps
1. **Verify ESP is enabled**:
   - Press `F2` to toggle
   - Check GUI toggle in ESP tab
   - Look for "ESP: ON" message

2. **Check distance settings**:
   - Players might be too far away
   - Increase max distance in settings

3. **Verify players are present**:
   - Ensure there are other players in the game
   - Check if players are within render distance

#### Solutions

**Increase Max Distance**
```lua
-- Set ESP max distance to 1000 studs
getgenv().AimbotESP.Components.Config:Set("esp.maxDistance", 1000)
```

**Enable All ESP Features**
```lua
local config = getgenv().AimbotESP.Components.Config
config:Set("esp.boxes", true)
config:Set("esp.names", true)
config:Set("esp.healthBars", true)
config:Set("esp.tracers", true)
```

**Reset ESP System**
```lua
-- Restart ESP system
if getgenv().AimbotESP.Components.ESP then
    getgenv().AimbotESP.Components.ESP:Cleanup()
    getgenv().AimbotESP.Components.ESP:Initialize()
end
```

### ESP Colors Wrong

#### Symptoms
- All players show same color
- Team colors not working
- Colors are too dim/bright

#### Solutions

**Enable Team Colors**
```lua
getgenv().AimbotESP.Components.Config:Set("esp.teamColors", true)
```

**Adjust Transparency**
```lua
-- Make ESP more visible (less transparent)
getgenv().AimbotESP.Components.Config:Set("esp.transparency", 1.0)
```

**Fix Color Issues**
```lua
-- Reset ESP colors
local esp = getgenv().AimbotESP.Components.ESP
if esp then
    esp:DisableAll()
    wait(1)
    esp:Initialize()
end
```

### Tracers Not Working

#### Symptoms
- No lines pointing to players
- Tracers enabled but not visible

#### Solutions
```lua
-- Enable tracers
getgenv().AimbotESP.Components.Config:Set("esp.tracers", true)

-- Increase line thickness
getgenv().AimbotESP.Components.Config:Set("esp.thickness", 3)

-- Make tracers more visible
getgenv().AimbotESP.Components.Config:Set("esp.transparency", 0.8)
```

## 🖥️ GUI Problems

### GUI Not Appearing

#### Symptoms
- Pressing `INSERT` does nothing
- No GUI window visible

#### Solutions
1. **Try alternative hotkey**:
   ```lua
   -- Change GUI hotkey to F12
   getgenv().AimbotESP.Components.Config:Set("gui.hotkeys.toggleGUI", Enum.KeyCode.F12)
   ```

2. **Force show GUI**:
   ```lua
   -- Manually show GUI
   if getgenv().AimbotESP.Components.GUI then
       getgenv().AimbotESP.Components.GUI:SetVisible(true)
   end
   ```

3. **Reset GUI position**:
   ```lua
   -- Reset GUI to center of screen
   getgenv().AimbotESP.Components.Config:Set("gui.position", {X = 50, Y = 50})
   ```

### GUI Not Responding

#### Symptoms
- GUI appears but buttons don't work
- Sliders don't move
- Can't close GUI

#### Solutions
1. **Restart GUI system**:
   ```lua
   local gui = getgenv().AimbotESP.Components.GUI
   if gui then
       gui:Cleanup()
       gui:Initialize()
   end
   ```

2. **Check for conflicts**:
   - Close other GUIs that might interfere
   - Disable other scripts temporarily

3. **Emergency GUI reset**:
   ```lua
   -- Force close all GUIs and restart
   for _, gui in pairs(game.CoreGui:GetChildren()) do
       if gui.Name:find("Aimbot") or gui.Name:find("ESP") then
           gui:Destroy()
       end
   end
   ```

### GUI Too Small/Large

#### Symptoms
- GUI elements are tiny or huge
- Text is unreadable
- Buttons are wrong size

#### Solutions
```lua
-- Reset GUI scale to default
getgenv().AimbotESP.Components.Config:Set("gui.scale", 1.0)

-- Adjust for your screen
getgenv().AimbotESP.Components.Config:Set("gui.scale", 1.2) -- 20% larger
```

## ⚡ Performance Issues

### Low FPS/Lag

#### Symptoms
- Game runs slowly when script is active
- Stuttering or freezing
- High CPU usage

#### Solutions

**Reduce Update Rate**
```lua
-- Lower update rate to 30 FPS
getgenv().AimbotESP.Components.Config:Set("performance.updateRate", 30)
```

**Optimize ESP Settings**
```lua
local config = getgenv().AimbotESP.Components.Config
-- Reduce ESP distance
config:Set("esp.maxDistance", 200)
-- Disable expensive features
config:Set("esp.skeleton", false)
config:Set("esp.tracers", false)
-- Limit tracked players
config:Set("performance.maxTrackedPlayers", 10)
```

**Enable Optimizations**
```lua
getgenv().AimbotESP.Components.Config:Set("performance.optimizeRendering", true)
```

### Memory Issues

#### Symptoms
- Roblox crashes after extended use
- "Out of memory" errors
- Gradual performance degradation

#### Solutions
1. **Restart script periodically**:
   ```lua
   -- Emergency disable and restart
   getgenv().AimbotESP.State.EmergencyDisabled = true
   wait(5)
   getgenv().AimbotESP.State.EmergencyDisabled = false
   ```

2. **Clear history**:
   ```lua
   -- Clear anti-detection history
   if getgenv().AimbotESP.Components.AntiDetection then
       getgenv().AimbotESP.Components.AntiDetection.ActionHistory = {}
   end
   ```

## 🔧 Compatibility Problems

### Executor-Specific Issues

#### Synapse X
- **Issue**: Script loads but features don't work
- **Solution**: Ensure you're using the latest version
- **Workaround**: Try reinjecting before loading script

#### KRNL
- **Issue**: Some features missing or broken
- **Solution**: Disable advanced features:
  ```lua
  getgenv().AimbotESP.Components.Config:Set("antiDetection.enabled", false)
  ```

#### JJSploit
- **Issue**: Script fails to load completely
- **Solution**: Use basic mode only:
  ```lua
  -- Simplified loading for JJSploit
  getgenv().BASIC_MODE = true
  loadstring(game:HttpGet("..."))()
  ```

### Game-Specific Issues

#### Arsenal
- **Issue**: AimBot not working properly
- **Solution**: Use Arsenal-specific settings:
  ```lua
  local config = getgenv().AimbotESP.Components.Config
  config:Set("aimbot.targetPart", "Head")
  config:Set("aimbot.fov", 90)
  config:Set("aimbot.smoothness", 8)
  ```

#### Phantom Forces
- **Issue**: Getting detected quickly
- **Solution**: Use stealth settings:
  ```lua
  local config = getgenv().AimbotESP.Components.Config
  config:Set("aimbot.smoothness", 15)
  config:Set("antiDetection.stealthMode", true)
  config:Set("esp.enabled", false)
  ```

## ❌ Error Messages

### "Configuration validation failed"

#### Cause
Invalid setting value provided

#### Solution
```lua
-- Reset to defaults
getgenv().AimbotESP.Components.Config:Reset()
```

### "Safety protocol activated"

#### Cause
Anti-detection system detected suspicious behavior

#### Solution
1. Wait 10 seconds for automatic reset
2. Reduce aggressiveness of settings
3. Enable humanization features

### "Component failed to load"

#### Cause
Script component couldn't initialize

#### Solution
```lua
-- Reload the entire script
getgenv().AIMBOT_ESP_LOADED = false
loadstring(game:HttpGet("..."))()
```

### "HTTP request failed"

#### Cause
Network issues or blocked access

#### Solution
1. Check internet connection
2. Try using a VPN
3. Use manual installation method

## 🔬 Advanced Troubleshooting

### Debug Mode

Enable debug mode for detailed logging:
```lua
getgenv().AIMBOT_ESP_DEBUG = true
-- Reload script to enable debug output
```

### Component Status Check

Check individual component status:
```lua
local components = getgenv().AimbotESP.Components
for name, component in pairs(components) do
    print(name .. ":", component and "Loaded" or "Failed")
end
```

### Manual Component Restart

Restart specific components:
```lua
-- Restart AimBot
local aimbot = getgenv().AimbotESP.Components.Aimbot
if aimbot then
    aimbot:Cleanup()
    aimbot:Initialize()
end

-- Restart ESP
local esp = getgenv().AimbotESP.Components.ESP
if esp then
    esp:Cleanup()
    esp:Initialize()
end
```

### Complete System Reset

Nuclear option - completely reset everything:
```lua
-- WARNING: This will reset all settings
getgenv().AIMBOT_ESP_LOADED = false
getgenv().AimbotESP = nil

-- Clear all GUIs
for _, gui in pairs(game.CoreGui:GetChildren()) do
    if gui.Name:find("Aimbot") or gui.Name:find("ESP") then
        gui:Destroy()
    end
end

-- Reload script
wait(2)
loadstring(game:HttpGet("https://raw.githubusercontent.com/gokuthug1/-AimBot-ESP-latest-/main/src/main.lua"))()
```

## 📞 Getting Additional Help

If none of these solutions work:

1. **Check the GitHub Issues**: [Report new issues](https://github.com/gokuthug1/-AimBot-ESP-latest-/issues)
2. **Join Discussions**: [Community help](https://github.com/gokuthug1/-AimBot-ESP-latest-/discussions)
3. **Provide Details**: Include:
   - Your executor type and version
   - Game you're playing
   - Exact error messages
   - Steps to reproduce the issue
   - Your configuration settings

### Information to Include in Bug Reports

```lua
-- Run this and include the output in your bug report
print("=== SYSTEM INFO ===")
print("Executor:", identifyexecutor and identifyexecutor() or "Unknown")
print("Game:", game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name)
print("Script Version:", getgenv().AimbotESP and getgenv().AimbotESP.Version or "Not loaded")
print("Components:", getgenv().AimbotESP and #getgenv().AimbotESP.Components or 0)
print("Emergency Disabled:", getgenv().AimbotESP and getgenv().AimbotESP.State.EmergencyDisabled or "N/A")
```

---

*This troubleshooting guide is regularly updated. Check the GitHub repository for the latest version and additional solutions.*