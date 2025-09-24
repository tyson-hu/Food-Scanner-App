//
//  AddFlowUITests.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//

import XCTest

@MainActor
final class AddFlowUITests: BaseUITestCase {
    func test_AddFood_search_detail_log_updates_today() {
        // Go to Add tab
        let addTab = app.tabBars.buttons["Add"]
        XCTAssertTrue(addTab.waitForExistence(timeout: 3), "Add tab not found")
        addTab.tap()

        // Focus search and type a query
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field not found")
        searchField.tap()
        searchField.typeText("yogurt")

        // Tap the expected result
        let resultCell = app.staticTexts["Greek Yogurt, Plain"]
        XCTAssertTrue(resultCell.waitForExistence(timeout: 5), "Result row not found")
        resultCell.tap()

        // Tap "Log to Today"
        let logButton = app.buttons["Log Food"]
        XCTAssertTrue(logButton.waitForExistence(timeout: 3), "Log button not found")
        logButton.tap()

        // Should bounce to Today and show the logged item
        let todayTab = app.tabBars.buttons["Today"]
        XCTAssertTrue(todayTab.waitForExistence(timeout: 5), "Today tab button not found")
        if !todayTab.isSelected { todayTab.tap() }
        XCTAssertTrue(todayTab.isSelected, "Did not return to Today tab")

        let loggedRow = app.staticTexts["Greek Yogurt, Plain"]
        XCTAssertTrue(loggedRow.waitForExistence(timeout: 5), "Logged entry not visible in Today list")
    }
}
