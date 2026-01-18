//
//  SettingsMenuBarLayoutViewTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest
@testable import Drawer

// MARK: - SettingsMenuBarLayoutViewTests

/// Tests for SettingsMenuBarLayoutView reconciliation and icon matching logic.
///
/// These tests verify two critical behaviors:
/// - Spec 5.6: Ordering uses captured X-position as source of truth (not saved layout order)
/// - Spec 5.7: Icon matching uses windowID cache with multi-tier fallback
///
/// The tests focus on the `LayoutReconciler` which encapsulates the core reconciliation
/// algorithm used by the Menu Bar Layout feature.
final class SettingsMenuBarLayoutViewTests: XCTestCase {

    // MARK: - Properties

    /// Factory for creating test CapturedIcon instances
    private var iconFactory: MockCapturedIconFactory!

    /// The reconciler under test
    private var reconciler: LayoutReconciler!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        iconFactory = MockCapturedIconFactory()
        reconciler = LayoutReconciler()
    }

    override func tearDown() {
        iconFactory = nil
        reconciler = nil
        super.tearDown()
    }

    // MARK: - Spec 5.6: Ordering Tests

    /// Verifies that reconcile() uses captured X-position order as source of truth.
    ///
    /// Scenario:
    /// - Saved layout has icons in order: [A, B, C] with order values 0, 1, 2
    /// - Captured icons have X-positions: [B=100, C=200, A=300]
    ///
    /// Expected: Result should use captured order [B, C, A], not saved order [A, B, C]
    ///
    /// This is the core fix for Spec 5.6: When the user Command+Drags icons in the
    /// actual menu bar, clicking refresh should show them in the new order, not
    /// the previously saved order.
    func testReconcileLayout_UsesCapturedOrder() throws {
        // Arrange: Create captured icons with specific X-positions
        // The order in the array doesn't matter - reconciler should sort by X-position
        let iconB = iconFactory.createIcon(bundleId: "com.test.B", xPosition: 100, section: .hidden)
        let iconC = iconFactory.createIcon(bundleId: "com.test.C", xPosition: 200, section: .hidden)
        let iconA = iconFactory.createIcon(bundleId: "com.test.A", xPosition: 300, section: .hidden)

        // Captured icons in random order (simulating how capture might return them)
        let capturedIcons = [iconA, iconB, iconC]

        // Saved layout with different order (A=0, B=1, C=2)
        // This represents a previously saved state that differs from current menu bar
        let savedLayout = [
            iconFactory.createLayoutItem(from: iconA, orderOverride: 0)!,
            iconFactory.createLayoutItem(from: iconB, orderOverride: 1)!,
            iconFactory.createLayoutItem(from: iconC, orderOverride: 2)!
        ]

        // Act: Reconcile
        let result = reconciler.reconcile(
            capturedIcons: capturedIcons,
            savedLayout: savedLayout
        )

        // Assert: Result should be ordered by X-position [B, C, A]
        let bundleIds = result.items
            .filter { !$0.isSpacer }
            .sorted { $0.order < $1.order }
            .compactMap { $0.bundleIdentifier }

        XCTAssertEqual(bundleIds.count, 3, "Should have 3 items")
        XCTAssertEqual(bundleIds[0], "com.test.B", "First item should be B (x=100)")
        XCTAssertEqual(bundleIds[1], "com.test.C", "Second item should be C (x=200)")
        XCTAssertEqual(bundleIds[2], "com.test.A", "Third item should be A (x=300)")
    }

    /// Verifies that user section overrides are preserved during reconciliation.
    ///
    /// Scenario:
    /// - Captured icon A is in .hidden section (based on separator position)
    /// - Saved layout has A in .alwaysHidden section (user intentionally moved it)
    ///
    /// Expected: Result should have A in .alwaysHidden (respecting user override)
    ///
    /// Section overrides represent explicit user actions - dragging an icon to a
    /// different section in Settings. These must be preserved even when the menu
    /// bar's physical layout changes.
    func testReconcileLayout_RespectsSectionOverrides() throws {
        // Arrange: Create captured icon in .hidden section
        let capturedIcon = iconFactory.createIcon(
            bundleId: "com.test.app",
            xPosition: 100,
            section: .hidden  // Captured in hidden section
        )

        // Saved layout has the same icon in .alwaysHidden (user override)
        let savedItem = iconFactory.createLayoutItem(
            from: capturedIcon,
            sectionOverride: .alwaysHidden,  // User moved to alwaysHidden
            orderOverride: 0
        )!

        // Act: Reconcile
        let result = reconciler.reconcile(
            capturedIcons: [capturedIcon],
            savedLayout: [savedItem]
        )

        // Assert: Result should respect the user's section override
        XCTAssertEqual(result.items.count, 1, "Should have 1 item")
        XCTAssertEqual(result.items[0].section, .alwaysHidden, "Should preserve user's section override to .alwaysHidden")
        XCTAssertEqual(result.matchedCount, 1, "Should count as matched (has override)")
    }

    /// Verifies that new icons not in saved layout are placed in correct captured position.
    ///
    /// Scenario:
    /// - Saved layout has [A, B]
    /// - Captured icons are [A, C, B] (C is new, positioned between A and B)
    ///
    /// Expected: C should appear between A and B in result (not appended at end)
    ///
    /// This tests that new apps launching with menu bar icons appear in their
    /// correct position, not just appended to the end of the list.
    func testReconcileLayout_NewIconsUseCapturedPosition() throws {
        // Arrange: Create captured icons with C positioned between A and B
        let iconA = iconFactory.createIcon(bundleId: "com.test.A", xPosition: 100, section: .hidden)
        let iconC = iconFactory.createIcon(bundleId: "com.test.C", xPosition: 200, section: .hidden)  // New icon
        let iconB = iconFactory.createIcon(bundleId: "com.test.B", xPosition: 300, section: .hidden)

        let capturedIcons = [iconA, iconC, iconB]

        // Saved layout only has A and B (C is new)
        let savedLayout = [
            iconFactory.createLayoutItem(from: iconA, orderOverride: 0)!,
            iconFactory.createLayoutItem(from: iconB, orderOverride: 1)!
        ]

        // Act: Reconcile
        let result = reconciler.reconcile(
            capturedIcons: capturedIcons,
            savedLayout: savedLayout
        )

        // Assert: C should be in the middle, not at the end
        let bundleIds = result.items
            .filter { !$0.isSpacer }
            .sorted { $0.order < $1.order }
            .compactMap { $0.bundleIdentifier }

        XCTAssertEqual(bundleIds.count, 3, "Should have 3 items")
        XCTAssertEqual(bundleIds[0], "com.test.A", "First should be A (x=100)")
        XCTAssertEqual(bundleIds[1], "com.test.C", "Second should be C (x=200) - the new icon")
        XCTAssertEqual(bundleIds[2], "com.test.B", "Third should be B (x=300)")
        XCTAssertEqual(result.newCount, 3, "All items should be counted as new (using captured position)")
    }

    /// Verifies that spacers from saved layout are preserved.
    ///
    /// Spacers are user-created elements that don't exist in the actual menu bar.
    /// They must be preserved from the saved layout.
    func testReconcileLayout_PreservesSpacers() throws {
        // Arrange: Create a captured icon
        let capturedIcon = iconFactory.createIcon(
            bundleId: "com.test.app",
            xPosition: 100,
            section: .hidden
        )

        // Saved layout includes a spacer
        let savedLayout = [
            iconFactory.createLayoutItem(from: capturedIcon, orderOverride: 0)!,
            SettingsLayoutItem.spacer(section: .hidden, order: 1)
        ]

        // Act: Reconcile
        let result = reconciler.reconcile(
            capturedIcons: [capturedIcon],
            savedLayout: savedLayout
        )

        // Assert: Spacer should be preserved
        let spacers = result.items.filter { $0.isSpacer }
        XCTAssertEqual(spacers.count, 1, "Should preserve 1 spacer")
        XCTAssertEqual(spacers[0].section, .hidden, "Spacer should keep its section")
    }

    /// Verifies that windowID cache is populated during reconciliation.
    ///
    /// The windowID cache (Spec 5.7) maps layout item UUIDs to window IDs,
    /// enabling fast and reliable icon lookup for repositioning operations.
    func testReconcileLayout_PopulatesWindowIDCache() throws {
        // Arrange: Create captured icons with known window IDs
        let windowID: CGWindowID = 12345
        let capturedIcon = iconFactory.createIcon(
            bundleId: "com.test.app",
            xPosition: 100,
            section: .hidden,
            windowID: windowID
        )

        // Act: Reconcile
        let result = reconciler.reconcile(
            capturedIcons: [capturedIcon],
            savedLayout: []
        )

        // Assert: windowIDCache should contain the mapping
        XCTAssertEqual(result.items.count, 1, "Should have 1 item")
        let itemId = result.items[0].id
        XCTAssertEqual(result.windowIDCache[itemId], windowID, "windowIDCache should map item ID to window ID")
    }

    /// Verifies that icons without section overrides use their captured section.
    ///
    /// When a saved item exists but in the same section as captured, this is
    /// NOT an override - the item should still use the captured section.
    func testReconcileLayout_NoOverrideWhenSectionsMatch() throws {
        // Arrange: Create captured icon in .hidden section
        let capturedIcon = iconFactory.createIcon(
            bundleId: "com.test.app",
            xPosition: 100,
            section: .hidden
        )

        // Saved layout has the same icon in .hidden (same section - no override)
        let savedItem = iconFactory.createLayoutItem(
            from: capturedIcon,
            sectionOverride: .hidden,  // Same as captured
            orderOverride: 5  // Different order, but order should be ignored
        )!

        // Act: Reconcile
        let result = reconciler.reconcile(
            capturedIcons: [capturedIcon],
            savedLayout: [savedItem]
        )

        // Assert: Should use captured section (no override detected)
        XCTAssertEqual(result.items.count, 1, "Should have 1 item")
        XCTAssertEqual(result.items[0].section, .hidden, "Should use captured section")
        XCTAssertEqual(result.matchedCount, 0, "Should NOT count as matched override")
        XCTAssertEqual(result.newCount, 1, "Should count as new (using captured position)")
    }

    /// Verifies that order values are normalized within each section.
    ///
    /// Order values should be sequential (0, 1, 2, ...) within each section,
    /// regardless of the source order values.
    func testReconcileLayout_NormalizesOrdersWithinSection() throws {
        // Arrange: Create multiple icons in the same section
        let iconA = iconFactory.createIcon(bundleId: "com.test.A", xPosition: 100, section: .hidden)
        let iconB = iconFactory.createIcon(bundleId: "com.test.B", xPosition: 200, section: .hidden)
        let iconC = iconFactory.createIcon(bundleId: "com.test.C", xPosition: 300, section: .hidden)

        // Act: Reconcile
        let result = reconciler.reconcile(
            capturedIcons: [iconC, iconA, iconB],  // Random order in array
            savedLayout: []
        )

        // Assert: Orders should be sequential 0, 1, 2 based on X-position
        let hiddenItems = result.items
            .filter { $0.section == .hidden && !$0.isSpacer }
            .sorted { $0.order < $1.order }

        XCTAssertEqual(hiddenItems.count, 3)
        XCTAssertEqual(hiddenItems[0].order, 0)
        XCTAssertEqual(hiddenItems[0].bundleIdentifier, "com.test.A")
        XCTAssertEqual(hiddenItems[1].order, 1)
        XCTAssertEqual(hiddenItems[1].bundleIdentifier, "com.test.B")
        XCTAssertEqual(hiddenItems[2].order, 2)
        XCTAssertEqual(hiddenItems[2].bundleIdentifier, "com.test.C")
    }

    // MARK: - Spec 5.7: Icon Matching Tests

    /// Verifies that findIconItem() uses windowID cache as fast path.
    ///
    /// Scenario:
    /// - windowIDCache contains mapping: layoutItem.id -> windowID
    /// - IconItem exists with that windowID
    ///
    /// Expected: findIconItem() returns the IconItem via windowID lookup (fast path)
    func testFindIconItem_UsesWindowIDCache() throws {
        // TODO: Task 4 - Implement this test
        // This test will fail until Task 15 implementation
        throw XCTSkip("Test implementation pending Task 4")
    }

    /// Verifies fallback to bundle ID matching when windowID cache misses.
    ///
    /// Scenario:
    /// - windowIDCache is empty or stale
    /// - IconItem exists with matching bundle ID
    ///
    /// Expected: findIconItem() falls back to bundle ID matching
    func testFindIconItem_FallsBackToBundleID() throws {
        // TODO: Task 4 - Implement this test
        throw XCTSkip("Test implementation pending Task 4")
    }

    /// Verifies that findIconItem() returns nil for spacer items.
    ///
    /// Spacers don't have corresponding IconItems in the menu bar.
    func testFindIconItem_ReturnsNilForSpacers() throws {
        // TODO: Task 4 - Implement this test
        throw XCTSkip("Test implementation pending Task 4")
    }

    /// Verifies multi-tier fallback when title doesn't match.
    ///
    /// Scenario:
    /// - Saved layout has bundleID="com.app.test", title="Old Title"
    /// - Current IconItem has bundleID="com.app.test", title="New Title"
    ///
    /// Expected: findIconItem() matches via bundle ID ignoring title
    func testFindIconItem_MatchesByBundleIDIgnoringDynamicTitle() throws {
        // TODO: Task 4 - Implement this test
        throw XCTSkip("Test implementation pending Task 4")
    }

    /// Verifies owner name fallback for apps without bundle ID.
    ///
    /// Scenario:
    /// - Saved layout has bundleID from ownerName (not a real bundle ID)
    /// - Current IconItem has matching ownerName
    ///
    /// Expected: findIconItem() matches via owner name fallback
    func testFindIconItem_FallsBackToOwnerName() throws {
        // TODO: Task 4 - Implement this test
        throw XCTSkip("Test implementation pending Task 4")
    }
}
