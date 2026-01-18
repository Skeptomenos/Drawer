# Feature Request: Drag-to-Reposition Menu Bar Icons

## Overview

Enable users to physically reposition menu bar icons by dragging them between sections in the Settings > Menu Bar Layout view. When a user moves an icon from one section to another (e.g., from "Hidden Items" to "Shown Items"), the actual menu bar should reflect this change.

## Problem Statement

Currently, the Menu Bar Layout settings view allows users to:
- View captured menu bar icons organized by section
- Drag and drop icons between sections (Shown, Hidden, Always Hidden)
- Save layout preferences

However, these changes are **purely cosmetic** - they don't affect the actual position of icons in the macOS menu bar. Users expect that moving an icon to "Shown Items" would make it visible, and moving it to "Hidden Items" would hide it.

## Proposed Solution

Implement a mechanism to physically reposition menu bar icons when users change their section assignments in the Settings view.

### Technical Approaches

#### Option A: Accessibility API (Recommended)
Simulate Command+Drag operations using the Accessibility API (`AXUIElement`).

**Pros:**
- Uses documented (though complex) APIs
- Works with most third-party menu bar apps
- Matches how users manually rearrange icons

**Cons:**
- Requires Accessibility permission
- May have timing/reliability issues
- Some apps may not respond correctly

#### Option B: Private CGS APIs
Use private CoreGraphics Server APIs to directly set window positions.

**Pros:**
- Direct control over window frames
- Potentially more reliable

**Cons:**
- Undocumented, may break in future macOS versions
- App Store rejection risk
- May conflict with app-specific positioning logic

#### Option C: Hybrid Approach
Use Accessibility API as primary method, fall back to event simulation for stubborn icons.

---

## User Stories

### US-1: Move Icon to Shown Section
**As a** Drawer user  
**I want to** drag an icon from Hidden Items to Shown Items in Settings  
**So that** the icon becomes visible in my menu bar without using Command+Drag

**Acceptance Criteria:**
- Icon appears in the Shown Items section in Settings
- Icon physically moves to the visible area of the menu bar
- Icon remains in new position after app restart
- Change is applied within 500ms of dropping the icon

### US-2: Move Icon to Hidden Section
**As a** Drawer user  
**I want to** drag an icon from Shown Items to Hidden Items in Settings  
**So that** the icon is hidden when the menu bar is collapsed

**Acceptance Criteria:**
- Icon appears in the Hidden Items section in Settings
- Icon physically moves to the hidden area (left of the separator)
- Icon is only visible when menu bar is expanded
- Change persists across app restarts

### US-3: Move Icon to Always Hidden Section
**As a** Drawer user  
**I want to** drag an icon to Always Hidden Items in Settings  
**So that** the icon is never visible in the menu bar (only in Drawer panel)

**Acceptance Criteria:**
- Icon appears in Always Hidden Items section in Settings
- Icon is positioned left of the always-hidden separator
- Icon is never visible in the menu bar, even when expanded
- Icon is accessible via the Drawer panel (future feature)

### US-4: Reorder Icons Within Section
**As a** Drawer user  
**I want to** reorder icons within the same section  
**So that** I can customize the exact order of my menu bar icons

**Acceptance Criteria:**
- Icons can be dragged to new positions within the same section
- Menu bar reflects the new order
- Order persists across app restarts

### US-5: Undo Repositioning
**As a** Drawer user  
**I want to** undo a repositioning action  
**So that** I can revert accidental changes

**Acceptance Criteria:**
- Cmd+Z undoes the last repositioning action
- Icon returns to its previous position in both Settings and menu bar
- Multiple levels of undo are supported (at least 5)

### US-6: Handle Immovable Icons
**As a** Drawer user  
**I want to** see clear feedback when trying to move an immovable icon  
**So that** I understand why certain icons cannot be repositioned

**Acceptance Criteria:**
- System icons (Control Center, Clock, Siri) show a "locked" indicator
- Attempting to drag shows a tooltip explaining why it can't be moved
- Immovable icons are visually distinct (e.g., greyed out drag handle)

### US-7: Bulk Repositioning
**As a** Drawer user  
**I want to** select multiple icons and move them together  
**So that** I can quickly reorganize my menu bar

**Acceptance Criteria:**
- Shift+Click to select multiple icons
- Cmd+Click to toggle selection
- Dragging moves all selected icons as a group
- Icons maintain relative order when moved together

---

## Technical Requirements

### Permissions
- Accessibility permission required for icon repositioning
- Prompt user for permission when first attempting to reposition
- Provide clear explanation of why permission is needed

### Performance
- Repositioning should complete within 500ms
- UI should remain responsive during repositioning
- Background repositioning with progress indicator for bulk operations

### Error Handling
- Graceful fallback if repositioning fails
- User notification with retry option
- Logging for debugging failed repositions

### Persistence
- Save icon positions to UserDefaults
- Restore positions on app launch
- Handle cases where icons no longer exist (app uninstalled)

---

## Out of Scope (Future Considerations)

- Repositioning icons from apps that are not running
- Creating custom icon groups
- Icon appearance customization (size, color)
- Cross-display icon management

---

## Success Metrics

- 90% of repositioning attempts succeed on first try
- Average repositioning time < 300ms
- User satisfaction rating > 4.5/5 for menu bar organization feature
- < 5% of users report repositioning issues

---

## Dependencies

- Accessibility API access
- Menu bar icon capture working correctly (completed)
- Settings UI for section management (completed)

---

## Estimated Effort

| Component | Estimate |
|-----------|----------|
| Accessibility API integration | 3-5 days |
| Position calculation logic | 2-3 days |
| Error handling & fallbacks | 2 days |
| Undo/redo system | 1-2 days |
| Testing & edge cases | 2-3 days |
| **Total** | **10-15 days** |

---

## References

- [Ice (jordanbaird/Ice)](https://github.com/jordanbaird/Ice) - Reference implementation
- [Bartender](https://www.macbartender.com/) - Commercial reference
- [Apple Accessibility Programming Guide](https://developer.apple.com/library/archive/documentation/Accessibility/Conceptual/AccessibilityMacOSX/)
