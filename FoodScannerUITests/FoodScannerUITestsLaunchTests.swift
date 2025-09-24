//
//  FoodScannerUITestsLaunchTests.swift
//  FoodScannerUITests
//
//  Created by Tyson Hu on 9/19/25.
//

@preconcurrency import XCTest

/// Measures a clean cold start without auto-launch from BaseUITestCase.
final class FoodScannerUITestsLaunchTests: BaseUITestCase {
    override var autoLaunch: Bool { false }

    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            MainActor.assumeIsolated {
                app.launch()
                app.tap() // trigger the interruption monitor once
            }
        }
    }
}
