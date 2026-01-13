# Installation Guide

This guide provides detailed instructions for installing and setting up the Advanced AimBot & ESP system.

## ⚠️ Important Disclaimers

**READ THIS BEFORE PROCEEDING:**

- This software is for **EDUCATIONAL and RESEARCH purposes only**
- Using this in games may **violate Terms of Service** and result in **permanent account bans**
- The developers are **not responsible** for any consequences of use
- Use at your own risk and responsibility
- Respect other players and gaming communities

## 📋 Prerequisites

### Required Software
1. **Roblox Client** - Latest version recommended
2. **Script Executor** - One of the supported executors:
   - ✅ **Synapse X** (Recommended)
   - ✅ **KRNL** (Free alternative)
   - ✅ **Script-Ware**
   - ✅ **Oxygen U**
   - ✅ **Fluxus**
   - ⚠️ **JJSploit** (Limited features)

### System Requirements
- **OS**: Windows 10/11 (64-bit)
- **RAM**: 4GB minimum, 8GB recommended
- **CPU**: Any modern processor
- **GPU**: DirectX 11 compatible
- **Network**: Stable internet connection

## 🚀 Installation Methods

### Method 1: Loadstring (Recommended)

This is the easiest and most convenient method:

1. **Open your script executor**
2. **Copy and paste** the following code:
   ```lua
   loadstring(game:HttpGet("https://raw.githubusercontent.com/gokuthug1/-AimBot-ESP-latest-/main/src/main.lua"))()
   ```
3. **Execute the script**
4. **Wait for initialization** (should take 2-3 seconds)

### Method 2: Manual File Loading

For users who prefer local files:

1. **Download the repository**:
   - Go to the [GitHub repository](https://github.com/gokuthug1/-AimBot-ESP-latest-)
   - Click "Code" → "Download ZIP"
   - Extract the ZIP file

2. **Copy the main script**:
   - Open `src/main.lua` in a text editor
   - Copy all the content

3. **Execute in your script executor**:
   - Paste the content into your executor
   - Click "Execute" or "Inject"

### Method 3: Auto-Execute Setup

For automatic loading every time you join a game:

1. **Locate your executor's autoexec folder**:
   - **Synapse X**: `%appdata%/Synapse/autoexec`
   - **KRNL**: `%appdata%/Krnl/autoexec`
   - **Script-Ware**: `%appdata%/Script-Ware/autoexec`

2. **Create a new file**:
   - Name it `aimbot_esp.lua`
   - Paste the loadstring code from Method 1

3. **Restart Roblox**:
   - The script will automatically load when you join any game

## 🔧 First-Time Setup

### Initial Configuration

1. **Launch the script** using any of the methods above
2. **Wait for the welcome message**:
   ```
   🎯 Advanced AimBot & ESP v2.0.0
   📅 Build Date: 2026-01-13
   ⚠️  Educational use only - Use responsibly!
   ```

3. **Open the GUI**:
   - Press `INSERT` key to open the configuration interface
   - The GUI should appear in the center of your screen

4. **Configure basic settings**:
   - Navigate to the **Aimbot** tab
   - Adjust **FOV** (Field of View) to your preference (90-120 recommended)
   - Set **Smoothness** (8-15 for natural movement)
   - Choose **Target Part** (Head for precision, Smart for versatility)

5. **Configure ESP settings**:
   - Navigate to the **ESP** tab
   - Enable desired features (Player Boxes, Names, Health Bars)
   - Set **Max Distance** based on game type (300-500 recommended)

### Game-Specific Optimization

The system automatically detects popular games and applies optimized settings:

#### Arsenal
- FOV: 90°
- Smoothness: 8
- Target: Head
- ESP Distance: 300m

#### Phantom Forces
- FOV: 80°
- Smoothness: 12
- Target: Torso
- ESP Distance: 400m

#### Bad Business
- FOV: 100°
- Smoothness: 6
- Target: Smart
- ESP Distance: 350m

## 🎮 Basic Usage

### Essential Hotkeys
- `INSERT` - Toggle Configuration GUI
- `F1` - Toggle AimBot On/Off
- `F2` - Toggle ESP On/Off
- `F3` - Toggle Tracers
- `F4` - Cycle Target Mode (Head → Torso → Smart)
- `DELETE` - **Emergency Disable** (disables everything instantly)

### Getting Started
1. **Join a supported game**
2. **Execute the script**
3. **Press F1** to enable AimBot
4. **Press F2** to enable ESP
5. **Hold Right Mouse Button** to aim (default aim key)
6. **Adjust settings** using the GUI (`INSERT` key)

## 🛠️ Troubleshooting

### Common Issues

#### Script Not Loading
**Symptoms**: No welcome message, no GUI appears
**Solutions**:
- Ensure your executor is properly injected
- Try restarting Roblox and your executor
- Check if the game has anti-cheat protection
- Verify your internet connection

#### AimBot Not Working
**Symptoms**: No automatic aiming, FOV circle not visible
**Solutions**:
- Check if AimBot is enabled (`F1` key)
- Verify aim key is set correctly (default: Right Mouse Button)
- Ensure FOV is not too restrictive (try 120°)
- Check if team check is preventing targeting

#### ESP Not Visible
**Symptoms**: No player boxes, names, or tracers
**Solutions**:
- Confirm ESP is enabled (`F2` key)
- Check max distance settings (increase if needed)
- Verify players are within render distance
- Ensure colors aren't set to transparent

#### Performance Issues
**Symptoms**: Low FPS, lag, stuttering
**Solutions**:
- Reduce ESP max distance
- Disable unused ESP features
- Lower update rate in settings
- Close unnecessary programs

#### GUI Not Responding
**Symptoms**: Can't click buttons, sliders don't work
**Solutions**:
- Try pressing `INSERT` to close and reopen GUI
- Restart the script
- Check if another GUI is interfering

### Error Messages

#### "AimBot ESP is already loaded!"
- The script is already running
- Use `DELETE` key to emergency disable, then reload

#### "Configuration validation failed"
- Invalid setting value detected
- Reset to defaults in Settings tab

#### "Safety protocol activated"
- Anti-detection system triggered
- Wait 10 seconds for automatic reset

## 🔒 Security Considerations

### Anti-Cheat Awareness
- **Enable anti-detection** features in Settings
- **Use humanization** to appear more natural
- **Take breaks** to avoid detection patterns
- **Don't use maximum settings** (100% accuracy, 1° FOV, etc.)

### Account Safety
- **Use alternate accounts** for testing
- **Don't stream or record** while using
- **Be discreet** in chat and gameplay
- **Respect other players** and communities

### Best Practices
- Start with **conservative settings**
- **Gradually increase** performance as needed
- **Monitor for detection** signs (unusual lag, kicks)
- **Have exit strategy** ready (emergency disable)

## 📞 Getting Help

### Support Channels
- **GitHub Issues**: [Report bugs and issues](https://github.com/gokuthug1/-AimBot-ESP-latest-/issues)
- **Discussions**: [Community help and questions](https://github.com/gokuthug1/-AimBot-ESP-latest-/discussions)
- **Documentation**: Check other files in the `docs/` folder

### Before Asking for Help
1. **Read this guide completely**
2. **Check the troubleshooting section**
3. **Try basic solutions** (restart, reload, etc.)
4. **Provide detailed information**:
   - Your executor type and version
   - Game you're trying to use it in
   - Exact error messages
   - Steps to reproduce the issue

## 🔄 Updates and Maintenance

### Automatic Updates
The script checks for updates automatically and will notify you of new versions.

### Manual Updates
1. **Download the latest version** from GitHub
2. **Replace your existing files**
3. **Restart the script**
4. **Reconfigure settings** if needed

### Backup Your Settings
- Use the **Export** function in Settings tab
- Save the configuration string to a text file
- Use **Import** to restore settings after updates

---

## ✅ Installation Checklist

- [ ] Downloaded and installed a supported script executor
- [ ] Verified system requirements are met
- [ ] Successfully loaded the script using preferred method
- [ ] Opened the GUI and configured basic settings
- [ ] Tested AimBot and ESP functionality
- [ ] Configured hotkeys and preferences
- [ ] Read and understood safety considerations
- [ ] Bookmarked support resources

**Congratulations!** You're now ready to use the Advanced AimBot & ESP system. Remember to use it responsibly and respect the gaming community.

---

*For additional help, consult the other documentation files or visit our GitHub repository.*