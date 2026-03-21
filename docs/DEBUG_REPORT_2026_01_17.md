# Debug Report: Legacy Visual Artifacts & Outdated Build
**Date:** January 17, 2026
**Status:** Resolved

## 1. Problem Description
The user reported visual bugs in the menu bar interface:
- **Expected:** `<` (chevron left) and `●` (dot)
- **Observed:** `> D |` (chevron right, letter D, and pipe character)
- **Context:** Fresh install on a new Mac, but artifacts persisted.

## 2. Investigation & Findings

### 2.1. Code Review
- **Source Code (Current):**
  - Uses SF Symbols: `chevron.left`, `chevron.right`, `circle.fill`.
  - Autosave names: `drawer_toggle_v3`, `drawer_separator_v3`.
  - Logic: Hides menu bar icons by expanding a separator item.

- **Legacy Code (Hidden Bar):**
  - Used PNG assets: `ic_expand`, `ic_collapse`, `ic_line` (pipe).
  - Autosave names: `hiddenbar_expandcollapse`, `hiddenbar_separate`.

### 2.2. Artifact Analysis
The symbols observed (`|` and `>`) matched the **legacy PNG assets**:
- `|` corresponds to `ic_line.png` from the legacy Hidden Bar assets.
- `>` corresponds to `ic_collapse.png` (legacy) or potentially `chevron.right` (new).
- `D` was likely a visual artifact or fallback rendering of a missing/malformed legacy asset, or the `ic_expand` PNG.

### 2.3. Build Verification
Inspection of the running binary and installed app bundle revealed:
- **Binary Strings:** Contained `hiddenbar_expandcollapse` (legacy) instead of `drawer_toggle_v3` (new).
- **Asset Catalog:** Contained `ic_line`, `ic_expand`, `ic_collapse` (legacy PNGs) instead of just AppIcon.
- **Root Cause:** The `/Applications/Drawer.app` and `dist/Drawer.app` bundles were **outdated builds** generated from an older state of the codebase, despite the source files being up-to-date on disk. The main target's Resources phase was correctly configured to use the new assets, but the *installed* binary was old.

### 2.4. Logic Bug Found
During review, a logic bug was identified in `MenuBarManager.swift`:
- **Issue:** The initial state is `isCollapsed = true`.
- **Bug:** The toggle button image was initialized to `collapseImage` (`>`), implying "click to collapse".
- **Fix:** It should be initialized to `expandImage` (`<`), implying "click to expand".

## 3. Resolution

1.  **Code Fix:**
    - Updated `MenuBarManager.swift` to initialize the toggle button with `expandImage` instead of `collapseImage`.
    - Added fallback to `NSTouchBarGoBackTemplate` if SF Symbol lookup fails.

2.  **Build & Deploy:**
    - Cleaned and rebuilt the project using Xcode 26.2.
    - Verified the new binary contains `drawer_toggle_v3` and lacks legacy asset references.
    - Replaced `/Applications/Drawer.app` with the fresh build.
    - Updated `dist/Drawer.app` with the fresh build.

## 4. Verification
- **New State:** The app now runs the correct code.
- **Visuals:** Should now display `< ●` (SF Symbols) in the menu bar.
- **Behavior:** Initial state correctly shows `<` (expand arrow) when collapsed.

## 5. Recommendations
- **Build Automation:** Ensure `dist/` artifacts are updated automatically during release workflows to prevent stale builds.
- **Version Bumping:** Increment build version to ensure macOS recognizes the update.
