//
//  MockMenuBarManagerTests.swift
//  DrawerTests
//
//  Copyright © 2026 Drawer. MIT License.
//

import XCTest

@testable import Drawer

@MainActor
final class MockMenuBarManagerTests: XCTestCase {
    
    func testSETUP006_MockMenuBarManagerCanBeInstantiated() {
        let mock = MockMenuBarManager()
        
        XCTAssertNotNil(mock)
        XCTAssertTrue(mock.isCollapsed)
        XCTAssertFalse(mock.isToggling)
    }
    
    func testMockMenuBarManagerToggleFromCollapsed() {
        let mock = MockMenuBarManager()
        XCTAssertTrue(mock.isCollapsed)
        
        mock.toggle()
        
        XCTAssertFalse(mock.isCollapsed)
        XCTAssertTrue(mock.toggleCalled)
        XCTAssertEqual(mock.toggleCallCount, 1)
        XCTAssertTrue(mock.expandCalled)
    }
    
    func testMockMenuBarManagerToggleFromExpanded() {
        let mock = MockMenuBarManager()
        mock.setCollapsed(false)
        XCTAssertFalse(mock.isCollapsed)
        
        mock.toggle()
        
        XCTAssertTrue(mock.isCollapsed)
        XCTAssertTrue(mock.collapseCalled)
    }
    
    func testMockMenuBarManagerExpandWhenAlreadyExpanded() {
        let mock = MockMenuBarManager()
        mock.setCollapsed(false)
        
        mock.expand()
        
        XCTAssertFalse(mock.isCollapsed)
        XCTAssertTrue(mock.expandCalled)
        XCTAssertEqual(mock.expandCallCount, 1)
    }
    
    func testMockMenuBarManagerCollapseWhenAlreadyCollapsed() {
        let mock = MockMenuBarManager()
        XCTAssertTrue(mock.isCollapsed)
        
        mock.collapse()
        
        XCTAssertTrue(mock.isCollapsed)
        XCTAssertTrue(mock.collapseCalled)
        XCTAssertEqual(mock.collapseCallCount, 1)
    }
    
    func testMockMenuBarManagerResetTracking() {
        let mock = MockMenuBarManager()
        mock.toggle()
        mock.expand()
        mock.collapse()
        
        XCTAssertTrue(mock.toggleCalled)
        XCTAssertTrue(mock.expandCalled)
        XCTAssertTrue(mock.collapseCalled)
        
        mock.resetTracking()
        
        XCTAssertFalse(mock.toggleCalled)
        XCTAssertFalse(mock.expandCalled)
        XCTAssertFalse(mock.collapseCalled)
        XCTAssertEqual(mock.toggleCallCount, 0)
        XCTAssertEqual(mock.expandCallCount, 0)
        XCTAssertEqual(mock.collapseCallCount, 0)
    }
    
    func testMockMenuBarManagerReset() {
        let mock = MockMenuBarManager()
        mock.toggle()
        mock.setToggling(true)
        
        mock.reset()
        
        XCTAssertTrue(mock.isCollapsed)
        XCTAssertFalse(mock.isToggling)
        XCTAssertFalse(mock.toggleCalled)
    }
    
    func testMockMenuBarManagerDebounceBlocking() {
        let mock = MockMenuBarManager()
        mock.simulateDebounce = true
        mock.setToggling(true)
        
        mock.toggle()
        
        XCTAssertTrue(mock.toggleCalled)
        XCTAssertTrue(mock.isCollapsed)
    }
}
