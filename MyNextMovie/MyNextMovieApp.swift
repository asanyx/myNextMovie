import SwiftData
import SwiftUI

@main
struct MyNextMovieApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: storedModelTypes)
    }
}

private struct RootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            Tab("Movies", systemImage: symbolNameMovies) {
                MovieListView(
                    viewModel: MovieListViewModel(loadMovies: loadPopularMoviesWithCache),
                    loadDetails: loadDetailsWithCache
                )
            }
            Tab("Saved", systemImage: symbolNameSaved) {
                SavedMoviesView(loadDetails: loadDetailsWithCache)
            }
            Tab("Search", systemImage: symbolNameSearch) {
                SearchView(
                    viewModel: SearchViewModel(searchMovies: searchTMDBMovies),
                    loadDetails: loadDetailsWithCache
                )
            }
        }
    }

    private func loadPopularMoviesWithCache() async throws -> [Movie] {
        return try await loadPopularMovies(cache: modelContext)
    }

    private func loadDetailsWithCache(movieId: Int) async throws -> MovieDetails {
        return try await loadTMDBMovieDetails(movieId: movieId, cache: modelContext)
    }
}
