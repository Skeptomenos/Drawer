# Code Review: hidden/Info.plist

**Reviewer**: Ralphus  
**Date**: 2026-01-18  
**File**: `hidden/Info.plist`  
**Review Type**: Codebase Review  

## Summary

| Category | Findings |
|----------|----------|
| Critical | 0 |
| High | 0 |
| Medium | 0 |
| Low | 0 |
| Info | 3 |

**Verdict**: PASSED

---

## Review Checklist Results

### Security (P0)
- [x] No hardcoded secrets or API keys
- [x] No sensitive data exposure
- [x] Build variables properly used for bundle identifiers
- [N/A] Input validation (static configuration file)
- [N/A] Authentication/authorization (runtime concern)

### Correctness (P1)
- [x] All required bundle keys present
- [x] LSUIElement set to true (correct for menu bar utility)
- [x] LSMinimumSystemVersion uses deployment target variable
- [x] LSApplicationCategoryType appropriate (utilities)
- [x] Build variables used consistently

### Configuration Specific
- [x] App declared as agent (no dock icon) via LSUIElement
- [x] Bundle metadata complete (version, name, identifier)
- [x] No unnecessary entitlements exposure

### Permission Analysis
- [x] **Accessibility**: No Info.plist key required - managed by TCC via AXIsProcessTrusted
- [x] **Screen Recording**: No Info.plist key required - managed by TCC via CGPreflightScreenCaptureAccess
- [x] **ScreenCaptureKit**: Uses Screen Recording TCC permission, no additional keys needed

---

## [INFO] Empty CFBundleIconFile

> Icon file key is present but empty

**File**: `hidden/Info.plist:10`  
**Category**: Maintainability  
**Severity**: Info  

### Description

The `CFBundleIconFile` key is set to an empty string. While this works if the app icon is defined in an asset catalog (AppIcon set), it could be cleaner to either:
1. Remove the key entirely if using asset catalog
2. Set it to the actual .icns filename if using traditional icon

### Current Code

```xml
<key>CFBundleIconFile</key>
<string></string>
```

### Suggested Fix

If using asset catalog (recommended for modern apps):
```xml
<!-- Remove CFBundleIconFile key entirely, Xcode will use AppIcon from Assets.xcassets -->
```

Or if using traditional .icns file:
```xml
<key>CFBundleIconFile</key>
<string>AppIcon</string>
```

### Verification

1. Verify app icon displays correctly in Finder
2. Verify app icon shows in Activity Monitor when running

---

## [INFO] Copyright Year May Be Stale

> Copyright year is hardcoded as 2024

**File**: `hidden/Info.plist:30`  
**Category**: Maintainability  
**Severity**: Info  

### Description

The copyright string is hardcoded with year 2024. Consider updating or using a range.

### Current Code

```xml
<key>NSHumanReadableCopyright</key>
<string>Copyright 2024 Drawer. MIT License.</string>
```

### Suggested Fix

Update to current year or use range:
```xml
<key>NSHumanReadableCopyright</key>
<string>Copyright 2024-2026 Drawer. MIT License.</string>
```

### Verification

Check copyright displays correctly in About dialog.

---

## [INFO] Consider Adding Minimum System Enforcement Comment

> LSMinimumSystemVersion uses build variable without documentation

**File**: `hidden/Info.plist:25-26`  
**Category**: Maintainability  
**Severity**: Info  

### Description

The minimum system version correctly uses `$(MACOSX_DEPLOYMENT_TARGET)` build variable, which is set to macOS 14.0+ per AGENTS.md. This is good practice. Adding a comment in the project documentation noting this dependency would help future maintainers.

### Current Code

```xml
<key>LSMinimumSystemVersion</key>
<string>$(MACOSX_DEPLOYMENT_TARGET)</string>
```

### Verification

Per AGENTS.md, target OS is macOS 14.0+. Verify build settings match.

---

## Positive Observations

1. **Correct Agent Configuration**: `LSUIElement = true` properly hides the app from the Dock, which is correct for a menu bar utility.

2. **Build Variable Usage**: Proper use of Xcode build variables (`$(DEVELOPMENT_LANGUAGE)`, `$(EXECUTABLE_NAME)`, etc.) ensures consistency between Info.plist and build settings.

3. **Appropriate Category**: `public.app-category.utilities` is the correct App Store category for this type of application.

4. **No TCC Usage Description Keys Needed**: Unlike iOS, macOS Accessibility and Screen Recording permissions are managed via TCC and do not require Info.plist usage description keys. The app correctly handles permission requests programmatically via `PermissionManager.swift`.

5. **Standard Bundle Structure**: All required CFBundle keys are present and properly configured.

---

## Entitlements Cross-Reference

Checked `hidden/Hidden.entitlements`:
- `com.apple.security.app-sandbox`: true
- `com.apple.security.files.user-selected.read-only`: true

The sandbox entitlements are appropriate. Note that Accessibility and Screen Recording permissions operate independently of App Sandbox at the TCC level.

---

## Conclusion

The `hidden/Info.plist` file is correctly configured for a macOS menu bar utility. All required bundle keys are present, the app is properly configured as an agent (no Dock icon), and build variables are used appropriately. No security, correctness, or performance issues were identified.

The three info-level findings are minor housekeeping suggestions that do not affect functionality.
