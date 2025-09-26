//
//  FDCUtilityModels.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//  Refactored from FDCModels.swift for better organization
//

import Foundation

// MARK: - Utility Models

public struct AnyCodable: Codable, Equatable {
    let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try to decode as different types in order of likelihood
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue
        } else {
            // If all else fails, try to decode as a generic dictionary
            // This handles cases where the structure might be more complex
            let genericDict = try container.decode([String: AnyCodable].self)
            value = genericDict
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else if let arrayValue = value as? [AnyCodable] {
            try container.encode(arrayValue)
        } else if let dictValue = value as? [String: AnyCodable] {
            try container.encode(dictValue)
        } else {
            // If all else fails, encode as empty dictionary
            try container.encode([String: AnyCodable]())
        }
    }

    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        // Simple comparison based on type and value
        switch (lhs.value, rhs.value) {
        case let (lhsInt as Int, rhsInt as Int):
            lhsInt == rhsInt
        case let (lhsString as String, rhsString as String):
            lhsString == rhsString
        case let (lhsDouble as Double, rhsDouble as Double):
            lhsDouble == rhsDouble
        case let (lhsBool as Bool, rhsBool as Bool):
            lhsBool == rhsBool
        case let (lhsArray as [AnyCodable], rhsArray as [AnyCodable]):
            lhsArray == rhsArray
        case let (lhsDict as [String: AnyCodable], rhsDict as [String: AnyCodable]):
            lhsDict == rhsDict
        default:
            false
        }
    }
}
