//
//  ProductSourceDetection.swift
//  Food Scanner
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
        } else if gid.hasPrefix("off:") || gid.hasPrefix("gtin:") {
            return .off
        }
        return nil
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
}
