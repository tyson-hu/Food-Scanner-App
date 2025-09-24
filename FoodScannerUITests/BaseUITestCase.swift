//
//  BaseUITestCase.swift
//  BaseUITestCase
//
//  Created by Tyson Hu on 9/19/25.
//

import XCTest

/// Shared base for all UI tests. Main-actor isolated to satisfy Swift 6 concurrency.
@MainActor
class BaseUITestCase: XCTestCase {
    // Backing storage; initialized in setUpWithError() on the main actor.
    private var _app: XCUIApplication?

    /// Non-optional accessor for tests. If setup didn't run, fail loudly.
    var app: XCUIApplication {
        if let app = _app { return app }
        XCTFail("XCUIApplication not initialized. Did setUpWithError() run?")
        // Return a fresh instance to avoid crashing; test will already be marked failed.
        return XCUIApplication()
    }

    /// Override in subclasses to prevent auto-launch (used by LaunchTests).
    var autoLaunch: Bool { true }

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false

        // Create and configure on the main actor.
        let app = XCUIApplication()
        app.launchArguments += ["-ui-tests", "1"]
        app.launchEnvironment["UITESTS"] = "1"
        _app = app

        // One interruption monitor that handles common iOS 17/18 prompts.
        addUIInterruptionMonitor(withDescription: "System Alerts") { alert in
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

            // Notifications variants
            if alert.buttons["Don’t Allow"].exists { alert.buttons["Don’t Allow"].tap(); return true }
            if alert.buttons["Allow"].exists { alert.buttons["Allow"].tap(); return true }

            return false
        }

        if autoLaunch {
            app.launch()
            // Important: a tap gives the interruption monitor a chance to fire.
            app.tap()
        }
    }

    override func tearDownWithError() throws {
        if let app = _app,
           app.state == .runningForeground || app.state == .runningBackground {
            app.terminate()
        }
        _app = nil
        try super.tearDownWithError()
    }

    /// Call after an action that *should* trigger a system alert.
    func acknowledgeSystemAlertsIfNeeded() {
        app.tap()
    }
}
