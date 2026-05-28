//
//  CalryUITestsLaunchTests.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

@preconcurrency import XCTest

/// Measures a clean cold start without auto-launch from BaseUITestCase.
final class CalryUITestsLaunchTests: BaseUITestCase {
    override var autoLaunch: Bool { false }

    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            MainActor.assumeIsolated {
                let app = XCUIApplication()
                app.launchArguments += ["-ui-tests", "1"]
                app.launchEnvironment["UITESTS"] = "1"
                app.launch()
                app.tap() // trigger the interruption monitor once
            }
        }
    }
}
