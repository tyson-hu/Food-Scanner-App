//
//  CalorieRingView.swift
//  Calry
//
//  Created by Tyson Hu on 10/13/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import SwiftUI

struct CalorieRingView: View {
    let current: Double
    let target: Double
    let lineWidth: CGFloat

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(AppTheme.Colors.tertiary, lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AppTheme.Colors.calories,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(AppTheme.Animation.default, value: progress)

            // Center text
            VStack(spacing: 4) {
                Text("\(Int(current.rounded()))")
                    .font(AppTheme.Typography.largeTitle)
                    .fontWeight(.bold)

                Text("of \(Int(target)) cal")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CalorieRingView(current: 1_200, target: 2_000, lineWidth: 20)
        CalorieRingView(current: 2_000, target: 2_000, lineWidth: 15)
        CalorieRingView(current: 500, target: 2_000, lineWidth: 25)
    }
    .padding()
}
