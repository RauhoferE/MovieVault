//
//  MovieOverviewView.swift
//  MovieVault
//
//  Created by emre on 23.09.26.
//

import SwiftUI
import Combine
import SwiftData

@MainActor
class MovieListViewModel: ObservableObject {
    @Published var movies: [MoviesResponse.Movie] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var currentPage = 0
    private var totalPages = 1
    private var canLoadMore: Bool { currentPage < totalPages }

    func loadInitial(networkManager: NetworkManager) async {
        guard movies.isEmpty else { return }
        await loadNextPage(networkManager: networkManager)
    }

    func loadNextPageIfNeeded(currentItem movie: MoviesResponse.Movie, networkManager: NetworkManager) async {
        let thresholdIndex = movies.index(movies.endIndex, offsetBy: -5, limitedBy: movies.startIndex) ?? movies.startIndex
        guard let itemIndex = movies.firstIndex(where: { $0.id == movie.id }),
              itemIndex >= thresholdIndex else { return }

        await loadNextPage(networkManager: networkManager)
    }

    func refresh(networkManager: NetworkManager) async {
        currentPage = 0
        totalPages = 1
        movies = []
        await loadNextPage(networkManager: networkManager)
    }

    private func loadNextPage(networkManager: NetworkManager) async {
        guard !isLoading, canLoadMore else { return }
        isLoading = true
        errorMessage = nil

        do {
            let nextPage = currentPage + 1
            let response: MoviesResponse = try await networkManager.getMovies(page: nextPage)

            currentPage = response.page
            totalPages = response.total_pages
            movies.append(contentsOf: response.results)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

struct MovieOverviewView: View {
    @Environment(\.networkManager) private var networkManager
    @StateObject private var viewModel = MovieListViewModel()
    @Query private var favorites: [FavoriteMovie]

        private var favoriteIds: Set<Int> {
            Set(favorites.map { $0.id })
        }

    var body: some View {
        NavigationStack{
            List {
                ForEach(viewModel.movies, id: \.id) { movie in
                    NavigationLink(value: movie.id) {
                        MovieRow(movie: movie, isFavorite: favoriteIds.contains(movie.id))
                                        }
                        .task {
                            await viewModel.loadNextPageIfNeeded(currentItem: movie, networkManager: networkManager)
                        }
                }

                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding()
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.refresh(networkManager: networkManager)
            }
            .task {
                await viewModel.loadInitial(networkManager: networkManager)
            }
            .navigationDestination(for: Int.self){ movieId in
                MovieDetailView(movieId: movieId)
                
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "Undefined error happened")
            }
        }
        
    }
}

struct MovieRow: View {
    let movie: MoviesResponse.Movie
    let isFavorite: Bool

    private var posterURL: URL? {
        URL(string: "https://image.tmdb.org/t/p/w200\(movie.poster_path)")
    }

    private var year: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: movie.release_date)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: posterURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
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
                HStack {
                    Text(movie.title)
                        .font(.headline)
                        .lineLimit(2)

                    if isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                Text(year)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", movie.vote_average))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("(\(movie.vote_count))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(movie.overview)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
