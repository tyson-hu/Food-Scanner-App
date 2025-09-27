//
//  BarcodeScannerViewModel.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//

import AVFoundation
import Foundation
import Observation
import UIKit

// Suppress nonisolated(unsafe) warnings for properties that need to be accessed from Sendable closures
// These properties are safe to access from multiple threads in this specific use case

@MainActor
@Observable
final class BarcodeScannerViewModel {
    // MARK: - Published Properties

    var isScanningAvailable: Bool = false
    var scannedBarcode: String?
    var showErrorAlert: Bool = false
    var errorMessage: String = ""

    // MARK: - Private Properties

    // These properties are not part of the observable state and need to be accessed from Sendable closures
    @ObservationIgnored private var notificationObserver: NSObjectProtocol?
    @ObservationIgnored private nonisolated(unsafe) var lastScannedBarcode: String?
    @ObservationIgnored private nonisolated(unsafe) var lastScanTime: Date?

    // MARK: - Initialization

    init() {
        setupNotificationObserver()
    }

    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Public Methods

    func checkPermissions() {
        Task {
            await checkCameraPermission()
        }
    }

    func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    // MARK: - Private Methods

    private func checkCameraPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        print("📷 BarcodeScannerViewModel: Camera permission status: \(status.rawValue)")

        switch status {
        case .authorized:
            print("✅ BarcodeScannerViewModel: Camera access authorized")
            isScanningAvailable = true
        case .notDetermined:
            print("❓ BarcodeScannerViewModel: Camera permission not determined, requesting access")
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            print("📷 BarcodeScannerViewModel: Camera access granted: \(granted)")
            isScanningAvailable = granted
        case .denied, .restricted:
            print("❌ BarcodeScannerViewModel: Camera access denied or restricted")
            isScanningAvailable = false
            showErrorAlert = true
            errorMessage = "Camera access is required to scan barcodes. Please enable camera access in Settings."
        @unknown default:
            print("⚠️ BarcodeScannerViewModel: Unknown camera permission status")
            isScanningAvailable = false
        }
    }

    private func setupNotificationObserver() {
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .barcodeScanned,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            print("🔔 BarcodeScannerViewModel: Received barcode notification")
            guard let self,
                  let userInfo = notification.userInfo,
                  let barcode = userInfo["barcode"] as? String else {
                print("❌ BarcodeScannerViewModel: Invalid notification data")
                return
            }

            print("📱 BarcodeScannerViewModel: Processing barcode: \(barcode)")

            // Debounce: Only process if it's a different barcode or enough time has passed
            let now = Date()
            let timeSinceLastScan = lastScanTime?.timeIntervalSince(now) ?? 0

            if barcode != lastScannedBarcode || abs(timeSinceLastScan) > 2.0 {
                lastScannedBarcode = barcode
                lastScanTime = now

                Task { @MainActor in
                    self.scannedBarcode = barcode

                    // Clear the barcode after a short delay to allow for re-scanning
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    self.scannedBarcode = nil
                }
            } else {
                print("🚫 BarcodeScannerViewModel: Ignoring duplicate barcode scan")
            }
        }
    }
}
