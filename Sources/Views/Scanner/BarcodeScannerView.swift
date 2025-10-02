//
//  BarcodeScannerView.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import AVFoundation
import SwiftUI
import Vision
import VisionKit

struct BarcodeScannerView: View {
    @State private var viewModel = BarcodeScannerViewModel()
    @State private var isInitialized = false
    var onDetect: (String) -> Void = { _ in }

    var body: some View {
        Group {
            if !isInitialized {
                // Show loading state while checking permissions
                LoadingView()
            } else if viewModel.isScanningAvailable {
                ScannerView(viewModel: viewModel, onDetect: onDetect)
            } else {
                PermissionView(viewModel: viewModel)
            }
        }
        .onAppear {
            Task { @MainActor in
                // Small delay to ensure smooth transition and prevent flash
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                await viewModel.checkPermissions()
                isInitialized = true
            }
        }
    }
}

private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Initializing Scanner...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

private struct ScannerView: View {
    var viewModel: BarcodeScannerViewModel
    var onDetect: (String) -> Void
    @State private var isScannerReady = false

    var body: some View {
        ZStack {
            // Camera view
            DataScannerViewControllerRepresentable(
                recognizedDataTypes: [
                    .barcode(symbologies: [.upce, .code128, .code39, .ean13, .ean8, .pdf417, .qr, .aztec])
                ],
                recognizesMultipleItems: false,
                isHighFrameRateTrackingEnabled: true,
                isPinchToZoomEnabled: true,
                isGuidanceEnabled: true,
                isHighlightingEnabled: true,
                isScannerReady: $isScannerReady
            )
            .ignoresSafeArea()

            // Overlay UI
            VStack {
                Spacer()

                // Instructions
                Text("Point your camera at a barcode")
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.black.opacity(0.7))
                    .cornerRadius(8)
                    .padding(.bottom, 20)
            }
        }
        .onChange(of: viewModel.scannedBarcode) { _, barcode in
            if let barcode {
                handleBarcodeScan(barcode)
            }
        }
        .alert("Scan Error", isPresented: Binding(
            get: { viewModel.showErrorAlert },
            set: { viewModel.showErrorAlert = $0 }
        )) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .onAppear {
            // Mark scanner as ready when view appears
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                isScannerReady = true
            }
        }
        .onDisappear {
            // Mark scanner as not ready when view disappears
            isScannerReady = false
        }
    }

    private func handleBarcodeScan(_ barcode: String) {
        print("🎯 BarcodeScannerView: Handling barcode scan: \(barcode)")

        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        // Pass the barcode/UPC directly to the search functionality
        // The search will look for foods with this UPC in the FDC database
        print("🔍 BarcodeScannerView: Searching for UPC: \(barcode)")
        onDetect(barcode)
    }
}

private struct PermissionView: View {
    var viewModel: BarcodeScannerViewModel

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 50, weight: .light))
                .foregroundColor(.secondary)

            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text("To scan barcodes, please allow camera access in Settings.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("Open Settings") {
                viewModel.openSettings()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - DataScannerViewController Representable

private struct DataScannerViewControllerRepresentable: UIViewControllerRepresentable {
    let recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType>
    let recognizesMultipleItems: Bool
    let isHighFrameRateTrackingEnabled: Bool
    let isPinchToZoomEnabled: Bool
    let isGuidanceEnabled: Bool
    let isHighlightingEnabled: Bool
    @Binding var isScannerReady: Bool

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: recognizedDataTypes,
            qualityLevel: .balanced,
            recognizesMultipleItems: recognizesMultipleItems,
            isHighFrameRateTrackingEnabled: isHighFrameRateTrackingEnabled,
            isPinchToZoomEnabled: isPinchToZoomEnabled,
            isGuidanceEnabled: isGuidanceEnabled,
            isHighlightingEnabled: isHighlightingEnabled
        )

        scanner.delegate = context.coordinator
        context.coordinator.scanner = scanner
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // Start or stop scanning based on ready state
        if isScannerReady {
            // Use a small delay to ensure the scanner is fully ready
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                context.coordinator.startScanning()
            }
        } else {
            context.coordinator.stopScanning()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        weak var scanner: DataScannerViewController?

        override init() {
            super.init()
        }

        func startScanning() {
            guard let scanner else {
                print("❌ BarcodeScanner: Scanner not available")
                return
            }

            // Check if already scanning
            guard !scanner.isScanning else {
                print("ℹ️ BarcodeScanner: Already scanning")
                return
            }

            do {
                try scanner.startScanning()
                print("✅ BarcodeScanner: Started scanning successfully")
            } catch {
                print("❌ BarcodeScanner: Failed to start scanning: \(error)")
                print("❌ BarcodeScanner: Error details: \(error.localizedDescription)")
            }
        }

        func stopScanning() {
            guard let scanner else { return }
            scanner.stopScanning()
            print("⏹️ BarcodeScanner: Stopped scanning")
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            // Handle tap on recognized item if needed
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            print("🔍 BarcodeScanner: didAdd called with \(addedItems.count) items")
            // Handle newly recognized items
            for item in addedItems {
                if case let .barcode(barcode) = item {
                    let barcodeValue = barcode.payloadStringValue ?? ""
                    print("📱 BarcodeScanner: Detected barcode - \(barcodeValue)")

                    // Post notification with scanned barcode
                    NotificationCenter.default.post(
                        name: .barcodeScanned,
                        object: nil,
                        userInfo: ["barcode": barcodeValue]
                    )
                }
            }
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didRemove removedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            // Handle removed items if needed
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didUpdate updatedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            // Handle updated items if needed
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let barcodeScanned = Notification.Name("barcodeScanned")
}
