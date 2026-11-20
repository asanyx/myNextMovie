import Foundation
import SwiftData

func fetchSavedMovies(_ context: ModelContext, movieId: Int) -> [SavedMovie] {
    let descriptor = FetchDescriptor<SavedMovie>(
        predicate: #Predicate { savedMovie in
            savedMovie.movieId == movieId
        }
    )
    return (try? context.fetch(descriptor)) ?? []
}

func isMovieSaved(_ context: ModelContext, movieId: Int) -> Bool {
    return !fetchSavedMovies(context, movieId: movieId).isEmpty
}

func toggleSavedMovie(_ context: ModelContext, _ movie: Movie, now: Date) {
    let savedCopies = fetchSavedMovies(context, movieId: movie.id)
    if savedCopies.isEmpty {
        context.insert(SavedMovie(movie: movie, savedAt: now))
    } else {
        for savedCopy in savedCopies {
            context.delete(savedCopy)
        }
    }
}

func movieFromSaved(_ savedMovie: SavedMovie) -> Movie {
    return Movie(
        id: savedMovie.movieId,
        title: savedMovie.title,
        overview: savedMovie.overview,
        releaseDate: savedMovie.releaseDate,
        posterPath: savedMovie.posterPath,
        voteAverage: savedMovie.voteAverage,
        genreIds: savedMovie.genreIds
    )
}

func moviesFromSaved(_ savedMovies: [SavedMovie]) -> [Movie] {
    return savedMovies.map(movieFromSaved)
}
