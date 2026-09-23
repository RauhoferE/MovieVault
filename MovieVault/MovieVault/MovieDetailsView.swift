//
//  MovieDetailsView.swift
//  MovieVault
//
//  Created by emre on 23.09.26.
//

import SwiftUI
import Combine
import SwiftData

@MainActor
class MovieDetailViewModel: ObservableObject {
    @Published var details: MovieDetails?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load(movieId: Int, networkManager: NetworkManager) async {
        isLoading = true
        errorMessage = nil

        do {
            details = try await networkManager.getMovieDetails(id: movieId)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

struct MovieDetailView: View {
    let movieId: Int

    @Environment(\.networkManager) private var networkManager
    @Environment(\.modelContext) private var modelContext
        @Query private var favorites: [FavoriteMovie]
    @StateObject private var viewModel = MovieDetailViewModel()
    
    private var isFavorite: Bool {
            favorites.contains { $0.id == movieId }
        }

    var body: some View {
        ScrollView {
            if let details = viewModel.details {
                content(for: details)
            } else if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 300)
            }
        }
        .ignoresSafeArea(edges: .top)
        .task {
            await viewModel.load(movieId: movieId, networkManager: networkManager)
        }
        .toolbar {
                    if let details = viewModel.details {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                toggleFavorite(details: details)
                            } label: {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .foregroundColor(isFavorite ? .red : .primary)
                            }
                        }
                    }
                }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    private func toggleFavorite(details: MovieDetails) {
        if let existing = favorites.first(where: { $0.id == movieId }) {
            modelContext.delete(existing)
        } else {
            let favorite = FavoriteMovie(from: details)
            modelContext.insert(favorite)
        }
    }

    @ViewBuilder
    private func content(for details: MovieDetails) -> some View {
        VStack(alignment: .leading, spacing: 0) {
             // Backdrop, plain, no overlap
             AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w780\(details.backdrop_path)")) { phase in
                 switch phase {
                 case .success(let image):
                     image.resizable().aspectRatio(contentMode: .fill)
                 default:
                     Color.gray.opacity(0.2)
                 }
             }
             .frame(height: 220)
             .clipped()

             // Poster + title, side by side, normal flow below the backdrop
             HStack(alignment: .top, spacing: 12) {
                 AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w342\(details.poster_path)")) { phase in
                     switch phase {
                     case .success(let image):
                         image.resizable().aspectRatio(contentMode: .fill)
                     default:
                         Color.gray.opacity(0.3)
                     }
                 }
                 .frame(width: 100, height: 150)
                 .clipShape(RoundedRectangle(cornerRadius: 8))
                 .shadow(radius: 4)

                 titleSection(for: details)
                     .padding(.top, 4)
             }
             .padding()

             VStack(alignment: .leading, spacing: 16) {
                 metaRow(for: details)
                 genresRow(for: details)

                 if !details.overview.isEmpty {
                     Text("Overview")
                         .font(.headline)
                     Text(details.overview)
                         .font(.body)
                         .foregroundColor(.secondary)
                 }
             }
             .padding(.horizontal)
             .padding(.bottom)
         }
    }

    private func titleSection(for details: MovieDetails) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(details.title)
                .font(.title2)
                .fontWeight(.bold)

            if !details.tagline.isEmpty {
                Text(details.tagline)
                    .font(.subheadline)
                    .italic()
                    .foregroundColor(.secondary)
            }
        }
    }

    private func metaRow(for details: MovieDetails) -> some View {
        HStack(spacing: 16) {
            Label(year(from: details.release_date), systemImage: "calendar")
            if details.runtime > 0 {
                Label(formattedRuntime(details.runtime), systemImage: "clock")
            }
            Label(String(format: "%.1f", details.vote_average), systemImage: "star.fill")
                .foregroundColor(.orange)
        }
        .font(.subheadline)
        .foregroundColor(.secondary)
    }

    private func genresRow(for details: MovieDetails) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(details.genres, id: \.id) { genre in
                    Text(genre.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func year(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }

    private func formattedRuntime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return hours > 0 ? "\(hours)h \(mins)m" : "\(mins)m"
    }
}
