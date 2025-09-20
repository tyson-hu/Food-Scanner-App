//
//  AddFoodLogPayload.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//

import Foundation

struct AddFoodLogPayload: Sendable, Equatable {
    let details: FDCFoodDetails
    let serving: Double
    let date: Date = Date()
}
