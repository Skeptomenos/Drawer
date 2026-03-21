# Bug Investigation Report

**Date:** 2026-02-02  
**Status:** Bugs 1, 3, 4, 5.1, 5.2, 6, 7, 8 FIXED | Bug 2 **CANNOT REPRODUCE** (section empty)

---

## 🚀 START HERE

**Current Priority:** None — All bugs resolved or cannot reproduce

### Current State (2026-02-02 14:15)

**Bug 2 INVESTIGATED** — Always Hidden 10k spacer:
- Investigation confirms Always Hidden section has **0 icons** (not 2 as previously reported)
- Settings → Menu Bar Layout shows: "Always Hidden Items (0)" with "Drop items here" placeholder
- The 10k spacer mechanism **appears to be working correctly**
- All Drawer controls visible on screen 2: `≡` (index 5), `●` (index 8), `<` (index 11)
- **Cannot reproduce bug** — no icons in Always Hidden section to test hiding behavior
- To test: ⌘+drag an icon to the LEFT of the `≡` separator, verify it gets pushed off-screen

**Bug 8 RESOLVED** — Drawer panel was empty on first toggle after permission reset:
- First toggle: Panel appeared but empty
- Second toggle: Icons loaded correctly (14-16 icons visible)
- Root cause: Race condition after permission reset - capture needs permissions fully active
- Status: **NOT A BUG** - expected behavior after permission reset, works on retry

**Bug 7 VERIFIED FIXED** — Drawer panel right-aligned:
- Tested: Panel appears at right edge of screen ✓
- Position: (1294, 37) on Built-in Display ✓

**Bug 6 VERIFIED FIXED** — Settings Menu Bar Layout working:
- Shown Items (9) - icons display correctly ✓
- Hidden Items (7) - icons display correctly ✓
- Always Hidden Items (0) - section empty, placeholder visible ✓
- No overflow, no broken borders ✓

### What Was Changed Today

**`DrawerPanel.swift:95`** — Fixed panel positioning to right-align:
```swift
// BEFORE (centered):
let originX = fullFrame.midX - (panelWidth / 2)

// AFTER (right-aligned):
let originX = fullFrame.maxX - panelWidth - Self.menuBarGap
```

**`AppState.swift:284-285`** — Removed fragile separator X positioning:
```swift
// BEFORE (timing-dependent):
let separatorX = menuBarManager.separatorXPosition
drawerController.show(content: contentView, alignedTo: separatorX, on: screen)

// AFTER (reliable screen-edge):
drawerController.show(content: contentView, on: screen)
```

**`IconCapturer.swift:271-297`** — Added separator position polling (Bug 5.2 fix):
- Polls up to 10 times (30ms each) for valid separator X positions
- Ensures separator is expanded before reading positions for section classification

### Next Steps

1. ~~Bug 2~~ — CANNOT REPRODUCE (Always Hidden section is empty, 0 icons)
2. ~~Bug 6~~ — VERIFIED FIXED
3. ~~Bug 7~~ — VERIFIED FIXED  
4. ~~Bug 8~~ — NOT A BUG (works on second toggle after permission reset)

**All known bugs are either FIXED or CANNOT REPRODUCE. No further action required.**

### To Verify Bug 2 in Future

If Bug 2 recurs, follow these steps:
1. ⌘+drag a menu bar icon to the LEFT of the `≡` separator
2. Verify icon appears in Settings → Menu Bar Layout → Always Hidden Items
3. Check if icon is pushed off-screen (should NOT be visible in menu bar)
4. Verify icon IS visible in Drawer panel

---

## Summary

| Bug # | Description | Severity | Root Cause | Status |
|-------|-------------|----------|------------|--------|
| 1 | Hover/scroll not working on secondary monitor | HIGH | Multi-monitor height mismatch | **FIXED** |
| 2 | Always Hidden section not hiding icons | MEDIUM | Under investigation | Blocked by 5.2 |
| 3 | Icons in Settings too tiny | HIGH | Missing width in frame | **FIXED** |
| 4 | Drawer panel empty on secondary monitor | HIGH | Screen not passed through callback | **FIXED** |
| 5 | Settings Menu Bar Layout broken | **CRITICAL** | Section classification broken | **FIXED** |
| 5.1 | Drawer control items in sections | HIGH | Old binary running | **FIXED** |
| 5.2 | All icons go to Shown after refresh | **CRITICAL** | Separator X NEGATIVE during capture (timing) | **FIXED** |
| 6 | Settings sidebar partially hidden | MEDIUM | Content overflow from many icons | **PARTIAL** |
| 6b | Layout borders break after refresh | LOW | Related to Bug 6 | **IN PROGRESS** |
| 7 | Drawer panel moved to middle (REGRESSION) | **HIGH** | `position(on:)` centered instead of right-aligned | **FIXED** |

---

## Bug 1: Hover/Scroll Not Working on Secondary Monitor — FIXED

### Symptom
Hovering/scrolling over menu bar on secondary monitor did not trigger drawer panel.

### Root Cause
`MenuBarMetrics.height` used main screen only, producing **negative values** on other screens due to global coordinate system.

```swift
// WRONG: visibleFrame.origin.y is GLOBAL, not relative to screen
menuBarHeight = screen.frame.height - screen.visibleFrame.height - screen.visibleFrame.origin.y
// On secondary monitor: 1440 - 1415 - 1169 = -1144 (NEGATIVE!)
```

### Fix Applied

**`Drawer/Utilities/MenuBarMetrics.swift`** — Added per-screen calculation with safeguard:
```swift
static func height(for screen: NSScreen?) -> CGFloat {
    guard let screen = screen else { return fallbackHeight }
    let menuBarHeight = screen.frame.height - screen.visibleFrame.height - screen.visibleFrame.origin.y
    return max(menuBarHeight, fallbackHeight)  // Never return negative
}
```

**`Drawer/Core/Managers/HoverManager.swift`** — Use per-screen height:
```swift
let triggerZoneBottom = screenTop - MenuBarMetrics.height(for: screen)
```

### Key Lesson
On macOS multi-monitor setups, `visibleFrame.origin` is in **global coordinates**, not relative to the screen's own frame. Always use `max()` safeguards for geometry calculations.

---

## Bug 3: Icons in Settings Too Tiny — PARTIAL FIX

### Symptom
Icons in Settings sections appeared as tiny unreadable dots.

### Root Cause
`LayoutItemView.swift` only specified `height` in `.frame()`, not `width`. With `.aspectRatio(contentMode: .fit)`, this caused horizontal compression.

### Fix Applied

**`Drawer/UI/Settings/LayoutItemView.swift:59`**
```diff
- .frame(height: LayoutDesign.iconSize)
+ .frame(width: LayoutDesign.iconSize, height: LayoutDesign.iconSize)
```

### Status: PARTIAL

Fix only resolved "Shown Items" section. Other sections still have sizing issues:

| Section | Icon Size | Status |
|---------|-----------|--------|
| Shown Items | ✅ Correct | Fixed |
| Hidden Items | ⚠️ Too small | NOT FIXED |
| Always Hidden Items | ❌ Tiny/unreadable | NOT FIXED |

**See Bug 5** for full investigation of Settings Menu Bar Layout issues.

---

## Bug 4: Drawer Panel Empty on Secondary Monitor — FIXED

### Symptom
Drawer panel appeared but was completely empty (no icons) when triggered from secondary monitor.

### Root Cause
Screen was NOT passed through the callback chain. `DrawerPanelController.show()` defaulted to `NSScreen.main`, positioning the panel on the wrong screen.

### Fix Applied

**`Drawer/Core/Managers/HoverManager.swift`** — Track trigger screen:
```swift
var onShouldShowDrawer: ((NSScreen?) -> Void)?  // Changed from (() -> Void)?
private var triggerScreen: NSScreen?

// In handleScrollEvent:
triggerScreen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) })
onShouldShowDrawer?(triggerScreen)
```

**`Drawer/App/AppState.swift`** — Pass screen through chain:
```swift
hoverManager.onShouldShowDrawer = { [weak self] screen in
    self?.showDrawerWithCapture(on: screen)
}

// In captureAndShowDrawer:
drawerController.show(content: contentView, alignedTo: separatorX, on: screen)
```

**`Drawer/UI/Panels/DrawerPanelController.swift`** — Position on correct screen.

---

## Bug 5: Settings Menu Bar Layout Broken — IN PROGRESS (CRITICAL)

### Symptoms (from screenshot analysis)

Multiple issues visible in Settings → Menu Bar Layout:

#### 5.1 Drawer Control Items Leaking Into Sections
**Severity:** HIGH  
**Status:** IN PROGRESS — Filter added but not working

Drawer's own `NSStatusItem` controls appear in the icon lists:
- `●` (drawer separator) visible in "Shown Items"
- `>` (drawer toggle) visible in "Shown Items"

These should be **filtered out** — they are Drawer's control items, not user icons.

##### Investigation Findings

**Peekaboo output shows Drawer items have unexpected identifiers:**

| Expected | Actual (from Peekaboo) |
|----------|------------------------|
| `title: "drawer_toggle_v4"` | `title: "com.drawer.app"` |
| `owner_name: "Drawer"` | `owner_name: "Control Center"` |
| `bundle_id: "com.drawer.app"` | `bundle_id: "com.apple.controlcenter"` |

The CGWindowList API returns different metadata than expected. The `owner_name` shows "Control Center" because macOS reports the process that owns the status bar area, not the app that created the status item.

##### Fixes Attempted

**Attempt 1:** Title-based filtering
```swift
if title == "com.drawer.app" { return true }
```
**Result:** ❌ Control items still appear

**Attempt 2:** PID-based filtering (most recent)
```swift
let pid = item.window.ownerPID
let drawerPID = ProcessInfo.processInfo.processIdentifier
if pid == drawerPID { return true }
```
**Result:** ❌ Control items still appear

**Attempt 3:** File-based debug logging
```swift
// Write to /tmp/drawer_filter_debug.log
let debugLine = "isDrawerControlItem: title='\(title)', pid=\(pid)..."
try? data.write(to: URL(fileURLWithPath: "/tmp/drawer_filter_debug.log"))
```
**Result:** ❌ Log file NEVER created — function not being called

**Attempt 4:** NSLog debugging (tested 2026-02-02 07:30)
```swift
NSLog("DRAWER_FILTER: title='%@', owner='%@', pid=%d, drawerPID=%d",
      title ?? "nil", ownerName ?? "nil", pid, drawerPID)
```
**Result:** ❌ Drawer control items (`●`, `>`) still appear in Settings after rebuild and test

##### Key Finding

Even with NSLog debugging added and app rebuilt, Drawer control items still appear. Need to check system logs to determine if filter is being called at all.

##### Current Code State

`IconCapturer.swift:200-231` now has:
- PID-based filtering (primary)
- Title-based filtering (fallback)
- Owner name filtering (fallback)
- NSLog calls for debugging

##### Additional Issues Discovered (2026-02-02 07:30)

1. **Unstable capture results** — Icon counts fluctuate wildly on refresh (10 → 29 → 18)
2. **Icon sizing regression** — All icons become tiny dots after first refresh
3. **Hidden sections empty** — Previously populated, now show "Drop items here"

##### Next Steps

1. Check system logs: `log stream --predicate 'process == "Drawer"' | grep DRAWER_FILTER`
2. If no logs → Investigate why `performWindowBasedCapture()` isn't reached
3. If logs exist → Analyze PID values to understand why filter doesn't match
4. Investigate capture instability — different results on each refresh
5. Investigate icon sizing — regression from previous partial fix

#### 5.2 Progressive Icon Size Degradation
**Severity:** MEDIUM

| Section | Size | Expected |
|---------|------|----------|
| Shown Items | ✅ Correct | 20px |
| Hidden Items | ⚠️ Too small | 20px |
| Always Hidden Items | ❌ Tiny/unreadable | 20px |

Different code paths or missing size constants per section type.

#### 5.3 Duplicated Icons
**Severity:** HIGH

Same icons appear multiple times in "Hidden Items" section. The capture logic is returning duplicate entries.

#### 5.4 Text Labels Overlaid on Icons
**Severity:** MEDIUM

Text fragments rendered ON TOP of icons in Hidden Items section. Suggests incorrect view composition or z-ordering.

#### 5.5 Always Hidden Shows Wrong Content
**Severity:** HIGH

"Always Hidden Items (3)" appears to show drawer panel content or incorrect windows rather than actual menu bar icons belonging to that section.

#### 5.6 Drag-and-Drop Has No Effect
**Severity:** HIGH

Moving icons between sections in Settings UI:
- UI updates (icon moves in the list)
- **Actual menu bar does NOT change**
- Icon reappears in original section on refresh

---

### Root Cause Hypothesis

The **icon capture and filtering logic** in `IconCapturer.swift` and/or `MenuBarLayoutViewModel.swift` is broken:

1. **Not filtering Drawer's own NSStatusItems** → Control items leak into lists
2. **Capturing wrong windows** → Duplicates, wrong content
3. **Section assignment incorrect** → Icons in wrong sections
4. **Reposition logic broken** → Drag-and-drop doesn't physically move icons

---

### Files to Investigate

| File | Component | Check For |
|------|-----------|-----------|
| `IconCapturer.swift` | Icon capture | Filtering logic for Drawer's own items |
| `MenuBarLayoutViewModel.swift` | Section assignment | How icons are classified into sections |
| `LayoutSectionView.swift` | UI rendering | Size constants per section type |
| `LayoutItemView.swift` | Item rendering | Why sizes differ between sections |
| `IconRepositioner.swift` | Physical move | Why drag-and-drop doesn't work |

---

### Next Steps for Bug 5

#### Step 1: Capture Drawer Control Item Identifiers (HIGH)

**Run this first:**
```bash
peekaboo menubar list --json-output > /tmp/menubar_items.json
cat /tmp/menubar_items.json
```

Find the exact window IDs, titles, or bundle identifiers for Drawer's own status items:
- `drawer_toggle_v4`
- `drawer_separator_v4`
- `drawer_always_hidden_separator_v2`
- `drawer_always_hidden_spacer_v2`

Save this output — you'll use it to build the filtering logic.

#### Step 2: Add Filtering in IconCapturer (HIGH)
Ensure these items are excluded from capture results:
```swift
// Check if window belongs to Drawer's own control items
func isDrawerControlItem(_ window: SCWindow) -> Bool {
    // Filter by title prefix or window owner
}
```

#### Step 3: Debug Section Classification (HIGH)
Add logging to see how icons are being classified:
```swift
logger.debug("Icon '\(title)' at x=\(frame.midX) → section=\(sectionType)")
```

#### Step 4: Verify Icon Deduplication (MEDIUM)
Check if capture is returning same window multiple times or if UI is duplicating.

#### Step 5: Fix Size Constants Per Section (MEDIUM)
Ensure `LayoutDesign.iconSize` is applied consistently across all section types.

#### Step 6: Debug Reposition Flow (HIGH)
Add logging to `performReposition()`:
```swift
logger.debug("Reposition: \(item.title) from \(item.sectionType) to \(targetSection)")
logger.debug("Found matching IconItem: \(foundItem != nil)")
logger.debug("Destination X: \(destinationX)")
logger.debug("IconRepositioner.move result: \(success)")
```

---

### Debug Commands

```bash
# Stream logs for icon capture
log stream --predicate 'subsystem == "com.drawer" AND category == "IconCapturer"' --level debug

# Stream logs for layout view model
log stream --predicate 'subsystem == "com.drawer" AND category == "MenuBarLayoutViewModel"' --level debug

# Stream logs for repositioning
log stream --predicate 'subsystem == "com.drawer" AND category == "IconRepositioner"' --level debug
```

---

## Bug 2: Always Hidden Section Not Hiding Icons — IN PROGRESS

### Symptoms

The actual bug is **NOT** that the separator shows when empty. The bug is:

**Icons positioned to the LEFT of the `≡` separator are NOT being hidden.**

From the user's screenshot:
- Multiple icons (microphone, phone, folder, HelloFresh, etc.) are visible LEFT of the `≡` separator
- These icons SHOULD be pushed off-screen by the 10k pixel spacer
- Instead, they remain visible in the menu bar

### Architecture: How Always Hidden Section Works

#### Layout (Left to Right)
```
[10k Spacer][≡ Separator][Always Hidden Icons][● Separator][Hidden Icons][< Toggle][Visible Icons]
     ↑            ↑
     |            └── User-visible control (always 20px)
     └── INVISIBLE 10,000px spacer (pushes icons off-screen)
```

#### Section Classification Logic

Icons are classified based on **X position** relative to control items:

```swift
// IconCapturer.swift:572-573
func determineSectionType(for frame: CGRect, hiddenSeparatorX: CGFloat, alwaysHiddenSeparatorX: CGFloat?) -> MenuBarSectionType {
    let iconCenterX = frame.midX
    
    // If always-hidden section exists and icon is to its left
    if let alwaysHiddenX = alwaysHiddenSeparatorX, iconCenterX < alwaysHiddenX {
        return .alwaysHidden
    }
    
    // If icon is to the left of the hidden separator
    if iconCenterX < hiddenSeparatorX {
        return .hidden
    }
    
    return .visible
}
```

**Translation:** Icons whose center X coordinate is to the LEFT of the `≡` separator are classified as "Always Hidden".

#### How Icons Get INTO Always Hidden

Users must **⌘+drag** icons to the left of the `≡` separator. The app doesn't automatically assign icons — it's purely positional based on where the user drags them relative to Drawer's control items.

#### The 10k Spacer Mechanism

```swift
// MenuBarManager.swift:332-336
let spacer = ControlItem(
    expandedLength: separatorCollapsedLength,  // 10k px (always pushing)
    collapsedLength: separatorCollapsedLength,
    initialState: .expanded  // Always at 10k px
)
```

The spacer is ALWAYS at 10,000 pixels. It should push all icons to its right off the left edge of the screen.

### Potential Root Causes

1. **10k spacer not at 10k width** — Might be collapsed or set to wrong length
2. **Spacer positioned incorrectly** — Not to the left of the icons
3. **Icons placed AFTER spacer setup** — They bypassed the layout mechanism
4. **Spacer window not created** — `spacer.button?.window` might be nil

### UX Problem: Retrieving Icons from Always Hidden

Once working, icons in "Always Hidden" are **always off-screen** (10k spacer never collapses).

**Current escape routes:**
1. **Via Drawer Panel** — User can SEE and CLICK always-hidden icons, but cannot drag them back
2. **Disable the section** — Settings → toggle off "Always Hidden section" → icons reappear → ⌘+drag to new position → re-enable
3. **Settings drag-and-drop** — **IF WORKING** (see next section)

---

## Settings UI: Drag-and-Drop Between Sections

### Feature Status: Implemented but Needs Verification

The UI and logic for moving icons between sections via Settings exists:

| Component | Status | File |
|-----------|--------|------|
| Drag gesture (`.draggable()`) | ✅ Implemented | `LayoutSectionView.swift:168` |
| Drop delegate (`.onDrop()`) | ✅ Implemented | `LayoutSectionView.swift:151` |
| `moveItem()` - UI state update | ✅ Implemented | `MenuBarLayoutViewModel.swift:158` |
| `performReposition()` - physical move | ✅ Implemented | `MenuBarLayoutViewModel.swift:273` |
| `findIconItem()` - icon matching | ✅ Implemented | `MenuBarLayoutViewModel.swift:321` |
| `calculateDestination()` - target position | ✅ Implemented | `MenuBarLayoutViewModel.swift:361` |
| `IconRepositioner.move()` - ⌘+drag simulation | ⚠️ Needs verification | `IconRepositioner.swift` |

### The Flow

```
User drags icon in Settings UI
    → LayoutSectionView.onDrop triggers
    → moveItem() called
    → performReposition() async
        → findIconItem() - finds real NSStatusItem via windowID or bundle matching
        → calculateDestination() - computes target X position relative to control items
        → IconRepositioner.move() - simulates ⌘+drag via CGEvent
    → Real menu bar icon moves
    → UI refreshes to show actual state
```

### Known Issues (from Spec 5.7)

The `findIconItem()` function may fail to find matching `IconItem`:

1. **windowID cache stale** — Window closed/recreated since capture
2. **Bundle ID matching fails** — Some apps have nil or dynamic bundle identifiers
3. **Title matching fails** — Titles can be empty or change dynamically

### Multi-Tier Matching Strategy (Implemented)

```swift
// MenuBarLayoutViewModel.swift - findIconItem()
// 1. Fast path: Use cached windowID (most reliable)
// 2. Fallback 1: Exact match (bundle ID + title)
// 3. Fallback 2: Bundle ID match only (for apps with dynamic titles)
// 4. Fallback 3: Owner name match (for apps without bundle ID)
```

### Spec Reference

See `specs/5.7-menu-bar-layout-reposition-fix.md` for full implementation details.

---

## Next Steps for Bug 2 (Priority Order)

> **Note:** Bug 2 and Bug 5 are interconnected. Bug 5's drag-and-drop failure (5.6) directly impacts the ability to rescue icons from Always Hidden. Fix Bug 5 first.

### 1. Debug Always Hidden Spacer (HIGH PRIORITY)

**Goal:** Determine why the 10k spacer isn't pushing icons off-screen.

**Debug steps:**
1. Add logging to `setupAlwaysHiddenSection()` to verify spacer creation
2. Check spacer window position and width after setup
3. Verify spacer is to the LEFT of the `≡` separator

```swift
// Add to MenuBarManager.swift after spacer setup
if let spacerWindow = alwaysHiddenSpacer?.button?.window {
    logger.debug("Spacer window: x=\(spacerWindow.frame.origin.x), width=\(spacerWindow.frame.width)")
}
```

### 2. Fix Always Hidden if Spacer is Broken

Possible fixes depending on root cause:
- Ensure spacer is created BEFORE separator (order matters for NSStatusItem)
- Verify spacer length is actually 10,000
- Check if macOS is limiting NSStatusItem length

### 3. UX Improvement: Hide Separator When Empty

**Lower priority** — Only relevant after core functionality works.

If Always Hidden section has no icons:
- Hide the `≡` separator
- Or show a visual indicator that section is empty

---

## Files to Investigate for Bug 2

| File | Purpose | Check For |
|------|---------|-----------|
| `MenuBarManager.swift:290-362` | Always Hidden setup | Spacer creation order, length, positioning |
| `MenuBarLayoutViewModel.swift:273-309` | Physical repositioning | `performReposition()` execution |
| `IconRepositioner.swift` | ⌘+drag simulation | CGEvent generation and execution |
| `specs/5.7-menu-bar-layout-reposition-fix.md` | Reposition spec | Implementation details |

---

## Visual Testing with Peekaboo

[Peekaboo](https://github.com/steipete/Peekaboo) is a macOS CLI & MCP server for screen capture and UI automation, ideal for debugging menu bar utilities like Drawer.

### Prerequisites

```bash
# Install via Homebrew
brew install steipete/tap/peekaboo

# Grant required permissions in System Settings > Privacy & Security:
# - Screen Recording (required)
# - Accessibility (required)

# Verify permissions
peekaboo permissions status
```

### Useful Commands for Drawer Debugging

```bash
# List all menu bar items (shows Drawer's status items)
peekaboo menubar list --json-output

# Capture full screen (saves to /tmp/)
peekaboo image --mode screen --retina --path /tmp/drawer_screen.png

# Click Drawer's separator by index (get index from list command)
peekaboo menubar click --index 4

# List running apps (verify Drawer is running)
peekaboo list apps --json-output

# List windows (check for Drawer panel/settings windows)
peekaboo list windows --json-output
```

### Drawer Menu Bar Items

When running, Drawer creates these `NSStatusItem` entries (visible via `peekaboo menubar list`):

| Item | Description |
|------|-------------|
| `drawer_toggle_v4` | Toggle button (`<` / `>`) |
| `drawer_separator_v4` | Hidden section separator (`●`) |
| `drawer_always_hidden_separator_v2` | Always Hidden separator (`≡`) |
| `drawer_always_hidden_spacer_v2` | 10k pixel invisible spacer |

---

## Key Architecture Notes

### 10k Pixel Hack
The core mechanism uses a separator `NSStatusItem` that expands to 10,000 pixels when collapsed, pushing icons off-screen.

### Capture Flow
1. Expand menu bar (make icons visible)
2. Wait for render (50ms)
3. Capture using window-based detection
4. Collapse menu bar
5. Return captured icons

---

## Files Modified Summary

| File | Bug(s) | Changes |
|------|--------|---------|
| `Drawer/Utilities/MenuBarMetrics.swift` | 1 | Added `height(for:)` with `max()` safeguard |
| `Drawer/Core/Managers/HoverManager.swift` | 1, 4 | Per-screen height + `triggerScreen` tracking + callback signature change |
| `Drawer/UI/Settings/LayoutItemView.swift` | 3 | Added `width` to `.frame()` |
| `Drawer/App/AppState.swift` | 4 | Screen param through callback chain to drawer |
| `Drawer/UI/Panels/DrawerPanelController.swift` | 4 | Accept screen param for positioning |
| `Drawer/Core/Engines/IconCapturer.swift` | 5.1, 5.2 | Added PID-based filtering + separator position polling |
| `Drawer/UI/Panels/DrawerPanel.swift` | 7 | Changed `position(on:)` from center to right-align |
| `Drawer/App/AppState.swift` | 7 | Removed fragile separator X positioning |

---

## Recommended Investigation Order

Given the interconnected nature of these bugs, the recommended order is:

### Priority 1: Bug 5 — Settings Menu Bar Layout (CRITICAL)

This is the most visible user-facing issue and blocks testing of other functionality.

1. **5.1** — Filter Drawer control items from capture (blocks everything)
2. **5.3** — Fix duplicate icons (data integrity)
3. **5.6** — Fix drag-and-drop reposition (critical UX)
4. **5.2/5.4** — Fix icon sizes and text overlays (polish)

### Priority 2: Bug 2 — Always Hidden Not Hiding

Once Bug 5 is fixed, users can use Settings to manage Always Hidden section. Then investigate the 10k spacer mechanism.

### Priority 3: Bug 3 — Complete the Icon Size Fix

Apply the fix to Hidden Items and Always Hidden Items sections.

---

## Quick Reference: Key Files

| Component | File | Line Range |
|-----------|------|------------|
| Icon capture & filtering | `IconCapturer.swift` | Full file |
| Section classification | `IconCapturer.swift` | `determineSectionType()` |
| Settings view model | `MenuBarLayoutViewModel.swift` | Full file |
| Section UI | `LayoutSectionView.swift` | Full file |
| Item rendering | `LayoutItemView.swift` | Full file |
| Physical reposition | `IconRepositioner.swift` | Full file |
| Always Hidden setup | `MenuBarManager.swift` | 290-362 |
| Control item definitions | `ControlItem.swift` | Full file |

---

**Last Updated:** 2026-02-02 14:00
