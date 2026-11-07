import SwiftUI

@main
struct MyNextMovieApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
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
            Tab("Search", systemImage: symbolNameSearch, role: .search) {
                SearchView(
                    viewModel: SearchViewModel(searchMovies: searchTMDBMovies),
                    loadDetails: fetchMovieDetails
                )
            }
        }
    }
}
