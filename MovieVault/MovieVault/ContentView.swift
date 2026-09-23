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
        NavigationStack {
            MovieOverviewView()
                .toolbar(.hidden, for: .navigationBar)
                .environment(\.networkManager, networkManager)
        }
    }
}
