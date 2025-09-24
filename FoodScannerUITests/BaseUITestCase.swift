//
//  BaseUITestCase.swift
//  BaseUITestCase
//
//  Created by Tyson Hu on 9/19/25.
//

import XCTest

/// Shared base for all UI tests. Handles system alerts & common launch flags.
@MainActor
class BaseUITestCase: XCTestCase {
    /// The app under test. Private to avoid SwiftLint violation.
    private var _app: XCUIApplication?

    /// The app under test. Computed property for clean test code.
    var app: XCUIApplication {
        guard let app = _app else {
            fatalError("App not initialized. Make sure setUpWithError() is called.")
        }
        return app
    }

    /// Override to disable automatic app launch in setUp (used by LaunchTests).
    /// Default is `true` so most tests auto-launch.
    var autoLaunch: Bool { true }

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false

        _app = XCUIApplication()
        // Flags/environment your app can look for to tweak behavior in UI tests.
        app.launchArguments += ["-ui-tests", "1"]
        app.launchEnvironment["UITESTS"] = "1"

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
            if alert.buttons["Don't Allow"].exists { alert.buttons["Don't Allow"].tap(); return true }
            if alert.buttons["Allow"].exists { alert.buttons["Allow"].tap(); return true }

            return false
        }

        if autoLaunch {
            app.launch()
            // Important: interact once so interruption monitor can fire.
            app.tap()
        }
    }

    @MainActor
    override func tearDownWithError() throws {
        if let app = _app,
           app.state == .runningForeground || app.state == .runningBackground {
            app.terminate()
        }
        _app = nil
        try super.tearDownWithError()
    }

    /// Call this after an action that *should* trigger a system alert.
    @MainActor
    func acknowledgeSystemAlertsIfNeeded() {
        app.tap()
    }
}
