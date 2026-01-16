# Drawer Refactoring Plan

**Date**: January 15, 2026  
**Status**: Planning  
**Scope**: Architectural improvements and technical debt reduction

This document outlines four significant refactoring efforts that require dedicated planning and execution beyond simple bug fixes.

---

## Table of Contents

1. [REFACTOR-001: Remove Storyboards and Complete SwiftUI Migration](#refactor-001-remove-storyboards-and-complete-swiftui-migration)
2. [REFACTOR-002: Reduce Singleton Overuse with Dependency Injection](#refactor-002-reduce-singleton-overuse-with-dependency-injection)
3. [REFACTOR-003: Implement Smart Icon Edge Detection](#refactor-003-implement-smart-icon-edge-detection)
4. [REFACTOR-004: Archive and Remove Legacy Code](#refactor-004-archive-and-remove-legacy-code)

---

## REFACTOR-001: Remove Storyboards and Complete SwiftUI Migration

**Priority**: High  
**Effort**: Large (2-3 days)  
**Risk**: Medium  

### Background

Per `AGENTS.md`, the project mandates: **"NO Storyboards: All UI must be code-based (SwiftUI)."**

Currently, the `hidden/` folder contains legacy storyboard-based UI that violates this guideline:

```
hidden/
├── Base.lproj/
│   └── Main.storyboard          # ❌ Storyboard
├── Features/
│   ├── About/
│   │   └── AboutViewController.swift      # Uses @IBOutlet
│   ├── Preferences/
│   │   ├── PreferencesViewController.swift    # Uses @IBOutlet (15+ outlets)
│   │   └── PreferencesWindowController.swift  # Loads from storyboard
```

### Current State Analysis

#### Storyboard Dependencies

| File | IBOutlets | IBActions | Storyboard References |
|------|-----------|-----------|----------------------|
| `AboutViewController.swift` | 1 (`lblVersion`) | 0 | `instantiateController(withIdentifier: "aboutVC")` |
| `PreferencesViewController.swift` | 15+ | 5+ | `instantiateController(withIdentifier: "prefVC")` |
| `PreferencesWindowController.swift` | 0 | 0 | `instantiateController(withIdentifier: "MainWindow")` |

#### Force Casts from Storyboard Loading

```swift
// AboutViewController.swift:16
let vc = NSStoryboard(name:"Main", bundle: nil).instantiateController(withIdentifier: "aboutVC") as! AboutViewController

// PreferencesViewController.swift:60
let vc = NSStoryboard(name:"Main", bundle: nil).instantiateController(withIdentifier: "prefVC") as! PreferencesViewController

// PreferencesWindowController.swift:19
let wc = NSStoryboard(name:"Main", bundle: nil).instantiateController(withIdentifier: "MainWindow") as! PreferencesWindowController
```

### Migration Status

The new `Drawer/` codebase already has SwiftUI replacements:

| Legacy (Storyboard) | New (SwiftUI) | Status |
|---------------------|---------------|--------|
| `PreferencesViewController` | `SettingsView.swift` | ✅ Complete |
| `PreferencesWindowController` | Native `Settings` scene | ✅ Complete |
| `AboutViewController` | `AboutView.swift` | ✅ Complete |
| `Main.storyboard` | `DrawerApp.swift` | ✅ Complete |

### Migration Plan

#### Phase 1: Verify SwiftUI Parity (Day 1)

1. **Audit feature parity** between legacy and new UI:

   | Feature | Legacy Location | SwiftUI Location | Parity |
   |---------|-----------------|------------------|--------|
   | Launch at Login toggle | `PreferencesViewController` | `GeneralSettingsView` | ✅ |
   | Auto-collapse toggle | `PreferencesViewController` | `GeneralSettingsView` | ✅ |
   | Auto-collapse delay slider | `PreferencesViewController` | `GeneralSettingsView` | ✅ |
   | Global hotkey recording | `PreferencesViewController` | `GeneralSettingsView` | ⚠️ Placeholder only |
   | Hide separators toggle | `PreferencesViewController` | `AppearanceSettingsView` | ✅ |
   | Always-hidden section | `PreferencesViewController` | `AppearanceSettingsView` | ✅ |
   | Full status bar toggle | `PreferencesViewController` | `AppearanceSettingsView` | ✅ |
   | Version display | `AboutViewController` | `AboutView` | ✅ |
   | GitHub link | `AboutViewController` | `AboutView` | ✅ |

2. **Identify missing features**:
   - Global hotkey recording UI (currently shows "Not Set" with no recorder)
   - Status bar icon preview in preferences

#### Phase 2: Remove Storyboard References (Day 2)

1. **Update project file** to remove storyboard from build:
   ```
   Hidden Bar.xcodeproj/project.pbxproj
   ```

2. **Remove storyboard files**:
   ```bash
   rm -rf hidden/Base.lproj/Main.storyboard
   rm -rf LauncherApplication/Base.lproj/Main.storyboard
   ```

3. **Update Info.plist** to remove `NSMainStoryboardFile` key

4. **Verify app launches** without storyboard

#### Phase 3: Implement Missing Features (Day 2-3)

1. **Global Hotkey Recorder**:
   ```swift
   // New file: Drawer/UI/Components/HotkeyRecorderView.swift
   struct HotkeyRecorderView: View {
       @Binding var hotkey: GlobalHotkeyConfig?
       @State private var isRecording = false
       
       var body: some View {
           Button(action: { isRecording.toggle() }) {
               if isRecording {
                   Text("Press keys...")
                       .foregroundColor(.accentColor)
               } else if let hotkey = hotkey {
                   Text(hotkey.description)
               } else {
                   Text("Click to record")
                       .foregroundColor(.secondary)
               }
           }
           .onKeyPress { key in
               // Record key combination
           }
       }
   }
   ```

2. **Status Bar Preview** (optional enhancement):
   ```swift
   // Visual preview of icon arrangement in preferences
   struct StatusBarPreviewView: View {
       var body: some View {
           HStack {
               // Show toggle icon, separator, hidden icons representation
           }
       }
   }
   ```

#### Phase 4: Cleanup (Day 3)

1. Remove unused legacy files (see REFACTOR-004)
2. Update documentation
3. Run full test suite

### Acceptance Criteria

- [ ] No storyboard files in project
- [ ] No `@IBOutlet` or `@IBAction` in codebase
- [ ] No `NSStoryboard` references in code
- [ ] All preferences accessible via SwiftUI Settings
- [ ] App launches and functions correctly
- [ ] Global hotkey recording works (or documented as future work)

### Rollback Plan

Keep `hidden/` folder in a separate git branch until migration is verified stable in production.

---

## REFACTOR-002: Reduce Singleton Overuse with Dependency Injection

**Priority**: Medium  
**Effort**: Large (2-3 days)  
**Risk**: Medium (requires careful testing)  

### Background

The codebase has 9 singletons, making unit testing difficult and creating hidden dependencies:

| Singleton | Purpose | Testability Impact |
|-----------|---------|-------------------|
| `AppState.shared` | Central app state | Cannot mock for UI tests |
| `SettingsManager.shared` | User preferences | Cannot test with different settings |
| `PermissionManager.shared` | TCC permissions | Cannot simulate permission states |
| `DrawerManager.shared` | Drawer state | Cannot test drawer logic in isolation |
| `IconCapturer.shared` | Screen capture | Cannot mock capture results |
| `EventSimulator.shared` | Click simulation | Cannot test without accessibility |
| `HoverManager.shared` | Mouse tracking | Cannot simulate hover events |
| `LaunchAtLoginManager.shared` | Login item | Cannot test without system changes |
| `PreferencesWindowController.shared` | Legacy window | N/A (being removed) |

### Current Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        AppState                              │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐    │
│  │ MenuBar     │ │ Drawer      │ │ DrawerPanel         │    │
│  │ Manager     │ │ Manager     │ │ Controller          │    │
│  └──────┬──────┘ └──────┬──────┘ └──────────┬──────────┘    │
│         │               │                    │               │
│         ▼               ▼                    ▼               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              Singletons (Global Access)              │    │
│  │  SettingsManager  PermissionManager  IconCapturer   │    │
│  │  EventSimulator   HoverManager       LaunchAtLogin  │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### Target Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Dependency Container                     │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Protocols (Abstractions)                            │    │
│  │  SettingsProviding  PermissionChecking  IconCapturing│    │
│  │  EventSimulating    HoverTracking       LoginManaging│    │
│  └─────────────────────────────────────────────────────┘    │
│                            │                                 │
│                            ▼                                 │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  Concrete Implementations (Injected)                 │    │
│  │  SettingsManager  PermissionManager  IconCapturer   │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                        AppState                              │
│         (Receives dependencies through initializer)          │
└─────────────────────────────────────────────────────────────┘
```

### Implementation Plan

#### Phase 1: Define Protocols (Day 1)

Create protocol abstractions for each manager:

```swift
// Drawer/Core/Protocols/SettingsProviding.swift
protocol SettingsProviding: AnyObject {
    var autoCollapseEnabled: Bool { get set }
    var autoCollapseDelay: Double { get set }
    var launchAtLogin: Bool { get set }
    var showOnHover: Bool { get set }
    var hasCompletedOnboarding: Bool { get set }
    
    var autoCollapseSettingsChanged: AnyPublisher<Void, Never> { get }
    var showOnHoverSubject: PassthroughSubject<Bool, Never> { get }
}

// Drawer/Core/Protocols/PermissionChecking.swift
protocol PermissionChecking: AnyObject {
    var hasAccessibility: Bool { get }
    var hasScreenRecording: Bool { get }
    var hasAllPermissions: Bool { get }
    var permissionStatusChanged: AnyPublisher<Void, Never> { get }
    
    func requestAccessibility()
    func requestScreenRecording()
}

// Drawer/Core/Protocols/IconCapturing.swift
protocol IconCapturing: AnyObject {
    var isCapturing: Bool { get }
    var lastCaptureResult: MenuBarCaptureResult? { get }
    var lastError: CaptureError? { get }
    
    func captureHiddenIcons(menuBarManager: MenuBarManager) async throws -> MenuBarCaptureResult
}

// Drawer/Core/Protocols/EventSimulating.swift
protocol EventSimulating: AnyObject {
    var hasAccessibilityPermission: Bool { get }
    func simulateClick(at point: CGPoint) async throws
}

// Drawer/Core/Protocols/HoverTracking.swift
protocol HoverTracking: AnyObject {
    var isMonitoring: Bool { get }
    var onShouldShowDrawer: (() -> Void)? { get set }
    var onShouldHideDrawer: (() -> Void)? { get set }
    
    func startMonitoring()
    func stopMonitoring()
    func setDrawerVisible(_ visible: Bool)
}
```

#### Phase 2: Conform Existing Classes (Day 1)

```swift
// SettingsManager.swift
extension SettingsManager: SettingsProviding {}

// PermissionManager.swift
extension PermissionManager: PermissionChecking {}

// IconCapturer.swift
extension IconCapturer: IconCapturing {}

// EventSimulator.swift
extension EventSimulator: EventSimulating {}

// HoverManager.swift
extension HoverManager: HoverTracking {}
```

#### Phase 3: Update AppState to Use Protocols (Day 2)

```swift
@MainActor
final class AppState: ObservableObject {
    
    // MARK: - Dependencies (Protocol Types)
    
    let menuBarManager: MenuBarManager
    let settings: SettingsProviding
    let permissions: PermissionChecking
    let drawerController: DrawerPanelController
    let drawerManager: DrawerManager
    let iconCapturer: IconCapturing
    let eventSimulator: EventSimulating
    let hoverManager: HoverTracking
    
    // MARK: - Singleton (for production use)
    
    static let shared = AppState()
    
    // MARK: - Initialization
    
    init(
        settings: SettingsProviding = SettingsManager.shared,
        permissions: PermissionChecking = PermissionManager.shared,
        drawerManager: DrawerManager = .shared,
        iconCapturer: IconCapturing = IconCapturer.shared,
        eventSimulator: EventSimulating = EventSimulator.shared,
        hoverManager: HoverTracking = HoverManager.shared
    ) {
        self.settings = settings
        self.permissions = permissions
        self.drawerManager = drawerManager
        self.iconCapturer = iconCapturer
        self.eventSimulator = eventSimulator
        self.hoverManager = hoverManager
        self.menuBarManager = MenuBarManager(settings: settings as! SettingsManager)
        self.drawerController = DrawerPanelController()
        
        // ... rest of init
    }
}
```

#### Phase 4: Create Mock Implementations for Testing (Day 2)

```swift
// DrawerTests/Mocks/MockPermissionManager.swift
final class MockPermissionManager: PermissionChecking {
    var hasAccessibility: Bool = true
    var hasScreenRecording: Bool = true
    var hasAllPermissions: Bool { hasAccessibility && hasScreenRecording }
    
    var permissionStatusChanged: AnyPublisher<Void, Never> {
        permissionStatusSubject.eraseToAnyPublisher()
    }
    private let permissionStatusSubject = PassthroughSubject<Void, Never>()
    
    func requestAccessibility() {
        hasAccessibility = true
        permissionStatusSubject.send()
    }
    
    func requestScreenRecording() {
        hasScreenRecording = true
        permissionStatusSubject.send()
    }
    
    // Test helpers
    func simulatePermissionDenied() {
        hasAccessibility = false
        hasScreenRecording = false
        permissionStatusSubject.send()
    }
}

// DrawerTests/Mocks/MockIconCapturer.swift
final class MockIconCapturer: IconCapturing {
    var isCapturing: Bool = false
    var lastCaptureResult: MenuBarCaptureResult?
    var lastError: CaptureError?
    
    var mockResult: Result<MenuBarCaptureResult, CaptureError>?
    
    func captureHiddenIcons(menuBarManager: MenuBarManager) async throws -> MenuBarCaptureResult {
        isCapturing = true
        defer { isCapturing = false }
        
        if let result = mockResult {
            switch result {
            case .success(let captureResult):
                lastCaptureResult = captureResult
                return captureResult
            case .failure(let error):
                lastError = error
                throw error
            }
        }
        
        throw CaptureError.captureFailedNoImage
    }
}
```

#### Phase 5: Write Unit Tests (Day 3)

```swift
// DrawerTests/AppStateTests.swift
@MainActor
final class AppStateTests: XCTestCase {
    
    var mockSettings: MockSettingsManager!
    var mockPermissions: MockPermissionManager!
    var mockIconCapturer: MockIconCapturer!
    var sut: AppState!
    
    override func setUp() {
        super.setUp()
        mockSettings = MockSettingsManager()
        mockPermissions = MockPermissionManager()
        mockIconCapturer = MockIconCapturer()
        
        sut = AppState(
            settings: mockSettings,
            permissions: mockPermissions,
            iconCapturer: mockIconCapturer
        )
    }
    
    func testShowDrawer_WhenPermissionDenied_RequestsPermission() async {
        // Given
        mockPermissions.hasScreenRecording = false
        
        // When
        sut.showDrawerWithCapture()
        
        // Then
        XCTAssertTrue(mockPermissions.requestScreenRecordingCalled)
    }
    
    func testCaptureAndShowDrawer_WhenCaptureSucceeds_ShowsDrawer() async {
        // Given
        mockPermissions.hasScreenRecording = true
        mockIconCapturer.mockResult = .success(MockData.captureResult)
        
        // When
        await sut.captureAndShowDrawer()
        
        // Then
        XCTAssertTrue(sut.isDrawerVisible)
        XCTAssertEqual(sut.drawerManager.items.count, 5)
    }
    
    func testCaptureAndShowDrawer_WhenCaptureFails_SetsError() async {
        // Given
        mockPermissions.hasScreenRecording = true
        mockIconCapturer.mockResult = .failure(.permissionDenied)
        
        // When
        await sut.captureAndShowDrawer()
        
        // Then
        XCTAssertEqual(sut.captureError, .permissionDenied)
    }
}
```

#### Phase 6: Gradual Rollout (Day 3+)

1. Keep `.shared` singletons working for backward compatibility
2. Update one component at a time to use DI
3. Add tests for each migrated component
4. Remove direct singleton access once all consumers use DI

### File Structure After Refactoring

```
Drawer/
├── Core/
│   ├── Protocols/           # NEW
│   │   ├── SettingsProviding.swift
│   │   ├── PermissionChecking.swift
│   │   ├── IconCapturing.swift
│   │   ├── EventSimulating.swift
│   │   └── HoverTracking.swift
│   ├── Managers/
│   │   ├── SettingsManager.swift      # + extension conformance
│   │   ├── PermissionManager.swift    # + extension conformance
│   │   └── ...
│   └── Engines/
│       └── IconCapturer.swift         # + extension conformance
└── ...

DrawerTests/                  # NEW
├── Mocks/
│   ├── MockSettingsManager.swift
│   ├── MockPermissionManager.swift
│   ├── MockIconCapturer.swift
│   ├── MockEventSimulator.swift
│   └── MockHoverManager.swift
├── AppStateTests.swift
├── MenuBarManagerTests.swift
├── IconCapturerTests.swift
└── ...
```

### Acceptance Criteria

- [ ] All managers have protocol abstractions
- [ ] `AppState` accepts dependencies through initializer
- [ ] Mock implementations exist for all protocols
- [ ] Unit tests cover critical paths
- [ ] Existing functionality unchanged
- [ ] `.shared` singletons still work for production

### Benefits

1. **Testability**: Can inject mocks for isolated unit testing
2. **Flexibility**: Easy to swap implementations
3. **Clarity**: Dependencies are explicit, not hidden
4. **Maintainability**: Easier to reason about component relationships

---

## REFACTOR-003: Implement Smart Icon Edge Detection

**Priority**: Medium  
**Effort**: Medium (1-2 days)  
**Risk**: Low  

### Background

The current icon slicing algorithm uses fixed-width assumptions:

```swift
// IconCapturer.swift:371
// TODO: Implement smarter edge detection for variable-width icons

private func sliceIcons(from image: CGImage, separatorX: CGFloat?) -> [CapturedIcon] {
    // Current: Fixed 22pt width + 4pt spacing
    let iconWidthPixels = standardIconWidth * scale  // 22pt
    let spacingPixels = iconSpacing * scale          // 4pt
    let stepSize = iconWidthPixels + spacingPixels   // 26pt
    
    // Blindly slices at fixed intervals
    while currentX + iconWidthPixels <= imageWidth {
        // Crop at fixed positions...
    }
}
```

### Problem

Menu bar icons have variable widths:

| Icon Type | Typical Width | Example |
|-----------|---------------|---------|
| Standard system icon | 22pt | Wi-Fi, Bluetooth |
| Battery with percentage | 40-50pt | Battery 100% |
| Date/Time | 60-80pt | "Thu 3:45 PM" |
| Third-party apps | 18-30pt | Varies |
| Control Center | 22pt | Standard |

Fixed-width slicing causes:
- Icons cut off mid-glyph
- Multiple icons merged into one slice
- Incorrect click targets

### Proposed Solution: Column Variance Analysis

Detect icon boundaries by analyzing vertical "gap" columns (low pixel variance):

```
Menu Bar Capture:
┌────────────────────────────────────────────────────────┐
│ [Icon1] ░ [Icon2] ░ [Wide Icon 3] ░ [Icon4] ░ [Icon5] │
└────────────────────────────────────────────────────────┘
          ▲         ▲               ▲         ▲
          │         │               │         │
       Gap columns (low variance = separator)
```

### Implementation

#### Step 1: Calculate Column Variance

```swift
// IconCapturer.swift

/// Analyzes a captured image to find icon boundaries using column variance
private func detectIconBoundaries(in image: CGImage) -> [CGFloat] {
    guard let context = createAnalysisContext(for: image),
          let pixelData = context.data else {
        return []
    }
    
    let width = image.width
    let height = image.height
    let bytesPerPixel = 4
    let bytesPerRow = context.bytesPerRow
    
    var columnVariances: [Double] = []
    
    // Calculate variance for each column
    for x in 0..<width {
        var pixelValues: [Double] = []
        
        for y in 0..<height {
            let offset = y * bytesPerRow + x * bytesPerPixel
            let alpha = Double(pixelData.load(fromByteOffset: offset + 3, as: UInt8.self))
            pixelValues.append(alpha)
        }
        
        let variance = calculateVariance(pixelValues)
        columnVariances.append(variance)
    }
    
    return findGapPositions(in: columnVariances)
}

/// Finds positions where variance drops below threshold (gaps between icons)
private func findGapPositions(in variances: [Double]) -> [CGFloat] {
    let threshold = 10.0  // Tune based on testing
    let minGapWidth = 2   // Minimum consecutive low-variance columns
    
    var gaps: [CGFloat] = []
    var gapStart: Int?
    var consecutiveLowVariance = 0
    
    for (index, variance) in variances.enumerated() {
        if variance < threshold {
            if gapStart == nil {
                gapStart = index
            }
            consecutiveLowVariance += 1
        } else {
            if consecutiveLowVariance >= minGapWidth, let start = gapStart {
                // Found a gap - record the center position
                let gapCenter = CGFloat(start + consecutiveLowVariance / 2)
                gaps.append(gapCenter)
            }
            gapStart = nil
            consecutiveLowVariance = 0
        }
    }
    
    return gaps
}

private func calculateVariance(_ values: [Double]) -> Double {
    guard !values.isEmpty else { return 0 }
    let mean = values.reduce(0, +) / Double(values.count)
    let squaredDiffs = values.map { ($0 - mean) * ($0 - mean) }
    return squaredDiffs.reduce(0, +) / Double(values.count)
}
```

#### Step 2: Update Slicing Logic

```swift
private func sliceIcons(from image: CGImage, separatorX: CGFloat?) -> [CapturedIcon] {
    let scale = NSScreen.main?.backingScaleFactor ?? 2.0
    
    // Try smart detection first
    let boundaries = detectIconBoundaries(in: image)
    
    if boundaries.count >= 2 {
        return sliceAtBoundaries(image: image, boundaries: boundaries, scale: scale)
    } else {
        // Fall back to fixed-width slicing
        logger.warning("Edge detection found insufficient boundaries, using fixed-width fallback")
        return sliceFixedWidth(image: image, separatorX: separatorX, scale: scale)
    }
}

private func sliceAtBoundaries(image: CGImage, boundaries: [CGFloat], scale: CGFloat) -> [CapturedIcon] {
    var icons: [CapturedIcon] = []
    let imageHeight = CGFloat(image.height)
    
    for i in 0..<(boundaries.count - 1) {
        let startX = boundaries[i]
        let endX = boundaries[i + 1]
        let width = endX - startX
        
        // Skip if too narrow (likely a false positive)
        guard width > 10 * scale else { continue }
        
        let cropRect = CGRect(x: startX, y: 0, width: width, height: imageHeight)
        
        if let croppedImage = image.cropping(to: cropRect) {
            let originalFrame = CGRect(
                x: startX / scale,
                y: 0,
                width: width / scale,
                height: imageHeight / scale
            )
            icons.append(CapturedIcon(image: croppedImage, originalFrame: originalFrame))
        }
    }
    
    return icons
}

private func sliceFixedWidth(image: CGImage, separatorX: CGFloat?, scale: CGFloat) -> [CapturedIcon] {
    // Existing fixed-width implementation
    // ... (current code)
}
```

#### Step 3: Add Configuration Options

```swift
// SettingsManager.swift
@AppStorage("useSmartIconDetection") var useSmartIconDetection: Bool = true
@AppStorage("iconDetectionThreshold") var iconDetectionThreshold: Double = 10.0
```

### Testing Strategy

1. **Unit Tests**: Test variance calculation with known pixel patterns
2. **Visual Tests**: Capture real menu bars and verify slicing
3. **Edge Cases**:
   - All icons same width
   - Very wide icons (date/time)
   - Very narrow icons
   - High-contrast vs low-contrast icons
   - Dark mode vs light mode

### Acceptance Criteria

- [ ] Variable-width icons correctly detected
- [ ] Click targets align with actual icon centers
- [ ] Fallback to fixed-width when detection fails
- [ ] Performance acceptable (< 50ms for detection)
- [ ] Works in both light and dark mode

---

## REFACTOR-004: Archive and Remove Legacy Code

**Priority**: Low  
**Effort**: Small (2-4 hours)  
**Risk**: Low  

### Background

The `hidden/` folder contains the original Hidden Bar codebase that has been superseded by the new `Drawer/` implementation. This legacy code:

- Uses storyboards (violates guidelines)
- Has different architecture patterns
- Contains duplicate functionality
- Increases maintenance burden
- Confuses new contributors

### Current Legacy Structure

```
hidden/
├── AppDelegate.swift                    # Replaced by Drawer/App/AppDelegate.swift
├── EventMonitor.swift                   # Replaced by Drawer/Utilities/GlobalEventMonitor.swift
├── Base.lproj/
│   └── Main.storyboard                  # Replaced by SwiftUI
├── Common/
│   ├── Assets.swift                     # Image loading
│   ├── Constant.swift                   # Constants
│   ├── Preferences.swift                # Replaced by SettingsManager
│   └── Util.swift                       # Utilities
├── Extensions/
│   ├── Bundle+Extension.swift
│   ├── Date+Extension.swift
│   ├── Notification.Name+Extension.swift
│   ├── NSWindow+Extension.swift
│   ├── StackView+Extension.swift
│   ├── String+Extension.swift
│   └── UserDefault+Extension.swift
├── Features/
│   ├── About/
│   │   └── AboutViewController.swift    # Replaced by AboutView.swift
│   ├── Preferences/
│   │   ├── PreferencesViewController.swift   # Replaced by SettingsView.swift
│   │   └── PreferencesWindowController.swift
│   └── StatusBar/
│       └── StatusBarController.swift    # Replaced by MenuBarManager.swift
├── Models/
│   ├── GlobalKeybindingPreferences.swift
│   └── SelectedSecond.swift
└── Views/
    ├── HyperlinkTextField.swift
    ├── NSBarButtonItem+Extension.swift
    └── NSView+Extension.swift

LauncherApplication/                      # Helper app for login item
├── AppDelegate.swift
├── Base.lproj/
│   └── Main.storyboard
└── ViewController.swift
```

### Migration Mapping

| Legacy File | New Replacement | Notes |
|-------------|-----------------|-------|
| `hidden/AppDelegate.swift` | `Drawer/App/AppDelegate.swift` | Complete replacement |
| `hidden/EventMonitor.swift` | `Drawer/Utilities/GlobalEventMonitor.swift` | Improved version |
| `hidden/Common/Preferences.swift` | `Drawer/Core/Managers/SettingsManager.swift` | Uses @AppStorage |
| `hidden/Features/StatusBar/StatusBarController.swift` | `Drawer/Core/Managers/MenuBarManager.swift` | Core logic preserved |
| `hidden/Features/About/AboutViewController.swift` | `Drawer/UI/Settings/AboutView.swift` | SwiftUI |
| `hidden/Features/Preferences/*` | `Drawer/UI/Settings/*` | SwiftUI |
| `LauncherApplication/` | `SMAppService` (macOS 13+) | No helper app needed |

### Archival Plan

#### Step 1: Create Archive Branch

```bash
# Create archive branch from current state
git checkout -b archive/hidden-bar-legacy
git push origin archive/hidden-bar-legacy

# Return to main
git checkout main
```

#### Step 2: Verify No Active Dependencies

Check that no code in `Drawer/` imports from `hidden/`:

```bash
# Search for imports from hidden folder
grep -r "import.*hidden" Drawer/
grep -r "hidden/" Drawer/

# Search for references to legacy classes
grep -r "StatusBarController" Drawer/
grep -r "PreferencesViewController" Drawer/
grep -r "AboutViewController" Drawer/
```

#### Step 3: Update Project File

Remove `hidden/` and `LauncherApplication/` from Xcode project:

1. Open `Hidden Bar.xcodeproj`
2. Remove `hidden` group from project navigator
3. Remove `LauncherApplication` target
4. Update scheme to only build `Drawer` target

#### Step 4: Remove Files

```bash
# Remove legacy folders
rm -rf hidden/
rm -rf LauncherApplication/

# Commit removal
git add -A
git commit -m "chore: remove legacy Hidden Bar code

The original Hidden Bar codebase has been fully replaced by the new
Drawer implementation using SwiftUI and modern macOS APIs.

Legacy code archived in branch: archive/hidden-bar-legacy

Removed:
- hidden/ folder (storyboard-based UI)
- LauncherApplication/ (replaced by SMAppService)
"
```

#### Step 5: Update Documentation

Update `README.md` to reflect new architecture:

```markdown
## Architecture

Drawer is built with:
- **SwiftUI** for all UI components
- **Combine** for reactive state management
- **ScreenCaptureKit** for icon capture
- **SMAppService** for launch at login (no helper app required)

### Project Structure

```
Drawer/
├── App/           # App entry point and lifecycle
├── Core/          # Business logic and managers
├── Models/        # Data structures
├── UI/            # SwiftUI views
└── Utilities/     # Helper classes
```
```

#### Step 6: Preserve Attribution

Ensure copyright headers acknowledge original work:

```swift
//
//  MenuBarManager.swift
//  Drawer
//
//  Based on StatusBarController.swift from Hidden Bar
//  Original work Copyright © 2019 Dwarves Foundation
//  Modifications Copyright © 2026 Drawer
//
//  MIT License
//
```

### Files to Preserve (Copy to Drawer/)

Some legacy code may have useful utilities not yet migrated:

| Legacy File | Useful Code | Action |
|-------------|-------------|--------|
| `String+Extension.swift` | `.localized` property | Migrate if needed |
| `Date+Extension.swift` | Date formatting | Evaluate usefulness |
| `Constant.swift` | `isUsingLTRLanguage` | Already in MenuBarManager |

### Acceptance Criteria

- [ ] Archive branch created with full legacy code
- [ ] No runtime dependencies on legacy code
- [ ] Project builds without `hidden/` folder
- [ ] `LauncherApplication` target removed
- [ ] README updated
- [ ] Attribution preserved in relevant files
- [ ] App functions correctly after removal

### Rollback Plan

If issues discovered after removal:

```bash
# Restore from archive branch
git checkout archive/hidden-bar-legacy -- hidden/
git checkout archive/hidden-bar-legacy -- LauncherApplication/
```

---

## Summary

| Refactor | Priority | Effort | Dependencies |
|----------|----------|--------|--------------|
| REFACTOR-001: Remove Storyboards | High | Large | None |
| REFACTOR-002: Dependency Injection | Medium | Large | None |
| REFACTOR-003: Smart Icon Detection | Medium | Medium | None |
| REFACTOR-004: Remove Legacy Code | Low | Small | REFACTOR-001 |

### Recommended Execution Order

1. **REFACTOR-004** (Remove Legacy) - Quick win, reduces confusion
2. **REFACTOR-001** (Remove Storyboards) - Completes UI migration
3. **REFACTOR-003** (Icon Detection) - Improves core functionality
4. **REFACTOR-002** (Dependency Injection) - Enables testing, largest effort

### Total Estimated Effort

- Minimum: 5-6 days
- With thorough testing: 8-10 days

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-15 | Automated Analysis | Initial plan |
| 1.1 | 2026-01-15 | Deep Investigation | Added reference implementations from Ice, OnlySwitch, SwiftBar |

---

## Appendix A: Reference Implementations from External Projects

This appendix contains implementation patterns discovered from analyzing three production macOS menu bar utilities. **Ice** (https://github.com/jordanbaird/Ice) is the primary reference as it's architecturally most similar to Drawer.

### A.1 Projects Analyzed

| Project | Repository | Relevance |
|---------|------------|-----------|
| **Ice** | `jordanbaird/Ice` | Primary reference - sophisticated menu bar manager, SwiftUI-first, excellent architecture |
| **OnlySwitch** | `jacklandrin/OnlySwitch` | Secondary reference - protocol patterns, switch abstraction |
| **SwiftBar** | `swiftbar/SwiftBar` | Tertiary reference - plugin architecture, preferences patterns |

---

### A.2 Reference for REFACTOR-001: SwiftUI Migration

#### Ice's Storyboard-Free Entry Point

Ice uses a pure SwiftUI `@main` entry point with `@NSApplicationDelegateAdaptor`:

```swift
// Ice/Main/IceApp.swift
@main
struct IceApp: App {
    @NSApplicationDelegateAdaptor var appDelegate: AppDelegate
    @ObservedObject var appState = AppState()

    init() {
        NSSplitViewItem.swizzle()
        MigrationManager.migrateAll(appState: appState)
        appDelegate.assignAppState(appState)
    }

    var body: some Scene {
        SettingsWindow(appState: appState)
        PermissionsWindow(appState: appState)
    }
}
```

**Key Pattern**: No `WindowGroup` for settings - uses custom `Window` scene.

#### Ice's Settings Window as SwiftUI Scene

```swift
// Ice/Settings/SettingsWindow.swift
struct SettingsWindow: Scene {
    @ObservedObject var appState: AppState

    var body: some Scene {
        Window(Constants.settingsWindowTitle, id: Constants.settingsWindowID) {
            SettingsView()
                .readWindow { window in
                    guard let window else { return }
                    appState.assignSettingsWindow(window)
                }
                .frame(minWidth: 825, minHeight: 500)
        }
        .commandsRemoved()
        .windowResizability(.contentSize)
        .defaultSize(width: 900, height: 625)
        .environmentObject(appState)
        .environmentObject(appState.navigationState)
    }
}
```

**Key Pattern**: `.readWindow` modifier captures `NSWindow` reference for AppKit interop without storyboards.

#### Ice's HotkeyRecorder (Missing Feature in Drawer)

```swift
// Ice/UI/HotkeyRecorder/HotkeyRecorder.swift
struct HotkeyRecorder<Label: View>: View {
    @StateObject private var model: HotkeyRecorderModel

    private let label: Label

    init(hotkey: Hotkey, @ViewBuilder label: () -> Label) {
        self._model = StateObject(wrappedValue: HotkeyRecorderModel(hotkey: hotkey))
        self.label = label()
    }

    var body: some View {
        IceLabeledContent {
            HStack(spacing: 1) {
                leadingSegment
                trailingSegment
            }
            .frame(width: 132, height: 24)
        } label: {
            label
        }
    }

    @ViewBuilder
    private var leadingSegment: some View {
        Button {
            model.startRecording()
        } label: {
            if model.isRecording {
                Text("Type Hotkey")
            } else if model.hotkey.isEnabled {
                if let keyCombination = model.hotkey.keyCombination {
                    HStack(spacing: 0) {
                        Text(keyCombination.modifiers.symbolicValue)
                        Text(keyCombination.key.stringValue.capitalized)
                    }
                }
            } else {
                Text("Record Hotkey")
            }
        }
    }

    @ViewBuilder
    private var trailingSegment: some View {
        Button {
            if model.isRecording {
                model.stopRecording()
            } else if model.hotkey.isEnabled {
                model.hotkey.keyCombination = nil
            } else {
                model.startRecording()
            }
        } label: {
            Image(systemName: model.isRecording ? "escape" : 
                  model.hotkey.isEnabled ? "xmark.circle.fill" : "record.circle")
        }
    }
}
```

**Implementation Note**: Ice's hotkey system uses a `HotkeyRegistry` and `KeyCombination` model. Files to reference:
- `Ice/Hotkeys/Hotkey.swift`
- `Ice/Hotkeys/KeyCombination.swift`
- `Ice/Hotkeys/HotkeyRegistry.swift`
- `Ice/UI/HotkeyRecorder/HotkeyRecorderModel.swift`

---

### A.3 Reference for REFACTOR-002: Dependency Injection

#### Ice's Lazy Manager Pattern with Weak AppState

Ice uses a centralized `AppState` with lazy-initialized managers that hold weak references back:

```swift
// Ice/Main/AppState.swift
@MainActor
final class AppState: ObservableObject {
    /// A Boolean value that indicates whether the active space is fullscreen.
    @Published private(set) var isActiveSpaceFullscreen = Bridging.isSpaceFullscreen(Bridging.activeSpaceID)

    /// Manager for the menu bar's appearance.
    private(set) lazy var appearanceManager = MenuBarAppearanceManager(appState: self)

    /// Manager for events received by the app.
    private(set) lazy var eventManager = EventManager(appState: self)

    /// Manager for menu bar items.
    private(set) lazy var itemManager = MenuBarItemManager(appState: self)

    /// Manager for the state of the menu bar.
    private(set) lazy var menuBarManager = MenuBarManager(appState: self)

    /// Manager for app permissions.
    private(set) lazy var permissionsManager = PermissionsManager(appState: self)

    /// Manager for the app's settings.
    private(set) lazy var settingsManager = SettingsManager(appState: self)

    /// Manager for app updates.
    private(set) lazy var updatesManager = UpdatesManager(appState: self)

    /// Global cache for menu bar item images.
    private(set) lazy var imageCache = MenuBarItemImageCache(appState: self)

    /// Manager for menu bar item spacing (stateless, no appState needed).
    let spacingManager = MenuBarItemSpacingManager()

    /// Model for app-wide navigation.
    let navigationState = AppNavigationState()

    /// The app's hotkey registry (nonisolated for thread safety).
    nonisolated let hotkeyRegistry = HotkeyRegistry()

    /// The app's delegate.
    private(set) weak var appDelegate: AppDelegate?

    /// The window that contains the settings interface.
    private(set) weak var settingsWindow: NSWindow?
}
```

**Key Pattern**: Each manager receives `appState` in init and stores it as `weak`:

```swift
// Ice/MenuBar/MenuBarManager.swift
@MainActor
final class MenuBarManager: ObservableObject {
    /// The shared app state.
    private weak var appState: AppState?

    /// Storage for internal observers.
    private var cancellables = Set<AnyCancellable>()

    init(appState: AppState) {
        self.appState = appState
        // ... initialization
    }
}
```

#### Ice's Permission Protocol Pattern

```swift
// Ice/Permissions/Permission.swift
@MainActor
class Permission: ObservableObject, Identifiable {
    /// A Boolean value that indicates whether the app has this permission.
    @Published private(set) var hasPermission = false

    /// The title of the permission.
    let title: String
    /// Descriptive details for the permission.
    let details: [String]
    /// A Boolean value that indicates if the app can work without this permission.
    let isRequired: Bool

    /// The URL of the settings pane to open.
    private let settingsURL: URL?
    /// The function that checks permissions.
    private let check: () -> Bool
    /// The function that requests permissions.
    private let request: () -> Void

    init(
        title: String,
        details: [String],
        isRequired: Bool,
        settingsURL: URL?,
        check: @escaping () -> Bool,
        request: @escaping () -> Void
    ) {
        self.title = title
        self.details = details
        self.isRequired = isRequired
        self.settingsURL = settingsURL
        self.check = check
        self.request = request
        self.hasPermission = check()
        configureCancellables()
    }

    private func configureCancellables() {
        // Timer-based polling for permission changes
        Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                self?.hasPermission = self?.check() ?? false
            }
            .store(in: &cancellables)
    }

    func performRequest() {
        request()
        if let settingsURL {
            NSWorkspace.shared.open(settingsURL)
        }
    }
}

// Concrete implementations
final class AccessibilityPermission: Permission {
    init() {
        super.init(
            title: "Accessibility",
            details: ["Get real-time information about the menu bar.", "Arrange menu bar items."],
            isRequired: true,
            settingsURL: nil,
            check: { checkIsProcessTrusted() },
            request: { checkIsProcessTrusted(prompt: true) }
        )
    }
}

final class ScreenRecordingPermission: Permission {
    init() {
        super.init(
            title: "Screen Recording",
            details: ["Edit the menu bar's appearance.", "Display images of individual menu bar items."],
            isRequired: false,
            settingsURL: URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"),
            check: { ScreenCapture.checkPermissions() },
            request: { ScreenCapture.requestPermissions() }
        )
    }
}
```

#### Ice's PermissionsManager

```swift
// Ice/Permissions/PermissionsManager.swift
@MainActor
final class PermissionsManager: ObservableObject {
    enum PermissionsState {
        case missingPermissions
        case hasAllPermissions
        case hasRequiredPermissions
    }

    @Published var permissionsState = PermissionsState.missingPermissions

    let accessibilityPermission: AccessibilityPermission
    let screenRecordingPermission: ScreenRecordingPermission
    let allPermissions: [Permission]

    private(set) weak var appState: AppState?

    var requiredPermissions: [Permission] {
        allPermissions.filter { $0.isRequired }
    }

    init(appState: AppState) {
        self.appState = appState
        self.accessibilityPermission = AccessibilityPermission()
        self.screenRecordingPermission = ScreenRecordingPermission()
        self.allPermissions = [accessibilityPermission, screenRecordingPermission]
        configureCancellables()
    }

    private func configureCancellables() {
        Publishers.Merge(
            accessibilityPermission.$hasPermission.mapToVoid(),
            screenRecordingPermission.$hasPermission.mapToVoid()
        )
        .sink { [weak self] in
            guard let self else { return }
            if allPermissions.allSatisfy({ $0.hasPermission }) {
                permissionsState = .hasAllPermissions
            } else if requiredPermissions.allSatisfy({ $0.hasPermission }) {
                permissionsState = .hasRequiredPermissions
            } else {
                permissionsState = .missingPermissions
            }
        }
        .store(in: &cancellables)
    }
}
```

#### OnlySwitch's SwitchProvider Protocol (Alternative Pattern)

```swift
// OnlySwitch/Modules/Sources/Switches/SwitchProvider.swift
public protocol SwitchProvider: AnyObject {
    var type: SwitchType { get }
    var delegate: SwitchDelegate? { get set }
    var hint: String? { get }
    func currentStatus() async -> Bool
    func currentInfo() async -> String
    func operateSwitch(isOn: Bool) async throws
    func isVisible() -> Bool
}

public protocol SwitchDelegate: AnyObject {
    func shouldRefreshIfNeed(aSwitch: SwitchProvider)
}
```

#### SwiftBar's Plugin Protocol (For Future Extensibility)

```swift
// SwiftBar/Plugin/Plugin.swift
protocol Plugin: AnyObject {
    var id: PluginID { get }
    var type: PluginType { get }
    var name: String { get }
    var enabled: Bool { get }
    var content: String? { get set }
    var lastState: PluginState { get set }
    
    func refresh(reason: PluginRefreshReason)
    func enable()
    func disable()
    func start()
    func terminate()
}
```

---

### A.4 Reference for REFACTOR-003: Smart Icon Detection

#### CRITICAL INSIGHT: Ice Does NOT Use Pixel Variance Analysis

Ice uses **window frame data from CGWindowList APIs** to get exact icon boundaries, not pixel analysis. This is far more accurate.

#### Ice's WindowInfo Struct

```swift
// Ice/Utilities/WindowInfo.swift
struct WindowInfo {
    let windowID: CGWindowID
    let frame: CGRect
    let title: String?
    let layer: Int
    let alpha: Double
    let ownerPID: pid_t
    let ownerName: String?
    let isOnScreen: Bool

    /// A Boolean value that indicates whether the window represents a menu bar item.
    var isMenuBarItem: Bool {
        layer == kCGStatusWindowLevel
    }

    /// Creates a window with the given dictionary from CGWindowListCopyWindowInfo.
    private init?(dictionary: CFDictionary) {
        guard
            let info = dictionary as? [CFString: CFTypeRef],
            let windowID = info[kCGWindowNumber] as? CGWindowID,
            let boundsDict = info[kCGWindowBounds] as? NSDictionary,
            let frame = CGRect(dictionaryRepresentation: boundsDict),
            let layer = info[kCGWindowLayer] as? Int,
            let alpha = info[kCGWindowAlpha] as? Double,
            let ownerPID = info[kCGWindowOwnerPID] as? pid_t
        else {
            return nil
        }
        self.windowID = windowID
        self.frame = frame
        self.title = info[kCGWindowName] as? String
        self.layer = layer
        self.alpha = alpha
        self.ownerPID = ownerPID
        self.ownerName = info[kCGWindowOwnerName] as? String
        self.isOnScreen = info[kCGWindowIsOnscreen] as? Bool ?? false
    }

    init?(windowID: CGWindowID) {
        var pointer = UnsafeRawPointer(bitPattern: Int(windowID))
        guard
            let array = CFArrayCreate(kCFAllocatorDefault, &pointer, 1, nil),
            let list = CGWindowListCreateDescriptionFromArray(array) as? [CFDictionary],
            let dictionary = list.first
        else {
            return nil
        }
        self.init(dictionary: dictionary)
    }
}
```

#### Ice's Bridging Layer for Private CGS APIs

```swift
// Ice/Bridging/Bridging.swift
enum Bridging {
    /// Returns the frame for the window with the specified identifier.
    static func getWindowFrame(for windowID: CGWindowID) -> CGRect? {
        var rect = CGRect.zero
        let result = CGSGetScreenRectForWindow(CGSMainConnectionID(), windowID, &rect)
        guard result == .success else {
            Logger.bridging.error("CGSGetScreenRectForWindow failed with error \(result.logString)")
            return nil
        }
        return rect
    }

    /// Options that determine the window identifiers to return in a window list.
    struct WindowListOption: OptionSet {
        let rawValue: Int
        static let onScreen = WindowListOption(rawValue: 1 << 0)
        static let menuBarItems = WindowListOption(rawValue: 1 << 1)
        static let activeSpace = WindowListOption(rawValue: 1 << 2)
    }

    /// Returns a list of window identifiers using the given options.
    static func getWindowList(option: WindowListOption = []) -> [CGWindowID] {
        let list = if option.contains(.menuBarItems) {
            if option.contains(.onScreen) {
                getOnScreenMenuBarWindowList()
            } else {
                getMenuBarWindowList()
            }
        } else if option.contains(.onScreen) {
            getOnScreenWindowList()
        } else {
            getWindowList()
        }
        return if option.contains(.activeSpace) {
            list.filter(isWindowOnActiveSpace)
        } else {
            list
        }
    }

    private static func getMenuBarWindowList() -> [CGWindowID] {
        let windowCount = getWindowCount()
        var list = [CGWindowID](repeating: 0, count: windowCount)
        var realCount: Int32 = 0
        let result = CGSGetProcessMenuBarWindowList(
            CGSMainConnectionID(),
            0,
            Int32(windowCount),
            &list,
            &realCount
        )
        guard result == .success else {
            Logger.bridging.error("CGSGetProcessMenuBarWindowList failed")
            return []
        }
        return [CGWindowID](list[..<Int(realCount)])
    }
}
```

**Note**: These CGS functions are private APIs. Ice includes C shims in `Ice/Bridging/Shims/` to declare them.

#### Ice's MenuBarItem with Exact Frame Data

```swift
// Ice/MenuBar/MenuBarItems/MenuBarItem.swift
struct MenuBarItem {
    let window: WindowInfo
    let info: MenuBarItemInfo

    var windowID: CGWindowID { window.windowID }
    var frame: CGRect { window.frame }
    var title: String? { window.title }
    var isOnScreen: Bool { window.isOnScreen }

    /// Returns menu bar items on the given display.
    static func getMenuBarItems(
        on display: CGDirectDisplayID? = nil,
        onScreenOnly: Bool,
        activeSpaceOnly: Bool
    ) -> [MenuBarItem] {
        var option: Bridging.WindowListOption = [.menuBarItems]
        if onScreenOnly { option.insert(.onScreen) }
        if activeSpaceOnly { option.insert(.activeSpace) }

        var boundsPredicate: (CGWindowID) -> Bool = { _ in true }
        if let display {
            let displayBounds = CGDisplayBounds(display)
            boundsPredicate = { windowID in
                guard let windowFrame = Bridging.getWindowFrame(for: windowID) else { return false }
                return displayBounds.intersects(windowFrame)
            }
        }

        return Bridging.getWindowList(option: option).lazy
            .filter(boundsPredicate)
            .compactMap { MenuBarItem(windowID: $0) }
    }
}
```

#### Ice's Image Cache with Frame-Based Cropping

```swift
// Ice/MenuBar/MenuBarItems/MenuBarItemImageCache.swift
func createImages(for section: MenuBarSection.Name, screen: NSScreen) async -> [MenuBarItemInfo: CGImage] {
    guard let appState else { return [:] }

    let items = await appState.itemManager.itemCache[section]
    var images = [MenuBarItemInfo: CGImage]()
    let backingScaleFactor = screen.backingScaleFactor
    let displayBounds = CGDisplayBounds(screen.displayID)

    var itemInfos = [CGWindowID: MenuBarItemInfo]()
    var itemFrames = [CGWindowID: CGRect]()
    var windowIDs = [CGWindowID]()
    var frame = CGRect.null

    // Collect window IDs and frames
    for item in items {
        let windowID = item.windowID
        guard
            let itemFrame = Bridging.getWindowFrame(for: windowID),
            itemFrame.minY == displayBounds.minY
        else { continue }
        itemInfos[windowID] = item.info
        itemFrames[windowID] = itemFrame
        windowIDs.append(windowID)
        frame = frame.union(itemFrame)
    }

    // Capture composite image of all windows
    if let compositeImage = ScreenCapture.captureWindows(windowIDs, option: [.boundsIgnoreFraming, .bestResolution]),
       CGFloat(compositeImage.width) == frame.width * backingScaleFactor {
        // Crop each item from composite using known frames
        for windowID in windowIDs {
            guard
                let itemInfo = itemInfos[windowID],
                let itemFrame = itemFrames[windowID]
            else { continue }

            let cropRect = CGRect(
                x: (itemFrame.origin.x - frame.origin.x) * backingScaleFactor,
                y: (itemFrame.origin.y - frame.origin.y) * backingScaleFactor,
                width: itemFrame.width * backingScaleFactor,
                height: itemFrame.height * backingScaleFactor
            )

            if let itemImage = compositeImage.cropping(to: cropRect) {
                images[itemInfo] = itemImage
            }
        }
    }

    return images
}
```

#### Ice's ScreenCapture Utility

```swift
// Ice/Utilities/ScreenCapture.swift
enum ScreenCapture {
    /// Checks screen capture permissions by testing if we can read window titles.
    static func checkPermissions() -> Bool {
        for item in MenuBarItem.getMenuBarItems(onScreenOnly: false, activeSpaceOnly: true) {
            if item.owningApplication == .current { continue }
            return item.title != nil  // Can read title = has permission
        }
        return CGPreflightScreenCaptureAccess()
    }

    /// Requests screen capture permissions.
    static func requestPermissions() {
        if #available(macOS 15.0, *) {
            // CGRequestScreenCaptureAccess() is broken on macOS 15
            SCShareableContent.getWithCompletionHandler { _, _ in }
        } else {
            CGRequestScreenCaptureAccess()
        }
    }

    /// Captures a composite image of an array of windows.
    static func captureWindows(
        _ windowIDs: [CGWindowID],
        screenBounds: CGRect? = nil,
        option: CGWindowImageOption = []
    ) -> CGImage? {
        let pointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: windowIDs.count)
        for (index, windowID) in windowIDs.enumerated() {
            pointer[index] = UnsafeRawPointer(bitPattern: UInt(windowID))
        }
        guard let windowArray = CFArrayCreate(kCFAllocatorDefault, pointer, windowIDs.count, nil) else {
            return nil
        }
        // Uses deprecated CGWindowListCreateImageFromArray but necessary for offscreen items
        return CGImage(
            windowListFromArrayScreenBounds: screenBounds ?? .null,
            windowArray: windowArray,
            imageOption: option
        )
    }
}
```

#### Recommended Implementation for Drawer

Replace the current pixel-based slicing with Ice's window-based approach:

1. **Create `WindowInfo.swift`** - Wrap `CGWindowListCopyWindowInfo` data
2. **Create `Bridging.swift`** - Private CGS API wrappers with C shims
3. **Update `IconCapturer.swift`**:
   - Get menu bar item windows via `Bridging.getWindowList(option: .menuBarItems)`
   - Get exact frames via `Bridging.getWindowFrame(for: windowID)`
   - Capture composite image via `ScreenCapture.captureWindows(windowIDs)`
   - Crop each icon using its known frame (no pixel analysis needed)

---

### A.5 Additional Patterns Worth Adopting

#### Ice's 10k Pixel Hack (Control Item)

```swift
// Ice/MenuBar/ControlItem/ControlItem.swift
enum Lengths {
    static let standard: CGFloat = NSStatusItem.variableLength
    static let expanded: CGFloat = 10_000  // Push items off screen
}

// Toggle visibility by changing length
if isVisible {
    statusItem.length = switch section.name {
    case .visible: Lengths.standard
    case .hidden, .alwaysHidden:
        switch state {
        case .hideItems: Lengths.expanded
        case .showItems: Lengths.standard
        }
    }
}
```

#### Ice's IceBar Panel (Drawer Equivalent)

```swift
// Ice/UI/IceBar/IceBar.swift
final class IceBarPanel: NSPanel {
    init(appState: AppState) {
        super.init(
            contentRect: .zero,
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        self.title = "Ice Bar"
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = true
        self.allowsToolTipsWhenApplicationIsInactive = true
        self.isFloatingPanel = true
        self.animationBehavior = .none
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .mainMenu + 1
        self.collectionBehavior = [.fullScreenAuxiliary, .ignoresCycle, .moveToActiveSpace]
    }

    func show(section: MenuBarSection.Name, on screen: NSScreen) async {
        appState?.navigationState.isIceBarPresented = true
        currentSection = section

        await appState?.itemManager.cacheItemsIfNeeded()

        if ScreenCapture.cachedCheckPermissions() {
            await appState?.imageCache.updateCache()
        }

        contentView = IceBarHostingView(appState: appState, section: section)
        updateOrigin(for: screen)
        orderFrontRegardless()
    }
}
```

#### OnlySwitch's macOS 26 Tahoe Compatibility

```swift
// OnlySwitch/StatusBar/StatusBarController.swift
// macOS 26 Tahoe: Button might not be immediately available
setupMainItemButtonWithRetry(image: currentMenubarIcon)

@objc private func togglePopover(sender: AnyObject?) {
    // Safety check: ensure we're on main thread
    guard Thread.isMainThread else {
        DispatchQueue.main.async { [weak self] in
            self?.togglePopover(sender: sender)
        }
        return
    }
    
    // macOS 26 Tahoe: Validate button still exists
    guard mainItem.button != nil else {
        print("⚠️ togglePopover called but status bar button is nil")
        return
    }
    // ... rest of implementation
}
```

---

### A.6 Files to Study in Ice Repository

For implementation reference, prioritize these files:

| Category | Files |
|----------|-------|
| **Architecture** | `Ice/Main/AppState.swift`, `Ice/Main/IceApp.swift` |
| **Menu Bar** | `Ice/MenuBar/MenuBarManager.swift`, `Ice/MenuBar/MenuBarSection.swift` |
| **Control Items** | `Ice/MenuBar/ControlItem/ControlItem.swift` |
| **Icon Capture** | `Ice/MenuBar/MenuBarItems/MenuBarItemImageCache.swift` |
| **Window APIs** | `Ice/Utilities/WindowInfo.swift`, `Ice/Bridging/Bridging.swift` |
| **Screen Capture** | `Ice/Utilities/ScreenCapture.swift` |
| **Permissions** | `Ice/Permissions/Permission.swift`, `Ice/Permissions/PermissionsManager.swift` |
| **Settings** | `Ice/Settings/SettingsWindow.swift`, `Ice/Settings/SettingsView.swift` |
| **Hotkeys** | `Ice/UI/HotkeyRecorder/HotkeyRecorder.swift`, `Ice/Hotkeys/Hotkey.swift` |
| **IceBar (Drawer)** | `Ice/UI/IceBar/IceBar.swift` |

---

### A.7 Updated Priority Recommendation

Based on the investigation, the recommended execution order changes:

| Order | Refactor | Reason |
|-------|----------|--------|
| 1 | **REFACTOR-003** (Icon Detection) | Biggest functional improvement - Ice's window-based approach is dramatically more accurate than pixel variance |
| 2 | **REFACTOR-001** (Remove Storyboards) | Enables clean architecture, Ice provides clear template |
| 3 | **REFACTOR-002** (Dependency Injection) | Ice's lazy manager pattern is proven and testable |
| 4 | **REFACTOR-004** (Remove Legacy) | Cleanup after other refactors complete |

**Rationale**: REFACTOR-003 should be prioritized because Ice's window-based approach completely eliminates the need for pixel variance analysis, making the implementation simpler and more reliable.
