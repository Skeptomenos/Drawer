# Testing with XcodeBuildMCP

Drawer uses XcodeBuildMCP for automated building, testing, and simulator interaction. **Agents must use these tools** for testing rather than manual xcodebuild commands.

## Quick Reference

### Setup (Do This First)

```
XcodeBuildMCP_session-set-defaults
  projectPath: /path/to/Drawer.xcodeproj
  scheme: Drawer
  simulatorName: iPhone 16 Pro
  useLatestOS: true
```

### Common Workflows

| Task                    | Tool                              |
| ----------------------- | --------------------------------- |
| Build for simulator     | `XcodeBuildMCP_build_sim`           |
| Build & run             | `XcodeBuildMCP_build_run_sim`       |
| Run all tests           | `XcodeBuildMCP_test_sim`            |
| Run macOS tests         | `XcodeBuildMCP_test_macos`          |
| Take screenshot         | `XcodeBuildMCP_screenshot`          |
| Get UI hierarchy        | `XcodeBuildMCP_describe_ui`         |
| Clean build             | `XcodeBuildMCP_clean`               |

## Build Commands

### Build for Simulator
```
XcodeBuildMCP_build_sim
```

### Build and Run
```
XcodeBuildMCP_build_run_sim
```

### Build for macOS (Native)
```
XcodeBuildMCP_build_macos
```

### Clean Build Products
```
XcodeBuildMCP_clean
  platform: macOS
```

## Testing

### Run All Tests
```
XcodeBuildMCP_test_sim
```

For macOS-specific tests:
```
XcodeBuildMCP_test_macos
```

### Run Tests with Environment Variables
```
XcodeBuildMCP_test_sim
  testRunnerEnv: {"SOME_VAR": "value"}
```

## Simulator Management

### List Available Simulators
```
XcodeBuildMCP_list_sims
```

### Boot a Simulator
```
XcodeBuildMCP_boot_sim
```

### Open Simulator App
```
XcodeBuildMCP_open_sim
```

### Install App on Simulator
```
XcodeBuildMCP_install_app_sim
  appPath: /path/to/Drawer.app
```

### Launch App
```
XcodeBuildMCP_launch_app_sim
  bundleId: com.drawer.app
```

### Stop App
```
XcodeBuildMCP_stop_app_sim
  bundleId: com.drawer.app
```

## UI Testing & Debugging

### Get UI Hierarchy
Use this to find element coordinates for automation:
```
XcodeBuildMCP_describe_ui
```
Returns JSON tree with frame data (x, y, width, height) for all visible elements.

### Take Screenshot
```
XcodeBuildMCP_screenshot
```

### Tap at Coordinates
```
XcodeBuildMCP_tap
  x: 100
  y: 200
```

Or by accessibility ID:
```
XcodeBuildMCP_tap
  id: "toggleButton"
```

### Type Text
```
XcodeBuildMCP_type_text
  text: "Hello World"
```

### Swipe/Scroll
```
XcodeBuildMCP_gesture
  preset: scroll-down
```

Available presets: `scroll-up`, `scroll-down`, `scroll-left`, `scroll-right`, `swipe-from-left-edge`, `swipe-from-right-edge`, `swipe-from-top-edge`, `swipe-from-bottom-edge`

## Log Capture

### Start Capturing Logs
```
XcodeBuildMCP_start_sim_log_cap
  bundleId: com.drawer.app
```

Returns a `logSessionId` to use when stopping.

### Stop and Retrieve Logs
```
XcodeBuildMCP_stop_sim_log_cap
  logSessionId: <id from start>
```

## macOS App Testing

For testing the actual macOS menu bar app:

### Build and Run macOS App
```
XcodeBuildMCP_build_run_macos
```

### Get App Path
```
XcodeBuildMCP_get_mac_app_path
```

### Launch macOS App
```
XcodeBuildMCP_launch_mac_app
  appPath: /path/to/Drawer.app
```

### Stop macOS App
```
XcodeBuildMCP_stop_mac_app
  appName: Drawer
```

## Project Discovery

### Find Xcode Projects
```
XcodeBuildMCP_discover_projs
  workspaceRoot: /Users/david.helmus/repos/Drawer
```

### List Schemes
```
XcodeBuildMCP_list_schemes
```

### Show Build Settings
```
XcodeBuildMCP_show_build_settings
```

## Session Defaults

Set defaults once to avoid repeating parameters:

```
XcodeBuildMCP_session-set-defaults
  workspacePath: /path/to/Drawer.xcodeproj
  scheme: Drawer
  simulatorName: iPhone 16 Pro
  useLatestOS: true
  configuration: Debug
```

View current defaults:
```
XcodeBuildMCP_session-show-defaults
```

Clear defaults:
```
XcodeBuildMCP_session-clear-defaults
  all: true
```

## Typical Testing Workflow

1. **Set session defaults** (once per session)
   ```
   XcodeBuildMCP_session-set-defaults
     scheme: Drawer
     simulatorName: iPhone 16 Pro
   ```

2. **Build the app**
   ```
   XcodeBuildMCP_build_sim
   ```

3. **Run tests**
   ```
   XcodeBuildMCP_test_sim
   ```

4. **If tests fail, capture logs**
   ```
   XcodeBuildMCP_start_sim_log_cap
     bundleId: com.drawer.app
   
   # Reproduce the issue...
   
   XcodeBuildMCP_stop_sim_log_cap
     logSessionId: <id>
   ```

5. **For UI verification**
   ```
   XcodeBuildMCP_describe_ui
   XcodeBuildMCP_screenshot
   ```

## When to Use XcodeBuildMCP vs Manual Commands

| Scenario                  | Use                     |
| ------------------------- | ----------------------- |
| Building the app          | `XcodeBuildMCP_build_*`   |
| Running tests             | `XcodeBuildMCP_test_*`    |
| UI interaction testing    | `XcodeBuildMCP_tap`, etc. |
| Debugging with logs       | `XcodeBuildMCP_*_log_cap` |
| Quick shell commands      | Bash tool               |
| Reading/editing files     | Read/Edit tools         |

**Always prefer XcodeBuildMCP tools** for Xcode operations - they provide better error handling, structured output, and session management.
