# Phase 1: Foundation & Refactor Specification

**Goal**: Establish a modern SwiftUI codebase using Hidden Bar's core logic as a reference, but discarding its legacy UI architecture. By the end of this phase, the app should be able to hide/show icons using the "separator" method, but without the Drawer UI.

## Task 1.1: Project Setup ## Task 1.1: Project Setup & Clean Slate Clean Slate ✅
- **Objective**: Initialize a new SwiftUI project structure and migrate essential assets/logic.
- **Inputs**: Hidden Bar source code.
- **Steps**:
  1.  Initialize a new SwiftUI App lifecycle (`DrawerApp.swift`).
  2.  Copy `Assets.xcassets` from Hidden Bar (icons).
  3.  Delete `Main.storyboard`, `PreferencesWindowController.swift`, and `AppDelegate.swift` (we will recreate the delegate logic in the App struct adaptor if needed, or pure SwiftUI).
  4.  Set up the folder structure:
      ```
      Drawer/
      ├── App/
      ├── Core/ (Logic)
      ├── UI/ (Views)
      └── Utilities/
      ```
- **Acceptance Criteria**: App compiles and runs as a blank SwiftUI window. No legacy storyboard errors.

## Task 1.2: Port StatusBarController (Logic Only)
- **Objective**: Extract the "10k pixel hack" logic into a clean `MenuBarManager` observable object.
- **Inputs**: `StatusBarController.swift` (reference).
- **Steps**:
  1.  Create `MenuBarManager.swift`.
  2.  Implement the `NSStatusItem` creation for:
      - `expandCollapseItem` (The toggle button)
      - `separatorItem` (The physical barrier)
  3.  Implement `toggle()` function:
      - **Hide**: Set `separatorItem.length = 10000`.
      - **Show**: Set `separatorItem.length = 20`.
  4.  Connect `expandCollapseItem` click action to `toggle()`.
- **Acceptance Criteria**: Running the app places an icon in the menu bar. Clicking it toggles a gap (the spacer) in the menu bar.

## Task 1.3: Migration of User Defaults
- **Objective**: Replace `Preferences.swift` with modern `AppStorage` or a robust `SettingsManager`.
- **Steps**:
  1.  Create `SettingsManager.swift` (ObservableObject).
  2.  Define keys for:
      - `isAutoHidden` (Bool)
      - `autoHideDelay` (Double)
      - `startAtLogin` (Bool)
  3.  Migrate the logic for "Auto-hide after N seconds" into `MenuBarManager`.
- **Acceptance Criteria**: App remembers state between launches. Auto-hide timer works.

## Task 1.4: Launch at Login (Modernization)
- **Objective**: Implement "Start at Login" using the modern `SMAppService` (macOS 13+) if possible, or the standard helper app method if backward compatibility (macOS 14 is our target, so `SMAppService` is preferred).
- **Steps**:
  1.  Add `LaunchAtLogin` package (or implement manually via `SMAppService`).
  2.  Add toggle in a temporary SwiftUI content view.
- **Acceptance Criteria**: Toggling the switch adds/removes the app from Login Items (verifiable in System Settings).

## Task 1.5: Accessibility & Permissions Stub
- **Objective**: Create the `PermissionManager` to handle permissions request.
- **Steps**:
  1.  Create `PermissionManager.swift`.
  2.  Add functions to check `AXIsProcessTrusted()` (Accessibility).
  3.  Add functions to check `CGPreflightScreenCaptureAccess()` (Screen Recording - prep for Phase 2).
  4.  Create a simple "Onboarding" view that shows current permission status.
- **Acceptance Criteria**: App correctly reports if it has Accessibility permissions.
