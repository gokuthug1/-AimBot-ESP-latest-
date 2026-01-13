# Configuration Reference

This document provides a comprehensive reference for all configuration options available in the Advanced AimBot & ESP system.

## 📋 Table of Contents

- [Configuration Overview](#configuration-overview)
- [AimBot Settings](#aimbot-settings)
- [ESP Settings](#esp-settings)
- [GUI Settings](#gui-settings)
- [Anti-Detection Settings](#anti-detection-settings)
- [Performance Settings](#performance-settings)
- [Game-Specific Profiles](#game-specific-profiles)
- [Advanced Configuration](#advanced-configuration)

## 🔧 Configuration Overview

The configuration system is organized into several categories, each controlling different aspects of the system. All settings can be modified through the GUI or programmatically through the API.

### Configuration Structure
```lua
Config = {
    aimbot = { ... },
    esp = { ... },
    gui = { ... },
    antiDetection = { ... },
    performance = { ... }
}
```

## 🎯 AimBot Settings

### Basic Settings

#### `enabled` (boolean)
- **Default**: `false`
- **Description**: Master toggle for AimBot functionality
- **GUI**: Toggle button in AimBot tab
- **Hotkey**: F1

#### `aimKey` (EnumItem)
- **Default**: `Enum.UserInputType.MouseButton2`
- **Description**: Key/button to hold for aiming
- **Options**: 
  - `MouseButton1` (Left Click)
  - `MouseButton2` (Right Click)
  - `MouseButton3` (Middle Click)
- **GUI**: Dropdown in AimBot tab

#### `targetPart` (string)
- **Default**: `"Head"`
- **Description**: Which body part to target
- **Options**:
  - `"Head"` - Targets the head for maximum damage
  - `"Torso"` - Targets torso/chest for reliability
  - `"Smart"` - Automatically chooses best target
- **GUI**: Dropdown in AimBot tab
- **Hotkey**: F4 (cycles through options)

### Targeting Settings

#### `fov` (number)
- **Default**: `120`
- **Range**: `1` to `180`
- **Description**: Field of view angle in degrees
- **Recommendations**:
  - `60-80°` - Competitive/realistic
  - `90-120°` - Balanced
  - `120-180°` - Aggressive/obvious
- **GUI**: Slider in AimBot tab

#### `smoothness` (number)
- **Default**: `10`
- **Range**: `1` to `50`
- **Description**: How smooth the aim movement is (higher = smoother)
- **Recommendations**:
  - `1-5` - Instant/snappy (obvious)
  - `6-15` - Natural human-like
  - `16-50` - Very slow/smooth
- **GUI**: Slider in AimBot tab

#### `prediction` (boolean)
- **Default**: `true`
- **Description**: Predict target movement for better accuracy
- **Use Cases**:
  - `true` - For fast-moving targets
  - `false` - For stationary/slow targets
- **GUI**: Toggle in AimBot tab

### Filtering Settings

#### `teamCheck` (boolean)
- **Default**: `true`
- **Description**: Ignore teammates when targeting
- **GUI**: Toggle in AimBot tab

#### `visibilityCheck` (boolean)
- **Default**: `true`
- **Description**: Only target visible players (line of sight)
- **GUI**: Toggle in AimBot tab

#### `maxDistance` (number)
- **Default**: `1000`
- **Range**: `50` to `5000`
- **Description**: Maximum targeting distance in studs
- **GUI**: Slider in AimBot tab

#### `priorityMode` (string)
- **Default**: `"Distance"`
- **Description**: How to prioritize multiple targets
- **Options**:
  - `"Distance"` - Closest target first
  - `"Health"` - Lowest health first
  - `"Threat"` - Most dangerous first
- **GUI**: Dropdown in AimBot tab

## 👁️ ESP Settings

### Basic Settings

#### `enabled` (boolean)
- **Default**: `false`
- **Description**: Master toggle for ESP functionality
- **GUI**: Toggle button in ESP tab
- **Hotkey**: F2

#### `maxDistance` (number)
- **Default**: `500`
- **Range**: `50` to `2000`
- **Description**: Maximum ESP render distance in studs
- **GUI**: Slider in ESP tab

### Visual Elements

#### `players` (boolean)
- **Default**: `true`
- **Description**: Show player indicators
- **GUI**: Toggle in ESP tab

#### `boxes` (boolean)
- **Default**: `true`
- **Description**: Draw bounding boxes around players
- **GUI**: Toggle in ESP tab

#### `names` (boolean)
- **Default**: `true`
- **Description**: Display player names
- **GUI**: Toggle in ESP tab

#### `healthBars` (boolean)
- **Default**: `true`
- **Description**: Show health bars next to players
- **GUI**: Toggle in ESP tab

#### `distance` (boolean)
- **Default**: `true`
- **Description**: Display distance to players
- **GUI**: Toggle in ESP tab

#### `tracers` (boolean)
- **Default**: `true`
- **Description**: Draw lines pointing to players
- **GUI**: Toggle in ESP tab
- **Hotkey**: F3

#### `skeleton` (boolean)
- **Default**: `false`
- **Description**: Show player skeleton/bone structure
- **GUI**: Toggle in ESP tab

### Appearance Settings

#### `teamColors` (boolean)
- **Default**: `true`
- **Description**: Use team-based colors for ESP elements
- **GUI**: Toggle in ESP tab

#### `showTeammates` (boolean)
- **Default**: `false`
- **Description**: Show ESP for teammates
- **GUI**: Toggle in ESP tab

#### `thickness` (number)
- **Default**: `2`
- **Range**: `1` to `10`
- **Description**: Line thickness for ESP elements
- **GUI**: Slider in ESP tab

#### `transparency` (number)
- **Default**: `0.8`
- **Range**: `0.1` to `1.0`
- **Description**: Transparency of ESP elements (1.0 = opaque)
- **GUI**: Slider in ESP tab

## 🖥️ GUI Settings

### Basic Settings

#### `enabled` (boolean)
- **Default**: `true`
- **Description**: Enable GUI system
- **Note**: Disabling this will hide all GUI elements

#### `theme` (string)
- **Default**: `"Dark"`
- **Description**: GUI color theme
- **Options**:
  - `"Dark"` - Dark theme with blue accents
  - `"Light"` - Light theme for bright environments
  - `"Blue"` - Blue-themed interface
- **GUI**: Dropdown in Settings tab

#### `scale` (number)
- **Default**: `1.0`
- **Range**: `0.5` to `2.0`
- **Description**: GUI scaling factor
- **GUI**: Slider in Settings tab

#### `position` (table)
- **Default**: `{X = 50, Y = 50}`
- **Description**: GUI position on screen
- **Note**: Automatically saved when dragging GUI

### Hotkey Settings

#### `hotkeys.toggleGUI` (EnumItem)
- **Default**: `Enum.KeyCode.Insert`
- **Description**: Key to toggle GUI visibility

#### `hotkeys.toggleAimbot` (EnumItem)
- **Default**: `Enum.KeyCode.F1`
- **Description**: Key to toggle AimBot

#### `hotkeys.toggleESP` (EnumItem)
- **Default**: `Enum.KeyCode.F2`
- **Description**: Key to toggle ESP

#### `hotkeys.toggleTracers` (EnumItem)
- **Default**: `Enum.KeyCode.F3`
- **Description**: Key to toggle tracers

#### `hotkeys.cycleTarget` (EnumItem)
- **Default**: `Enum.KeyCode.F4`
- **Description**: Key to cycle target modes

#### `hotkeys.emergencyDisable` (EnumItem)
- **Default**: `Enum.KeyCode.Delete`
- **Description**: Emergency disable all features

## 🛡️ Anti-Detection Settings

### Basic Settings

#### `enabled` (boolean)
- **Default**: `true`
- **Description**: Enable anti-detection measures
- **GUI**: Toggle in Settings tab

#### `humanization` (boolean)
- **Default**: `true`
- **Description**: Add human-like behavior patterns
- **GUI**: Toggle in Settings tab

#### `stealthMode` (boolean)
- **Default**: `false`
- **Description**: Minimize visual indicators
- **GUI**: Toggle in Settings tab

### Advanced Settings

#### `randomDelay` (table)
- **Default**: `{min = 0.01, max = 0.05}`
- **Description**: Random delay range for actions
- **Format**: `{min = number, max = number}`

#### `maxActionsPerSecond` (number)
- **Default**: `30`
- **Range**: `5` to `100`
- **Description**: Maximum actions per second limit
- **GUI**: Slider in Settings tab

## ⚡ Performance Settings

### Basic Settings

#### `updateRate` (number)
- **Default**: `60`
- **Range**: `10` to `240`
- **Description**: Update frequency in FPS
- **GUI**: Slider in Settings tab

#### `renderDistance` (number)
- **Default**: `500`
- **Range**: `100` to `2000`
- **Description**: Maximum render distance for optimizations

#### `maxTrackedPlayers` (number)
- **Default**: `20`
- **Range**: `5` to `50`
- **Description**: Maximum number of players to track

#### `optimizeRendering` (boolean)
- **Default**: `true`
- **Description**: Enable rendering optimizations

## 🎮 Game-Specific Profiles

The system automatically detects games and applies optimized settings:

### Arsenal Profile
```lua
{
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
}
```

### Phantom Forces Profile
```lua
{
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
}
```

### Bad Business Profile
```lua
{
    aimbot = {
        fov = 100,
        smoothness = 6,
        targetPart = "Smart"
    },
    esp = {
        maxDistance = 350,
        healthBars = true
    }
}
```

### Counter Blox Profile
```lua
{
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
```

## 🔧 Advanced Configuration

### Programmatic Configuration

You can modify settings programmatically using the Config API:

```lua
local config = getgenv().AimbotESP.Components.Config

-- Get a setting
local fov = config:Get("aimbot.fov")

-- Set a setting
config:Set("aimbot.fov", 90)

-- Toggle a boolean setting
config:Toggle("aimbot.enabled")

-- Reset to defaults
config:Reset()
```

### Configuration Validation

All settings are validated when changed:

```lua
-- This will fail validation
config:Set("aimbot.fov", 200) -- FOV must be 1-180

-- This will succeed
config:Set("aimbot.fov", 120)
```

### Export/Import Configuration

```lua
-- Export current configuration
local configString = config:Export()

-- Import configuration
config:Import(configString)
```

### Event Handling

Listen for configuration changes:

```lua
config:OnChanged(function(changeData)
    print("Setting changed:", changeData.path)
    print("Old value:", changeData.oldValue)
    print("New value:", changeData.newValue)
end)
```

## 📊 Recommended Settings

### Beginner Settings
```lua
aimbot = {
    enabled = true,
    fov = 120,
    smoothness = 15,
    targetPart = "Smart",
    prediction = true
}
esp = {
    enabled = true,
    maxDistance = 400,
    boxes = true,
    names = true,
    healthBars = true
}
```

### Competitive Settings
```lua
aimbot = {
    enabled = true,
    fov = 80,
    smoothness = 10,
    targetPart = "Head",
    prediction = true
}
esp = {
    enabled = true,
    maxDistance = 300,
    boxes = true,
    names = false,
    healthBars = true
}
```

### Stealth Settings
```lua
aimbot = {
    enabled = true,
    fov = 60,
    smoothness = 20,
    targetPart = "Torso",
    prediction = false
}
esp = {
    enabled = false
}
antiDetection = {
    enabled = true,
    humanization = true,
    stealthMode = true
}
```

## 🚨 Important Notes

### Security Considerations
- **Never use maximum settings** (1° FOV, 1 smoothness, etc.)
- **Enable anti-detection** for safer usage
- **Use realistic settings** that mimic human behavior
- **Take breaks** to avoid detection patterns

### Performance Impact
- **Higher update rates** consume more CPU
- **Larger render distances** affect performance
- **More ESP elements** reduce FPS
- **Optimize settings** based on your hardware

### Compatibility
- Some settings may not work with certain executors
- Game-specific features may vary
- Anti-cheat systems may detect certain configurations

---

*This configuration reference is updated regularly. Check the GitHub repository for the latest version.*