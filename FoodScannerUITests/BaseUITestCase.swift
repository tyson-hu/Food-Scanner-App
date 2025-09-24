import XCTest

/// Shared base for all UI tests. Handles system alerts & common launch flags.
class BaseUITestCase: XCTestCase {
    /// The app under test. Lazy so it's initialized before first use in setUp.
    private(set) lazy var app = XCUIApplication()

    /// Override to disable automatic app launch in setUp (used by LaunchTests).
    /// Default is `true` so most tests auto-launch.
    var autoLaunch: Bool { true }

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false

        // Touch `app` to ensure it's initialized, then configure it.
        _ = app
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
            if alert.buttons["Don’t Allow"].exists { alert.buttons["Don’t Allow"].tap(); return true }
            if alert.buttons["Allow"].exists { alert.buttons["Allow"].tap(); return true }

            return false
        }

        if autoLaunch {
            app.launch()
            // Important: interact once so interruption monitor can fire.
            app.tap()
        }
    }

    override func tearDownWithError() throws {
        // Optional: keep sims clean
        if app.state == .runningForeground || app.state == .runningBackground {
            app.terminate()
        }
        try super.tearDownWithError()
    }

    /// Call this after an action that *should* trigger a system alert.
    func acknowledgeSystemAlertsIfNeeded() {
        app.tap()
    }
}
