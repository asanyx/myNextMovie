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
    var body: some View {
        TabView {
            Tab("Movies", systemImage: symbolNameMovies) {
                MovieListView(
                    viewModel: MovieListViewModel(loadMovies: fetchPopularMovies),
                    loadDetails: fetchMovieDetails
                )
            }
            Tab("Saved", systemImage: symbolNameSaved) {
                SavedMoviesView(loadDetails: fetchMovieDetails)
            }
            Tab("Search", systemImage: symbolNameSearch) {
                SearchView(
                    viewModel: SearchViewModel(searchMovies: searchTMDBMovies),
                    loadDetails: fetchMovieDetails
                )
            }
        }
    }
}
