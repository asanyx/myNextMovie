import SwiftData
import SwiftUI

struct SavedMoviesView: View {
    @Query(sort: \SavedMovie.savedAt, order: .reverse) private var savedMovies: [SavedMovie]
    private let loadDetails: MovieDetailsLoader

    init(loadDetails: @escaping MovieDetailsLoader) {
        self.loadDetails = loadDetails
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Saved")
                .navigationDestination(for: Movie.self) { movie in
                    MovieDetailView(movie: movie, loadDetails: loadDetails)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if savedMovies.isEmpty {
            ContentUnavailableView(
                "No saved movies",
                systemImage: symbolNameSaved,
                description: Text("Save a movie with the bookmark on its details screen.")
            )
        } else {
            MovieGrid(title: "Watch Later", movies: moviesFromSaved(savedMovies))
        }
    }
}

struct SaveMovieButton: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var savedCopies: [SavedMovie]

    let movie: Movie

    init(movie: Movie) {
        self.movie = movie
        let movieId = movie.id
        _savedCopies = Query(
            filter: #Predicate { savedMovie in
                savedMovie.movieId == movieId
            }
        )
    }

    var body: some View {
        Button {
            toggleSavedMovie(modelContext, movie, now: .now)
        } label: {
            Image(systemName: savedCopies.isEmpty ? symbolNameSaved : symbolNameSavedFilled)
        }
        .accessibilityLabel(savedCopies.isEmpty ? "Save movie" : "Remove saved movie")
    }
}

#Preview {
    SavedMoviesView(loadDetails: fetchMovieDetails)
        .modelContainer(for: storedModelTypes, inMemory: true)
}
