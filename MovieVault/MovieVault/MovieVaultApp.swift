//
//  MovieVaultApp.swift
//  MovieVault
//
//  Created by emre on 23.09.26.
//

import SwiftUI
import SwiftData

@main
struct MovieVaultApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                
        }.modelContainer(for: FavoriteMovie.self)
    }
}
