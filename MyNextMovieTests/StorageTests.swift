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
struct SearchHistoryTests {
    @Test func newestSearchComesFirst() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let start = Date(timeIntervalSince1970: 0)

        recordSearch(context, query: "matrix", now: start.addingTimeInterval(60))
        recordSearch(context, query: "alien", now: start.addingTimeInterval(120))

        #expect(recentSearches(context).map(\.query) == ["alien", "matrix"])
    }

    @Test func repeatedSearchMovesToTop() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let start = Date(timeIntervalSince1970: 0)

        recordSearch(context, query: "matrix", now: start.addingTimeInterval(60))
        recordSearch(context, query: "alien", now: start.addingTimeInterval(120))
        recordSearch(context, query: "matrix", now: start.addingTimeInterval(180))

        #expect(recentSearches(context).map(\.query) == ["matrix", "alien"])
    }

    @Test func emptyAndSpacesAreNotRecorded() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let now = Date(timeIntervalSince1970: 0)

        recordSearch(context, query: "", now: now)
        recordSearch(context, query: "   ", now: now)
        recordSearch(context, query: "  dune  ", now: now)

        #expect(recentSearches(context).map(\.query) == ["dune"])
    }

    @Test func keepsOnlyRecentSearches() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let start = Date(timeIntervalSince1970: 0)

        for minute in 0..<13 {
            recordSearch(
                context,
                query: "query \(minute)",
                now: start.addingTimeInterval(60 * Double(minute))
            )
        }

        let history = recentSearches(context)
        #expect(history.count == maxSearchHistoryCount)
        #expect(history.first?.query == "query 12")
    }

    @Test func clearRemovesEverything() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let now = Date(timeIntervalSince1970: 0)

        recordSearch(context, query: "matrix", now: now)
        recordSearch(context, query: "alien", now: now.addingTimeInterval(60))
        clearSearchHistory(context)

        #expect(recentSearches(context).isEmpty)
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
