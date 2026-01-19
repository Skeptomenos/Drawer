# Code Style Guide

Swift conventions and patterns for the Drawer codebase.

## File Header

```swift
//
//  FileName.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//
```

## Imports

Group alphabetically: Apple frameworks first, then third-party.

```swift
import AppKit
import Combine
import Foundation
import os.log
import ScreenCaptureKit
import SwiftUI

import HotKey
```

## Naming Conventions

| Type                | Convention            | Example                            |
| ------------------- | --------------------- | ---------------------------------- |
| Variables/Functions | camelCase             | `isDrawerVisible`, `toggleDrawer()` |
| Classes/Structs     | PascalCase            | `MenuBarManager`, `DrawerPanel`      |
| Protocols           | PascalCase + -ing/able | `IconCapturing`, `Configurable`      |
| Constants           | camelCase             | `separatorCollapsedLength`           |

## MARK Comments

```swift
// MARK: - Section Name
// MARK: Published State
// MARK: Private Methods
```

## Error Handling

Define domain-specific errors with `LocalizedError`:

```swift
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

## Concurrency

- Use `@MainActor` for all UI-related classes
- Use `async/await` for asynchronous operations
- Use `Task { }` for fire-and-forget async work
- Avoid `DispatchQueue` unless interfacing with legacy APIs

## Memory Management

- Use `[weak self]` in closures that capture `self`
- Use `assign(to: &$property)` for Combine bindings (no retain cycle)
- Cancel Combine subscriptions in `deinit`

## Forbidden Patterns

| Pattern                       | Use Instead                 |
| ----------------------------- | --------------------------- |
| Storyboards/XIBs              | SwiftUI code                |
| Cocoa Bindings                | Combine or `@Published`       |
| `DispatchQueue.main`            | `@MainActor`                  |
| Force unwrapping (`!`)          | `guard let` or `if let`         |
| Empty catch blocks            | Handle or log errors        |
| Bypassing TCC programmatically | `PermissionManager` flow     |

## UI/UX Guidelines

### Materials
- Use `NSVisualEffectView` bridged to SwiftUI
- Default material: `.menu` or `.popover`

### Animations
```swift
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isVisible)
```

### Typography
- System fonts: `.system(size: 13)`
- Match menu bar text weight

### Iconography
- SF Symbols with `.medium` stroke weight

### Visual Polish
- 0.5px inner border: `Color.white.opacity(0.2)`
- Shadow: `Shadow(radius: 5)`

## Reference Images

Check `specs/reference_images/` before implementing Views.
