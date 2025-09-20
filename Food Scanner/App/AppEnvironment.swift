//
//  AppEnvironment.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//

import SwiftUI

struct AppEnvironment: Sendable {
    // MARK: Fill in later (fdc, repositories). Keep dateProvider now.
    var dateProvider: () -> Date = { Date() }
}

private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppEnvironment()
}

extension EnvironmentValues {
    var appEnv: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
