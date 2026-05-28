//
//  AppTheme.swift
//  Calry
//
//  Created by Tyson Hu on 10/13/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import SwiftUI

public enum AppTheme {
    // MARK: - Colors

    public enum Colors {
        public static let primary = Color.accentColor
        public static let secondary = Color.secondary
        public static let background = Color(.systemBackground)
        public static let secondaryBackground = Color(.secondarySystemBackground)
        public static let tertiary = Color(.tertiarySystemFill)

        // Semantic colors
        public static let success = Color.green
        public static let warning = Color.orange
        public static let error = Color.red

        // Nutrient colors
        public static let calories = Color.orange
        public static let protein = Color.blue
        public static let fat = Color.purple
        public static let carbs = Color.green
    }

    // MARK: - Typography

    public enum Typography {
        public static let largeTitle = Font.largeTitle.weight(.bold)
        public static let title = Font.title.weight(.semibold)
        public static let title2 = Font.title2.weight(.semibold)
        public static let headline = Font.headline
        public static let body = Font.body
        public static let callout = Font.callout
        public static let caption = Font.caption
        public static let caption2 = Font.caption2
    }

    // MARK: - Spacing

    public enum Spacing {
        public static let xxs: CGFloat = 4
        // swiftlint:disable:next identifier_name
        public static let xs: CGFloat = 8
        // swiftlint:disable:next identifier_name
        public static let sm: CGFloat = 12
        // swiftlint:disable:next identifier_name
        public static let md: CGFloat = 16
        // swiftlint:disable:next identifier_name
        public static let lg: CGFloat = 24
        // swiftlint:disable:next identifier_name
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    public enum CornerRadius {
        // swiftlint:disable:next identifier_name
        public static let sm: CGFloat = 4
        // swiftlint:disable:next identifier_name
        public static let md: CGFloat = 8
        // swiftlint:disable:next identifier_name
        public static let lg: CGFloat = 12
        // swiftlint:disable:next identifier_name
        public static let xl: CGFloat = 16
    }

    // MARK: - Animation

    public enum Animation {
        public static let `default` = SwiftUI.Animation.easeInOut(duration: 0.2)
        public static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
        public static let slow = SwiftUI.Animation.easeInOut(duration: 0.3)
    }
}
