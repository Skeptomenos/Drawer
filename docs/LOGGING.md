# Logging Guidelines

Drawer uses extensive debug logging for ongoing refinement, troubleshooting, and user support. **Debug logs should be preserved, not removed after feature completion.**

## Framework

Use Apple's unified logging via `os.log`:

```swift
import os.log

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.drawer",
    category: "ComponentName"
)
```

## Log Levels

| Level   | Method             | Usage                             | Example                            |
| ------- | ------------------ | --------------------------------- | ---------------------------------- |
| Debug   | `logger.debug()`   | Detailed flow, state dumps        | Icon positions, matching attempts  |
| Info    | `logger.info()`    | Key events, milestones            | "Refresh triggered"                |
| Warning | `logger.warning()` | Recoverable issues                | "Cache miss, falling back"         |
| Error   | `logger.error()`   | Failures requiring attention      | "Could not find IconItem"          |

## Categories

Use consistent category names for filtering:

| Category                    | Files                            | Purpose                     |
| --------------------------- | -------------------------------- | --------------------------- |
| `MenuBarManager`              | MenuBarManager.swift             | Toggle, collapse/expand     |
| `IconCapturer`                | IconCapturer.swift               | Screen capture, slicing     |
| `IconRepositioner`            | IconRepositioner.swift           | CGEvent-based moves         |
| `SettingsMenuBarLayoutView`   | SettingsMenuBarLayoutView.swift  | Layout reconciliation       |
| `PermissionManager`           | PermissionManager.swift          | TCC permission checks       |
| `DrawerManager`               | DrawerManager.swift              | Panel show/hide             |

## Log Format Conventions

```swift
// Structured format for complex operations
logger.debug("=== OPERATION START ===")
logger.debug("Input: param1=\(value1), param2=\(value2)")
// ... operation ...
logger.debug("=== OPERATION END: result=\(result) ===")

// Indentation for hierarchical data
logger.debug("Processing \(items.count) items:")
for (index, item) in items.enumerated() {
    logger.debug("  [\(index)] name=\(item.name), value=\(item.value)")
}

// Context in error logs
logger.error("Operation failed: \(error.localizedDescription)")
logger.error("  Context: bundleId=\(bundleId ?? "nil"), windowID=\(windowID)")
```

## Viewing Logs

```bash
# Stream all Drawer logs in real-time
log stream --predicate 'subsystem == "com.drawer"' --level debug

# Filter by category
log stream --predicate 'subsystem == "com.drawer" AND category == "IconRepositioner"' --level debug

# Save to file
log stream --predicate 'subsystem == "com.drawer"' --level debug > ~/Desktop/drawer_debug.log

# Search historical logs
log show --predicate 'subsystem == "com.drawer"' --last 1h --level debug
```

## Components Requiring Persistent Logging

These components deal with complex system interactions and **must retain debug logging**:

1. **Menu Bar Layout** (`SettingsMenuBarLayoutView.swift`)
   - Icon reconciliation logic
   - Drag-drop operations
   - Physical repositioning triggers

2. **Icon Repositioner** (`IconRepositioner.swift`)
   - CGEvent creation and posting
   - Frame change detection
   - Retry and wake-up logic

3. **Icon Capturer** (`IconCapturer.swift`)
   - Window enumeration
   - Section type detection
   - Separator position calculations

4. **Permission Manager** (`PermissionManager.swift`)
   - TCC permission state changes
   - Permission request flows

## Performance Considerations

- Debug logs are compiled out in Release builds when using `logger.debug()`
- For hot paths, guard expensive string interpolation:

```swift
#if DEBUG
logger.debug("Expensive log: \(expensiveComputation())")
#endif
```

## Why Preserve Logs

Unlike typical development where debug logs are removed, Drawer's logs are preserved because:

1. **User Support**: Logs help diagnose user-reported issues
2. **macOS Updates**: System behavior may change between versions
3. **Third-Party Apps**: Menu bar apps may behave unexpectedly
4. **Regression Detection**: Logs help identify when behavior changes
