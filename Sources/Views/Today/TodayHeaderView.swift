//
//  TodayHeaderView.swift
//  Calry
//
//  Created by Tyson Hu on 10/13/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import SwiftUI

struct TodayHeaderView: View {
    @Binding var currentDate: Date

    var body: some View {
        HStack {
            Button(
                action: {
                    if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) {
                        currentDate = newDate
                    }
                },
                label: {
                    Image(systemName: "chevron.left")
                        .font(AppTheme.Typography.title2)
                }
            )

            Spacer()

            Text(dateString)
                .font(AppTheme.Typography.headline)

            Spacer()

            Button(
                action: {
                    if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) {
                        currentDate = newDate
                    }
                },
                label: {
                    Image(systemName: "chevron.right")
                        .font(AppTheme.Typography.title2)
                }
            )
            .disabled(Calendar.current.isDateInTomorrow(currentDate))
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    private var dateString: String {
        if Calendar.current.isDateInToday(currentDate) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(currentDate) {
            return "Yesterday"
        } else if Calendar.current.isDateInTomorrow(currentDate) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: currentDate)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        TodayHeaderView(currentDate: .constant(Date()))
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) {
            TodayHeaderView(currentDate: .constant(yesterday))
        }
        if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
            TodayHeaderView(currentDate: .constant(tomorrow))
        }
    }
    .padding()
}
