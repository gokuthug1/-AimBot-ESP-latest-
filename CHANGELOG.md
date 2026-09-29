# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2026-09-28

### Added
- **Unified Native Master Loader**: `src/main.lua` seamlessly orchestrates all modular components (`Config`, `Utils`, `AntiDetection`, `Aimbot`, `ESP`, `GUI`) with multi-tier resolution (local filesystem, GitHub raw HttpGet, and standalone execution fallback).
- **Multi-Mode Aiming**: Added Camera CFrame Lerp aiming (essential for first-person shooters and LockCenter mode such as Arsenal, Phantom Forces, Bad Business, Counter Blox, and mobile), alongside MouseMoveRel and Hybrid modes.
- **Universal TriggerBot**: Integrated high-speed TriggerBot supporting crosshair raycasting, team/NPC filtering, tool-equipped checks, and universal click emulation (`mouse1click`, `mouse1press`/`mouse1release`, `VirtualInputManager`, `Tool:Activate`).
- **Dual-Engine Visuals**: Drawing API support for zero-GUI-footprint rendering, with automatic fallback to ScreenGui across any executor or platform.
- **3D-to-2D Bounding Box Projection**: 8-corner projected bounding boxes that remain upright, accurate, and never collapse or invert regardless of pitch or player orientation.
- **Bone Skeleton ESP**: Complete joint mapping and real-time bone rendering for both R6 and R15 character rigs.
- **X-Ray / Wall Chams**: Transparent wall chams with pristine material/transparency caching and restoration.
- **Target NPC Support**: Real-time detection and targeting for non-player Humanoid models in both Aimbot and ESP.
- **Next-Gen GUI**: Sleek sidebar tabs, animated minimize-to-pill transition, 7 theme palettes (Default, Ruby, Ocean, Midnight, Forest, Light, Blue), and custom background image URL/ID support with opacity slider.
- **Centralized Hotkeys**: Pre-bound handlers for `INSERT` / `RightShift` (GUI), `F1` (AimBot), `F2` (ESP), `F3` (Tracers), `F4` (Cycle Target Part), and `DELETE` (Emergency Disable).
- **Persistent Profile Storage**: Save and load profiles to executor filesystem (`writefile`/`readfile`) with in-memory fallback.

### Fixed
- Fixed non-functional mouse aiming in `aimbot.lua` where `mousemoverel` was commented out.
- Fixed broken tracers in `esp.lua` caused by incorrect anchor point rotation.
- Fixed schema validation errors in `config.lua` when setting nested paths (e.g. `gui.hotkeys.toggleAimbot`).
- Fixed synchronous `task.wait(10)` freezing the frame loop in `anti_detection.lua` by using asynchronous `task.spawn`.
- Fixed CoreGui permission errors on restricted executors by using universal `getSafeGuiParent()` with `gethui()` fallback.
- Fixed infinite wait loop in `examples/basic_usage.lua` by properly exposing `getgenv().AimbotESP.Loaded` in `main.lua`.

---

## [2.0.0] - 2026-01-13

### Added
- Complete modular architecture with separate files for each component
- Advanced GUI configuration system with real-time updates
- Anti-detection mechanisms with randomized behavior patterns
- Profile system for game-specific configurations
- Advanced prediction algorithms for moving targets
- Skeleton ESP with bone structure visualization
- Health bar displays with color-coded health levels
- Distance indicators for all visible players
- Hotkey system with customizable key bindings
- Emergency disable functionality
- Performance optimization settings
- Team-based color coding for ESP
- FOV circle visualization
- Smooth aiming with configurable smoothness levels
- Multiple target selection modes (Head, Torso, Smart)
- Rate limiting to prevent detection
- Comprehensive error handling and validation
- Extensive documentation and examples
- API for integration with other scripts
- Support for multiple script executors
- Compatibility testing for popular Roblox games

---

## [1.0.0] - 2026-01-12

### Added
- Initial release
- Basic AimBot functionality
- Simple ESP features
- MIT License
