//
//  SectionHeaderView.swift
//  Calry
//
//  Created by Tyson Hu on 10/13/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import SwiftUI

struct SectionHeaderView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(AppTheme.Typography.headline)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        SectionHeaderView(title: "Breakfast")
        SectionHeaderView(title: "Lunch")
        SectionHeaderView(title: "Dinner")
        SectionHeaderView(title: "Snacks")
    }
    .padding()
}
