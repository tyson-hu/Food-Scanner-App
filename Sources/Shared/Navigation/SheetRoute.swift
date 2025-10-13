//
//  SheetRoute.swift
//  Calry
//
//  Created by Tyson Hu on 10/13/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

enum SheetRoute: Identifiable, Hashable {
    case search(meal: Meal, onSelect: (String) -> Void)
    case portion(foodGID: String, meal: Meal)
    case editEntry(entryId: UUID)

    var id: String {
        switch self {
        case let .search(meal, _):
            "search-\(String(describing: meal))"
        case let .portion(gid, meal):
            "portion-\(gid)-\(String(describing: meal))"
        case let .editEntry(id):
            "edit-\(id.uuidString)"
        }
    }

    static func == (lhs: SheetRoute, rhs: SheetRoute) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
