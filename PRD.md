# Product Requirements Document: Drawer

## 1. Product Overview
**Drawer** is a lightweight, high-performance macOS menu bar utility designed to declutter the system menu bar. It allows users to hide infrequently used menu bar icons into a secondary, collapsible "Drawer," providing a clean and focused workspace.

### Value Proposition
- **Declutter**: Reclaim screen real estate by hiding "noisy" icons.
- **Accessibility**: Keep all tools one click away without them crowding the main bar.
- **Native Experience**: Built with SwiftUI to feel like a first-party part of macOS.
- **Performance**: Minimal CPU/Memory footprint, leveraging modern macOS APIs.

---

## 2. Core Features

### 2.1 The Split (Standard vs. Hidden Items)
- **Concept**: A logical divider in the menu bar.
- **Functionality**:
    - Icons to the left of the "Split" are moved to the Hidden category.
    - Icons to the right remain visible at all times.
    - Users can drag the Split icon to reconfigure visibility on the fly.

### 2.2 The Drawer (Secondary Bar)
- **Concept**: A floating, secondary menu bar that reveals hidden items.
- **Functionality**:
    - Appears as a sleek overlay (NSPanel) below or replacing the main menu bar.
    - Contains all icons marked as "Hidden."
    - Supports full interaction with hidden icons (click, right-click, drag).

### 2.3 Auto-hide/Show Logic
- **Triggers**:
    - Click the Drawer icon to toggle.
    - Hover over the menu bar (optional setting).
    - Global keyboard shortcut.
- **Auto-collapse**:
    - Automatically hides the Drawer after X seconds of inactivity.
    - Hides when the user clicks anywhere outside the Drawer.

---

## 3. Technical Requirements

### 3.1 Hiding Mechanism (The "10k Pixel Hack")
- To hide menu bar items without terminating the owner apps, Drawer moves the window associated with the `NSStatusItem` to a coordinate far off-screen (e.g., x: -10,000).
- This ensures the app remains active and its menu bar item continues to function/update in the background.

### 3.2 Drawer Implementation
- **UI Container**: `NSPanel` configured as a `nonactivatingPanel` with `.canJoinAllSpaces` and `.fullSizeContentView`.
- **Visuals**: Use `NSVisualEffectView` with `material: .menu` or `.hudWindow` to match macOS system aesthetics.
- **Layout**: Dynamic SwiftUI view that calculates the width based on the number of hidden items.

### 3.3 Permissions
- **Accessibility (TCC)**: Required to programmatically move and reorder menu bar icons.
- **Screen Recording**: Required for `ScreenCaptureKit` or `CoreGraphics` to detect the positions and presence of third-party menu bar items.

---

## 4. UI/UX Guidelines

### 4.1 "Beautiful" Definition
- **Consistency**: Strictly follow Apple's Human Interface Guidelines (HIG).
- **Subtlety**: No jarring colors; use system-defined vibrant materials.
- **Precision**: Pixel-perfect alignment with the system menu bar.

### 4.2 Animations
- **Expansion**: A smooth "slide-out" or "fade-in" animation when opening the Drawer.
- **Transitions**: Spring-based animations for a responsive, tactile feel.

### 4.3 Materials
- Support for **Light/Dark Mode** out of the box.
- Use of **Vibrancy** to allow background colors to bleed through elegantly.

---

## 5. Roadmap

### Phase 1: Core Hiding (Refactored Hidden Bar)
- Port and refactor the original Hidden Bar logic to modern Swift 5.9.
- Implement basic "Split" functionality.
- Stabilize the 10k pixel hiding mechanism on macOS 14+.

### Phase 2: The Drawer (The New Engine)
- Develop the `NSPanel` based secondary bar.
- Implement the logic to "teleport" icons from the off-screen area into the Drawer panel.
- Add basic auto-hide timers.

### Phase 3: Polish (UI/UX)
- Add a comprehensive Settings panel (SwiftUI).
- Implement global hotkeys.
- Refine animations and multi-monitor support.

---

## 6. Architecture

### MVVM Structure
- **Model**: `MenuBarItem`, `DrawerSettings`.
- **View**: `DrawerPanelView`, `SettingsView`, `MenuBarSplitView`.
- **ViewModel**: `DrawerViewModel` (Manages visibility state, timers, and icon positions).

### Key Managers
- **MenuBarManager**: The core engine that interacts with the system to find and move status items.
- **PermissionManager**: Handles the flow for requesting and verifying TCC permissions.
- **SettingsManager**: Persists user preferences using `UserDefaults` or `AppStorage`.
- **HotKeyManager**: Manages global keyboard shortcuts using `ShortcutRecorder` or `MASShortcut`.
