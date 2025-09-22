//
//  PhotoIntakeView.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//

import SwiftUI

struct PhotoIntakeView: View {
    var onRecognize: (Int) -> Void = { _ in }

    var body: some View {
        ContentUnavailableView(
            "Photo recognition coming soon",
            systemImage: "camera.macro",
            description: Text("Stub for M1. We'll add Vision/CoreML later.")
        )
        .safeAreaInset(edge: .bottom) {
            Button("Simulate Match (fdcId 67890)") { onRecognize(67890) }
                .buttonStyle(.borderedProminent)
                .padding()
        }
    }
}
