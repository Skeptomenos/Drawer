# Drawer Agent Operational Guide (AGENTS.md)

## 1. Project Overview

**Drawer** is a high-performance macOS menu bar utility (forked from Hidden Bar) that declutters the system menu bar by hiding icons into a secondary, collapsible "Drawer" (NSPanel).

**Goal**: Create a native macOS menu bar utility that equals or surpasses Bartender in aesthetics and functionality.

| Attribute | Value |
|-----------|-------|
| Target OS | macOS 14.0+ |
| Language | Swift 5.9+ |
| Frameworks | SwiftUI (UI), AppKit (Windowing/StatusItems), ScreenCaptureKit (Icon Capture) |
| Architecture | MVVM |
| License | MIT |

---

## 2. Build, Lint & Test Commands

### Build
```bash
# Debug build
xcodebuild -scheme Drawer -configuration Debug build

# Release build
xcodebuild -scheme Drawer -configuration Release build

# Clean build
xcodebuild -scheme Drawer clean build
```

### Linting
```bash
# Lint all files
swiftlint lint Drawer/

# Auto-fix issues
swiftlint --fix Drawer/

# Lint specific file
swiftlint lint Drawer/Core/Managers/MenuBarManager.swift
```

### Testing
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

**Test Suite**: The `DrawerTests/` target contains 31 test files with 277 tests covering all managers, engines, models, and utilities. Run `xcodebuild test` to execute the full suite.

---

## 3. Code Style Guidelines

### File Header
```swift
//
//  FileName.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//
```

### Imports (Alphabetical, Grouped)
```swift
import AppKit          // 1. Apple frameworks
import Combine
import Foundation
import os.log
import ScreenCaptureKit
import SwiftUI

import HotKey          // 2. Third-party dependencies
```

### Naming Conventions
| Type | Convention | Example |
|------|------------|---------|
| Variables/Functions | camelCase | `isDrawerVisible`, `toggleDrawer()` |
| Classes/Structs/Enums | PascalCase | `MenuBarManager`, `DrawerPanel` |
| Protocols | PascalCase + -ing/-able | `IconCapturing`, `Configurable` |
| Constants | camelCase | `separatorCollapsedLength` |

### MARK Comments
```swift
// MARK: - Section Name
// MARK: Published State
// MARK: Private Methods
```

### Error Handling
```swift
// Define domain-specific errors with LocalizedError
enum CaptureError: Error, LocalizedError {
    case permissionDenied
    case menuBarNotFound
    case systemError(Error)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Screen Recording permission is required"
        case .menuBarNotFound:
            return "Could not locate the menu bar window"
        case .systemError(let error):
            return "System error: \(error.localizedDescription)"
        }
    }
}
```

### Concurrency
- Use `@MainActor` for all UI-related classes
- Use `async/await` for asynchronous operations
- Use `Task { }` for fire-and-forget async work
- Avoid `DispatchQueue` unless interfacing with legacy APIs

### Memory Management
- Use `[weak self]` in closures that capture `self`
- Use `assign(to: &$property)` for Combine bindings (no retain cycle)
- Cancel Combine subscriptions in `deinit`

---

## 4. Project Structure

```
Drawer/
├── App/                    # App entry point
│   ├── DrawerApp.swift     # @main SwiftUI App
│   ├── AppDelegate.swift   # NSApplicationDelegate
│   └── AppState.swift      # Global state coordinator
├── Core/
│   ├── Managers/           # Business logic singletons
│   │   ├── MenuBarManager.swift    # CRITICAL: 10k pixel hack
│   │   ├── DrawerManager.swift
│   │   ├── PermissionManager.swift
│   │   ├── SettingsManager.swift
│   │   ├── HoverManager.swift
│   │   └── LaunchAtLoginManager.swift
│   └── Engines/
│       └── IconCapturer.swift      # ScreenCaptureKit logic
├── UI/
│   ├── Panels/             # NSPanel wrappers (DrawerPanel)
│   ├── Overlay/            # Overlay mode components (OverlayPanel, OverlayPanelController)
│   ├── Settings/           # Preferences views
│   ├── Onboarding/         # First-run experience
│   └── Components/         # Reusable UI elements
├── Models/                 # Data structures
├── Utilities/              # Extensions, helpers
└── Bridging/               # Private API shims
```

---

## 5. Critical Infrastructure

| Component | Responsibility | Risk Level |
|-----------|----------------|------------|
| `MenuBarManager` | 10k pixel hack, NSStatusItem positions | **CRITICAL** |
| `IconCapturer` | ScreenCaptureKit menu bar capture | **HIGH** |
| `PermissionManager` | TCC (Accessibility/Screen Recording) | **HIGH** |
| `DrawerPanel` | NSPanel hosting secondary bar | MEDIUM |
| `EventSimulator` | Click-through simulation | MEDIUM |

**Modify with extreme caution. Always verify menu bar behavior after changes.**

---

## 6. Forbidden Patterns

| Pattern | Reason |
|---------|--------|
| Storyboards/XIBs | All UI must be code-based (SwiftUI) |
| Cocoa Bindings | Use Combine or `@Published` |
| `DispatchQueue.main` | Use `@MainActor` instead |
| Force unwrapping (`!`) | Use `guard let` or `if let` |
| Empty catch blocks | Always handle or log errors |
| Bypassing TCC programmatically | Use `PermissionManager` flow |

---

## 7. UI/UX Design System

### Materials
- Use `NSVisualEffectView` bridged to SwiftUI
- Default material: `.menu` or `.popover`

### Animations
```swift
// Standard drawer animation
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isVisible)
```

### Typography
- Use system fonts: `.system(size: 13)`
- Match menu bar text weight

### Iconography
- Use SF Symbols with `.medium` stroke weight

### Visual Polish
- 0.5px inner border: `Color.white.opacity(0.2)`
- Shadow: `Shadow(radius: 5)`

### Reference Images
Check `specs/reference_images/` before implementing Views. Use `look_at` tool to analyze layout, padding, and materials.

---

## 8. Testing Strategy

### Unit Tests (Required for Managers/Engines)
```swift
import XCTest
@testable import Drawer

final class MenuBarManagerTests: XCTestCase {
    @MainActor
    func testToggle() async {
        let manager = MenuBarManager()
        XCTAssertTrue(manager.isCollapsed)
        manager.toggle()
        XCTAssertFalse(manager.isCollapsed)
    }
}
```

### UI Verification
- Use Xcode Previews for all Views
- Create Preview Content assets for mock data

### Manual Verification Plan
For system interactions, document verification steps:
```
1. Build and run app
2. Click toggle icon in menu bar
3. Verify separator expands/collapses
4. Verify icons shift position correctly
```

---

## 9. Agent Instructions

### Before Starting Work
1. Read `PRD.md` for product context
2. Check `specs/` for phase-specific requirements
3. Review `specs/reference_images/` for UI work

### After Modifying Critical Components
1. Verify menu bar icons respond to Command+Drag
2. Test toggle behavior in both LTR and RTL layouts
3. Confirm no memory leaks with Instruments

### Permission Handling
- Never bypass TCC permissions programmatically
- Always use `PermissionManager` for permission flows
- Test with permissions both granted and denied

### Commit Guidelines
- Maintain MIT license headers
- Preserve original Hidden Bar attribution where applicable
- Run `swiftlint` before committing

---

## 10. Quick Reference

### Key Files to Understand First
1. `AppState.swift` - Central state coordinator
2. `MenuBarManager.swift` - Core hiding mechanism
3. `IconCapturer.swift` - Screen capture logic
4. `DrawerPanelController.swift` - Panel presentation

### Common Tasks
| Task | Location |
|------|----------|
| Add new setting | `SettingsManager.swift` |
| Modify hiding behavior | `MenuBarManager.swift` |
| Change drawer appearance | `DrawerContentView.swift` |
| Add permission check | `PermissionManager.swift` |
| Handle global events | `GlobalEventMonitor.swift` |
