# Menu Bar Implementation Strategy Report

## 1. Executive Summary
Both **Hidden Bar** and **Ice** utilize the same fundamental mechanism for hiding icons: the **Length Manipulation Hack** (often called the "10k pixel hack"). However, **Ice** offers a significantly more robust, event-driven architecture and provides an alternative "Overlay Panel" mode that bypasses the limitations of the length hack (e.g., the MacBook Notch).

**Recommendation:** Drawer should adopt **Ice's architecture** (Section-based, Event-driven) while retaining the core Length Hack for simplicity, but ideally architecting the app to support an "Overlay Mode" (Ice Bar) in the future to solve the Notch problem definitively.

## 2. Implementation Analysis

### 2.1. The "10k Pixel Hack" (Core Mechanism)
This is the industry standard for lightweight menu bar hiders.
*   **Mechanism:** You create a "Separator" `NSStatusItem` positioned between the icons you want to hide and the ones you want to keep.
*   **Hiding:** You set the `length` of this separator to `10,000` pixels. This pushes all icons to its **left** off the screen.
*   **Showing:** You shrink the separator's `length` to a small value (e.g., `20` pixels), allowing the icons to slide back into view.
*   **Positioning:** Both apps rely on `NSStatusItem.autosaveName` to persist the position of their toggle/separator items.

### 2.2. Hidden Bar vs. Ice

| Feature | Hidden Bar (Legacy) | Ice (Modern) |
| :--- | :--- | :--- |
| **Architecture** | **Monolithic:** Logic is centralized in `StatusBarController.swift`. Hard to test/maintain. | **Modular:** Uses `MenuBarManager`, `MenuBarSection`, and `ControlItem` classes. Heavily uses **Combine** for reactive state. |
| **Sections** | Managed via loosely coupled `NSStatusItem`s (`btnSeparate`, `btnAlwaysHidden`). | Explicitly models `Visible`, `Hidden`, and `AlwaysHidden` as `MenuBarSection` objects. |
| **Always Hidden** | Implemented as a second separator. Less robust state management. | Implemented as a first-class Section with its own `ControlItem` and toggle logic. |
| **Notch Handling** | Susceptible to icons being lost behind the notch. | **Solved via Overlay:** Can render hidden items in a separate floating panel (`IceBarPanel`) instead of the menu bar. |
| **Icons** | Static PNG assets (`ic_line`, etc.). | **Dynamic:** Uses a `ControlItemImage` enum supporting SF Symbols (`systemSymbolName`), Custom Drawings (`NSBezierPath`), and Asset Catalogs. |
| **Rehide Logic** | Basic Timer. | Advanced Strategies: Timer, "Focused App" change, and Mouse Monitor (using `UniversalEventMonitor`). |

## 3. Best Practices & Lessons for Drawer

### 3.1. Architecture: The "Section" Model
Instead of managing individual buttons, manage **Sections**.
*   Create a `MenuBarSection` class that holds a reference to its `ControlItem` (the toggle button).
*   The `ControlItem` should manage the `NSStatusItem` and its length.
*   **Benefit:** This makes adding "Always Hidden" or other future sections trivial.

### 3.2. State Management
Use **Combine** (as Ice does) or **Observation** (Swift 5.9+) to react to state changes.
*   The `ControlItem` should observe its own `$state` (hidden/visible) and update the `NSStatusItem.length` automatically.
*   This prevents UI/State desynchronization bugs (like the one we just fixed in Drawer).

### 3.3. The "Overlay" Solution (Long-term)
The "10k hack" is fragile on Notched MacBooks because items pushed "off screen" might actually just get stuck behind the notch.
*   **Lesson from Ice:** Implement an "Overlay Mode" where hidden icons are NOT shown in the menu bar at all, but drawn in a separate `NSPanel` floating below the bar.
*   **Implementation:** Requires capturing the window list (via Private APIs like `CGSGetWindowList`) and mirroring/drawing them in a custom view. This is complex but is the *only* robust way to handle the Notch.

### 3.4. Icon Rendering
Don't use static PNGs.
*   **Lesson:** Use a robust `ControlItemImage` enum that can render:
    *   **SF Symbols:** For native look (`chevron.left`, `circle.fill`).
    *   **Programmatic Drawing:** Ice draws its chevrons using `NSBezierPath` to ensure perfect pixel alignment and weight.
    *   **Custom Images:** Allow user-provided data.

## 4. Recommended Implementation for Drawer

1.  **Refactor `MenuBarManager`** to manage `[MenuBarSection]` instead of raw items.
2.  **Adopt the "Always Hidden" pattern** from Ice: Use a second separator item to the left of the main separator.
    *   Structure: `[Always Hidden Items] | [Hidden Items] | [Visible Items]`
3.  **Use Programmatic Icons:** Switch from `NSImage(systemSymbolName:)` to drawing code (or cached SF Symbols) to ensure reliability and visual consistency.
4.  **Future-Proofing:** Prepare the architecture to support an "Overlay Panel" mode (like `IceBarPanel`) to solve the Notch issue for pro users.
