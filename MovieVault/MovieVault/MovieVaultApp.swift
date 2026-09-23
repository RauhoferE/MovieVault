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
    //var sharedModelContainer: ModelContainer = {
    //    let schema = Schema([
    //        Item.self,
    //    ])
    //    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

     //   do {
     //       return try ModelContainer(for: schema, configurations: [modelConfiguration])
     //   } catch {
     //       fatalError("Could not create ModelContainer: \(error)")
     //   }
    //}()

    var body: some Scene {
        WindowGroup {
            ContentView()
                
        }.modelContainer(for: FavoriteMovie.self)
        //.modelContainer(sharedModelContainer)
    }
}
