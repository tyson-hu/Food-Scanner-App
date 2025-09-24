//
//  FoodScannerUITestsLaunchTests.swift
//  FoodScannerUITests
//
//  Created by Tyson Hu on 9/19/25.
//

import XCTest

/// Keeps the standard launch performance test, measuring a clean cold start.
final class FoodScannerUITestsLaunchTests: BaseUITestCase {
    override var autoLaunch: Bool { false }

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        // `app` is configured by Base; we intentionally haven't launched yet.
    }

    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
            app.tap() // trigger interruption handler once after launch
        }
    }
}
