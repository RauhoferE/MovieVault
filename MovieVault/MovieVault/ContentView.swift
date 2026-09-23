//
//  ContentView.swift
//  MovieVault
//
//  Created by emre on 23.09.26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var networkManager = NetworkManager()

    var body: some View {
        
            TabView {
                        MovieOverviewView()
                            .tabItem {
                                Label("Movies", systemImage: "film")
                            }
                            .toolbar(.hidden, for: .navigationBar)
                            .environment(\.networkManager, networkManager)

                        FavoritesView()
                            .tabItem {
                                Label("Favorites", systemImage: "heart.fill")
                            }
                            .toolbar(.hidden, for: .navigationBar)
                            .environment(\.networkManager, networkManager)
                    }
            
                
        
    }
}
