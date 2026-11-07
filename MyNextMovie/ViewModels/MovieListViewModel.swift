import Foundation
import Observation

/// A class only because SwiftUI's @Observable requires one.
@Observable
final class MovieListViewModel {
    private(set) var state = LoadState.idle
    private(set) var movies: [Movie] = []
    private(set) var errorMessage = ""

    private let loadMovies: MovieLoader

    init(loadMovies: @escaping MovieLoader) {
        self.loadMovies = loadMovies
    }

    /// Loads movies the first time the screen appears.
    func loadIfNeeded() async {
        if state == .idle {
            await load()
        }
    }

    func load() async {
        state = .loading
        do {
            movies = try await loadMovies()
            state = .loaded
        } catch {
            errorMessage = error.localizedDescription
            state = .failed
        }
    }
}
