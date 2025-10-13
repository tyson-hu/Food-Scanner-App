//
//  Unit+Decoding.swift
//  Calry
//
//  Created by Tyson Hu on 10/13/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

extension Unit {
    /// Decode Unit from string (for edit flow compatibility)
    static func from(rawValue: String) -> Unit {
        switch rawValue.lowercased() {
        case "grams", "g":
            return .grams
        case "milliliters", "ml":
            return .milliliters
        case "serving":
            return .serving
        default:
            // Handle household units encoded as "household:label"
            if rawValue.hasPrefix("household:") {
                let label = String(rawValue.dropFirst("household:".count))
                return .household(label: label)
            }
            // Fallback for unknown units
            return .serving
        }
    }
}
