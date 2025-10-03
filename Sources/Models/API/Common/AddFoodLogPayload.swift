//
//  AddFoodLogPayload.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

struct AddFoodLogPayload: Sendable, Equatable {
    let details: FDCFoodDetails
    let serving: Double
    let date: Date = .init()
}
