# Building Drawer

Commands for building, linting, and testing the Drawer project.

> **For Agents:** Use XcodeBuildMCP tools instead of manual xcodebuild commands. See [TESTING.md](TESTING.md) for the complete XcodeBuildMCP reference.

## Build

**Preferred (XcodeBuildMCP):**
```
XcodeBuildMCP_build_macos                    # Debug build
XcodeBuildMCP_build_macos extraArgs: ["-configuration", "Release"]  # Release build
XcodeBuildMCP_clean                          # Clean build
```

**Manual (reference only):**
```bash
# Debug build
xcodebuild -scheme Drawer -configuration Debug build

# Release build
xcodebuild -scheme Drawer -configuration Release build

# Clean build
xcodebuild -scheme Drawer clean build
```

## Linting

```bash
# Lint all files
swiftlint lint Drawer/

# Auto-fix issues
swiftlint --fix Drawer/

# Lint specific file
swiftlint lint Drawer/Core/Managers/MenuBarManager.swift
```

## Testing

**Preferred (XcodeBuildMCP):**
```
XcodeBuildMCP_test_macos                     # Run all tests
XcodeBuildMCP_test_macos extraArgs: ["-only-testing:DrawerTests/MenuBarManagerTests"]  # Single class
```

**Manual (reference only):**
```bash
# Run all tests
xcodebuild test -scheme Drawer -destination 'platform=macOS'

# Run single test class
xcodebuild test -scheme Drawer -destination 'platform=macOS' \
  -only-testing:DrawerTests/MenuBarManagerTests

# Run single test method
xcodebuild test -scheme Drawer -destination 'platform=macOS' \
  -only-testing:DrawerTests/MenuBarManagerTests/testToggle
```

## Test Suite

The `DrawerTests/` target contains 38 test files covering:

- `DrawerTests/App/` - AppState tests
- `DrawerTests/Core/Managers/` - Manager tests
- `DrawerTests/Core/Engines/` - Engine tests
- `DrawerTests/Models/` - Model tests
- `DrawerTests/Utilities/` - Utility tests
- `DrawerTests/Mocks/` - Mock objects for dependency injection

## Manual Verification

For system interactions that can't be unit tested:

1. Build and run app
2. Click toggle icon in menu bar
3. Verify separator expands/collapses
4. Verify icons shift position correctly
5. Test Command+Drag repositioning
6. Verify hover triggers drawer appearance
7. Test click-through on drawer icons
