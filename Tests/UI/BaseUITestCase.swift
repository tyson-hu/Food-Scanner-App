//
//  BaseUITestCase.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

@preconcurrency import XCTest

/// Shared base for all UI tests.
/// - No @MainActor on the class or overrides (so we match XCTestCase signatures).
/// - Use MainActor.assumeIsolated { } at the call sites that touch XCUI APIs.
class BaseUITestCase: XCTestCase {
    // Backing store; only mutate/read inside MainActor.assumeIsolated blocks.
    @MainActor private static var _sharedApp: XCUIApplication?

    /// Non-optional accessor. Lazily creates/configures the app the first time.
    var app: XCUIApplication {
        BaseUITestCase.getApp()
    }

    private static func getApp() -> XCUIApplication {
        MainActor.assumeIsolated {
            if let existingApp = _sharedApp { return existingApp }
            let appInstance = XCUIApplication()
            appInstance.launchArguments += ["-ui-tests", "1"]
            appInstance.launchEnvironment["UITESTS"] = "1"
            _sharedApp = appInstance
            return appInstance
        }
    }

    /// Override in subclasses to prevent auto-launch (used by LaunchTests).
    var autoLaunch: Bool { true }

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false

        // Handle common system alerts (camera/photos/mic/notifications/paste).
        addUIInterruptionMonitor(withDescription: "System Alerts") { alert in
            MainActor.assumeIsolated {
                let buttons = [
                    "Allow", "OK",
                    "While Using the App", "Allow While Using App", "Allow Once",
                    "Keep Only While Using",
                    "Allow All Photos", "Allow Access to All Photos",
                    "Allow Paste", "Connect", "Join", "Continue"
                ]
                for title in buttons where alert.buttons[title].exists {
                    alert.buttons[title].tap()
                    return true
                }
                // Photos sheet variant (collection view) on newer iOS
                let allPhotos = alert.collectionViews.buttons["Allow Access to All Photos"]
                if allPhotos.exists { allPhotos.tap(); return true }

                // Notifications variants
                if alert.buttons["Don’t Allow"].exists { alert.buttons["Don’t Allow"].tap(); return true }
                if alert.buttons["Allow"].exists { alert.buttons["Allow"].tap(); return true }

                return false
            }
        }

        if autoLaunch {
            MainActor.assumeIsolated {
                let app = BaseUITestCase.getApp()
                app.launch()
                // Poke once so the interruption monitor can fire.
                app.tap()
            }
        }
    }

    override func tearDownWithError() throws {
        MainActor.assumeIsolated {
            if let appInstance = BaseUITestCase._sharedApp,
               appInstance.state == .runningForeground || appInstance.state == .runningBackground {
                appInstance.terminate()
            }
            BaseUITestCase._sharedApp = nil
        }
        try super.tearDownWithError()
    }

    /// Call this after an action that *should* trigger a system alert.
    func acknowledgeSystemAlertsIfNeeded() {
        MainActor.assumeIsolated { BaseUITestCase.getApp().tap() }
    }
}
