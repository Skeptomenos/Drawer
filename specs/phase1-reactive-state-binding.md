# Spec: Phase 1 - Reactive State Binding

**Phase:** 1
**Priority:** High (P1)
**Estimated Time:** 20-30 minutes
**Dependencies:** Phase 0 (completed)
**Parent Doc:** `docs/IMPLEMENTATION_PLAN_ARCHITECTURE_IMPROVEMENTS.md`

---

## Objective

Add Combine-based reactive bindings to `MenuBarManager` so that changes to `isCollapsed` automatically update the separator length and toggle button image. This eliminates manual state synchronization and prevents future desync bugs.

---

## Background

Currently, `expand()` and `collapse()` methods manually update:
1. `separatorItem.length`
2. `toggleItem.button?.image`
3. `isCollapsed`

This creates multiple points of failure. If any update is missed, the UI and state become desynchronized (as happened with the Phase 0 bug).

---

## Requirements

### Functional Requirements

1. When `isCollapsed` changes to `true`:
   - `separatorItem.length` must be set to `separatorCollapsedLength` (10000)
   - `toggleItem.button?.image` must be set to `expandImage`

2. When `isCollapsed` changes to `false`:
   - `separatorItem.length` must be set to `separatorExpandedLength` (20)
   - `toggleItem.button?.image` must be set to `collapseImage`

3. The binding must skip the initial value (handled by `setupUI`)

4. The `expand()` and `collapse()` methods should be simplified to only update `isCollapsed`

### Non-Functional Requirements

- No retain cycles (use `[weak self]`)
- Store subscription in `cancellables`
- Maintain existing debounce behavior

---

## Implementation

### File to Modify

`Drawer/Core/Managers/MenuBarManager.swift`

### Step 1: Add Reactive Binding in init()

After `setupSettingsBindings()`, add:

```swift
private func setupStateBindings() {
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
            self.logger.debug("State binding triggered: isCollapsed=\(collapsed), length=\(self.separatorItem.length)")
        }
        .store(in: &cancellables)
}
```

Call this method in `init()`:

```swift
init(settings: SettingsManager = .shared) {
    self.settings = settings
    self.toggleItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    self.separatorItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    setupUI(attempt: 1)
    setupSettingsBindings()
    setupStateBindings() // ADD THIS
    
    // ... rest of init
}
```

### Step 2: Simplify expand() Method

**Before:**
```swift
func expand() {
    guard isCollapsed else { return }
    logger.debug("Expanding...")
    
    separatorItem.length = separatorExpandedLength
    toggleItem.button?.image = collapseImage
    isCollapsed = false
    
    startAutoCollapseTimer()
    logger.debug("Expanded. Separator Length: \(self.separatorItem.length)")
}
```

**After:**
```swift
func expand() {
    guard isCollapsed else { return }
    logger.debug("Expanding...")
    
    isCollapsed = false  // Triggers reactive binding
    startAutoCollapseTimer()
}
```

### Step 3: Simplify collapse() Method

**Before:**
```swift
func collapse() {
    guard isSeparatorValidPosition, !isCollapsed else {
        logger.debug("Collapse aborted. ValidPos: \(self.isSeparatorValidPosition), IsCollapsed: \(self.isCollapsed)")
        return
    }
    logger.debug("Collapsing...")
    
    cancelAutoCollapseTimer()
    separatorItem.length = separatorCollapsedLength
    toggleItem.button?.image = expandImage
    isCollapsed = true
    logger.debug("Collapsed. Separator Length: \(self.separatorItem.length)")
}
```

**After:**
```swift
func collapse() {
    guard isSeparatorValidPosition, !isCollapsed else {
        logger.debug("Collapse aborted. ValidPos: \(self.isSeparatorValidPosition), IsCollapsed: \(self.isCollapsed)")
        return
    }
    logger.debug("Collapsing...")
    
    cancelAutoCollapseTimer()
    isCollapsed = true  // Triggers reactive binding
}
```

---

## Acceptance Criteria

- [ ] New `setupStateBindings()` method exists
- [ ] `$isCollapsed` publisher drives separator length updates
- [ ] `$isCollapsed` publisher drives toggle image updates
- [ ] `expand()` only sets `isCollapsed = false` (plus timer)
- [ ] `collapse()` only sets `isCollapsed = true` (plus timer cancel)
- [ ] No duplicate length/image assignments in `expand()`/`collapse()`
- [ ] `.dropFirst()` prevents duplicate initial update
- [ ] Build succeeds with no warnings
- [ ] Manual test: Toggle works correctly (expand/collapse)
- [ ] Manual test: Auto-collapse still works

---

## Testing

### Manual Verification Steps

1. Build and run app
2. Click toggle chevron in menu bar
3. Verify separator expands (icons appear)
4. Wait for auto-collapse (if enabled) or click again
5. Verify separator collapses (icons hidden)
6. Check Console.app for debug logs confirming reactive binding triggered

### Debug Log Expected

```
State binding triggered: isCollapsed=false, length=20.0
State binding triggered: isCollapsed=true, length=10000.0
```

---

## Rollback Plan

If issues arise, revert `expand()` and `collapse()` to their original implementations and remove `setupStateBindings()`. The Phase 0 fix ensures correct initial state regardless.

---

## Files Changed

| File | Change |
|------|--------|
| `Drawer/Core/Managers/MenuBarManager.swift` | Add `setupStateBindings()`, simplify `expand()`/`collapse()` |
