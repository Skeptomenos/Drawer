# Phase 3: UI/UX Polish & Release Specification

**Goal**: Transform the raw functionality into a "Beautiful" product. Focus on animations, styling, settings, and native look-and-feel.

## Task 3.1: Visuals & Materials
- **Objective**: Apply native macOS aesthetics to the Drawer.
- **Steps**:
  1.  Wrap `DrawerView` in `VisualEffectView` (NSVisualEffectView bridging).
  2.  Configure material to `menu` or `popover` (frosted glass).
  3.  Add subtle border (0.5px) and shadow to match macOS menu styling.
  4.  Ensure rounded corners at the bottom.
- **Acceptance Criteria**: Drawer looks like a native system component, not a web view.

## Task 3.2: Animations
- **Objective**: Smooth transitions for the Drawer.
- **Steps**:
  1.  Implement `.transition(.move(edge: .top).combined(with: .opacity))` for the Drawer content.
  2.  Use `.spring()` animation for showing/hiding.
  3.  Ensure no flickering during the "Capture -> Show" sequence (Task 2.2 might need optimization here).
- **Acceptance Criteria**: Drawer slides in/out smoothly without jank.

## Task 3.3: Settings UI (General & Appearance)
- **Objective**: Create the user-facing configuration window.
- **Visual Reference**: Use `look_at` on `specs/reference_images/settings-layout.jpg`. Observe the sidebar layout, icon usage, and control grouping.
- **Steps**:
  1.  Create `SettingsView.swift` with `TabView` (General, Appearance, About).
  2.  **General**: Toggles for Start at Login, Auto-hide delay.
  3.  **Appearance**: Drawer height slider, spacing slider, toggle for "Show on Hover" vs "Click Only".
- **Acceptance Criteria**: Clean, functional settings window. Changes reflect immediately in app behavior.

## Task 3.4: Icon Arrangement UI
- **Objective**: Allow users to define *which* icons are hidden vs. shown.
- **Visual Reference**: Use `look_at` on `specs/reference_images/settings-layout.jpg` (if it contains layout editor) or `specs/reference_images/icon-drawer.jpg` to understand icon sizing context.
- **Steps**:
  1.  This is tricky because we can't easily drag *real* system icons.
  2.  **Simpler approach**: Use the standard "Command+Drag" system behavior (users drag icons *past* our separator).
  3.  **Advanced approach (Future)**: Build a UI that shows all running apps and lets user check "Hide".
  4.  *For v1.0, document the "Command+Drag" method in an onboarding view.*
- **Acceptance Criteria**: Onboarding screen explaining how to organize icons using macOS native drag.

## Task 3.5: Final Polish & Assets
- **Objective**: Prepare for release.
- **Steps**:
  1.  Design and add AppIcon (Asset Catalog).
  2.  Add "About" screen with version info and credits.
  3.  Code signing & Hardened Runtime (if planning to notarize).
  4.  Verify Dark Mode / Light Mode compatibility.
- **Acceptance Criteria**: App looks professional in both themes. No debug logs.
