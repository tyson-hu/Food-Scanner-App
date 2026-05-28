//
//  AppEnvironment+EnvironmentKey.swift
//  Calry
//
//  Created by Tyson Hu on 10/13/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation
import SwiftUI

private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppEnvironment = .preview
}

public extension EnvironmentValues {
    var appEnv: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
