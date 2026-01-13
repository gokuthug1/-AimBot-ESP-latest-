# 🎯 Advanced AimBot & ESP for Roblox

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Lua](https://img.shields.io/badge/Language-Lua-blue.svg)](https://www.lua.org/)
[![Version](https://img.shields.io/badge/Version-2.0.0-green.svg)](https://github.com/gokuthug1/-AimBot-ESP-latest-)

A sophisticated, modular AimBot and ESP (Extra Sensory Perception) system for Roblox with advanced features, anti-detection mechanisms, and extensive customization options.

## ⚠️ IMPORTANT DISCLAIMER

**This project is for EDUCATIONAL and RESEARCH purposes only.**

- Using this software may violate Roblox's Terms of Service
- Your account may be permanently banned
- Use at your own risk and responsibility
- The developers are not responsible for any consequences
- This tool is intended for learning game development and security research

## ✨ Features

### 🎯 AimBot System
- **Smart Target Selection**: Prioritizes closest enemies or lowest health targets
- **Smooth Aiming**: Natural mouse movement simulation
- **Prediction System**: Advanced trajectory calculation for moving targets
- **FOV Limiting**: Configurable field of view restrictions
- **Anti-Detection**: Randomized timing and human-like behavior
- **Multiple Aim Modes**: Head, torso, or smart body part selection

### 👁️ ESP (Extra Sensory Perception)
- **Player ESP**: See players through walls with customizable colors
- **Health Bars**: Real-time health visualization
- **Distance Display**: Shows distance to all players
- **Name Tags**: Player names with team colors
- **Skeleton ESP**: Bone structure visualization
- **Box ESP**: 2D/3D bounding boxes around players
- **Tracers**: Lines pointing to enemy locations

### 🛡️ Anti-Detection Features
- **Randomized Delays**: Human-like timing variations
- **Smooth Transitions**: Natural movement patterns
- **Detection Avoidance**: Smart behavior to avoid anti-cheat
- **Rate Limiting**: Prevents suspicious rapid actions
- **Stealth Mode**: Minimal visual indicators

### ⚙️ Advanced Configuration
- **GUI Interface**: Easy-to-use configuration menu
- **Hotkey System**: Customizable key bindings
- **Profile System**: Save and load different configurations
- **Real-time Adjustments**: Modify settings during gameplay

## 🚀 Installation

### Method 1: Script Executor
1. Download a Roblox script executor (Synapse X, KRNL, etc.)
2. Copy the contents of `src/main.lua`
3. Paste into your executor and run

### Method 2: Auto-Execute
1. Place `main.lua` in your executor's autoexec folder
2. Restart Roblox for automatic loading

### Method 3: Loadstring (Recommended)
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/gokuthug1/-AimBot-ESP-latest-/main/src/main.lua"))()
```

## 🎮 Usage

### Basic Usage
1. Execute the script in your preferred Roblox game
2. Press `INSERT` to open the configuration GUI
3. Adjust settings to your preference
4. Press `F1` to toggle AimBot
5. Press `F2` to toggle ESP

### Hotkeys (Default)
- `INSERT` - Toggle Configuration GUI
- `F1` - Toggle AimBot
- `F2` - Toggle ESP
- `F3` - Toggle Tracers
- `F4` - Cycle Aim Target (Head/Torso/Smart)
- `DELETE` - Emergency Disable All Features

### Configuration Options

#### AimBot Settings
- **Enable**: Toggle AimBot on/off
- **Aim Key**: Key to hold for aiming (default: Right Mouse Button)
- **Target Part**: Head, Torso, or Smart selection
- **FOV**: Field of view circle (10-180 degrees)
- **Smoothness**: Aim smoothing factor (1-20)
- **Prediction**: Enable target movement prediction
- **Team Check**: Ignore teammates

#### ESP Settings
- **Enable**: Toggle ESP on/off
- **Players**: Show player boxes and names
- **Health Bars**: Display health information
- **Distance**: Show distance to players
- **Tracers**: Lines to players
- **Skeleton**: Bone structure display
- **Team Colors**: Use team-based colors

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
