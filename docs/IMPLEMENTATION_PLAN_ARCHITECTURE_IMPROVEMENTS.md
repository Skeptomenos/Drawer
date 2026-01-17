# Implementation Plan: Architecture Improvements
**Date:** January 17, 2026
**Status:** Draft
**Based on:** `docs/ARCHITECTURE_COMPARISON.md`, `docs/ROOT_CAUSE_INVISIBLE_ICONS.md`

---

## Executive Summary

This document outlines a phased approach to improving Drawer's architecture based on lessons learned from analyzing Ice (a competing menu bar utility). The goals are:

1. Fix critical bugs caused by state desynchronization
2. Adopt a more maintainable Section-based architecture
3. Add feature parity with Ice ("Always Hidden" section)
4. Future-proof for Overlay Mode to solve the MacBook Notch problem

---

## Phase 0: Critical Bug Fix (P0)

### Task: Fix Initial State Desynchronization

**File:** `Drawer/Core/Managers/MenuBarManager.swift`
**Priority:** CRITICAL
**Effort:** 1 line change
**Status:** Ready to implement

#### Problem
Line 172 unconditionally sets `separatorItem.length = separatorExpandedLength` (20px), ignoring `isCollapsed = true`.

#### Solution
```swift
// Before (line 172)
separatorItem.length = separatorExpandedLength

// After
separatorItem.length = isCollapsed ? separatorCollapsedLength : separatorExpandedLength
```

#### Acceptance Criteria
- [ ] On app launch, if `isCollapsed = true`, separator length is 10000
- [ ] Toggle button shows correct chevron matching state
- [ ] Menu bar icons are hidden on startup

---

## Phase 1: Reactive State Binding (P1)

### Task: Add Combine-Based Length Synchronization

**Priority:** High
**Effort:** Small
**Dependencies:** Phase 0

#### Problem
Manual state management leads to desynchronization bugs. The separator length and toggle image must always match `isCollapsed`.

#### Solution
Add a reactive binding that automatically updates the separator length when `isCollapsed` changes.

```swift
// In MenuBarManager.init(), after setting up items:
$isCollapsed
    .dropFirst() // Skip initial value (handled in setupUI)
    .sink { [weak self] collapsed in
        guard let self = self else { return }
        self.separatorItem.length = collapsed 
            ? self.separatorCollapsedLength 
            : self.separatorExpandedLength
        self.toggleItem.button?.image = collapsed 
            ? self.expandImage 
            : self.collapseImage
    }
    .store(in: &cancellables)
```

#### Benefits
- Single source of truth for state
- Automatic UI updates
- Prevents future desync bugs

#### Acceptance Criteria
- [ ] Changing `isCollapsed` automatically updates separator length
- [ ] Changing `isCollapsed` automatically updates toggle image
- [ ] `expand()` and `collapse()` only need to update `isCollapsed`

---

## Phase 2: Section-Based Architecture (P1-P2)

### Task: Refactor to MenuBarSection + ControlItem Model

**Priority:** High
**Effort:** Medium (2-3 days)
**Dependencies:** Phase 1

#### Current Architecture
```
MenuBarManager
├── toggleItem: NSStatusItem (raw)
└── separatorItem: NSStatusItem (raw)
```

#### Target Architecture
```
MenuBarManager
├── visibleSection: MenuBarSection
│   └── controlItem: ControlItem → NSStatusItem
├── hiddenSection: MenuBarSection
│   └── controlItem: ControlItem → NSStatusItem
└── alwaysHiddenSection: MenuBarSection? (optional)
    └── controlItem: ControlItem → NSStatusItem
```

#### New Files to Create

**1. `Drawer/Core/Models/MenuBarSection.swift`**
```swift
enum SectionType: String, CaseIterable {
    case visible
    case hidden
    case alwaysHidden
}

@MainActor
final class MenuBarSection: ObservableObject, Identifiable {
    let id: UUID = UUID()
    let type: SectionType
    let controlItem: ControlItem
    
    @Published var isExpanded: Bool {
        didSet { controlItem.state = isExpanded ? .expanded : .collapsed }
    }
    
    init(type: SectionType, controlItem: ControlItem) {
        self.type = type
        self.controlItem = controlItem
    }
}
```

**2. `Drawer/Core/Models/ControlItem.swift`**
```swift
enum ControlItemState {
    case expanded
    case collapsed
    case hidden
}

@MainActor
final class ControlItem: ObservableObject {
    let statusItem: NSStatusItem
    
    @Published var state: ControlItemState = .collapsed {
        didSet { updateStatusItemLength() }
    }
    
    @Published var image: ControlItemImage?
    
    private let expandedLength: CGFloat
    private let collapsedLength: CGFloat
    
    init(
        statusItem: NSStatusItem,
        expandedLength: CGFloat = 20,
        collapsedLength: CGFloat = 10000
    ) {
        self.statusItem = statusItem
        self.expandedLength = expandedLength
        self.collapsedLength = collapsedLength
    }
    
    private func updateStatusItemLength() {
        switch state {
        case .expanded:
            statusItem.length = expandedLength
        case .collapsed:
            statusItem.length = collapsedLength
        case .hidden:
            statusItem.isVisible = false
        }
    }
}
```

**3. `Drawer/Core/Models/ControlItemImage.swift`**
```swift
enum ControlItemImage {
    case sfSymbol(String, weight: NSFont.Weight = .medium)
    case bezierPath(() -> NSBezierPath)
    case asset(String)
    case none
    
    func render(size: NSSize = NSSize(width: 18, height: 18)) -> NSImage? {
        switch self {
        case .sfSymbol(let name, let weight):
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: weight)
            return NSImage(systemSymbolName: name, accessibilityDescription: name)?
                .withSymbolConfiguration(config)
        case .bezierPath(let pathBuilder):
            return renderBezierPath(pathBuilder(), size: size)
        case .asset(let name):
            return NSImage(named: name)
        case .none:
            return nil
        }
    }
    
    private func renderBezierPath(_ path: NSBezierPath, size: NSSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.labelColor.setFill()
        path.fill()
        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
```

#### Refactored MenuBarManager
```swift
@MainActor
final class MenuBarManager: ObservableObject {
    @Published private(set) var isCollapsed: Bool = true
    
    private var sections: [MenuBarSection] = []
    private var hiddenSection: MenuBarSection!
    private var visibleSection: MenuBarSection!
    
    init(settings: SettingsManager = .shared) {
        setupSections()
        setupBindings()
    }
    
    private func setupSections() {
        // Create hidden section (separator)
        let separatorItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let separatorControl = ControlItem(statusItem: separatorItem)
        hiddenSection = MenuBarSection(type: .hidden, controlItem: separatorControl)
        
        // Create visible section (toggle button)
        let toggleItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let toggleControl = ControlItem(statusItem: toggleItem, expandedLength: 28, collapsedLength: 28)
        visibleSection = MenuBarSection(type: .visible, controlItem: toggleControl)
        
        sections = [hiddenSection, visibleSection]
    }
    
    func toggle() {
        isCollapsed.toggle()
        hiddenSection.isExpanded = !isCollapsed
    }
}
```

#### Acceptance Criteria
- [ ] `MenuBarSection` and `ControlItem` classes created
- [ ] `MenuBarManager` refactored to use sections
- [ ] All existing functionality preserved
- [ ] Unit tests pass

---

## Phase 3: "Always Hidden" Section (P2)

### Task: Add Third Section for Permanently Hidden Icons

**Priority:** Medium
**Effort:** Medium (1-2 days)
**Dependencies:** Phase 2

#### Feature Description
Users can Option+Drag icons past a second separator to "permanently hide" them. These icons only appear in the Drawer panel, never in the menu bar.

#### Menu Bar Layout
```
[Always Hidden Icons] | [Hidden Icons] | [Visible Icons] | Toggle
                      ^                 ^
            alwaysHiddenSep       separatorItem
```

#### Implementation
1. Add `alwaysHiddenSection: MenuBarSection` to `MenuBarManager`
2. Add `alwaysHiddenSectionEnabled` setting in `SettingsManager`
3. Update `IconCapturer` to capture icons between both separators
4. Update Drawer UI to show section labels

#### Settings
```swift
// In SettingsManager.swift
@AppStorage("alwaysHiddenSectionEnabled") var alwaysHiddenSectionEnabled: Bool = false
```

#### Acceptance Criteria
- [ ] Third separator appears when setting enabled
- [ ] Icons between separators are "always hidden"
- [ ] Drawer panel shows all hidden icons (both sections)
- [ ] Setting persists across app restarts

---

## Phase 4: Overlay Mode (P3)

### Task: Render Hidden Icons in NSPanel Instead of Menu Bar

**Priority:** Low (Future)
**Effort:** Large (1-2 weeks)
**Dependencies:** Phase 2, Phase 3

#### Problem
The 10k pixel hack is fragile on notched MacBooks. Icons can get stuck behind the notch or in invalid positions.

#### Solution
Implement "Overlay Mode" where hidden icons are:
1. Kept at 10k offset (permanently hidden from menu bar)
2. Captured via `CGWindowList` APIs
3. Rendered in a floating `NSPanel` at menu bar level

#### Key Components
1. **Icon Mirroring:** Capture and render icon windows in real-time
2. **Click Passthrough:** Forward clicks to original menu bar items
3. **Panel Positioning:** Match menu bar height and styling

#### Existing Infrastructure
Drawer already has:
- `DrawerPanel` - Floating NSPanel
- `DrawerPanelController` - Panel management
- `IconCapturer` - CGWindowList capture
- `EventSimulator` - Click passthrough

#### New Behavior Flow
```
1. User clicks toggle → Open Overlay Panel (not expand menu bar)
2. Panel shows captured icons at menu bar level
3. User clicks icon in panel → EventSimulator sends click to real menu bar
4. Panel dismisses
```

#### Acceptance Criteria
- [ ] Overlay mode setting in preferences
- [ ] Panel renders at menu bar Y-coordinate
- [ ] Captured icons match menu bar appearance
- [ ] Click-through works reliably
- [ ] Works correctly on notched MacBooks

---

## Priority Matrix

| Phase | Task | Effort | Impact | Target |
|-------|------|--------|--------|--------|
| 0 | Fix initial state bug | 1 line | Critical | Immediate |
| 1 | Reactive state binding | Small | High | Week 1 |
| 2 | Section architecture | Medium | High | Week 2-3 |
| 3 | Always Hidden section | Medium | Medium | Week 4 |
| 4 | Overlay Mode | Large | High | Future |

---

## Testing Strategy

### Unit Tests (Required)
```swift
// MenuBarManagerTests.swift
func testInitialStateSync() {
    let manager = MenuBarManager()
    XCTAssertTrue(manager.isCollapsed)
    XCTAssertEqual(manager.currentSeparatorLength, 10000)
}

func testToggleUpdatesLength() {
    let manager = MenuBarManager()
    manager.toggle() // Expand
    XCTAssertEqual(manager.currentSeparatorLength, 20)
    manager.toggle() // Collapse
    XCTAssertEqual(manager.currentSeparatorLength, 10000)
}
```

### Integration Tests
- [ ] Verify icons visible after app launch
- [ ] Verify toggle works correctly
- [ ] Verify auto-collapse timer

### Manual Verification
- [ ] Test on notched MacBook
- [ ] Test on non-notched Mac
- [ ] Test with crowded menu bar (10+ icons)
- [ ] Test RTL layout

---

## Files to Modify/Create

### Phase 0-1
| File | Action |
|------|--------|
| `Drawer/Core/Managers/MenuBarManager.swift` | Modify (fix line 172) |

### Phase 2
| File | Action |
|------|--------|
| `Drawer/Core/Models/MenuBarSection.swift` | Create |
| `Drawer/Core/Models/ControlItem.swift` | Create |
| `Drawer/Core/Models/ControlItemImage.swift` | Create |
| `Drawer/Core/Managers/MenuBarManager.swift` | Refactor |
| `DrawerTests/MenuBarManagerTests.swift` | Create |

### Phase 3
| File | Action |
|------|--------|
| `Drawer/Core/Managers/SettingsManager.swift` | Add setting |
| `Drawer/Core/Managers/MenuBarManager.swift` | Add section |
| `Drawer/UI/Settings/GeneralSettingsView.swift` | Add toggle |

### Phase 4
| File | Action |
|------|--------|
| `Drawer/UI/Panels/OverlayPanel.swift` | Create |
| `Drawer/Core/Managers/OverlayManager.swift` | Create |
| `Drawer/Core/Engines/IconCapturer.swift` | Modify |

---

## Appendix: Reference Implementation (Ice)

Key files from Ice to study:
- `Ice/MenuBar/MenuBarSection.swift`
- `Ice/MenuBar/ControlItem.swift`
- `Ice/MenuBar/ControlItemImage.swift`
- `Ice/IceBar/IceBarPanel.swift`

These provide proven patterns for Section-based architecture and Overlay rendering.
