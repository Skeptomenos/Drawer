# Spec: Phase 2C - Unit Tests for Menu Bar Architecture

**Phase:** 2C
**Priority:** Medium (P2)
**Estimated Time:** 25-30 minutes
**Dependencies:** Phase 2B (Section Architecture)
**Parent Doc:** `docs/IMPLEMENTATION_PLAN_ARCHITECTURE_IMPROVEMENTS.md`

---

## Objective

Create a comprehensive unit test suite for the new menu bar architecture components:
- `ControlItemState`
- `ControlItemImage`
- `ControlItem`
- `MenuBarSection`
- `MenuBarManager`

---

## Background

The AGENTS.md file specifies that unit tests are required for all Managers/Engines. The new Section-based architecture needs test coverage to:
- Prevent regression of the initial state bug (Phase 0)
- Verify reactive state bindings work correctly
- Ensure RTL layout support functions properly
- Document expected behavior for future maintainers

---

## Test Target Setup

### Create Test Target (if not exists)

1. In Xcode: File → New → Target → Unit Testing Bundle
2. Name: `DrawerTests`
3. Target to Test: `Drawer`

### Test Files to Create

```
DrawerTests/
├── Models/
│   ├── ControlItemStateTests.swift
│   ├── ControlItemImageTests.swift
│   ├── ControlItemTests.swift
│   └── MenuBarSectionTests.swift
└── Managers/
    └── MenuBarManagerTests.swift
```

---

## Implementation

### File 1: `DrawerTests/Models/ControlItemStateTests.swift`

```swift
//
//  ControlItemStateTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest
@testable import Drawer

final class ControlItemStateTests: XCTestCase {
    
    func testAllCasesExist() {
        let allCases = ControlItemState.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.expanded))
        XCTAssertTrue(allCases.contains(.collapsed))
        XCTAssertTrue(allCases.contains(.hidden))
    }
    
    func testRawValues() {
        XCTAssertEqual(ControlItemState.expanded.rawValue, "expanded")
        XCTAssertEqual(ControlItemState.collapsed.rawValue, "collapsed")
        XCTAssertEqual(ControlItemState.hidden.rawValue, "hidden")
    }
}
```

### File 2: `DrawerTests/Models/ControlItemImageTests.swift`

```swift
//
//  ControlItemImageTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest
import AppKit
@testable import Drawer

final class ControlItemImageTests: XCTestCase {
    
    func testSFSymbolRenders() {
        let image = ControlItemImage.sfSymbol("chevron.left")
        let rendered = image.render()
        
        XCTAssertNotNil(rendered, "SF Symbol should render")
        XCTAssertTrue(rendered!.isTemplate, "SF Symbol should be template image")
    }
    
    func testSFSymbolWithWeightRenders() {
        let image = ControlItemImage.sfSymbol("chevron.left", weight: .bold)
        let rendered = image.render()
        
        XCTAssertNotNil(rendered)
    }
    
    func testBezierPathRenders() {
        let image = ControlItemImage.bezierPath {
            let path = NSBezierPath()
            path.move(to: NSPoint(x: 0, y: 0))
            path.line(to: NSPoint(x: 10, y: 10))
            path.line(to: NSPoint(x: 0, y: 10))
            path.close()
            return path
        }
        let rendered = image.render(size: NSSize(width: 20, height: 20))
        
        XCTAssertNotNil(rendered)
        XCTAssertTrue(rendered!.isTemplate)
        XCTAssertEqual(rendered!.size.width, 20)
        XCTAssertEqual(rendered!.size.height, 20)
    }
    
    func testNoneReturnsNil() {
        let image = ControlItemImage.none
        let rendered = image.render()
        
        XCTAssertNil(rendered)
    }
    
    func testAssetWithInvalidNameReturnsNil() {
        let image = ControlItemImage.asset("nonexistent_asset_12345")
        let rendered = image.render()
        
        XCTAssertNil(rendered)
    }
    
    func testStaticChevronImages() {
        XCTAssertNotNil(ControlItemImage.chevronLeft.render())
        XCTAssertNotNil(ControlItemImage.chevronRight.render())
        XCTAssertNotNil(ControlItemImage.separatorDot.render())
    }
}
```

### File 3: `DrawerTests/Models/ControlItemTests.swift`

```swift
//
//  ControlItemTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest
import AppKit
@testable import Drawer

@MainActor
final class ControlItemTests: XCTestCase {
    
    var controlItem: ControlItem!
    
    override func setUp() async throws {
        controlItem = ControlItem(
            expandedLength: 20,
            collapsedLength: 10000,
            initialState: .collapsed
        )
    }
    
    override func tearDown() async throws {
        controlItem = nil
    }
    
    // MARK: - Initial State Tests
    
    func testInitialStateIsCollapsed() {
        XCTAssertEqual(controlItem.state, .collapsed)
    }
    
    func testInitialLengthMatchesCollapsedState() {
        XCTAssertEqual(controlItem.length, 10000)
    }
    
    func testInitWithExpandedState() {
        let item = ControlItem(initialState: .expanded)
        XCTAssertEqual(item.state, .expanded)
        XCTAssertEqual(item.length, 20)
    }
    
    // MARK: - State Change Tests
    
    func testStateChangeToExpandedUpdatesLength() {
        controlItem.state = .expanded
        
        XCTAssertEqual(controlItem.length, 20)
    }
    
    func testStateChangeToCollapsedUpdatesLength() {
        controlItem.state = .expanded
        controlItem.state = .collapsed
        
        XCTAssertEqual(controlItem.length, 10000)
    }
    
    func testStateChangeToHiddenUpdatesVisibility() {
        controlItem.state = .hidden
        
        XCTAssertFalse(controlItem.statusItem.isVisible)
    }
    
    func testDuplicateStateChangeDoesNothing() {
        controlItem.state = .collapsed
        let initialLength = controlItem.length
        
        controlItem.state = .collapsed // Same state
        
        XCTAssertEqual(controlItem.length, initialLength)
    }
    
    // MARK: - Custom Length Tests
    
    func testCustomLengths() {
        let item = ControlItem(
            expandedLength: 50,
            collapsedLength: 5000,
            initialState: .collapsed
        )
        
        XCTAssertEqual(item.length, 5000)
        
        item.state = .expanded
        XCTAssertEqual(item.length, 50)
    }
    
    // MARK: - Image Tests
    
    func testSettingImageUpdatesButton() {
        controlItem.image = .sfSymbol("chevron.left")
        
        XCTAssertNotNil(controlItem.button?.image)
    }
    
    func testSettingNilImageClearsButton() {
        controlItem.image = .sfSymbol("chevron.left")
        controlItem.image = nil
        
        XCTAssertNil(controlItem.button?.image)
    }
    
    // MARK: - Autosave Name Tests
    
    func testAutosaveNameCanBeSet() {
        controlItem.autosaveName = "test_autosave_name"
        
        XCTAssertEqual(controlItem.autosaveName, "test_autosave_name")
    }
}
```

### File 4: `DrawerTests/Models/MenuBarSectionTests.swift`

```swift
//
//  MenuBarSectionTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest
@testable import Drawer

@MainActor
final class MenuBarSectionTests: XCTestCase {
    
    var controlItem: ControlItem!
    var section: MenuBarSection!
    
    override func setUp() async throws {
        controlItem = ControlItem(initialState: .collapsed)
        section = MenuBarSection(
            type: .hidden,
            controlItem: controlItem,
            isExpanded: false
        )
    }
    
    override func tearDown() async throws {
        section = nil
        controlItem = nil
    }
    
    // MARK: - Initialization Tests
    
    func testInitWithCorrectType() {
        XCTAssertEqual(section.type, .hidden)
    }
    
    func testInitWithCorrectExpandedState() {
        XCTAssertFalse(section.isExpanded)
    }
    
    func testInitWithExpandedTrue() {
        let expandedSection = MenuBarSection(
            type: .visible,
            controlItem: ControlItem(initialState: .expanded),
            isExpanded: true
        )
        
        XCTAssertTrue(expandedSection.isExpanded)
    }
    
    // MARK: - State Synchronization Tests
    
    func testIsExpandedSyncsWithControlItem() {
        section.isExpanded = true
        
        XCTAssertEqual(controlItem.state, .expanded)
    }
    
    func testCollapsingUpdateControlItem() {
        section.isExpanded = true
        section.isExpanded = false
        
        XCTAssertEqual(controlItem.state, .collapsed)
    }
    
    // MARK: - IsEnabled Tests
    
    func testDisablingHidesControlItem() {
        section.isEnabled = false
        
        XCTAssertEqual(controlItem.state, .hidden)
    }
    
    func testReEnablingRestoresState() {
        section.isExpanded = true
        section.isEnabled = false
        section.isEnabled = true
        
        XCTAssertEqual(controlItem.state, .expanded)
    }
    
    // MARK: - Action Tests
    
    func testToggle() {
        XCTAssertFalse(section.isExpanded)
        
        section.toggle()
        XCTAssertTrue(section.isExpanded)
        
        section.toggle()
        XCTAssertFalse(section.isExpanded)
    }
    
    func testExpand() {
        section.expand()
        
        XCTAssertTrue(section.isExpanded)
    }
    
    func testExpandWhenAlreadyExpanded() {
        section.isExpanded = true
        section.expand()
        
        XCTAssertTrue(section.isExpanded)
    }
    
    func testCollapse() {
        section.isExpanded = true
        section.collapse()
        
        XCTAssertFalse(section.isExpanded)
    }
    
    // MARK: - Section Type Tests
    
    func testAllSectionTypes() {
        XCTAssertEqual(MenuBarSectionType.allCases.count, 3)
        
        for type in MenuBarSectionType.allCases {
            let testSection = MenuBarSection(
                type: type,
                controlItem: ControlItem()
            )
            XCTAssertEqual(testSection.type, type)
        }
    }
    
    func testSectionTypeDisplayNames() {
        XCTAssertEqual(MenuBarSectionType.visible.displayName, "Visible")
        XCTAssertEqual(MenuBarSectionType.hidden.displayName, "Hidden")
        XCTAssertEqual(MenuBarSectionType.alwaysHidden.displayName, "Always Hidden")
    }
}
```

### File 5: `DrawerTests/Managers/MenuBarManagerTests.swift`

```swift
//
//  MenuBarManagerTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest
import Combine
@testable import Drawer

@MainActor
final class MenuBarManagerTests: XCTestCase {
    
    var manager: MenuBarManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        manager = MenuBarManager()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() async throws {
        cancellables = nil
        manager = nil
    }
    
    // MARK: - Initial State Tests (Regression for Phase 0 Bug)
    
    func testInitialStateIsCollapsed() {
        XCTAssertTrue(manager.isCollapsed, "Manager should start collapsed")
    }
    
    func testInitialSeparatorLengthMatchesCollapsedState() {
        // This is the critical test for the Phase 0 bug fix
        XCTAssertEqual(
            manager.currentSeparatorLength, 
            10000, 
            "Separator must be 10000 when isCollapsed=true (Phase 0 bug regression)"
        )
    }
    
    func testHiddenSectionMatchesCollapsedState() {
        XCTAssertFalse(manager.hiddenSection.isExpanded)
    }
    
    // MARK: - Toggle Tests
    
    func testToggleFromCollapsedToExpanded() {
        manager.toggle()
        
        XCTAssertFalse(manager.isCollapsed)
        XCTAssertEqual(manager.currentSeparatorLength, 20)
    }
    
    func testToggleFromExpandedToCollapsed() async {
        manager.toggle() // Expand
        
        // Wait for debounce
        try? await Task.sleep(nanoseconds: 400_000_000)
        
        manager.toggle() // Collapse
        
        XCTAssertTrue(manager.isCollapsed)
        XCTAssertEqual(manager.currentSeparatorLength, 10000)
    }
    
    func testToggleIsDebounced() {
        manager.toggle()
        manager.toggle() // Should be ignored (debounce)
        
        // Should still be expanded (second toggle ignored)
        XCTAssertFalse(manager.isCollapsed)
    }
    
    // MARK: - Expand/Collapse Direct Tests
    
    func testExpandWhenCollapsed() {
        manager.expand()
        
        XCTAssertFalse(manager.isCollapsed)
        XCTAssertTrue(manager.hiddenSection.isExpanded)
    }
    
    func testExpandWhenAlreadyExpanded() {
        manager.expand()
        manager.expand() // Should be no-op
        
        XCTAssertFalse(manager.isCollapsed)
    }
    
    func testCollapseWhenExpanded() async {
        manager.expand()
        
        // Wait for position to stabilize
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        manager.collapse()
        
        XCTAssertTrue(manager.isCollapsed)
        XCTAssertFalse(manager.hiddenSection.isExpanded)
    }
    
    func testCollapseWhenAlreadyCollapsed() {
        manager.collapse() // Should be no-op
        
        XCTAssertTrue(manager.isCollapsed)
    }
    
    // MARK: - Reactive Binding Tests
    
    func testIsCollapsedPublishesChanges() {
        var receivedValues: [Bool] = []
        
        manager.$isCollapsed
            .dropFirst() // Skip initial
            .sink { receivedValues.append($0) }
            .store(in: &cancellables)
        
        manager.toggle()
        
        XCTAssertEqual(receivedValues, [false])
    }
    
    // MARK: - RTL Support Tests
    
    func testExpandImageSymbolNameForLTR() {
        // Assuming test runs in LTR environment
        if manager.isLeftToRight {
            XCTAssertEqual(manager.expandImageSymbolName, "chevron.left")
            XCTAssertEqual(manager.collapseImageSymbolName, "chevron.right")
        }
    }
    
    // MARK: - Section Access Tests
    
    func testHiddenSectionExists() {
        XCTAssertNotNil(manager.hiddenSection)
        XCTAssertEqual(manager.hiddenSection.type, .hidden)
    }
    
    func testVisibleSectionExists() {
        XCTAssertNotNil(manager.visibleSection)
        XCTAssertEqual(manager.visibleSection.type, .visible)
    }
    
    func testSeparatorControlItemAccessor() {
        XCTAssertNotNil(manager.separatorControlItem)
        XCTAssertEqual(manager.separatorControlItem.length, manager.currentSeparatorLength)
    }
}
```

---

## Acceptance Criteria

- [ ] Test target `DrawerTests` exists in Xcode project
- [ ] All test files created in proper directory structure
- [ ] All tests pass (`xcodebuild test -scheme Drawer`)
- [ ] `testInitialSeparatorLengthMatchesCollapsedState` catches Phase 0 regression
- [ ] No flaky tests (run multiple times to verify)
- [ ] Test coverage for all public methods on tested classes

---

## Running Tests

```bash
# Run all tests
xcodebuild test -scheme Drawer -destination 'platform=macOS'

# Run specific test class
xcodebuild test -scheme Drawer -destination 'platform=macOS' \
  -only-testing:DrawerTests/MenuBarManagerTests

# Run single test method
xcodebuild test -scheme Drawer -destination 'platform=macOS' \
  -only-testing:DrawerTests/MenuBarManagerTests/testInitialSeparatorLengthMatchesCollapsedState
```

---

## Notes

- Tests use `@MainActor` because the classes under test require main thread
- `async` test methods are used for tests that need delays
- Combine-based tests use `cancellables` to manage subscriptions
- The Phase 0 regression test is the most critical - it must never fail

---

## Files Created

| File | Purpose |
|------|---------|
| `DrawerTests/Models/ControlItemStateTests.swift` | State enum tests |
| `DrawerTests/Models/ControlItemImageTests.swift` | Image rendering tests |
| `DrawerTests/Models/ControlItemTests.swift` | ControlItem behavior tests |
| `DrawerTests/Models/MenuBarSectionTests.swift` | Section behavior tests |
| `DrawerTests/Managers/MenuBarManagerTests.swift` | Manager integration tests |
