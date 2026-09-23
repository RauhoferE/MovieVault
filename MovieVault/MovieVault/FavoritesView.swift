//
//  FavoritesView.swift
//  MovieVault
//
//  Created by emre on 23.09.26.
//

import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Query(sort: \FavoriteMovie.title) private var favorites: [FavoriteMovie]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    ContentUnavailableView(
                        "No Favorites Yet",
                        systemImage: "heart",
                        description: Text("Movies you favorite will show up here.")
                    )
                } else {
                    List {
                        ForEach(favorites, id: \.id) { favorite in
                            NavigationLink(value: favorite.id) {
                                FavoriteRow(favorite: favorite)
                            }
                        }
                        .onDelete(perform: deleteFavorites)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationDestination(for: Int.self) { movieId in
                MovieDetailView(movieId: movieId)
            }
            .navigationTitle("Favorites")
        }
    }

    private func deleteFavorites(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(favorites[index])
        }
    }
}

struct FavoriteRow: View {
    let favorite: FavoriteMovie

    private var posterURL: URL? {
        URL(string: "https://image.tmdb.org/t/p/w200\(favorite.poster_path)")
    }

    private var year: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: favorite.release_date)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: posterURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .failure:
                    Color.gray.opacity(0.2)
                        .overlay(Image(systemName: "photo").foregroundColor(.gray))
                default:
                    Color.gray.opacity(0.1)
                        .overlay(ProgressView())
                }
            }
            .frame(width: 60, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 6) {
                Text(favorite.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(year)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", favorite.vote_average))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("(\(favorite.vote_count))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(favorite.overview)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}


