# Spec: Phase 3 - "Always Hidden" Section

**Phase:** 3
**Priority:** Medium (P2)
**Estimated Time:** 30-40 minutes
**Dependencies:** Phase 2B (Section Architecture)
**Parent Doc:** `docs/IMPLEMENTATION_PLAN_ARCHITECTURE_IMPROVEMENTS.md`

---

## Objective

Add a third menu bar section called "Always Hidden" that allows users to permanently hide certain icons. These icons will only be visible in the Drawer panel, never in the native menu bar - even when expanded.

---

## Background

### Current State (After Phase 2)
```
Menu Bar Layout:
[Hidden Icons] | [Visible Icons] [Toggle]
               ^
         separatorItem
```

### Target State (Phase 3)
```
Menu Bar Layout:
[Always Hidden] | [Hidden Icons] | [Visible Icons] [Toggle]
                ^                 ^
      alwaysHiddenSep       separatorItem
```

### User Workflow
1. Enable "Always Hidden Section" in Preferences
2. A new separator appears in the menu bar
3. Option+Drag icons to the left of this separator
4. These icons are permanently hidden (10k hack always active)
5. Access them only via the Drawer panel

---

## Feature Requirements

### Functional Requirements

1. **Setting Toggle**: Add `alwaysHiddenSectionEnabled` preference
2. **Third Separator**: Create `alwaysHiddenSection: MenuBarSection` in `MenuBarManager`
3. **Persistent State**: Always-hidden separator stays at 10k length
4. **Drawer Integration**: Capture icons from both hidden sections
5. **UI Labels**: Drawer panel shows section headers ("Hidden" / "Always Hidden")

### Non-Functional Requirements

- Minimal performance impact
- Smooth enable/disable transition
- Persists across app restarts

---

## Implementation

### Step 1: Add Setting to SettingsManager

**File:** `Drawer/Core/Managers/SettingsManager.swift`

```swift
// Add to existing settings
@AppStorage("alwaysHiddenSectionEnabled") var alwaysHiddenSectionEnabled: Bool = false {
    didSet {
        alwaysHiddenSectionEnabledSubject.send(alwaysHiddenSectionEnabled)
    }
}

let alwaysHiddenSectionEnabledSubject = PassthroughSubject<Bool, Never>()

// Add to existing combined publisher if applicable
var alwaysHiddenSettingsChanged: AnyPublisher<Void, Never> {
    alwaysHiddenSectionEnabledSubject
        .map { _ in () }
        .eraseToAnyPublisher()
}
```

### Step 2: Add Always Hidden Section to MenuBarManager

**File:** `Drawer/Core/Managers/MenuBarManager.swift`

Add property:
```swift
/// The always-hidden section (optional, user-enabled)
private(set) var alwaysHiddenSection: MenuBarSection?

/// All active sections including optional always-hidden
private var sections: [MenuBarSection] {
    [alwaysHiddenSection, hiddenSection, visibleSection].compactMap { $0 }
}
```

Add setup method:
```swift
private func setupAlwaysHiddenSection() {
    guard settings.alwaysHiddenSectionEnabled else {
        // Remove section if disabled
        if alwaysHiddenSection != nil {
            alwaysHiddenSection?.isEnabled = false
            alwaysHiddenSection = nil
            logger.info("Always Hidden section disabled")
        }
        return
    }
    
    guard alwaysHiddenSection == nil else { return }
    
    // Create always-hidden control item
    let alwaysHiddenControl = ControlItem(
        expandedLength: separatorExpandedLength,
        collapsedLength: separatorCollapsedLength,
        initialState: .collapsed // Always stays collapsed
    )
    alwaysHiddenControl.image = .sfSymbol("line.3.horizontal", weight: .regular)
    alwaysHiddenControl.autosaveName = "drawer_always_hidden_v1"
    
    alwaysHiddenSection = MenuBarSection(
        type: .alwaysHidden,
        controlItem: alwaysHiddenControl,
        isExpanded: false, // Never expands
        isEnabled: true
    )
    
    logger.info("Always Hidden section enabled")
}
```

Add binding in `setupSettingsBindings()`:
```swift
settings.alwaysHiddenSettingsChanged
    .sink { [weak self] in
        self?.setupAlwaysHiddenSection()
    }
    .store(in: &cancellables)
```

Call in `init()`:
```swift
setupSections()
setupAlwaysHiddenSection() // ADD THIS
setupSettingsBindings()
setupStateBindings()
```

### Step 3: Modify Toggle Logic

The always-hidden section should NEVER expand when toggle is pressed. Update the state binding:

```swift
private func setupStateBindings() {
    $isCollapsed
        .dropFirst()
        .sink { [weak self] collapsed in
            guard let self = self else { return }
            
            // Hidden section responds to toggle
            self.hiddenSection.isExpanded = !collapsed
            
            // Always-hidden section stays collapsed (never expands)
            // No change needed - it's always collapsed
            
            // Update toggle image
            self.visibleSection.controlItem.image = collapsed 
                ? self.expandImage 
                : self.collapseImage
                
            self.logger.debug("State binding: isCollapsed=\(collapsed)")
        }
        .store(in: &cancellables)
}
```

### Step 4: Add Settings UI

**File:** `Drawer/UI/Settings/GeneralSettingsView.swift`

Add toggle in the appropriate section:

```swift
Section("Advanced") {
    Toggle("Enable \"Always Hidden\" section", isOn: $settings.alwaysHiddenSectionEnabled)
        .help("Add a third separator for icons that should never appear in the menu bar")
}
```

### Step 5: Update IconCapturer

**File:** `Drawer/Core/Engines/IconCapturer.swift`

Modify capture logic to identify which section an icon belongs to:

```swift
struct CapturedIcon: Identifiable {
    let id: UUID
    let image: CGImage
    let originalFrame: CGRect
    let capturedAt: Date
    let itemInfo: MenuBarItemInfo?
    let sectionType: MenuBarSectionType // NEW
}
```

Update capture method to determine section based on X position relative to separators:

```swift
private func determineSectionType(
    for frame: CGRect,
    hiddenSeparatorX: CGFloat,
    alwaysHiddenSeparatorX: CGFloat?
) -> MenuBarSectionType {
    let iconCenterX = frame.midX
    
    // If always-hidden section exists and icon is to its left
    if let alwaysHiddenX = alwaysHiddenSeparatorX, iconCenterX < alwaysHiddenX {
        return .alwaysHidden
    }
    
    // If icon is between always-hidden and hidden separators (or just left of hidden)
    if iconCenterX < hiddenSeparatorX {
        return .hidden
    }
    
    return .visible
}
```

### Step 6: Update Drawer UI

**File:** `Drawer/UI/Panels/DrawerContentView.swift`

Add section headers when always-hidden is enabled:

```swift
struct DrawerContentView: View {
    let items: [DrawerItem]
    let isLoading: Bool
    var error: Error?
    var onItemTap: ((DrawerItem) -> Void)?
    
    private var alwaysHiddenItems: [DrawerItem] {
        items.filter { $0.sectionType == .alwaysHidden }
    }
    
    private var hiddenItems: [DrawerItem] {
        items.filter { $0.sectionType == .hidden }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !alwaysHiddenItems.isEmpty {
                SectionHeader(title: "Always Hidden")
                IconGrid(items: alwaysHiddenItems, onItemTap: onItemTap)
            }
            
            if !hiddenItems.isEmpty {
                if !alwaysHiddenItems.isEmpty {
                    Divider()
                }
                SectionHeader(title: "Hidden")
                IconGrid(items: hiddenItems, onItemTap: onItemTap)
            }
            
            if items.isEmpty && !isLoading {
                EmptyStateView()
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
    }
}
```

### Step 7: Update DrawerItem Model

**File:** `Drawer/Models/DrawerItem.swift`

Add section type:

```swift
struct DrawerItem: Identifiable, Equatable {
    let id: UUID
    let image: CGImage
    let originalFrame: CGRect
    let capturedAt: Date
    let index: Int
    let sectionType: MenuBarSectionType // NEW
    
    var clickTarget: CGPoint {
        CGPoint(x: originalFrame.midX, y: originalFrame.midY)
    }
}
```

---

## Acceptance Criteria

- [ ] `alwaysHiddenSectionEnabled` setting in SettingsManager
- [ ] Toggle in General Settings UI
- [ ] Third separator appears when enabled
- [ ] Third separator uses distinct icon (line.3.horizontal)
- [ ] Third separator never expands (always at 10k)
- [ ] Icons captured correctly identify their section
- [ ] Drawer panel shows section headers when applicable
- [ ] Disabling removes the separator cleanly
- [ ] Setting persists across app restarts
- [ ] Build succeeds with no warnings

---

## Testing

### Manual Verification Steps

1. Build and run app
2. Open Preferences → General
3. Enable "Always Hidden section"
4. Verify third separator appears in menu bar
5. Option+Drag an icon to the left of new separator
6. Click toggle to expand hidden section
7. Verify "always hidden" icon does NOT appear
8. Open Drawer panel (right-click separator → Show Drawer)
9. Verify both section headers appear
10. Verify "always hidden" icon appears in Drawer
11. Click icon in Drawer → verify click-through works
12. Disable the setting → verify separator disappears
13. Re-enable → verify separator reappears with remembered position

### Edge Cases

- Enable/disable rapidly
- Many icons in always-hidden section
- RTL layout support
- Notched MacBook (separator behind notch)

---

## Files Changed

| File | Action |
|------|--------|
| `Drawer/Core/Managers/SettingsManager.swift` | Add setting |
| `Drawer/Core/Managers/MenuBarManager.swift` | Add section |
| `Drawer/UI/Settings/GeneralSettingsView.swift` | Add toggle |
| `Drawer/Core/Engines/IconCapturer.swift` | Add section detection |
| `Drawer/Models/DrawerItem.swift` | Add sectionType |
| `Drawer/UI/Panels/DrawerContentView.swift` | Add section headers |
