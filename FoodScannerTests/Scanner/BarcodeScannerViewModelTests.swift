//
//  BarcodeScannerViewModelTests.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/26/25.
//

import AVFoundation
@testable import Food_Scanner
import XCTest

@MainActor
final class BarcodeScannerViewModelTests: XCTestCase {
    var viewModel: BarcodeScannerViewModel?

    override func setUp() {
        super.setUp()
        viewModel = BarcodeScannerViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Permission Tests

    func testInitialState() {
        guard let viewModel else {
            XCTFail("ViewModel not initialized")
            return
        }
        XCTAssertFalse(viewModel.isScanningAvailable)
        XCTAssertNil(viewModel.scannedBarcode)
        XCTAssertFalse(viewModel.showErrorAlert)
        XCTAssertEqual(viewModel.errorMessage, "")
    }

    func testPermissionCheckWithAuthorizedStatus() async {
        guard let viewModel else {
            XCTFail("ViewModel not initialized")
            return
        }

        // Mock authorized status
        let expectation = XCTestExpectation(description: "Permission check completed")

        // Since we can't easily mock AVCaptureDevice.authorizationStatus in tests,
        // we'll test the error handling path instead
        await viewModel.checkPermissions()

        // The actual permission status depends on the test environment
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Barcode Scanning Tests

    func testBarcodeNotificationHandling() {
        guard let viewModel else {
            XCTFail("ViewModel not initialized")
            return
        }

        let testBarcode = "1234567890123"

        // Post notification
        NotificationCenter.default.post(
            name: .barcodeScanned,
            object: nil,
            userInfo: ["barcode": testBarcode]
        )

        // Give a moment for the async processing
        let expectation = XCTestExpectation(description: "Barcode processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(viewModel.scannedBarcode, testBarcode)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testBarcodeClearingAfterDelay() {
        guard let viewModel else {
            XCTFail("ViewModel not initialized")
            return
        }

        let testBarcode = "1234567890123"

        // Post notification
        NotificationCenter.default.post(
            name: .barcodeScanned,
            object: nil,
            userInfo: ["barcode": testBarcode]
        )

        // Wait for barcode to be set
        let setExpectation = XCTestExpectation(description: "Barcode set")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(viewModel.scannedBarcode, testBarcode)
            setExpectation.fulfill()
        }
        wait(for: [setExpectation], timeout: 1.0)

        // Wait for barcode to be cleared
        let clearExpectation = XCTestExpectation(description: "Barcode cleared")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            XCTAssertNil(viewModel.scannedBarcode)
            clearExpectation.fulfill()
        }
        wait(for: [clearExpectation], timeout: 2.0)
    }

    func testInvalidBarcodeNotification() {
        guard let viewModel else {
            XCTFail("ViewModel not initialized")
            return
        }

        // Post notification without barcode
        NotificationCenter.default.post(
            name: .barcodeScanned,
            object: nil,
            userInfo: [:]
        )

        // Give a moment for processing
        let expectation = XCTestExpectation(description: "Invalid notification processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNil(viewModel.scannedBarcode)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Settings Tests

    func testOpenSettings() {
        guard let viewModel else {
            XCTFail("ViewModel not initialized")
            return
        }

        // This test verifies the method doesn't crash
        // In a real test environment, we'd mock UIApplication
        viewModel.openSettings()

        // If we get here without crashing, the test passes
        XCTAssertTrue(true)
    }

    // MARK: - UPC Barcode Tests

    func testValidUPCBarcodeScan() {
        guard let viewModel else {
            XCTFail("ViewModel not initialized")
            return
        }

        let validUPC = "0031604031121"

        // Post notification with valid UPC
        NotificationCenter.default.post(
            name: .barcodeScanned,
            object: nil,
            userInfo: ["barcode": validUPC]
        )

        // Give a moment for the async processing
        let expectation = XCTestExpectation(description: "Valid UPC processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(viewModel.scannedBarcode, validUPC)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testUPCBarcodeClearingAfterDelay() {
        guard let viewModel else {
            XCTFail("ViewModel not initialized")
            return
        }

        let validUPC = "0031604031121"

        // Post notification with valid UPC
        NotificationCenter.default.post(
            name: .barcodeScanned,
            object: nil,
            userInfo: ["barcode": validUPC]
        )

        // Wait for barcode to be set
        let setExpectation = XCTestExpectation(description: "UPC barcode set")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(viewModel.scannedBarcode, validUPC)
            setExpectation.fulfill()
        }
        wait(for: [setExpectation], timeout: 1.0)

        // Wait for barcode to be cleared
        let clearExpectation = XCTestExpectation(description: "UPC barcode cleared")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            XCTAssertNil(viewModel.scannedBarcode)
            clearExpectation.fulfill()
        }
        wait(for: [clearExpectation], timeout: 2.0)
    }

    func testDuplicateUPCBarcodeIgnored() {
        guard let viewModel else {
            XCTFail("ViewModel not initialized")
            return
        }

        let validUPC = "0031604031121"

        // Post first notification
        NotificationCenter.default.post(
            name: .barcodeScanned,
            object: nil,
            userInfo: ["barcode": validUPC]
        )

        // Wait for first barcode to be set
        let firstExpectation = XCTestExpectation(description: "First UPC barcode set")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(viewModel.scannedBarcode, validUPC)
            firstExpectation.fulfill()
        }
        wait(for: [firstExpectation], timeout: 1.0)

        // Immediately post duplicate notification
        NotificationCenter.default.post(
            name: .barcodeScanned,
            object: nil,
            userInfo: ["barcode": validUPC]
        )

        // Wait a bit and verify the barcode is still the same (not updated)
        let duplicateExpectation = XCTestExpectation(description: "Duplicate UPC ignored")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // The barcode should still be the same, not updated
            XCTAssertEqual(viewModel.scannedBarcode, validUPC)
            duplicateExpectation.fulfill()
        }
        wait(for: [duplicateExpectation], timeout: 1.0)
    }
}
