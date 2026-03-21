# Fix 001: Menu Bar Icon Visibility

**Date**: 2026-01-18  
**File**: `Drawer/Core/Managers/MenuBarManager.swift`  
**Severity**: Critical (app unusable)

---

## Problem

The Drawer application launched successfully but menu bar icons (Toggle and Separator) were invisible. Debug logs revealed:

- **Toggle Frame**: `x: -4115`
- **Separator Frame**: `x: -4088`

The Toggle was positioned to the LEFT of the Separator (`-4115 < -4088`), causing it to be pushed off-screen when the Separator expanded to 10,000 pixels.

## Root Cause

In `setupSections()`, the initialization order was:
1. Create Separator
2. Create Toggle

macOS `NSStatusBar` places new `NSStatusItem`s to the LEFT of existing items. This resulted in:

```
[Toggle] [Separator]  ← WRONG
```

When the Separator expanded to 10k pixels (default collapsed state), it pushed the Toggle off-screen.

## Required Layout

```
[Separator] [Toggle]  ← CORRECT
```

The Toggle must be to the RIGHT of the Separator so it remains visible when the Separator expands.

## Fix Applied

### 1. Reversed Initialization Order (lines 177-223)

**Before**:
```swift
private func setupSections(attempt: Int) {
    // Create separator control item (for hidden section)
    let separatorControl = ControlItem(...)
    // ... setup separator ...
    
    // Create toggle control item (for visible section)
    let toggleControl = ControlItem(...)
    // ... setup toggle ...
}
```

**After**:
```swift
private func setupSections(attempt: Int) {
    // Create toggle control item FIRST (for visible section)
    // This ensures Toggle is placed rightmost, staying visible when Separator expands.
    let toggleControl = ControlItem(...)
    // ... setup toggle ...
    
    // Create separator control item SECOND (for hidden section)
    // This places Separator to the LEFT of Toggle.
    let separatorControl = ControlItem(...)
    // ... setup separator ...
}
```

### 2. Bumped Autosave Names

macOS persists `NSStatusItem` positions based on `autosaveName`. Users who ran the buggy version had corrupted saved layouts.

| Item      | Before               | After                |
|-----------|----------------------|----------------------|
| Toggle    | `drawer_toggle_v3`   | `drawer_toggle_v4`   |
| Separator | `drawer_separator_v3`| `drawer_separator_v4`|

This forces a fresh layout for all users.

## Verification Steps

1. Build and run the app
2. Toggle icon (`<` or `>`) should appear immediately in menu bar
3. Click Toggle → Separator shrinks, revealing hidden icons to its left
4. Click again → Separator expands, hiding icons, Toggle stays visible

## Lessons Learned

- `NSStatusItem` creation order determines visual position (right-to-left packing)
- Always document the expected layout in comments when order matters
- Use autosaveName versioning to reset corrupted user defaults after layout bugs
