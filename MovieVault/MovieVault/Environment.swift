//
//  Environment.swift
//  MovieVault
//
//  Created by emre on 23.09.26.
//

import Foundation
import SwiftUI
private struct NetworkManagerKey: EnvironmentKey {
    static let defaultValue = NetworkManager()
}

extension EnvironmentValues {
    var networkManager: NetworkManager {
        get { self[NetworkManagerKey.self] }
        set { self[NetworkManagerKey.self] = newValue }
    }
}
