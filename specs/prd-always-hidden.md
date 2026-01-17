# PRD: Always-Hidden Section for Drawer

## Introduction

Add a third status item to create an "always-hidden" section in the menu bar. Icons placed in this section will never appear in the menu bar itself, even when expanded. They will only be visible in the floating Drawer panel. This allows users to completely hide rarely used items while keeping them accessible via the Drawer.

## Goals

- Create a designated "always-hidden" zone in the menu bar
- Ensure icons in this zone never appear in the main menu bar (even when expanded)
- Display these icons exclusively in the Drawer panel
- Maintain existing drag-and-drop customization
- Provide visual feedback for the always-hidden separator

## User Stories

### US-001: Always-Hidden Separator
**Description:** As a user, I want a second separator in my menu bar that defines the "always-hidden" zone.

**Acceptance Criteria:**
- [ ] A second separator icon (`▎` or similar) appears when enabled
- [ ] The separator is visually distinct from the main separator (e.g., dimmed)
- [ ] Users can drag icons to the left of this separator
- [ ] The separator position validates correctly (must be left of the main separator in LTR)

### US-002: Hiding Logic
**Description:** As a user, I want icons in the always-hidden zone to stay hidden even when I expand the menu bar.

**Acceptance Criteria:**
- [ ] When menu bar is expanded, the always-hidden separator expands to 10,000px
- [ ] Icons to the left of the always-hidden separator remain pushed off-screen
- [ ] The main separator expands to 20px (normal behavior) to show the "regular hidden" icons

### US-003: Drawer Visibility
**Description:** As a user, I want to see my always-hidden icons when I open the Drawer.

**Acceptance Criteria:**
- [ ] When Drawer is triggered (hover/click), ALL separators expand to 20px for capture
- [ ] IconCapturer captures the entire range (Always Hidden + Hidden)
- [ ] Drawer panel displays all hidden icons (both types)
- [ ] After capture, menu bar returns to previous state (Always Hidden collapsed)

### US-004: Configuration
**Description:** As a user, I want to enable/disable this feature in settings.

**Acceptance Criteria:**
- [ ] "Always-hidden section" toggle in Appearance settings
- [ ] Enabling shows the second separator
- [ ] Disabling hides the second separator and moves icons to the "regular hidden" section

## Functional Requirements

- **FR-1:** `MenuBarManager` manages a third `NSStatusItem` (`alwaysHiddenItem`)
- **FR-2:** `alwaysHiddenItem` behaves like `separatorItem` but with different expansion logic
- **FR-3:** Validation logic prevents `alwaysHiddenItem` from being to the right of `separatorItem` (LTR)
- **FR-4:** `IconCapturer` uses a special `expandAll()` method during capture to see everything
- **FR-5:** `IconCapturer` restores state using `collapseAll()` or `restoreState()`

## Technical Considerations

### Menu Bar Layout
```
[Always Hidden] ▏ [Hidden] ● < [Visible]
                ↑          ↑ ↑
                │          │ └── Toggle
                │          └──── Main Separator
                └─────────────── Always-Hidden Separator
```

### Collapse Logic
- **Collapsed**:
  - `separatorItem.length = 10000`
  - `alwaysHiddenItem.length = 10000` (if enabled)
- **Expanded (Menu Bar)**:
  - `separatorItem.length = 20`
  - `alwaysHiddenItem.length = 10000` (keeps leftmost icons hidden)
- **Expanded (Drawer Capture)**:
  - `separatorItem.length = 20`
  - `alwaysHiddenItem.length = 20` (everything visible for screenshot)

### Settings Storage
- Key: `alwaysHiddenEnabled` (Bool)
- Default: `false`

## Success Metrics
- Always-hidden icons never flash in the menu bar during normal toggle
- Drawer displays all icons correctly
- No layout glitches when enabling/disabling the feature
