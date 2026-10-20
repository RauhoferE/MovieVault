//
//  DiscoverView.swift
//  MovieVault
//
//  Created by emre on 20.10.26.
//

import SwiftUI
import Combine
import SwiftData

@MainActor
class DiscoverViewModel: ObservableObject {
    @Published var genres: [MovieDetails.Genre] = []
    @Published var deck: [DiscoverResponse.Movie] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadGenres(networkManager: NetworkManager) async {
        guard genres.isEmpty else { return }
        do {
            genres = try await networkManager.getGenres().genres
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadDeck(genreIds: [Int], networkManager: NetworkManager) async {
        deck = []
        guard genreIds.count == 2 else { return }
        isLoading = true
        errorMessage = nil

        do {
            // Discover is sorted, so jump to a random page to get a random set of movies
            let firstPage = try await networkManager.discoverMovies(genreIds: genreIds, page: 1)
            var results = firstPage.results
            let lastPage = min(firstPage.total_pages, 500)
            if lastPage > 1 {
                results = try await networkManager.discoverMovies(genreIds: genreIds, page: Int.random(in: 1...lastPage)).results
            }
            deck = Array(results.filter { $0.poster_path != nil }.shuffled().prefix(10))
        } catch {
            // A newer genre pick or reroll cancelled this load
            if Task.isCancelled { return }
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

struct DiscoverView: View {
    @Environment(\.networkManager) private var networkManager
    @Environment(\.modelContext) private var modelContext
    @Query private var favorites: [FavoriteMovie]
    @StateObject private var viewModel = DiscoverViewModel()
    @State private var path = NavigationPath()
    @State private var selectedGenres: [Int] = []
    @State private var rerollCount = 0
    @State private var savedCount = 0

    private struct DeckKey: Equatable {
        let genres: [Int]
        let reroll: Int
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 16) {
                genrePicker
                deck
                    .frame(maxHeight: .infinity)
            }
            .padding(.bottom)
            .navigationTitle("Movie Fusion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        rerollCount += 1
                    } label: {
                        Image(systemName: "shuffle")
                    }
                    .disabled(selectedGenres.count < 2)
                    .symbolEffect(.bounce, value: rerollCount)
                }
            }
            .navigationDestination(for: Int.self) { movieId in
                MovieDetailView(movieId: movieId)
            }
            .task {
                await viewModel.loadGenres(networkManager: networkManager)
            }
            .task(id: DeckKey(genres: selectedGenres, reroll: rerollCount)) {
                await viewModel.loadDeck(genreIds: selectedGenres, networkManager: networkManager)
            }
            .sensoryFeedback(.success, trigger: savedCount)
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var genrePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.genres, id: \.id) { genre in
                    let isSelected = selectedGenres.contains(genre.id)
                    Button {
                        toggleGenre(genre.id)
                    } label: {
                        Text(genre.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
                            .foregroundColor(isSelected ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .sensoryFeedback(.selection, trigger: selectedGenres)
    }

    @ViewBuilder
    private var deck: some View {
        if selectedGenres.count < 2 {
            ContentUnavailableView(
                "Pick Two Genres and find interesting fusions",
                systemImage: "theatermasks",
                description: Text("Choose \(2 - selectedGenres.count) more genre\(selectedGenres.isEmpty ? "s" : "") to get a stack of movies.")
            )
        } else if viewModel.isLoading {
            ProgressView()
        } else if viewModel.deck.isEmpty {
            ContentUnavailableView {
                Label("No More Movies", systemImage: "rectangle.stack")
            } description: {
                Text("Reroll for a fresh mix or try another fusion.")
            } actions: {
                Button("Reroll") { rerollCount += 1 }
                    .buttonStyle(.borderedProminent)
            }
        } else {
            ZStack {
                // Only render the top few cards, the first movie sits on top
                ForEach(Array(viewModel.deck.prefix(3).enumerated().reversed()), id: \.element.id) { index, movie in
                    SwipeCard(movie: movie, isTop: index == 0) { direction in
                        swiped(movie, direction: direction)
                    } onTap: {
                        path.append(movie.id)
                    }
                    .scaleEffect(1 - CGFloat(index) * 0.05)
                    .offset(y: CGFloat(index) * 12)
                }
            }
            .padding(.horizontal, 24)
            .animation(.spring, value: viewModel.deck.map(\.id))
        }
    }

    private func toggleGenre(_ id: Int) {
        if let index = selectedGenres.firstIndex(of: id) {
            selectedGenres.remove(at: index)
        } else {
            selectedGenres.append(id)
            // Picking a third genre replaces the oldest one
            if selectedGenres.count > 2 {
                selectedGenres.removeFirst()
            }
        }
    }

    private func swiped(_ movie: DiscoverResponse.Movie, direction: SwipeCard.Direction) {
        viewModel.deck.removeAll { $0.id == movie.id }
        guard direction == .right else { return }
        savedCount += 1

        guard !favorites.contains(where: { $0.id == movie.id }) else { return }
        Task {
            do {
                // Favorites store the full details, so fetch them before saving
                let details = try await networkManager.getMovieDetails(id: movie.id)
                modelContext.insert(FavoriteMovie(from: details))
            } catch {
                viewModel.errorMessage = "Couldn't save \(movie.title): \(error.localizedDescription)"
            }
        }
    }
}

struct SwipeCard: View {
    enum Direction {
        case left, right
    }

    let movie: DiscoverResponse.Movie
    let isTop: Bool
    let onSwipe: (Direction) -> Void
    let onTap: () -> Void

    @State private var offset: CGSize = .zero
    private let swipeThreshold: CGFloat = 120

    private var posterURL: URL? {
        movie.poster_path.flatMap { URL(string: "https://image.tmdb.org/t/p/w500\($0)") }
    }

    var body: some View {
        AsyncImage(url: posterURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            default:
                Color.gray.opacity(0.2)
                    .overlay(ProgressView())
            }
        }
        .aspectRatio(2/3, contentMode: .fit)
        .overlay(alignment: .bottomLeading) { infoOverlay }
        .overlay {
            stamp("heart.fill", color: .green, progress: offset.width / swipeThreshold)
        }
        .overlay {
            stamp("xmark", color: .red, progress: -offset.width / swipeThreshold)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 6)
        .offset(offset)
        .rotationEffect(.degrees(Double(offset.width / 20)))
        .allowsHitTesting(isTop)
        .onTapGesture(perform: onTap)
        .gesture(
            DragGesture()
                .onChanged { offset = $0.translation }
                .onEnded { value in
                    if abs(value.translation.width) > swipeThreshold {
                        let direction: Direction = value.translation.width > 0 ? .right : .left
                        withAnimation(.easeOut(duration: 0.25)) {
                            offset.width = direction == .right ? 600 : -600
                        } completion: {
                            onSwipe(direction)
                        }
                    } else {
                        withAnimation(.spring) { offset = .zero }
                    }
                }
        )
    }

    private var infoOverlay: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(movie.title)
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(2)
            HStack(spacing: 12) {
                if let year = movie.release_date?.prefix(4), !year.isEmpty {
                    Label(String(year), systemImage: "calendar")
                }
                Label(String(format: "%.1f", movie.vote_average), systemImage: "star.fill")
            }
            .font(.subheadline)
        }
        .foregroundColor(.white)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom))
    }

    // Fades in and grows as the card is dragged towards the swipe threshold
    private func stamp(_ systemImage: String, color: Color, progress: CGFloat) -> some View {
        let clamped = min(max(progress, 0), 1)
        return Image(systemName: systemImage)
            .font(.system(size: 120, weight: .heavy))
            .foregroundColor(color)
            .shadow(color: .black.opacity(0.4), radius: 8)
            .scaleEffect(0.6 + 0.4 * clamped)
            .opacity(Double(clamped))
    }
}
