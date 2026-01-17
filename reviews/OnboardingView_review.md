# Code Review: OnboardingView.swift

**File**: `Drawer/UI/Onboarding/OnboardingView.swift`  
**Reviewer**: Ralphus  
**Date**: 2026-01-18  
**Verdict**: PASSED

## Summary

| Category | Status | Findings |
|----------|--------|----------|
| Security | PASSED | 0 issues |
| Correctness | PASSED | 0 issues |
| Performance | PASSED | 0 issues |
| Maintainability | PASSED | 1 low |
| Testing | PASSED | 0 issues |

**Total**: 0 critical, 0 high, 0 medium, 1 low, 3 info

---

## Findings

### [LOW] Missing MARK Comments

> File lacks MARK section comments per project conventions

**File**: `Drawer/UI/Onboarding/OnboardingView.swift`  
**Category**: Maintainability  
**Severity**: Low  

#### Description

The file does not use MARK comments to organize sections as specified in AGENTS.md ("Use `// MARK: - Section Name`"). While the file is short (139 lines) and readable, MARK comments would improve navigation and maintain consistency with other project files.

#### Current Code

```swift
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var permissionManager = PermissionManager.shared
    @State private var currentStep: OnboardingStep = .welcome

    let onComplete: () -> Void

    var body: some View {
        // ...
    }

    @ViewBuilder
    private var stepContent: some View {
        // ...
    }
```

#### Suggested Fix

```swift
struct OnboardingView: View {
    // MARK: - Environment & State
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var permissionManager = PermissionManager.shared
    @State private var currentStep: OnboardingStep = .welcome

    // MARK: - Properties
    
    let onComplete: () -> Void

    // MARK: - Body
    
    var body: some View {
        // ...
    }

    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        // ...
    }
    
    // MARK: - Navigation
    
    private var navigationBar: some View {
        // ...
    }
    
    // MARK: - Private Methods
    
    private func advanceToNextStep() {
        // ...
    }
}
```

#### Verification

1. Check Xcode minimap shows MARK sections
2. Verify consistency with other UI files in project

---

### [INFO] StateObject Used for Singleton

> Using @StateObject for a singleton is semantically incorrect

**File**: `Drawer/UI/Onboarding/OnboardingView.swift:28`  
**Category**: Maintainability  
**Severity**: Info  

#### Description

`PermissionManager.shared` is accessed via `@StateObject`, but since it's a singleton whose lifecycle is managed externally, `@ObservedObject` would be more semantically correct. Both work, but `@StateObject` implies the view owns the object's lifecycle.

#### Current Code

```swift
@StateObject private var permissionManager = PermissionManager.shared
```

#### Suggested Fix

```swift
@ObservedObject private var permissionManager = PermissionManager.shared
```

---

### [INFO] canAdvance Always Returns True

> Step advancement is not gated on permission state

**File**: `Drawer/UI/Onboarding/OnboardingView.swift:118-120`  
**Category**: Correctness  
**Severity**: Info  

#### Description

The `canAdvance` property always returns `true`, allowing users to skip past the permissions step without granting permissions. This is likely intentional (the app will prompt later), but could be enhanced for a stricter onboarding experience.

#### Current Code

```swift
private var canAdvance: Bool {
    true
}
```

#### Suggested Enhancement (Optional)

```swift
private var canAdvance: Bool {
    switch currentStep {
    case .permissions:
        return permissionManager.hasAllPermissions
    default:
        return true
    }
}
```

---

### [INFO] No Unit Tests for OnboardingStep Enum

> Logic in OnboardingStep enum is untested

**File**: `Drawer/UI/Onboarding/OnboardingView.swift:10-24`  
**Category**: Testing  
**Severity**: Info  

#### Description

The `OnboardingStep` enum has testable logic (`canSkip` property, `rawValue` progression) that could benefit from simple unit tests. The view includes a SwiftUI Preview for visual testing.

#### Suggested Test

```swift
final class OnboardingStepTests: XCTestCase {
    func testCanSkipValues() {
        XCTAssertFalse(OnboardingStep.welcome.canSkip)
        XCTAssertTrue(OnboardingStep.permissions.canSkip)
        XCTAssertTrue(OnboardingStep.tutorial.canSkip)
        XCTAssertFalse(OnboardingStep.completion.canSkip)
    }
    
    func testStepProgression() {
        XCTAssertEqual(OnboardingStep.welcome.rawValue, 0)
        XCTAssertEqual(OnboardingStep.completion.rawValue, 3)
        XCTAssertEqual(OnboardingStep.allCases.count, 4)
    }
}
```

---

## Positive Observations

1. **Clean architecture**: Good use of computed properties to decompose the view
2. **Type safety**: `OnboardingStep` enum with `CaseIterable` prevents invalid states
3. **Animation**: Proper use of `withAnimation` for smooth transitions
4. **SwiftUI patterns**: Correct use of `@ViewBuilder`, `@Environment(\.dismiss)`
5. **Preview**: Includes `#Preview` for development testing
