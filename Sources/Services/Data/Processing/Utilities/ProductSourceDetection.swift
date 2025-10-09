//
//  ProductSourceDetection.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

enum ProductSupportStatus {
    case supported(SourceTag)
    case unsupported(SourceTag?)
    case unknown
}

enum ProductSourceDetection {
    /// Detects the source from a GID and determines if it's supported for detailed nutrition information
    static func detectSupportStatus(from gid: String) -> ProductSupportStatus {
        guard let source = extractSource(from: gid) else {
            return .unknown
        }

        switch source {
        case .fdc:
            return .supported(source)
        case .off:
            return .unsupported(source)
        }
    }

    /// Extracts the source tag from a GID
    static func extractSource(from gid: String) -> SourceTag? {
        if gid.hasPrefix("fdc:") {
            return .fdc
        } else if gid.hasPrefix("off:") {
            return .off
        } else if gid.hasPrefix("gtin:") {
            // GTINs can come from multiple sources - we cannot determine source from GID alone
            // The source should be determined from the provenance information in the FoodCard/FoodDetails
            return nil
        }
        return nil
    }

    /// Extracts the source tag from a FoodCard using provenance information
    static func extractSource(from foodCard: FoodCard) -> SourceTag? {
        foodCard.provenance.source
    }

    /// Extracts the source tag from a FoodDetails using provenance information
    static func extractSource(from foodDetails: FoodDetails) -> SourceTag? {
        foodDetails.provenance.source
    }

    /// Detects support status from a FoodCard using provenance information
    static func detectSupportStatus(from foodCard: FoodCard) -> ProductSupportStatus {
        let source = extractSource(from: foodCard)
        return detectSupportStatus(from: source)
    }

    /// Detects support status from a FoodDetails using provenance information
    static func detectSupportStatus(from foodDetails: FoodDetails) -> ProductSupportStatus {
        let source = extractSource(from: foodDetails)
        return detectSupportStatus(from: source)
    }

    /// Detects support status from a source tag
    private static func detectSupportStatus(from source: SourceTag?) -> ProductSupportStatus {
        guard let source else {
            return .unknown
        }

        switch source {
        case .fdc:
            return .supported(source)
        case .off:
            return .unsupported(source)
        }
    }

    /// Checks if a product is supported for detailed nutrition information
    static func isSupported(for gid: String) -> Bool {
        switch detectSupportStatus(from: gid) {
        case .supported:
            true
        case .unsupported, .unknown:
            false
        }
    }

    /// Checks if a FoodCard is supported for detailed nutrition information
    static func isSupported(for foodCard: FoodCard) -> Bool {
        switch detectSupportStatus(from: foodCard) {
        case .supported:
            true
        case .unsupported, .unknown:
            false
        }
    }

    /// Checks if a FoodDetails is supported for detailed nutrition information
    static func isSupported(for foodDetails: FoodDetails) -> Bool {
        switch detectSupportStatus(from: foodDetails) {
        case .supported:
            true
        case .unsupported, .unknown:
            false
        }
    }
}
