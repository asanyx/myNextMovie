import Foundation
import SwiftData
import Testing

@testable import MyNextMovie

@MainActor
struct SavedMovieTests {
    @Test func toggleSavesThenRemoves() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let movie = testMovies[0]
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        toggleSavedMovie(context, movie, now: now)
        #expect(isMovieSaved(context, movieId: movie.id))

        toggleSavedMovie(context, movie, now: now)
        #expect(!isMovieSaved(context, movieId: movie.id))
    }

    @Test func savedCopyKeepsEveryField() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let movie = testMovies[0]
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        toggleSavedMovie(context, movie, now: now)
        let savedCopies = fetchSavedMovies(context, movieId: movie.id)

        #expect(moviesFromSaved(savedCopies) == [movie])
    }
}

@MainActor
func makeTestContainer() throws -> ModelContainer {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(
        for: Schema(storedModelTypes),
        configurations: [configuration]
    )
}
