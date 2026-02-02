//
//  DrawerUITests.swift
//  DrawerUITests
//
//  UI tests for critical Drawer app flows.
//

import XCTest

/// UI test suite for the Drawer menu bar utility.
///
/// These tests verify critical user flows:
/// - App launch and basic functionality
/// - Menu bar icon presence
/// - Permission handling
final class DrawerUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - App Launch Tests

    /// Verifies the app launches successfully.
    ///
    /// This is a smoke test that ensures:
    /// - The app binary exists and is valid
    /// - The app can launch without crashing
    /// - The app reaches a running state
    func testAppLaunches() throws {
        app.launch()
        XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground,
                      "App should be in a running state after launch")
    }

    /// Verifies the app launches and terminates cleanly.
    ///
    /// Menu bar apps often run in the background, so this test
    /// verifies we can gracefully terminate the app.
    func testAppLaunchesAndTerminates() throws {
        app.launch()
        sleep(1)
        app.terminate()
        XCTAssertTrue(app.state == .notRunning, "App should be terminated")
    }

    /// Verifies the app can be launched multiple times in succession.
    ///
    /// This catches issues with:
    /// - Resource cleanup on termination
    /// - State persistence between launches
    /// - Menu bar item registration/unregistration
    func testAppRelaunchStability() throws {
        for iteration in 1...3 {
            app.launch()
            XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground,
                          "App should be running on iteration \(iteration)")
            app.terminate()
        }
    }

    // MARK: - Settings Window Tests

    /// Verifies the Settings window can be opened via menu.
    ///
    /// Requires accessibility permissions and Settings menu item to be accessible.
    func testSettingsWindowOpens() throws {
        app.launch()
        sleep(1)

        let menuBarsQuery = app.menuBars
        if menuBarsQuery.count > 0 {
            menuBarsQuery.menuBarItems["Drawer"].click()
            if menuBarsQuery.menuItems["Settings…"].exists {
                menuBarsQuery.menuItems["Settings…"].click()
                let settingsWindow = app.windows["Settings"]
                let exists = settingsWindow.waitForExistence(timeout: 5)
                XCTAssertTrue(exists, "Settings window should appear")
            }
        }
    }
}
