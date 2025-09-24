//
//  FoodScannerUITestsLaunchTests.swift
//  FoodScannerUITests
//
//  Created by Tyson Hu on 9/19/25.
//

import XCTest

final class FoodScannerUITestsLaunchTests: BaseUITestCase {
    override static var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override var autoLaunch: Bool { false }

    @MainActor
    func testLaunch() throws {
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
