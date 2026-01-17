# Spec: Phase 2B - MenuBarSection and Manager Refactor

**Phase:** 2B
**Priority:** High (P1-P2)
**Estimated Time:** 30-40 minutes
**Dependencies:** Phase 2A (Core Models)
**Parent Doc:** `docs/IMPLEMENTATION_PLAN_ARCHITECTURE_IMPROVEMENTS.md`

---

## Objective

Create the `MenuBarSection` model and refactor `MenuBarManager` to use the Section-based architecture. This provides a clean abstraction for managing menu bar regions and prepares for the "Always Hidden" feature.

---

## Background

After Phase 2A, we have:
- `ControlItem` - Wraps NSStatusItem with reactive state
- `ControlItemImage` - Flexible icon rendering
- `ControlItemState` - State enum

Now we need:
- `MenuBarSection` - Groups a ControlItem with section metadata
- Refactored `MenuBarManager` - Uses sections instead of raw status items

---

## Files to Create/Modify

### 1. CREATE: `Drawer/Core/Models/MenuBarSection.swift`

### 2. MODIFY: `Drawer/Core/Managers/MenuBarManager.swift`

---

## Implementation

### File 1: `Drawer/Core/Models/MenuBarSection.swift`

```swift
//
//  MenuBarSection.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import Combine
import os.log

/// Represents the type of menu bar section
enum MenuBarSectionType: String, CaseIterable, Identifiable {
    /// The always-visible toggle button area
    case visible
    
    /// The hideable section (between separator and toggle)
    case hidden
    
    /// The always-hidden section (only visible in Drawer panel)
    case alwaysHidden
    
    var id: String { rawValue }
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .visible: return "Visible"
        case .hidden: return "Hidden"
        case .alwaysHidden: return "Always Hidden"
        }
    }
}

/// Represents a logical section of the menu bar.
/// Each section contains a control item that manages its separator/toggle.
@MainActor
final class MenuBarSection: ObservableObject, Identifiable {
    
    // MARK: - Properties
    
    let id: UUID = UUID()
    let type: MenuBarSectionType
    let controlItem: ControlItem
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.drawer", category: "MenuBarSection")
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published State
    
    /// Whether this section is currently expanded (showing its icons)
    @Published var isExpanded: Bool = false {
        didSet {
            guard oldValue != isExpanded else { return }
            controlItem.state = isExpanded ? .expanded : .collapsed
            logger.debug("Section '\(self.type.rawValue)' isExpanded=\(self.isExpanded)")
        }
    }
    
    /// Whether this section is enabled (visible in menu bar)
    @Published var isEnabled: Bool = true {
        didSet {
            guard oldValue != isEnabled else { return }
            if !isEnabled {
                controlItem.state = .hidden
            } else {
                controlItem.state = isExpanded ? .expanded : .collapsed
            }
            logger.debug("Section '\(self.type.rawValue)' isEnabled=\(self.isEnabled)")
        }
    }
    
    // MARK: - Initialization
    
    /// Creates a new MenuBarSection
    /// - Parameters:
    ///   - type: The type of section
    ///   - controlItem: The control item managing this section's status bar presence
    ///   - isExpanded: Initial expanded state (default: false)
    ///   - isEnabled: Initial enabled state (default: true)
    init(
        type: MenuBarSectionType,
        controlItem: ControlItem,
        isExpanded: Bool = false,
        isEnabled: Bool = true
    ) {
        self.type = type
        self.controlItem = controlItem
        self.isExpanded = isExpanded
        self.isEnabled = isEnabled
        
        // Apply initial state
        if !isEnabled {
            controlItem.state = .hidden
        } else {
            controlItem.state = isExpanded ? .expanded : .collapsed
        }
    }
    
    // MARK: - Actions
    
    /// Toggles the expanded state of this section
    func toggle() {
        isExpanded.toggle()
    }
    
    /// Expands this section (shows hidden icons)
    func expand() {
        guard !isExpanded else { return }
        isExpanded = true
    }
    
    /// Collapses this section (hides icons)
    func collapse() {
        guard isExpanded else { return }
        isExpanded = false
    }
    
    deinit {
        cancellables.removeAll()
    }
}
```

### File 2: Refactor `MenuBarManager.swift`

This is a significant refactor. The key changes:

1. Replace `toggleItem`/`separatorItem` with `ControlItem` instances
2. Wrap them in `MenuBarSection` objects
3. Simplify toggle logic to use section methods
4. Maintain backward compatibility for existing callers

```swift
//
//  MenuBarManager.swift
//  Drawer
//
//  Copyright © 2026 Drawer. MIT License.
//

import AppKit
import Combine
import os.log

// MARK: - MenuBarManager

/// Implements the "10k pixel hack" - hides menu bar icons by expanding a separator to 10,000px,
/// pushing icons off-screen. This is the HEART of the app.
@MainActor
final class MenuBarManager: ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var isCollapsed: Bool = true
    @Published private(set) var isToggling: Bool = false
    
    // MARK: - Sections
    
    /// The hidden section (separator that expands to hide icons)
    private(set) var hiddenSection: MenuBarSection!
    
    /// The visible section (toggle button)
    private(set) var visibleSection: MenuBarSection!
    
    /// All active sections
    private var sections: [MenuBarSection] {
        [hiddenSection, visibleSection].compactMap { $0 }
    }
    
    // MARK: - Legacy Accessors (for backward compatibility)
    
    /// Exposes the separator's control item for legacy code
    var separatorControlItem: ControlItem {
        hiddenSection.controlItem
    }
    
    /// Exposes the toggle's control item for legacy code  
    var toggleControlItem: ControlItem {
        visibleSection.controlItem
    }
    
    // MARK: - Dependencies
    
    private let settings: SettingsManager
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.drawer", category: "MenuBarManager")
    private var cancellables = Set<AnyCancellable>()
    private var autoCollapseTask: Task<Void, Never>?
    
    // MARK: - Constants
    
    private let separatorExpandedLength: CGFloat = 20
    private let separatorCollapsedLength: CGFloat = 10000
    private let debounceDelay: TimeInterval = 0.3
    private let maxRetryAttempts = 3
    private let retryDelayNanoseconds: UInt64 = 200_000_000
    
    // MARK: - Test Accessors
    
    var currentSeparatorLength: CGFloat {
        hiddenSection.controlItem.length
    }
    
    var currentToggleImageDescription: String? {
        visibleSection.controlItem.button?.image?.accessibilityDescription
    }
    
    var expandImageSymbolName: String {
        isLTRLanguage ? "chevron.left" : "chevron.right"
    }
    
    var collapseImageSymbolName: String {
        isLTRLanguage ? "chevron.right" : "chevron.left"
    }
    
    var isLeftToRight: Bool {
        isLTRLanguage
    }
    
    // MARK: - RTL Support
    
    private var isLTRLanguage: Bool {
        NSApplication.shared.userInterfaceLayoutDirection == .leftToRight
    }
    
    private var isSeparatorValidPosition: Bool {
        guard
            let toggleX = visibleSection.controlItem.button?.window?.frame.origin.x,
            let separatorX = hiddenSection.controlItem.button?.window?.frame.origin.x
        else { return false }
        
        return isLTRLanguage ? (toggleX >= separatorX) : (toggleX <= separatorX)
    }
    
    // MARK: - Images (RTL-aware)
    
    private var expandImage: ControlItemImage {
        .sfSymbol(isLTRLanguage ? "chevron.left" : "chevron.right")
    }
    
    private var collapseImage: ControlItemImage {
        .sfSymbol(isLTRLanguage ? "chevron.right" : "chevron.left")
    }
    
    private let separatorImage: ControlItemImage = .sfSymbol("circle.fill", weight: .regular)
    
    // MARK: - Callbacks
    
    var onShowDrawer: (() -> Void)?
    
    // MARK: - Initialization
    
    #if DEBUG
    private var debugTimer: Timer?
    #endif

    init(settings: SettingsManager = .shared) {
        self.settings = settings
        
        setupSections()
        setupSettingsBindings()
        setupStateBindings()
        
        logger.debug("Initialized with section-based architecture")
        
        #if DEBUG
        setupDebugTimer()
        #endif
    }
    
    deinit {
        #if DEBUG
        debugTimer?.invalidate()
        #endif
        autoCollapseTask?.cancel()
        cancellables.removeAll()
    }
    
    // MARK: - Setup
    
    private func setupSections() {
        // Create separator control item (for hidden section)
        let separatorControl = ControlItem(
            expandedLength: separatorExpandedLength,
            collapsedLength: separatorCollapsedLength,
            initialState: isCollapsed ? .collapsed : .expanded
        )
        separatorControl.image = separatorImage
        separatorControl.autosaveName = "drawer_separator_v3"
        separatorControl.setMenu(createContextMenu())
        
        hiddenSection = MenuBarSection(
            type: .hidden,
            controlItem: separatorControl,
            isExpanded: !isCollapsed
        )
        
        // Create toggle control item (for visible section)
        let toggleControl = ControlItem(
            expandedLength: NSStatusItem.variableLength,
            collapsedLength: NSStatusItem.variableLength,
            initialState: .expanded // Toggle is always visible
        )
        toggleControl.image = isCollapsed ? expandImage : collapseImage
        toggleControl.autosaveName = "drawer_toggle_v3"
        toggleControl.setAction(target: self, action: #selector(toggleButtonPressed))
        toggleControl.setSendAction(on: [.leftMouseUp, .rightMouseUp])
        
        visibleSection = MenuBarSection(
            type: .visible,
            controlItem: toggleControl,
            isExpanded: true // Toggle section is always expanded
        )
        
        logger.info("Sections setup complete")
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            self.verifyVisibility()
        }
    }
    
    private func setupSettingsBindings() {
        settings.autoCollapseSettingsChanged
            .sink { [weak self] in
                self?.restartAutoCollapseTimerIfNeeded()
            }
            .store(in: &cancellables)
    }
    
    private func setupStateBindings() {
        // Sync isCollapsed with hiddenSection.isExpanded
        $isCollapsed
            .dropFirst()
            .sink { [weak self] collapsed in
                guard let self = self else { return }
                self.hiddenSection.isExpanded = !collapsed
                self.visibleSection.controlItem.image = collapsed 
                    ? self.expandImage 
                    : self.collapseImage
                self.logger.debug("State binding: isCollapsed=\(collapsed)")
            }
            .store(in: &cancellables)
    }
    
    #if DEBUG
    private func setupDebugTimer() {
        debugTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.logger.debug("--- SECTION DEBUG ---")
                self.logger.debug("Hidden: expanded=\(self.hiddenSection.isExpanded), length=\(self.hiddenSection.controlItem.length)")
                self.logger.debug("Visible: expanded=\(self.visibleSection.isExpanded)")
                self.logger.debug("---------------------")
            }
        }
    }
    #endif
    
    private func verifyVisibility() {
        let toggleVisible = visibleSection.controlItem.button?.window?.frame.width ?? 0 > 0
        let separatorVisible = hiddenSection.controlItem.button?.window?.frame.width ?? 0 > 0
        
        if toggleVisible && separatorVisible {
            logger.info("Menu bar icons verified visible")
        } else {
            logger.warning("Visibility check failed. Toggle: \(toggleVisible), Separator: \(separatorVisible)")
        }
    }
    
    private func createContextMenu() -> NSMenu {
        let menu = NSMenu()
        
        let drawerItem = NSMenuItem(
            title: "Show Drawer",
            action: #selector(showDrawerPressed),
            keyEquivalent: "d"
        )
        drawerItem.target = self
        menu.addItem(drawerItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let preferencesItem = NSMenuItem(
            title: "Preferences...",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        preferencesItem.target = self
        menu.addItem(preferencesItem)
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(
            title: "Quit Drawer",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        
        return menu
    }
    
    // MARK: - Actions
    
    @objc private func toggleButtonPressed(_ sender: NSStatusBarButton) {
        logger.debug("Toggle Button Pressed")
        guard let event = NSApp.currentEvent else { return }
        
        let isOptionKeyPressed = event.modifierFlags.contains(.option)
        
        if event.type == .leftMouseUp && !isOptionKeyPressed {
            toggle()
        }
    }
    
    @objc private func showDrawerPressed() {
        onShowDrawer?()
    }
    
    @objc private func openPreferences() {
        AppDelegate.shared?.openSettings()
    }
    
    // MARK: - Toggle Logic
    
    func toggle() {
        logger.debug("toggle() called. isToggling: \(self.isToggling), isCollapsed: \(self.isCollapsed)")
        guard !isToggling else { return }
        isToggling = true
        
        if isCollapsed {
            expand()
        } else {
            collapse()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceDelay) { [weak self] in
            self?.isToggling = false
        }
    }
    
    func expand() {
        guard isCollapsed else { return }
        logger.debug("Expanding...")
        
        isCollapsed = false // Triggers state binding
        startAutoCollapseTimer()
    }
    
    func collapse() {
        guard isSeparatorValidPosition, !isCollapsed else {
            logger.debug("Collapse aborted. ValidPos: \(self.isSeparatorValidPosition), IsCollapsed: \(self.isCollapsed)")
            return
        }
        logger.debug("Collapsing...")
        
        cancelAutoCollapseTimer()
        isCollapsed = true // Triggers state binding
    }
    
    // MARK: - Auto-Collapse Timer
    
    private func startAutoCollapseTimer() {
        guard settings.autoCollapseEnabled else { return }
        
        cancelAutoCollapseTimer()
        
        let delay = settings.autoCollapseDelay
        autoCollapseTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            await self?.collapse()
        }
    }
    
    private func cancelAutoCollapseTimer() {
        autoCollapseTask?.cancel()
        autoCollapseTask = nil
    }
    
    private func restartAutoCollapseTimerIfNeeded() {
        guard !isCollapsed else { return }
        startAutoCollapseTimer()
    }
}
```

---

## Migration Notes

### Breaking Changes
None for external callers. The public API remains:
- `isCollapsed: Bool`
- `toggle()`
- `expand()`
- `collapse()`

### Internal Changes
- `toggleItem` → `visibleSection.controlItem.statusItem`
- `separatorItem` → `hiddenSection.controlItem.statusItem`
- Images now use `ControlItemImage` enum
- State synchronization via Combine bindings

---

## Acceptance Criteria

- [ ] `MenuBarSection` class created with `type`, `controlItem`, `isExpanded`, `isEnabled`
- [ ] `MenuBarSectionType` enum created with `visible`, `hidden`, `alwaysHidden`
- [ ] `MenuBarManager` refactored to use `hiddenSection` and `visibleSection`
- [ ] `setupSections()` creates sections with proper initial state
- [ ] `setupStateBindings()` syncs `isCollapsed` with section state
- [ ] All existing functionality preserved (toggle, expand, collapse, auto-collapse)
- [ ] RTL support still works
- [ ] Context menu still works
- [ ] Build succeeds with no warnings
- [ ] Manual test: App launches with icons in correct state
- [ ] Manual test: Toggle works correctly

---

## Testing

### Manual Verification Steps

1. Build and run app
2. Verify toggle chevron appears in menu bar
3. Click toggle - verify icons expand
4. Click toggle again - verify icons collapse
5. Right-click separator - verify context menu appears
6. Enable auto-collapse in settings - verify it works
7. Test on RTL layout if possible

### Console Logs to Verify

```
Initialized with section-based architecture
Sections setup complete
State binding: isCollapsed=false
Section 'hidden' isExpanded=true
State binding: isCollapsed=true
Section 'hidden' isExpanded=false
```

---

## Rollback Plan

Keep a backup of the original `MenuBarManager.swift` before refactoring. If issues arise, revert to the backup and investigate incrementally.

---

## Files Changed

| File | Action |
|------|--------|
| `Drawer/Core/Models/MenuBarSection.swift` | Create |
| `Drawer/Core/Managers/MenuBarManager.swift` | Major refactor |
