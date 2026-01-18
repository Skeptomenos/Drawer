# Review: LauncherApplication/Info.plist

**Reviewed**: 2026-01-18  
**Reviewer**: Ralphus  
**Status**: PASSED  
**Findings**: 0 critical, 0 high, 0 medium, 1 low, 4 info

---

## Summary

The `LauncherApplication/Info.plist` is a standard configuration file for a macOS launch-at-login helper application. The launcher uses `LSBackgroundOnly` to remain invisible while launching the main Drawer app. No security issues found. Several maintenance-related inconsistencies with the main app's rebrand from "Hidden Bar" to "Drawer".

---

## [LOW] LSBackgroundOnly Usage Should Be Documented

> Launcher uses LSBackgroundOnly which prevents any UI - behavior difference from LSUIElement

**File**: `LauncherApplication/Info.plist:23-24`  
**Category**: Maintainability  
**Severity**: Low  

### Description

The launcher app uses `LSBackgroundOnly` while the main app uses `LSUIElement`. Both hide the app from the Dock, but they have different behaviors:

- **LSUIElement**: App is hidden from Dock but can still show windows/UI
- **LSBackgroundOnly**: App is completely invisible, cannot show any UI windows

This is the correct choice for a launcher helper, but it should be documented so future maintainers understand the difference.

### Current Code

```xml
<key>LSBackgroundOnly</key>
<true/>
```

### Suggested Fix

No code change needed. Add a comment in AGENTS.md or project documentation explaining:

```markdown
## Launcher Application

The LauncherApplication uses `LSBackgroundOnly` (not `LSUIElement`) because:
1. It should never show any UI
2. It only exists to launch the main app at login
3. It terminates immediately after launching the main app
```

### Verification

1. Build and run LauncherApplication
2. Confirm it doesn't appear in Dock
3. Confirm it launches Drawer and terminates

---

## [INFO] Outdated Copyright Notice

> Copyright references "Dwarves Foundation" instead of "Drawer"

**File**: `LauncherApplication/Info.plist:27-28`  
**Category**: Maintainability  
**Severity**: Info  

### Description

The copyright notice still references the original Hidden Bar authors. Should be updated to match the main app's copyright for consistency.

### Current Code

```xml
<key>NSHumanReadableCopyright</key>
<string>Copyright © 2019 Dwarves Foundation. All rights reserved.</string>
```

### Suggested Fix

```xml
<key>NSHumanReadableCopyright</key>
<string>Copyright © 2024 Drawer. MIT License.</string>
```

### Verification

Build the app and check the About dialog or `mdls` output.

---

## [INFO] Hardcoded Version Strings

> Version strings use literals instead of build variables

**File**: `LauncherApplication/Info.plist:19-21`  
**Category**: Maintainability  
**Severity**: Info  

### Description

The launcher uses hardcoded version strings `"1.0"` and `"2"` while the main app uses build variables `$(MARKETING_VERSION)` and `$(CURRENT_PROJECT_VERSION)`. This means version numbers must be manually synchronized.

### Current Code

```xml
<key>CFBundleShortVersionString</key>
<string>1.0</string>
<key>CFBundleVersion</key>
<string>2</string>
```

### Suggested Fix

```xml
<key>CFBundleShortVersionString</key>
<string>$(MARKETING_VERSION)</string>
<key>CFBundleVersion</key>
<string>$(CURRENT_PROJECT_VERSION)</string>
```

### Verification

1. Build the project
2. Verify both apps report the same version: `mdls -name kMDItemVersion /path/to/app`

---

## [INFO] Legacy App Name Reference in AppDelegate

> AppDelegate still references "Hidden Bar" instead of "Drawer"

**File**: `LauncherApplication/AppDelegate.swift:34`  
**Category**: Maintainability  
**Severity**: Info  

### Description

The launcher's AppDelegate has a hardcoded reference to `"Hidden Bar"` as the app name to launch. This is inconsistent with the Drawer rebrand.

### Current Code

```swift
let appName = "Hidden Bar"
components.append(appName) //main app name
```

### Suggested Fix

```swift
let appName = "Drawer"
components.append(appName) //main app name
```

### Verification

1. Build and archive the app
2. Ensure the launcher successfully starts the main Drawer app

---

## [INFO] Legacy Bundle Identifier Reference

> AppDelegate references old bundle identifier "com.dwarvesv.minimalbar"

**File**: `LauncherApplication/AppDelegate.swift:20`  
**Category**: Maintainability  
**Severity**: Info  

### Description

The launcher checks for the running main app using the old Hidden Bar bundle identifier. Should be updated to match Drawer's identifier.

### Current Code

```swift
let mainAppIdentifier = "com.dwarvesv.minimalbar"
```

### Suggested Fix

```swift
let mainAppIdentifier = "com.drawer.app" // or actual Drawer bundle ID
```

### Verification

1. Check main app's actual bundle identifier in Xcode project
2. Update the launcher to match
3. Test launch-at-login functionality

---

## Checklist Summary

### Security (P0)
- [x] No secrets hardcoded
- [x] No sensitive configuration exposed
- [x] Appropriate entitlements (app-sandbox, read-only file access)

### Correctness (P1)  
- [x] LSBackgroundOnly appropriate for launcher helper
- [x] LSMinimumSystemVersion uses build variable
- [x] Standard plist structure

### Performance (P2)
- [x] N/A for configuration file

### Maintainability (P3)
- [ ] Copyright outdated (info)
- [ ] Version strings hardcoded (info)
- [ ] App name/identifier references outdated (info)
- [ ] LSBackgroundOnly vs LSUIElement difference undocumented (low)

### Testing (P4)
- [x] N/A for configuration file

---

## Verdict

**PASSED** - No critical or high severity findings. The launcher configuration is functionally correct. The info-level findings relate to consistency with the Drawer rebrand and can be addressed in a maintenance pass.
