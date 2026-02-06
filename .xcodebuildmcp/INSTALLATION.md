# XcodeBuildMCP Installation Summary

## Installation Date
2026-02-02

## What Was Installed

### 1. OpenCode MCP Configuration
**File**: `/Users/david.helmus/repos/apps/Drawer/opencode.json`

Added XcodeBuildMCP as a local MCP server with:
- All workflows enabled: simulator, ui-automation, debugging, macos, swift-package
- Incremental builds disabled (recommended for stability)
- Sentry telemetry enabled (can be disabled if needed)

### 2. Project Configuration
**File**: `/Users/david.helmus/repos/apps/Drawer/.xcodebuildmcp/config.yaml`

Created project-specific configuration with:
- Session defaults for Drawer project
- Project path: `./Drawer.xcodeproj`
- Scheme: `Drawer`
- Platform: macOS
- Architecture: arm64

### 3. XcodeBuildMCP Skill
**Location**: `~/.config/opencode/skills/xcodebuildmcp/`

Installed the official XcodeBuildMCP skill to help OpenCode agents discover and use the tools effectively.

## System Verification

✅ **macOS**: 26.2 (exceeds requirement of 14.5+)
✅ **Xcode**: 26.2 (exceeds requirement of 16.x+)
✅ **Node.js**: v25.3.0 (exceeds requirement of 18.x+)
✅ **AXe**: Bundled (required for UI automation)
✅ **Tools Available**: 64 tools across 13 workflows

## Available Workflows

1. **simulator** - iOS/watchOS/tvOS/visionOS simulator tools
2. **ui-automation** - UI testing and automation (tap, swipe, screenshot, etc.)
3. **debugging** - Debugging tools
4. **macos** - macOS-specific build and run tools
5. **swift-package** - Swift Package Manager tools
6. **device** - Physical device tools
7. **project-discovery** - Project and scheme discovery
8. **session-management** - Session defaults management
9. **simulator-management** - Simulator lifecycle management
10. **logging** - Log capture and management
11. **project-scaffolding** - Project template scaffolding
12. **utilities** - Utility tools
13. **doctor** - Diagnostic tools

## Next Steps

### To Use XcodeBuildMCP

1. **Restart OpenCode** to load the new MCP server
2. **Set session defaults** first:
   ```
   Use session_show_defaults to see current defaults
   Use session_set_defaults to configure project/scheme/simulator
   ```
3. **Use the tools** - OpenCode agents can now use XcodeBuildMCP tools

### Common Commands

- Build for macOS: `build_macos`
- Build and run: `build_run_macos`
- Run tests: `test_macos`
- List schemes: `list_schemes`
- Show build settings: `show_build_settings`

### Troubleshooting

If tools don't appear:
1. Restart OpenCode
2. Check `opencode.json` is valid JSON
3. Run `npx --package xcodebuildmcp@latest xcodebuildmcp-doctor` to verify installation
4. Check OpenCode logs for MCP connection errors

### Documentation

- XcodeBuildMCP docs: https://github.com/cameroncooke/XcodeBuildMCP
- OpenCode MCP docs: https://opencode.ai/docs/mcp-servers/
- Skill reference: `~/.config/opencode/skills/xcodebuildmcp/SKILL.md`

## Configuration Files

```
Drawer/
├── opencode.json                    # OpenCode config with MCP server
└── .xcodebuildmcp/
    ├── config.yaml                  # Project-specific XcodeBuildMCP config
    └── INSTALLATION.md              # This file
```

## Environment Variables (Optional)

You can override config via environment variables:

- `XCODEBUILDMCP_ENABLED_WORKFLOWS` - Comma-separated workflow list
- `INCREMENTAL_BUILDS_ENABLED` - Enable experimental incremental builds
- `XCODEBUILDMCP_SENTRY_DISABLED` - Disable error telemetry
- `XCODEBUILDMCP_DEBUG` - Enable debug logging

## Notes

- XcodeBuildMCP automatically skips macro validation to avoid Swift Macro build errors
- UI automation requires Screen Recording permission
- Physical device tools require proper code signing configuration
- Session defaults reduce token usage and ensure consistent behavior
