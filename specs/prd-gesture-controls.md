# PRD: Gesture Controls for Drawer

> **Note:** This PRD is a **feature spec** that is orthogonal to the architecture refactoring in `phase1-*` through `phase4b-*`. It can be implemented before, during, or after the architecture improvements. If implementing after Phase 2B, the `MenuBarManager` API may have changed slightly (sections-based). If implementing after Phase 4B, consider adding Overlay Mode support to scroll gestures.

## Introduction

Add intuitive gesture controls to show and hide the Drawer panel. Users can open the drawer by scrolling down (trackpad or mouse wheel) or hovering in the menu bar area, and close it by scrolling up or clicking outside. All gesture options are configurable via preferences, allowing users to customize their preferred interaction style.

This PRD also addresses an existing bug where the drawer disappears unexpectedly due to the HoverManager not knowing the drawer's frame position.

## Goals

- Enable scroll-down gesture (trackpad + mouse wheel) to open drawer when mouse is in menu bar
- Enable scroll-up gesture to close drawer (optional)
- Enable click-outside / focus-loss to close drawer (optional)
- Maintain existing hover-to-show functionality as a separate option
- Make all show/hide triggers independently configurable (multi-select)
- Fix existing bug: drawer disappearing because `drawerFrame` is never updated
- All options enabled by default for discoverability

## User Stories

### US-001: Fix Drawer Frame Tracking Bug
**Description:** As a user, I want the drawer to stay visible when my mouse is over it, so it doesn't disappear unexpectedly.

**Acceptance Criteria:**
- [ ] `HoverManager.updateDrawerFrame()` is called after drawer panel is shown
- [ ] Drawer remains visible when mouse moves within the drawer area
- [ ] Drawer only hides when mouse leaves both menu bar AND drawer area (with debounce)
- [ ] Typecheck/lint passes
- [ ] Manual test: Open drawer, move mouse around inside it - drawer stays open

---

### US-002: Add Scroll Gesture Detection Infrastructure
**Description:** As a developer, I need scroll wheel event monitoring so gestures can trigger drawer actions.

**Acceptance Criteria:**
- [ ] `GlobalEventMonitor` supports `.scrollWheel` event mask
- [ ] Scroll events are captured globally (works even when Drawer is not frontmost app)
- [ ] Trackpad and mouse wheel events are both detected
- [ ] Scroll direction (up/down) is correctly determined regardless of "natural scrolling" setting
- [ ] Gesture detection only activates when mouse is in menu bar zone (top ~24px)
- [ ] Typecheck/lint passes

---

### US-003: Scroll Down to Show Drawer
**Description:** As a user, I want to scroll down in the menu bar area to reveal the drawer, so I can access hidden icons with a natural gesture.

**Acceptance Criteria:**
- [ ] Scrolling down (two-finger swipe or mouse wheel) in menu bar area opens drawer
- [ ] Gesture requires accumulated scroll delta to exceed threshold (prevents accidental triggers)
- [ ] Works with both trackpad (precise deltas) and mouse wheel (discrete steps)
- [ ] Respects system "natural scrolling" preference (swipe direction feels correct)
- [ ] Gesture resets if user scrolls in opposite direction
- [ ] Drawer opens at correct position below menu bar
- [ ] Typecheck/lint passes
- [ ] Manual test: Swipe down with two fingers on menu bar - drawer opens

---

### US-004: Scroll Up to Hide Drawer
**Description:** As a user, I want to scroll up to dismiss the drawer, so I can hide it with the reverse gesture.

**Acceptance Criteria:**
- [ ] Scrolling up while drawer is visible closes it
- [ ] Works when mouse is in menu bar area OR over the drawer panel
- [ ] Gesture requires accumulated scroll delta to exceed threshold
- [ ] Works with both trackpad and mouse wheel
- [ ] This behavior is optional and controlled by a preference
- [ ] Typecheck/lint passes
- [ ] Manual test: With drawer open, swipe up - drawer closes

---

### US-005: Click Outside to Hide Drawer
**Description:** As a user, I want the drawer to close when I click elsewhere or switch to another app, so it doesn't block my workflow.

**Acceptance Criteria:**
- [ ] Clicking anywhere outside the drawer panel closes it
- [ ] Switching focus to another application closes the drawer
- [ ] Clicking on a drawer item does NOT close it (item action executes first)
- [ ] This behavior is optional and controlled by a preference
- [ ] Typecheck/lint passes
- [ ] Manual test: Open drawer, click on desktop - drawer closes
- [ ] Manual test: Open drawer, Cmd+Tab to another app - drawer closes

---

### US-006: Add Gesture Preferences UI
**Description:** As a user, I want to configure which gestures show/hide the drawer, so I can customize the behavior to my preference.

**Acceptance Criteria:**
- [ ] New "Gestures" or "Triggers" section in Settings/Preferences
- [ ] Multi-select options for "Show Drawer":
  - [ ] "Hover over menu bar" (existing, now as checkbox)
  - [ ] "Scroll down in menu bar"
- [ ] Multi-select options for "Hide Drawer":
  - [ ] "Scroll up"
  - [ ] "Click outside or switch apps"
  - [ ] "Move mouse away" (existing hover-out behavior)
- [ ] All options enabled by default
- [ ] Settings persist across app restarts
- [ ] Typecheck/lint passes
- [ ] Manual test: Toggle each option, verify behavior changes accordingly

---

### US-007: Persist Gesture Settings
**Description:** As a developer, I need to store gesture preferences so they persist across sessions.

**Acceptance Criteria:**
- [ ] Add to `SettingsManager`:
  - `showOnHover: Bool` (existing, keep for compatibility)
  - `showOnScrollDown: Bool` (new, default: true)
  - `hideOnScrollUp: Bool` (new, default: true)
  - `hideOnClickOutside: Bool` (new, default: true)
  - `hideOnMouseAway: Bool` (new, default: true)
- [ ] Settings stored via `@AppStorage` (UserDefaults)
- [ ] Changing settings immediately affects behavior (no restart required)
- [ ] Typecheck/lint passes

---

## Functional Requirements

- **FR-1:** Monitor global scroll wheel events using `NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel)`
- **FR-2:** Detect scroll direction accounting for `isDirectionInvertedFromDevice` (natural scrolling)
- **FR-3:** Accumulate scroll delta and trigger action when threshold (30px) is exceeded
- **FR-4:** Reset accumulated delta on direction change or gesture end (`event.phase == .ended`)
- **FR-5:** Only respond to scroll gestures when mouse is in menu bar trigger zone
- **FR-6:** Monitor for click-outside events using global mouse down monitor
- **FR-7:** Monitor for app deactivation using `NSWorkspace.didDeactivateApplicationNotification`
- **FR-8:** Call `HoverManager.updateDrawerFrame(panel.frame)` after showing drawer panel
- **FR-9:** All gesture triggers are independently toggleable via preferences
- **FR-10:** Gesture monitoring starts/stops based on whether any relevant preference is enabled

## Non-Goals

- No three-finger or four-finger gesture support (system-reserved)
- No gesture customization beyond enable/disable (no custom thresholds in UI)
- No haptic feedback (not available for menu bar interactions)
- No gesture to toggle drawer (only separate show/hide gestures)
- No pinch-to-zoom or other complex gestures

## Design Considerations

### Settings UI Layout

```
Triggers
--------
Show Drawer when:
  [x] Hover over menu bar
  [x] Scroll down in menu bar

Hide Drawer when:
  [x] Scroll up
  [x] Click outside or switch apps  
  [x] Move mouse away from drawer
```

### Gesture Feel

- Scroll threshold: ~30px accumulated delta (feels intentional, not accidental)
- Debounce: 150ms for show, 300ms for hide (matches existing hover behavior)
- Animation: Use existing drawer show/hide animations (spring in, fade out)

## Technical Considerations

### Event Monitoring

```swift
// Scroll events - need global monitor
NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { event in
    // event.scrollingDeltaY - vertical scroll amount
    // event.hasPreciseScrollingDeltas - true for trackpad
    // event.isDirectionInvertedFromDevice - natural scrolling enabled
    // event.phase - .began, .changed, .ended for trackpad
}

// Click outside - need global monitor  
NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
    // Check if click is outside drawer frame
}

// App deactivation
NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didDeactivateApplicationNotification, ...
)
```

### Architecture

- Extend `HoverManager` to become `GestureManager` (or create separate manager)
- Keep `GlobalEventMonitor` utility class, add `.scrollWheel` support
- Gesture state machine: Idle -> Accumulating -> Triggered -> Cooldown

#### Integration with Architecture Refactor (Phase 2+)

If the Section-based architecture from `phase2b-section-architecture.md` has been implemented:
- Use `menuBarManager.hiddenSection.isExpanded` instead of `menuBarManager.isCollapsed`
- Access separator position via `menuBarManager.hiddenSection.controlItem.button?.window?.frame`

If Overlay Mode from `phase4b-overlay-mode-integration.md` has been implemented:
- Scroll gestures should respect `settings.overlayModeEnabled`
- When overlay mode is on, scroll-down triggers `overlayModeManager.showOverlay()` instead of `menuBarManager.expand()`

### Bug Fix Location

In `AppState.swift`, after line 230:
```swift
drawerController.show(content: contentView)
drawerManager.show()
// ADD: Update hover manager with drawer frame
if let panelFrame = drawerController.panel?.frame {
    hoverManager.updateDrawerFrame(panelFrame)
}
```

## Success Metrics

- Scroll gesture triggers drawer within 200ms of threshold being reached
- No accidental drawer opens during normal menu bar clicking
- Gesture feels responsive and matches system scroll behavior
- All existing hover functionality continues to work
- Drawer no longer disappears unexpectedly (bug fix verified)

## Open Questions

1. ~~Should scroll gestures work with mouse wheel or only trackpad?~~ **Resolved: Both**
2. ~~Should there be visual feedback during scroll accumulation?~~ **Resolved: No, keep it simple**
3. Should the scroll threshold be adjustable in advanced settings? (Suggest: No for v1)
4. Should we add a brief tutorial/tooltip on first use? (Suggest: No, discoverable naturally)

## Implementation Order

1. **US-001** - Fix drawer frame tracking bug (quick win, unblocks testing)
2. **US-007** - Add settings properties (foundation for other stories)
3. **US-002** - Scroll gesture detection infrastructure
4. **US-003** - Scroll down to show
5. **US-004** - Scroll up to hide
6. **US-005** - Click outside to hide
7. **US-006** - Settings UI (can be done in parallel with 3-5)
