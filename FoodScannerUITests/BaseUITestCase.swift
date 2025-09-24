//
//  BaseUITestCase.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/24/25.
//

import XCTest

/// Shared base for all UI tests. Handles system alerts & common launch flags.
class BaseUITestCase: XCTestCase {
    /// The app under test.
    var app: XCUIApplication?

    /// Override to disable automatic app launch in setUp (used by LaunchTests).
    /// Default is `true` so most tests auto-launch.
    var autoLaunch: Bool { true }

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false

        app = XCUIApplication()
        // Flags/environment your app can look for to tweak behavior in UI tests.
        app?.launchArguments += ["-ui-tests", "1"]
        app?.launchEnvironment["UITESTS"] = "1"

        // Set up comprehensive UI interruption monitors
        setupUIInterruptionMonitors()

        if autoLaunch {
            app?.launch()
            // Important: interact once so interruption monitor can fire.
            app?.tap()
        }
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    /// Set up all UI interruption monitors for comprehensive alert handling
    private func setupUIInterruptionMonitors() {
        // Monitor 1: System Alerts (permissions, notifications, etc.)
        addUIInterruptionMonitor(withDescription: "System Alerts") { alert in
            // Try common buttons first.
            let buttons = [
                "Allow", "OK",
                "While Using the App", "Allow While Using App", "Allow Once",
                "Keep Only While Using",
                "Allow All Photos", "Allow Access to All Photos",
                "Allow Paste", "Connect", "Join", "Continue",
            ]
            for title in buttons where alert.buttons[title].exists {
                alert.buttons[title].tap()
                return true
            }
            // Photos permission sometimes shows as a collection view in iOS 18.
            let allPhotos = alert.collectionViews.buttons["Allow Access to All Photos"]
            if allPhotos.exists { allPhotos.tap(); return true }

            // Notifications "Don't Allow"/"Allow" sheet variants
            if alert.buttons["Don't Allow"].exists { alert.buttons["Don't Allow"].tap(); return true }
            if alert.buttons["Allow"].exists { alert.buttons["Allow"].tap(); return true }

            return false
        }

        // Monitor 2: Camera and Photo Library Permissions
        addUIInterruptionMonitor(withDescription: "Camera/Photo Permissions") { alert in
            let cameraButtons = ["Allow", "OK", "While Using the App", "Allow While Using App"]
            for button in cameraButtons where alert.buttons[button].exists {
                alert.buttons[button].tap()
                return true
            }
            return false
        }

        // Monitor 3: Location Services
        addUIInterruptionMonitor(withDescription: "Location Services") { alert in
            let locationButtons = ["Allow", "Allow While Using App", "Allow Once", "Don't Allow"]
            for button in locationButtons where alert.buttons[button].exists {
                alert.buttons[button].tap()
                return true
            }
            return false
        }

        // Monitor 4: Network and Connectivity
        addUIInterruptionMonitor(withDescription: "Network Alerts") { alert in
            let networkButtons = ["OK", "Continue", "Retry", "Cancel", "Settings"]
            for button in networkButtons where alert.buttons[button].exists {
                alert.buttons[button].tap()
                return true
            }
            return false
        }

        // Monitor 5: Generic System Dialogs
        addUIInterruptionMonitor(withDescription: "Generic System Dialogs") { alert in
            // Handle any remaining system dialogs
            let genericButtons = ["OK", "Cancel", "Done", "Close", "Dismiss"]
            for button in genericButtons where alert.buttons[button].exists {
                alert.buttons[button].tap()
                return true
            }
            return false
        }
    }

    /// Call this after an action that *should* trigger a system alert.
    func acknowledgeSystemAlertsIfNeeded() {
        // A lightweight poke that gives the monitor a chance to run.
        app?.tap()
    }

    /// Wait for and handle any system alerts that might appear
    func handleSystemAlerts(timeout: TimeInterval = 5.0) {
        guard let app else { return }

        let startTime = Date()
        while Date().timeIntervalSince(startTime) < timeout {
            if !app.alerts.isEmpty {
                acknowledgeSystemAlertsIfNeeded()
                // Small delay to allow interruption monitors to process
                Thread.sleep(forTimeInterval: 0.5)
            } else {
                break
            }
        }
    }

    /// Tap an element and handle any resulting system alerts
    func tapAndHandleAlerts(_ element: XCUIElement, timeout: TimeInterval = 5.0) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element not found: \(element)")
        element.tap()
        handleSystemAlerts()
    }

    /// Type text and handle any resulting system alerts
    func typeTextAndHandleAlerts(_ text: String, in element: XCUIElement, timeout: TimeInterval = 5.0) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Element not found: \(element)")
        element.tap()
        element.typeText(text)
        handleSystemAlerts()
    }
}
