//
//  BarcodeScannerView.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//

import SwiftUI

struct BarcodeScannerView: View {
    var onDetect: (Int) -> Void = { _ in } // later: hand back real fdcId
    
    var body: some View {
        ContentUnavailableView(
            "Scanner coming soon",
            systemImage: "barcode.viewfinder",
            description: Text("This is a stub for M1. We'll wire VisionKit in M2.")
        )
        .safeAreaInset(edge: .bottom) {
            Button("Simulate Scan (fdcId 12345)") { onDetect(12345) }
                .buttonStyle(.borderedProminent)
                .padding()
        }
    }
}
