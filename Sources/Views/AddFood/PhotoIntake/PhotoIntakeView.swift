//
//  PhotoIntakeView.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import SwiftUI

struct PhotoIntakeView: View {
    var onRecognize: (String) -> Void = { _ in }

    var body: some View {
        ContentUnavailableView(
            "Photo recognition coming soon",
            systemImage: "camera.macro",
            description: Text("Stub for M1. We'll add Vision/CoreML later.")
        )
        .safeAreaInset(edge: .bottom) {
            Button("Simulate Match (fdcId 67890)") { onRecognize("fdc:67890") }
                .buttonStyle(.borderedProminent)
                .padding()
        }
    }
}
