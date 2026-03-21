# Spec: DEP-003 - Migration to @Observable Macro

## Context
Swift 5.9 introduced the `@Observable` macro, which simplifies state management by removing the need for `ObservableObject` protocol and `@Published` property wrappers. This significantly improves performance and reduces boilerplate.

## Problem
The entire project (13 classes) still uses the legacy `ObservableObject` and `@Published` pattern. This deviates from the project's mandate to use modern APIs.

**Affected Classes:**
`AppState`, `SettingsManager`, `MenuBarManager`, `PermissionManager`, `DrawerManager`, `HoverManager`, `OverlayModeManager`, `LaunchAtLoginManager`, `IconCapturer`, `ControlItem`, `MenuBarSection`, `DrawerPanelController`, `OverlayPanelController`.

## Known Limitation: @AppStorage Incompatibility
**SettingsManager cannot be migrated to @Observable.** The `@AppStorage` property wrapper creates computed properties internally, which conflicts with `@Observable`'s generated accessors. Build error:
```
error: property wrapper cannot be applied to a computed property
@AppStorage("autoCollapseEnabled") var autoCollapseEnabled: Bool = true
```

**Resolution:** SettingsManager intentionally remains `ObservableObject`. This is correct behavior per Apple's design - both patterns coexist in SwiftUI. The 12 other classes are migrated to `@Observable`.

## Mitigation Plan
1. **Annotate Classes:** Replace `class X: ObservableObject` with `@Observable class X`.
2. **Remove @Published:** Remove all `@Published` property wrappers from class properties.
3. **Update View Usage:**
   - Replace `@ObservedObject var x` with `@Bindable var x` (if two-way binding is needed) or just `let x` (if only read-only observation is needed).
   - Replace `@EnvironmentObject var x` with `@Environment(X.self) var x`.
4. **App Entry Point:** Update `DrawerApp` to inject instances into the environment using `.environment(instance)` instead of `.environmentObject(instance)`.
5. **Handle Combinations:** For classes using `Combine` pipelines (like `MenuBarManager`), ensure the transition to `@Observable` doesn't break manual `objectWillChange` or publisher logic.

## How to Test
1. **Compilation:** Verify the project builds without errors.
2. **UI Updates:** Navigate through all screens (Settings, Onboarding, Drawer Panel).
3. **Verification:** Ensure UI updates correctly when state changes (e.g., toggling settings, changing icon positions).
4. **Test Suite:** Update all unit tests that rely on `ObservableObject` (see `TEST-005`).

## References
- `rules/rules_swift.md` Section 1.
- Apple Documentation: [Migrating from ObservableObject to @Observable](https://developer.apple.com/documentation/swiftui/migrating-from-observableobject-to-observable)
