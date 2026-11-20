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
        AppContent(modelContext: modelContext)
    }
}

private struct AppContent: View {
    @State private var accountViewModel: AccountViewModel
    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        let viewModel = AccountViewModel(
            account: supabaseAccountService,
            syncSavedMovies: {
                // Cloud synchronization is added in task 3.
            },
            clearSavedMovies: {
                clearSavedMovies(modelContext)
            }
        )
        #if DEBUG
            viewModel.email = testAccountEmail
            viewModel.password = testAccountPassword
        #endif
        _accountViewModel = State(initialValue: viewModel)
    }

    var body: some View {
        if accountViewModel.isSignedIn {
            AppTabs(
                accountViewModel: accountViewModel,
                loadMovies: loadPopularMoviesWithCache,
                loadDetails: loadDetailsWithCache
            )
        } else {
            SignInView(viewModel: accountViewModel)
        }
    }

    private func loadPopularMoviesWithCache() async throws -> [Movie] {
        return try await loadPopularMovies(cache: modelContext)
    }

    private func loadDetailsWithCache(movieId: Int) async throws -> MovieDetails {
        return try await loadTMDBMovieDetails(movieId: movieId, cache: modelContext)
    }
}

private struct AppTabs: View {
    let accountViewModel: AccountViewModel
    let loadMovies: MovieLoader
    let loadDetails: MovieDetailsLoader

    var body: some View {
        TabView {
            Tab("Movies", systemImage: symbolNameMovies) {
                MovieListView(
                    viewModel: MovieListViewModel(loadMovies: loadMovies),
                    loadDetails: loadDetails
                )
            }
            Tab("Saved", systemImage: symbolNameSaved) {
                SavedMoviesView(loadDetails: loadDetails)
            }
            Tab("Account", systemImage: symbolNameAccount) {
                AccountView(viewModel: accountViewModel)
            }
            Tab("Search", systemImage: symbolNameSearch) {
                SearchView(
                    viewModel: SearchViewModel(searchMovies: searchTMDBMovies),
                    loadDetails: loadDetails
                )
            }
        }
    }
}
