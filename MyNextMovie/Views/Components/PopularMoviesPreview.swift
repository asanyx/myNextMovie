import SwiftUI

struct PopularMoviesPreview<Content: View>: View {
    @State private var movies: [Movie] = []
    @State private var errorMessage = ""
    @State private var isLoading = true

    private let content: ([Movie]) -> Content

    init(@ViewBuilder content: @escaping ([Movie]) -> Content) {
        self.content = content
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if !errorMessage.isEmpty {
                Text(errorMessage)
            } else if movies.isEmpty {
                ContentUnavailableView("No movies", systemImage: symbolNameMovies)
            } else {
                content(movies)
            }
        }
        .task { await loadMovies() }
    }

    private func loadMovies() async {
        do {
            movies = try await fetchPopularMovies()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
