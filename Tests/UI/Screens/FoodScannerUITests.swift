//
//  FoodScannerUITests.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

@preconcurrency import XCTest

final class FoodScannerUITests: BaseUITestCase {
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
