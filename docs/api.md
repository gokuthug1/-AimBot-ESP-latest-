# API Documentation

This document provides comprehensive API documentation for developers who want to integrate with or extend the Advanced AimBot & ESP system.

## 📋 Table of Contents

- [Getting Started](#getting-started)
- [Core API](#core-api)
- [Configuration API](#configuration-api)
- [AimBot API](#aimbot-api)
- [ESP API](#esp-api)
- [Utility API](#utility-api)
- [Anti-Detection API](#anti-detection-api)
- [Event System](#event-system)
- [Examples](#examples)

## 🚀 Getting Started

### Accessing the API

Once the script is loaded, all API functions are available through the global namespace:

```lua
-- Check if the system is loaded
if getgenv().AimbotESP then
    print("System loaded, version:", getgenv().AimbotESP.Version)
else
    error("AimBot ESP system not loaded")
end
```

### Basic API Structure

```lua
getgenv().AimbotESP = {
    Version = "2.0.0",
    BuildDate = "2026-01-13",
    Loaded = true,
    Components = {
        Config = ConfigAPI,
        Aimbot = AimbotAPI,
        ESP = ESPAPI,
        Utils = UtilsAPI,
        AntiDetection = AntiDetectionAPI,
        GUI = GUIAPI
    },
    Config = CurrentConfiguration,
    State = SystemState
}
```

## 🔧 Core API

### System Information

#### `getgenv().AimbotESP.Version`
- **Type**: `string`
- **Description**: Current version of the system
- **Example**: `"2.0.0"`

#### `getgenv().AimbotESP.BuildDate`
- **Type**: `string`
- **Description**: Build date of the current version
- **Example**: `"2026-01-13"`

#### `getgenv().AimbotESP.Loaded`
- **Type**: `boolean`
- **Description**: Whether the system is fully loaded
- **Example**: `true`

### System State

#### `getgenv().AimbotESP.State`
```lua
State = {
    AimbotEnabled = false,
    ESPEnabled = false,
    GUIVisible = false,
    EmergencyDisabled = false
}
```

### Component Access

```lua
-- Access individual components
local config = getgenv().AimbotESP.Components.Config
local aimbot = getgenv().AimbotESP.Components.Aimbot
local esp = getgenv().AimbotESP.Components.ESP
local utils = getgenv().AimbotESP.Components.Utils
```

## ⚙️ Configuration API

### Basic Configuration Methods

#### `Config:Get(path)`
Get a configuration value by path.

```lua
local config = getgenv().AimbotESP.Components.Config

-- Get a simple value
local fov = config:Get("aimbot.fov")

-- Get a nested value
local hotkey = config:Get("gui.hotkeys.toggleAimbot")

-- Get an entire section
local aimbotConfig = config:Get("aimbot")
```

**Parameters:**
- `path` (string): Dot-separated path to the configuration value

**Returns:**
- The configuration value, or `nil` if not found

#### `Config:Set(path, value)`
Set a configuration value by path.

```lua
local config = getgenv().AimbotESP.Components.Config

-- Set a simple value
config:Set("aimbot.fov", 90)

-- Set a nested value
config:Set("gui.hotkeys.toggleAimbot", Enum.KeyCode.F5)

-- Set multiple values
config:Set("aimbot.smoothness", 12)
config:Set("aimbot.targetPart", "Head")
```

**Parameters:**
- `path` (string): Dot-separated path to the configuration value
- `value` (any): The value to set

**Returns:**
- `boolean`: `true` if successful, `false` if validation failed

#### `Config:Toggle(path)`
Toggle a boolean configuration value.

```lua
local config = getgenv().AimbotESP.Components.Config

-- Toggle AimBot
config:Toggle("aimbot.enabled")

-- Toggle ESP
config:Toggle("esp.enabled")
```

**Parameters:**
- `path` (string): Path to a boolean configuration value

**Returns:**
- `boolean`: `true` if successful, `false` if not a boolean value

### Advanced Configuration Methods

#### `Config:Reset()`
Reset all configuration to default values.

```lua
local config = getgenv().AimbotESP.Components.Config
config:Reset()
```

#### `Config:Export()`
Export current configuration as a string.

```lua
local config = getgenv().AimbotESP.Components.Config
local configString = config:Export()
print(configString) -- Lua table string
```

**Returns:**
- `string`: Serialized configuration

#### `Config:Import(configString)`
Import configuration from a string.

```lua
local config = getgenv().AimbotESP.Components.Config
local success = config:Import(configString)
if success then
    print("Configuration imported successfully")
end
```

**Parameters:**
- `configString` (string): Serialized configuration string

**Returns:**
- `boolean`: `true` if successful, `false` if failed

#### `Config:ApplyProfile(profile)`
Apply a configuration profile.

```lua
local config = getgenv().AimbotESP.Components.Config
local arsenalProfile = {
    aimbot = {
        fov = 90,
        smoothness = 8,
        targetPart = "Head"
    }
}
config:ApplyProfile(arsenalProfile)
```

**Parameters:**
- `profile` (table): Configuration profile to apply

### Event Handling

#### `Config:OnChanged(callback)`
Listen for configuration changes.

```lua
local config = getgenv().AimbotESP.Components.Config
config:OnChanged(function(changeData)
    print("Setting changed:", changeData.path)
    print("Old value:", changeData.oldValue)
    print("New value:", changeData.newValue)
end)
```

**Parameters:**
- `callback` (function): Function to call when configuration changes

## 🎯 AimBot API

### Basic AimBot Methods

#### `Aimbot:GetCurrentTargetInfo()`
Get information about the current target.

```lua
local aimbot = getgenv().AimbotESP.Components.Aimbot
local targetInfo = aimbot:GetCurrentTargetInfo()

if targetInfo then
    print("Target:", targetInfo.name)
    print("Distance:", targetInfo.distance)
    print("Health:", targetInfo.health)
end
```

**Returns:**
- `table` or `nil`: Target information or nil if no target
  ```lua
  {
      name = "PlayerName",
      distance = 150,
      health = 75
  }
  ```

#### `Aimbot:FindBestTarget()`
Find the best target based on current settings.

```lua
local aimbot = getgenv().AimbotESP.Components.Aimbot
local target = aimbot:FindBestTarget()

if target then
    print("Best target:", target.player.Name)
    print("Distance:", target.distance)
end
```

**Returns:**
- `table` or `nil`: Target data or nil if no valid targets

#### `Aimbot:IsInFOV(position)`
Check if a position is within the AimBot FOV.

```lua
local aimbot = getgenv().AimbotESP.Components.Aimbot
local playerPosition = workspace.SomePlayer.HumanoidRootPart.Position
local inFOV = aimbot:IsInFOV(playerPosition)
print("In FOV:", inFOV)
```

**Parameters:**
- `position` (Vector3): World position to check

**Returns:**
- `boolean`: `true` if position is within FOV

### Advanced AimBot Methods

#### `Aimbot:GetTargetPart(character, targetMode)`
Get the target part for a character.

```lua
local aimbot = getgenv().AimbotESP.Components.Aimbot
local character = workspace.SomePlayer
local targetPart = aimbot:GetTargetPart(character, "Smart")
```

**Parameters:**
- `character` (Model): Player character
- `targetMode` (string): "Head", "Torso", or "Smart"

**Returns:**
- `BasePart` or `nil`: Target part or nil if not found

#### `Aimbot:PredictTargetPosition(targetPart, velocity)`
Predict where a target will be.

```lua
local aimbot = getgenv().AimbotESP.Components.Aimbot
local predictedPos = aimbot:PredictTargetPosition(targetPart, velocity)
```

**Parameters:**
- `targetPart` (BasePart): The target part
- `velocity` (Vector3): Current velocity of the target

**Returns:**
- `Vector3`: Predicted position

## 👁️ ESP API

### Basic ESP Methods

#### `ESP:GetStats()`
Get ESP statistics.

```lua
local esp = getgenv().AimbotESP.Components.ESP
local stats = esp:GetStats()
print("Visible players:", stats.visible)
print("Total tracked:", stats.total)
```

**Returns:**
- `table`: ESP statistics
  ```lua
  {
      visible = 5,
      total = 12
  }
  ```

#### `ESP:DisableAll()`
Disable all ESP elements.

```lua
local esp = getgenv().AimbotESP.Components.ESP
esp:DisableAll()
```

#### `ESP:CreatePlayerESP(player)`
Create ESP elements for a specific player.

```lua
local esp = getgenv().AimbotESP.Components.ESP
esp:CreatePlayerESP(game.Players.SomePlayer)
```

**Parameters:**
- `player` (Player): The player to create ESP for

#### `ESP:RemovePlayerESP(player)`
Remove ESP elements for a specific player.

```lua
local esp = getgenv().AimbotESP.Components.ESP
esp:RemovePlayerESP(game.Players.SomePlayer)
```

**Parameters:**
- `player` (Player): The player to remove ESP for

## 🛠️ Utility API

### Mathematical Utilities

#### `Utils:GetDistance(pos1, pos2)`
Calculate distance between two positions.

```lua
local utils = getgenv().AimbotESP.Components.Utils
local distance = utils:GetDistance(Vector3.new(0, 0, 0), Vector3.new(10, 0, 0))
print("Distance:", distance) -- 10
```

**Parameters:**
- `pos1` (Vector3): First position
- `pos2` (Vector3): Second position

**Returns:**
- `number`: Distance in studs

#### `Utils:Lerp(a, b, t)`
Linear interpolation between two values.

```lua
local utils = getgenv().AimbotESP.Components.Utils
local result = utils:Lerp(0, 100, 0.5)
print("Result:", result) -- 50
```

**Parameters:**
- `a` (number): Start value
- `b` (number): End value
- `t` (number): Interpolation factor (0-1)

**Returns:**
- `number`: Interpolated value

#### `Utils:Clamp(value, min, max)`
Clamp a value between min and max.

```lua
local utils = getgenv().AimbotESP.Components.Utils
local clamped = utils:Clamp(150, 0, 100)
print("Clamped:", clamped) -- 100
```

### Player Utilities

#### `Utils:IsPlayerAlive(player)`
Check if a player is alive.

```lua
local utils = getgenv().AimbotESP.Components.Utils
local alive = utils:IsPlayerAlive(game.Players.SomePlayer)
print("Alive:", alive)
```

**Parameters:**
- `player` (Player): Player to check

**Returns:**
- `boolean`: `true` if player is alive

#### `Utils:GetHealthPercentage(player)`
Get player's health percentage.

```lua
local utils = getgenv().AimbotESP.Components.Utils
local health = utils:GetHealthPercentage(game.Players.SomePlayer)
print("Health:", health .. "%")
```

**Parameters:**
- `player` (Player): Player to check

**Returns:**
- `number`: Health percentage (0-100)

#### `Utils:IsTeammate(player)`
Check if a player is on the same team.

```lua
local utils = getgenv().AimbotESP.Components.Utils
local teammate = utils:IsTeammate(game.Players.SomePlayer)
print("Teammate:", teammate)
```

**Parameters:**
- `player` (Player): Player to check

**Returns:**
- `boolean`: `true` if player is a teammate

### Screen/World Conversion

#### `Utils:WorldToScreen(position)`
Convert world position to screen coordinates.

```lua
local utils = getgenv().AimbotESP.Components.Utils
local screenPos, onScreen = utils:WorldToScreen(Vector3.new(0, 10, 0))
if onScreen then
    print("Screen position:", screenPos.X, screenPos.Y)
end
```

**Parameters:**
- `position` (Vector3): World position

**Returns:**
- `Vector2`: Screen position
- `boolean`: Whether position is on screen

#### `Utils:HasLineOfSight(from, to, ignoreList)`
Check if there's a clear line of sight between two positions.

```lua
local utils = getgenv().AimbotESP.Components.Utils
local hasLOS = utils:HasLineOfSight(
    game.Players.LocalPlayer.Character.HumanoidRootPart.Position,
    workspace.SomePlayer.HumanoidRootPart.Position,
    {game.Players.LocalPlayer.Character}
)
print("Line of sight:", hasLOS)
```

**Parameters:**
- `from` (Vector3): Starting position
- `to` (Vector3): Target position
- `ignoreList` (table, optional): Objects to ignore in raycast

**Returns:**
- `boolean`: `true` if clear line of sight exists

### Color Utilities

#### `Utils:GetHealthColor(healthPercent)`
Get color based on health percentage.

```lua
local utils = getgenv().AimbotESP.Components.Utils
local color = utils:GetHealthColor(75)
-- Returns green for >75% health
```

**Parameters:**
- `healthPercent` (number): Health percentage (0-100)

**Returns:**
- `Color3`: Color representing health level

#### `Utils:GetTeamColor(player)`
Get a player's team color.

```lua
local utils = getgenv().AimbotESP.Components.Utils
local color = utils:GetTeamColor(game.Players.SomePlayer)
```

**Parameters:**
- `player` (Player): Player to get team color for

**Returns:**
- `Color3`: Team color or white if no team

## 🛡️ Anti-Detection API

### Basic Anti-Detection Methods

#### `AntiDetection:IsActionAllowed(actionType)`
Check if an action is allowed by rate limiting.

```lua
local antiDetection = getgenv().AimbotESP.Components.AntiDetection
if antiDetection:IsActionAllowed("aim") then
    -- Perform aiming action
    print("Action allowed")
else
    print("Action blocked by rate limiting")
end
```

**Parameters:**
- `actionType` (string, optional): Type of action ("aim", "shoot", "movement", "general")

**Returns:**
- `boolean`: `true` if action is allowed

#### `AntiDetection:RecordAction(actionType, metadata)`
Record an action for tracking.

```lua
local antiDetection = getgenv().AimbotESP.Components.AntiDetection
antiDetection:RecordAction("aim", {
    reactionTime = 0.25,
    accuracy = 0.85
})
```

**Parameters:**
- `actionType` (string): Type of action
- `metadata` (table, optional): Additional data about the action

#### `AntiDetection:GetHumanizedDelay(baseDelay, variance)`
Get a humanized delay with randomness.

```lua
local antiDetection = getgenv().AimbotESP.Components.AntiDetection
local delay = antiDetection:GetHumanizedDelay(0.1, 0.3)
wait(delay)
```

**Parameters:**
- `baseDelay` (number, optional): Base delay in seconds
- `variance` (number, optional): Variance factor (0-1)

**Returns:**
- `number`: Humanized delay in seconds

### Advanced Anti-Detection Methods

#### `AntiDetection:HumanizeMovement(targetPos, currentPos, smoothness)`
Apply humanization to mouse movement.

```lua
local antiDetection = getgenv().AimbotESP.Components.AntiDetection
local humanizedPos = antiDetection:HumanizeMovement(
    Vector2.new(500, 300), -- Target position
    Vector2.new(400, 250), -- Current position
    10 -- Smoothness
)
```

**Parameters:**
- `targetPos` (Vector2): Target screen position
- `currentPos` (Vector2): Current screen position
- `smoothness` (number): Smoothness factor

**Returns:**
- `Vector2`: Humanized target position

#### `AntiDetection:ShouldIntentionallyMiss()`
Check if should intentionally miss for humanization.

```lua
local antiDetection = getgenv().AimbotESP.Components.AntiDetection
if antiDetection:ShouldIntentionallyMiss() then
    -- Add slight offset to aim
    print("Intentionally missing for humanization")
end
```

**Returns:**
- `boolean`: `true` if should miss intentionally

#### `AntiDetection:GetStats()`
Get anti-detection statistics.

```lua
local antiDetection = getgenv().AimbotESP.Components.AntiDetection
local stats = antiDetection:GetStats()
print("Suspicion level:", stats.suspicionLevel)
print("Recent actions:", stats.recentActions)
```

**Returns:**
- `table`: Anti-detection statistics

## 📡 Event System

### Configuration Events

```lua
local config = getgenv().AimbotESP.Components.Config

-- Listen for any configuration change
config:OnChanged(function(changeData)
    print("Config changed:", changeData.path)
    print("Old:", changeData.oldValue)
    print("New:", changeData.newValue)
end)

-- Listen for profile loads
config:OnProfileLoaded(function(profile)
    print("Profile loaded:", profile)
end)
```

### Custom Events

You can create custom event handlers:

```lua
-- Create a custom event handler
local function onTargetChanged(target)
    if target then
        print("New target acquired:", target.player.Name)
    else
        print("Target lost")
    end
end

-- Hook into the aimbot update cycle
local aimbot = getgenv().AimbotESP.Components.Aimbot
local originalUpdate = aimbot.Update
aimbot.Update = function(self)
    local oldTarget = self.CurrentTarget
    originalUpdate(self)
    local newTarget = self.CurrentTarget
    
    if oldTarget ~= newTarget then
        onTargetChanged(newTarget)
    end
end
```

## 💡 Examples

### Example 1: Custom Target Filter

```lua
-- Create a custom target filter that only targets players with low health
local utils = getgenv().AimbotESP.Components.Utils
local aimbot = getgenv().AimbotESP.Components.Aimbot

local originalFindBestTarget = aimbot.FindBestTarget
aimbot.FindBestTarget = function(self)
    local targets = utils:GetValidTargets()
    
    -- Filter for low health targets only
    local lowHealthTargets = {}
    for _, target in ipairs(targets) do
        if target.health < 50 then -- Less than 50% health
            table.insert(lowHealthTargets, target)
        end
    end
    
    if #lowHealthTargets > 0 then
        -- Sort by health (lowest first)
        table.sort(lowHealthTargets, function(a, b)
            return a.health < b.health
        end)
        return lowHealthTargets[1]
    end
    
    -- Fall back to original logic if no low health targets
    return originalFindBestTarget(self)
end
```

### Example 2: Custom ESP Element

```lua
-- Add a custom ESP element that shows player weapons
local esp = getgenv().AimbotESP.Components.ESP
local utils = getgenv().AimbotESP.Components.Utils

local function createWeaponLabel(player, parentFrame)
    local weaponLabel = Instance.new("TextLabel")
    weaponLabel.Name = "WeaponLabel"
    weaponLabel.Size = UDim2.new(1, 0, 0, 15)
    weaponLabel.Position = UDim2.new(0, 0, 1, 20)
    weaponLabel.BackgroundTransparency = 1
    weaponLabel.Text = "Unknown Weapon"
    weaponLabel.TextColor3 = Color3.new(1, 1, 0)
    weaponLabel.TextScaled = true
    weaponLabel.Font = Enum.Font.Gotham
    weaponLabel.Parent = parentFrame
    
    return weaponLabel
end

-- Hook into ESP creation
local originalCreatePlayerESP = esp.CreatePlayerESP
esp.CreatePlayerESP = function(self, player)
    originalCreatePlayerESP(self, player)
    
    local espData = self.PlayerESP[player]
    if espData and espData.elements.mainFrame then
        local weaponLabel = createWeaponLabel(player, espData.elements.mainFrame)
        espData.elements.weaponLabel = weaponLabel
    end
end

-- Update weapon display
local originalUpdatePlayerESP = esp.UpdatePlayerESP
esp.UpdatePlayerESP = function(self, player, espData)
    originalUpdatePlayerESP(self, player, espData)
    
    if espData.elements.weaponLabel and utils:IsPlayerAlive(player) then
        local character = player.Character
        local tool = character:FindFirstChildOfClass("Tool")
        
        if tool then
            espData.elements.weaponLabel.Text = tool.Name
            espData.elements.weaponLabel.Visible = true
        else
            espData.elements.weaponLabel.Visible = false
        end
    end
end
```

### Example 3: Performance Monitor

```lua
-- Create a performance monitoring system
local performanceMonitor = {
    frameCount = 0,
    lastUpdate = tick(),
    fps = 0,
    updateTimes = {}
}

function performanceMonitor:Update()
    local currentTime = tick()
    local deltaTime = currentTime - self.lastUpdate
    
    self.frameCount = self.frameCount + 1
    table.insert(self.updateTimes, deltaTime)
    
    -- Keep only last 60 updates
    if #self.updateTimes > 60 then
        table.remove(self.updateTimes, 1)
    end
    
    -- Calculate FPS every second
    if deltaTime >= 1.0 then
        self.fps = self.frameCount / deltaTime
        self.frameCount = 0
        self.lastUpdate = currentTime
        
        -- Calculate average update time
        local totalTime = 0
        for _, time in ipairs(self.updateTimes) do
            totalTime = totalTime + time
        end
        local avgUpdateTime = totalTime / #self.updateTimes
        
        print(string.format("FPS: %.1f, Avg Update Time: %.3fms", 
              self.fps, avgUpdateTime * 1000))
    end
end

-- Hook into the main update loop
local runService = game:GetService("RunService")
runService.Heartbeat:Connect(function()
    performanceMonitor:Update()
end)
```

### Example 4: Configuration Backup System

```lua
-- Automatic configuration backup system
local config = getgenv().AimbotESP.Components.Config
local backupSystem = {
    backups = {},
    maxBackups = 5
}

function backupSystem:CreateBackup(name)
    name = name or ("Backup_" .. os.date("%Y%m%d_%H%M%S"))
    
    local configData = config:Export()
    table.insert(self.backups, {
        name = name,
        data = configData,
        timestamp = tick()
    })
    
    -- Remove old backups
    while #self.backups > self.maxBackups do
        table.remove(self.backups, 1)
    end
    
    print("Configuration backup created:", name)
end

function backupSystem:RestoreBackup(name)
    for _, backup in ipairs(self.backups) do
        if backup.name == name then
            local success = config:Import(backup.data)
            if success then
                print("Configuration restored from:", name)
                return true
            else
                warn("Failed to restore backup:", name)
                return false
            end
        end
    end
    warn("Backup not found:", name)
    return false
end

function backupSystem:ListBackups()
    print("Available backups:")
    for i, backup in ipairs(self.backups) do
        print(string.format("%d. %s (%s)", i, backup.name, 
              os.date("%Y-%m-%d %H:%M:%S", backup.timestamp)))
    end
end

-- Auto-backup on significant changes
config:OnChanged(function(changeData)
    -- Create backup on major setting changes
    local majorSettings = {"aimbot.enabled", "esp.enabled", "antiDetection.enabled"}
    for _, setting in ipairs(majorSettings) do
        if changeData.path == setting then
            backupSystem:CreateBackup("Auto_" .. setting:gsub("%.", "_"))
            break
        end
    end
end)

-- Expose backup system globally
getgenv().AimbotESP.BackupSystem = backupSystem
```

---

*This API documentation is regularly updated. Check the GitHub repository for the latest version and additional examples.*