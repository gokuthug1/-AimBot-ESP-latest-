# 🎯 Advanced AimBot & ESP for Roblox

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Lua](https://img.shields.io/badge/Language-Lua-blue.svg)](https://www.lua.org/)
[![Version](https://img.shields.io/badge/Version-2.1.0-green.svg)](https://github.com/gokuthug1/-AimBot-ESP-latest-)

A sophisticated, modular AimBot, TriggerBot, and ESP (Extra Sensory Perception) system for Roblox with advanced features, multi-layered anti-detection mechanisms, dual-engine Drawing/GUI rendering, and extensive customization options.

## ⚠️ IMPORTANT DISCLAIMER

**This project is for EDUCATIONAL and RESEARCH purposes only.**

- Using this software may violate Roblox's Terms of Service
- Your account may be permanently banned
- Use at your own risk and responsibility
- The developers are not responsible for any consequences
- This tool is intended for learning game development and security research

## ✨ Features

### 🎯 AimBot & TriggerBot System
- **Multi-Mode Aiming**: Camera CFrame Lerp (FPS/LockCenter games like Arsenal/PF), MouseMoveRel, or Hybrid
- **Smart Target Selection**: Prioritizes closest enemies, lowest health, threat score, or crosshair distance
- **TriggerBot**: Universal automatic firing upon enemy crosshair alignment with tool & NPC filters
- **Smooth Aiming & Jitter Suppression**: Natural mouse movement and lerp simulation
- **Prediction System**: Advanced linear and quadratic velocity trajectory calculation for moving targets
- **FOV Limiting & Drawing Circle**: Configurable field of view with Drawing API & ScreenGui fallback
- **Multiple Aim Modes**: Head, Torso, Smart, or HumanoidRootPart selection
- **Target Indicator**: Dynamic reticle on current locked target

### 👁️ ESP (Extra Sensory Perception) & Visuals
- **3D-to-2D Bounding Boxes**: 8-corner projected bounding boxes that never collapse or invert at vertical angles
- **Bone Skeletons**: Real-time bone visualization for both R6 and R15 character rigs
- **Mathematically Centered Tracers**: Snaplines with Bottom, Center, and Top origin points
- **Health Bars & Text**: Real-time health visualization with color gradients
- **Name Tags & Distance**: Player names, display names, and distance indicators
- **Equipped Weapon Display**: Detects and displays weapon in hand or Unarmed status
- **Head Dot**: Precision indicator directly on player heads
- **X-Ray / Wall Chams**: Transparent map geometry with pristine material/transparency restoration
- **Target NPC Support**: Full ESP and aim support for non-player humanoid characters
- **Dual-Engine Rendering**: Drawing API for zero GUI footprint, with automatic ScreenGui fallback

### 🛡️ Anti-Detection Features
- **Humanized Movement Curves**: Natural Bezier curves, micro-overshoot, and tremor simulation
- **Action Rate Limiting**: Throttles aim, shoot, and movement frequencies
- **Suspicion Tracking**: Proactive suspicion level monitoring with asynchronous safety protocol
- **Stealth Mode**: Disables visible indicators for security and clean screen capture

### ⚙️ Advanced Configuration & UI
- **Next-Gen GUI**: Modern sidebar tabs, animated minimize-to-pill transition, and customizable background image
- **Theme Engine**: 7 color palettes (Default, Ruby, Ocean, Midnight, Forest, Light, Blue)
- **Centralized Hotkeys**: Instant keyboard toggles for all core features
- **Persistent Profile System**: Save and load profiles to executor filesystem (`writefile`/`readfile`)
- **Real-Time Synchronizer**: Live state updates across all modules

## 🚀 Installation

### Method 1: Script Executor (Recommended)
1. Download a Roblox script executor (Synapse X, KRNL, Script-Ware, Wave, Delta, etc.)
2. Copy the contents of `src/main.lua`
3. Paste into your executor and execute

### Method 2: Auto-Execute
1. Place `main.lua` in your executor's autoexec folder
2. Restart Roblox for automatic loading

### Method 3: Loadstring
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/gokuthug1/-AimBot-ESP-latest-/main/src/main.lua"))()
```

## 🎮 Usage

### Basic Usage
1. Execute the script in your preferred Roblox game
2. Press `INSERT` or `Right-Shift` to open the configuration GUI
3. Adjust settings to your preference
4. Press `F1` to toggle AimBot
5. Press `F2` to toggle ESP

### Hotkeys (Default)
- `INSERT` / `RightShift` - Toggle Configuration GUI
- `F1` - Toggle AimBot
- `F2` - Toggle ESP
- `F3` - Toggle Tracers
- `F4` - Cycle Aim Target Part (Head → Torso → Smart → HumanoidRootPart)
- `DELETE` - Emergency Disable All Features

### Configuration Options

#### AimBot Settings
- **Enable**: Toggle AimBot on/off
- **Aim Key**: Key to hold for aiming (default: Right Mouse Button)
- **Aim Mode**: Hybrid, Camera CFrame, or MouseMoveRel
- **Target Part**: Head, Torso, Smart, or HumanoidRootPart
- **FOV**: Field of view circle (10-180 degrees)
- **Smoothness**: Aim smoothing factor (1-30)
- **Prediction**: Enable target movement velocity prediction
- **Team Check**: Ignore teammates
- **Target NPCs**: Target non-player humanoids

#### TriggerBot Settings
- **Enable**: Toggle TriggerBot on/off
- **Delay**: Delay between shots in seconds (0.01 - 0.5s)
- **Require Tool**: Only fire when holding a weapon tool

#### ESP Settings
- **Enable**: Master toggle for all visuals
- **Boxes**: 2D bounding boxes around targets
- **Skeletons**: Bone joints for R6 and R15 characters
- **Tracers**: Snaplines to players (Bottom, Center, Top origin)
- **Health Bars**: Health bar and numeric text
- **Names & Distances**: Player tags and distance
- **Weapon Text**: Show equipped weapon
- **X-Ray**: See players through translucent walls

## 📁 Project Structure

```
├── README.md                 # This file
├── LICENSE                   # MIT License
├── CHANGELOG.md             # Version history
├── .gitignore               # Git ignore rules
├── src/                     # Source code
│   ├── main.lua            # Main entry point
│   ├── aimbot.lua          # AimBot functionality
│   ├── esp.lua             # ESP features
│   ├── config.lua          # Configuration system
│   ├── gui.lua             # User interface
│   ├── utils.lua           # Utility functions
│   └── anti_detection.lua  # Anti-detection measures
├── docs/                    # Documentation
│   ├── installation.md     # Detailed installation guide
│   ├── configuration.md    # Configuration reference
│   ├── troubleshooting.md  # Common issues and solutions
│   └── api.md              # API documentation
├── examples/                # Usage examples
│   ├── basic_usage.lua     # Simple implementation
│   ├── advanced_config.lua # Advanced configuration
│   └── custom_features.lua # Custom feature examples
└── assets/                  # Media files
    ├── screenshots/         # Feature screenshots
    └── demos/              # Video demonstrations
```

## 🔧 Advanced Configuration

### Custom Profiles
Create custom configuration profiles for different games:

```lua
local profiles = {
    ["Arsenal"] = {
        aimbot = {
            fov = 120,
            smoothness = 8,
            targetPart = "Head"
        },
        esp = {
            showHealth = true,
            showDistance = true
        }
    },
    ["Phantom Forces"] = {
        aimbot = {
            fov = 90,
            smoothness = 12,
            prediction = true
        }
    }
}
```

### API Usage
Integrate with other scripts:

```lua
local AimBot = require("aimbot")
local ESP = require("esp")

-- Initialize systems
AimBot:Initialize()
ESP:Initialize()

-- Custom event handling
AimBot.OnTargetChanged:Connect(function(target)
    print("New target:", target.Name)
end)
```

## 🛠️ Development

### Building from Source
1. Clone the repository
2. Modify source files in `src/`
3. Test in your preferred Roblox environment
4. Submit pull requests for improvements

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📋 Compatibility

### Supported Executors
- ✅ Synapse X
- ✅ KRNL
- ✅ Script-Ware
- ✅ Oxygen U
- ✅ Fluxus
- ⚠️ JJSploit (Limited features)

### Tested Games
- ✅ Arsenal
- ✅ Phantom Forces
- ✅ Bad Business
- ✅ Counter Blox
- ✅ Big Paintball
- ⚠️ Jailbreak (Partial support)

## 🐛 Troubleshooting

### Common Issues

**Script not loading:**
- Ensure your executor supports the required functions
- Check if the game has anti-cheat protection
- Try reinjecting your executor

**AimBot not working:**
- Verify the target part exists on player models
- Check FOV settings (may be too restrictive)
- Ensure team check settings are correct

**ESP not visible:**
- Confirm ESP is enabled in settings
- Check if players are within render distance
- Verify color settings aren't transparent

### Performance Issues
- Reduce ESP render distance
- Disable unused features
- Lower update frequencies in config

## 📈 Changelog

### Version 2.0.0 (2026-01-13)
- Complete rewrite with modular architecture
- Added advanced anti-detection systems
- Implemented GUI configuration interface
- Enhanced prediction algorithms
- Added profile system
- Improved performance optimization

### Version 1.0.0 (2026-01-12)
- Initial release
- Basic AimBot functionality
- Simple ESP features

## 🤝 Contributing

We welcome contributions! Please read our contributing guidelines:

1. **Code Style**: Follow Lua best practices
2. **Documentation**: Update docs for new features
3. **Testing**: Test thoroughly before submitting
4. **Ethics**: Maintain educational focus

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Roblox community for testing and feedback
- Open source Lua libraries used in development
- Security researchers for anti-detection insights

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/gokuthug1/-AimBot-ESP-latest-/issues)
- **Discussions**: [GitHub Discussions](https://github.com/gokuthug1/-AimBot-ESP-latest-/discussions)
---

**Remember: Use responsibly and respect others' gaming experience!**
