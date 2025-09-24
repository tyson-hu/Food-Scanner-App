//
//  FoodScannerUITests.swift
//  FoodScannerUITests
//
//  Created by Tyson Hu on 9/19/25.
//

import XCTest

final class FoodScannerUITests: BaseUITestCase {
    @MainActor
    func testExample() throws {
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // The app is already launched by BaseUITestCase
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
