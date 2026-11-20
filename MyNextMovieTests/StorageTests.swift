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
struct ResponseCacheTests {
    @Test func missingKeyGivesEmptyData() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        #expect(cachedResponseData(context, key: "missing").isEmpty)
    }

    @Test func storingAgainReplacesData() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let firstData = Data("first".utf8)
        let secondData = Data("second".utf8)
        let start = Date(timeIntervalSince1970: 0)

        storeCachedResponse(context, key: "popular", data: firstData, now: start)
        storeCachedResponse(
            context,
            key: "popular",
            data: secondData,
            now: start.addingTimeInterval(60)
        )

        #expect(cachedResponseData(context, key: "popular") == secondData)
        #expect(try context.fetchCount(FetchDescriptor<CachedResponse>()) == 1)
    }

    @Test func freshAnswerIsReturnedAndCached() async throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let freshData = Data("fresh".utf8)

        let returnedData = try await fetchWithCacheFallback(context, key: "popular") {
            freshData
        }

        #expect(returnedData == freshData)
        #expect(cachedResponseData(context, key: "popular") == freshData)
    }

    @Test func cachedAnswerIsReturnedWhenOffline() async throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let cachedData = Data("cached".utf8)
        storeCachedResponse(
            context,
            key: "popular",
            data: cachedData,
            now: Date(timeIntervalSince1970: 0)
        )

        let returnedData = try await fetchWithCacheFallback(context, key: "popular") {
            throw NoConnection()
        }

        #expect(returnedData == cachedData)
    }

    @Test func errorIsRethrownWhenNothingCached() async throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        await #expect(throws: NoConnection.self) {
            try await fetchWithCacheFallback(context, key: "popular") {
                throw NoConnection()
            }
        }
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
