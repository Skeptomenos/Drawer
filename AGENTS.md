# Drawer Agent Operational Guide (AGENTS.md)

## 1. Project Overview
**Drawer** is a high-performance macOS menu bar utility (forked from Hidden Bar) that declutters the system menu bar by hiding icons into a secondary, collapsible "Drawer" (NSPanel).

**Goal**: Create a high-performance, native macOS menu bar utility that equals or surpasses Bartender in aesthetics and functionality.

- **Target OS**: macOS 14.0+
- **Language**: Swift 5.9+
- **Frameworks**: SwiftUI (Primary UI), AppKit (Windowing/StatusItems), ScreenCaptureKit (Icon Capture).
- **Architecture**: MVVM (Model-View-ViewModel).

---

## 2. Build, Lint, & Test Commands

### Build
- **Standard**: `xcodebuild -scheme Drawer -configuration Debug build`
- **SwiftPM**: `swift build` (if applicable)

### Linting & Formatting
- **Tool**: `swiftlint`
- **Command**: `swiftlint lint`
- **Auto-fix**: `swiftlint --fix`
- **Style**: Adhere to the `.swiftlint.yml` rules (if present). Use 4-space indentation.

### Testing
- **Unit Tests**: `xcodebuild test -scheme DrawerTests`
- **SwiftPM Tests**: `swift test`

---

## 3. Code Style & Architecture Guidelines

### Architecture: MVVM
- **Models**: Plain structs for data (e.g., `MenuBarItem`, `Settings`).
- **Views**: Pure SwiftUI views. Use `NSViewRepresentable` only when wrapping legacy AppKit components.
- **ViewModels**: `ObservableObject` classes that handle business logic and state. Use `@Published` for UI-bound properties.

### UI Principles
- **SwiftUI First**: Avoid Storyboards, XIBs, and Cocoa Bindings.
- **Native Look**: Use system materials (`NSVisualEffectView` materials like `.menu` or `.hudWindow`).
- **Animations**: Use spring-based animations for a tactile feel.

### Naming Conventions
- **Variables/Functions**: `camelCase` (e.g., `isDrawerVisible`, `toggleDrawer()`).
- **Classes/Structs/Enums**: `PascalCase` (e.g., `MenuBarManager`, `DrawerPanel`).
- **Protocols**: `PascalCase`, usually ending in `-ing` or `-able` (e.g., `IconCapturing`).

### Imports
Group imports alphabetically:
1.  Standard Libraries (e.g., `Foundation`)
2.  Apple Frameworks (e.g., `SwiftUI`, `AppKit`, `ScreenCaptureKit`)
3.  Third-party Dependencies
4.  Local Project Files

---

## 4. Project Structure
```
Drawer/
├── App/            # App entry point, AppDelegate/SceneDelegate logic
├── Core/           # Business logic, Managers, Engines
│   ├── Managers/   # MenuBarManager, PermissionManager, SettingsManager
│   └── Engines/    # IconCapturer (ScreenCaptureKit logic)
├── UI/             # SwiftUI Views and ViewModifiers
│   ├── Components/ # Reusable UI elements
│   ├── Panels/     # NSPanel wrappers (DrawerPanel)
│   └── Settings/   # Settings/Preferences views
├── Models/         # Data structures and Enums
└── Utilities/      # Extensions, Helpers, Constants
```

---

## 5. Critical Infrastructure
These components are the "heart" of the application. Modify with extreme caution:

| Component | Responsibility | Risk Level |
|-----------|----------------|------------|
| `MenuBarManager` | Manages `NSStatusItem` positions and the "10k pixel hack". | **CRITICAL** |
| `IconCapturer` | Uses `ScreenCaptureKit` to take "ghost" images of hidden icons. | **HIGH** |
| `PermissionManager` | Handles TCC (Accessibility) and Screen Recording permissions. | **HIGH** |
| `DrawerPanel` | Custom `NSPanel` that hosts the secondary bar. | MEDIUM |

---

## 6. Workflow & Constraints

### Task Execution
- Follow the `Phase 1/2/3` roadmap defined in `PRD.md` and `specs/`.
- **Phase 1**: Foundation & Core Hiding.
- **Phase 2**: The Drawer Engine (Capture & Interaction).
- **Phase 3**: Polish & UI/UX.

### Forbidden Patterns
- **NO Storyboards**: All UI must be code-based (SwiftUI).
- **NO Cocoa Bindings**: Use Combine or `@Published` state management.
- **NO Manual Memory Management**: Leverage ARC and avoid retain cycles in closures (use `[weak self]`).

### Licensing
- **License**: MIT (Inherited from Hidden Bar reference).
- **Attribution**: Maintain original copyright headers for ported logic from Hidden Bar.

---

## 7. AI Agent Instructions
- **Context**: Always read `PRD.md` and `specs/` before starting a new task.
- **Verification**: After modifying logic in `MenuBarManager`, verify that menu bar icons still respond to system events (Command+Drag).
- **Safety**: Do not attempt to bypass TCC permissions programmatically; always use the `PermissionManager` flow.

---

## 8. Testing & Verification Strategy

### Unit Tests
- LLMs MUST write XCTest cases for all business logic (Managers, Engines). Run `xcodebuild test` to verify.

### UI Verification
- Use Xcode Previews for all Views. Create 'Preview Content' assets to mock data.

### Manual Verification
- For system interactions (Menu Bar clicks, Screen Capture), provide a 'Verification Plan' in the output.
- **Example**: "1. Build app. 2. Click toggle. 3. Verify spacer expands."

---

## 9. UI/UX Design System (The 'Beautiful' Standard)

### Materials
- Use `NSVisualEffectView` bridged to SwiftUI. Default material: `.menu` or `.popover`.

### Animations
- Use `.spring(response: 0.3, dampingFraction: 0.7)` for drawer toggles. Avoid linear animations.

### Typography
- Use standard macOS fonts (`.system(size: 13)`). Match menu bar text weight.

### Iconography
- Use SF Symbols. Ensure consistent stroke width (usually `.medium`).

### Borders/Shadows
- Add 0.5px inner border (`Color.white.opacity(0.2)`) and `Shadow(radius: 5)` for depth.

### Visual References
- **Location**: Store reference screenshots (Bartender UI, mockups, native macOS examples) in `specs/reference_images/`.
- **Agent Instruction**: Before implementing any View, agents MUST check this folder. If images exist, use the `look_at` tool to analyze layout, padding, font hierarchy, and materials, then replicate them in SwiftUI.
