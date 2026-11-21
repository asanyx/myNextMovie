import Foundation
import SwiftData
import Testing

@testable import MyNextMovie

@MainActor
private final class TestCloud {
    var movies: [CloudSavedMovie]
    var isOffline = false
    var uploadCallCount = 0

    init(movies: [CloudSavedMovie] = []) {
        self.movies = movies
    }

    var service: SavedMoviesCloud {
        return SavedMoviesCloud(
            fetchMovies: {
                if self.isOffline {
                    throw NoConnection()
                }
                return self.movies.sorted { $0.savedAt > $1.savedAt }
            },
            uploadMovies: { newMovies in
                if self.isOffline {
                    throw NoConnection()
                }
                self.uploadCallCount += 1
                let existingIds = Set(self.movies.map(\.id))
                self.movies.append(
                    contentsOf: newMovies.filter { !existingIds.contains($0.id) }
                )
            },
            removeMovie: { movieId in
                if self.isOffline {
                    throw NoConnection()
                }
                self.movies.removeAll { $0.id == movieId }
            }
        )
    }
}

@MainActor
struct SavedMoviesSyncTests {
    @Test func movieSavedOnDeviceGoesToAccount() async throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let cloud = TestCloud()
        let movie = testMovies[0]

        toggleSavedMovie(context, movie, now: testDate(1))
        try await syncSavedMovies(context, cloud: cloud.service)

        #expect(cloud.movies.map(\.id) == [movie.id])
        #expect(fetchSavedMovies(context, movieId: movie.id).first?.isInCloud == true)
    }

    @Test func movieIsSentOnlyOnce() async throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let cloud = TestCloud()
        toggleSavedMovie(context, testMovies[0], now: testDate(1))

        try await syncSavedMovies(context, cloud: cloud.service)
        try await syncSavedMovies(context, cloud: cloud.service)

        #expect(cloud.uploadCallCount == 1)
    }

    @Test func movieFromAccountComesToDevice() async throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let cloudMovie = makeCloudMovie(testMovies[0], savedAt: testDate(1))
        let cloud = TestCloud(movies: [cloudMovie])

        try await syncSavedMovies(context, cloud: cloud.service)

        let savedMovie = try #require(
            fetchSavedMovies(context, movieId: cloudMovie.id).first
        )
        #expect(movieFromSaved(savedMovie) == testMovies[0])
        #expect(savedMovie.isInCloud)
    }

    @Test func deviceAndAccountListsAreMerged() async throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let deviceMovie = testMovies[0]
        let accountMovie = testMovies[1]
        let cloud = TestCloud(
            movies: [makeCloudMovie(accountMovie, savedAt: testDate(1))]
        )
        toggleSavedMovie(context, deviceMovie, now: testDate(2))

        try await syncSavedMovies(context, cloud: cloud.service)

        let deviceIds = try context.fetch(FetchDescriptor<SavedMovie>())
            .map(\.movieId)
        #expect(Set(deviceIds) == Set([deviceMovie.id, accountMovie.id]))
        #expect(Set(cloud.movies.map(\.id)) == Set([deviceMovie.id, accountMovie.id]))
    }

    @Test func movieRemovedOnDeviceIsRemovedFromAccount() async throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let movie = testMovies[0]
        let cloud = TestCloud(
            movies: [makeCloudMovie(movie, savedAt: testDate(1))]
        )
        context.insert(
            SavedMovie(movie: movie, savedAt: testDate(1), isInCloud: true)
        )

        toggleSavedMovie(context, movie, now: testDate(2))
        try await syncSavedMovies(context, cloud: cloud.service)

        #expect(cloud.movies.isEmpty)
        #expect(try context.fetchCount(FetchDescriptor<RemovedSavedMovie>()) == 0)
    }

    @Test func movieRemovedOnAnotherDeviceIsRemovedHere() async throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let movie = testMovies[0]
        let cloud = TestCloud()
        context.insert(
            SavedMovie(movie: movie, savedAt: testDate(1), isInCloud: true)
        )

        try await syncSavedMovies(context, cloud: cloud.service)

        #expect(!isMovieSaved(context, movieId: movie.id))
    }

    @Test func changesMadeOfflineAreSentWithTheNextSync() async throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let removedMovie = testMovies[0]
        let addedMovie = testMovies[1]
        let cloud = TestCloud(
            movies: [makeCloudMovie(removedMovie, savedAt: testDate(1))]
        )
        context.insert(
            SavedMovie(
                movie: removedMovie,
                savedAt: testDate(1),
                isInCloud: true
            )
        )
        toggleSavedMovie(context, removedMovie, now: testDate(2))
        toggleSavedMovie(context, addedMovie, now: testDate(3))
        cloud.isOffline = true

        await #expect(throws: NoConnection.self) {
            try await syncSavedMovies(context, cloud: cloud.service)
        }
        #expect(cloud.movies.map(\.id) == [removedMovie.id])

        cloud.isOffline = false
        try await syncSavedMovies(context, cloud: cloud.service)

        #expect(cloud.movies.map(\.id) == [addedMovie.id])
        #expect(
            fetchSavedMovies(context, movieId: addedMovie.id).first?.isInCloud
                == true
        )
    }

    @Test func movieRemovedAndSavedAgainOfflineStays() async throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let movie = testMovies[0]
        let oldDate = testDate(1)
        let newDate = testDate(2)
        let cloud = TestCloud(
            movies: [makeCloudMovie(movie, savedAt: oldDate)]
        )
        context.insert(
            SavedMovie(movie: movie, savedAt: oldDate, isInCloud: true)
        )

        toggleSavedMovie(context, movie, now: newDate)
        toggleSavedMovie(context, movie, now: newDate)
        try await syncSavedMovies(context, cloud: cloud.service)

        #expect(cloud.movies.map(\.id) == [movie.id])
        let savedMovie = try #require(
            fetchSavedMovies(context, movieId: movie.id).first
        )
        #expect(savedMovie.savedAt == newDate)
        #expect(savedMovie.isInCloud)
        #expect(try context.fetchCount(FetchDescriptor<RemovedSavedMovie>()) == 0)
    }
}

@MainActor
struct CloudSavedMovieTests {
    @Test func encodesColumnNamesInSnakeCase() throws {
        let cloudMovie = makeCloudMovie(testMovies[0], savedAt: testDate(1))

        let data = try JSONEncoder().encode(cloudMovie)
        let json = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        #expect(json["release_date"] != nil)
        #expect(json["poster_path"] != nil)
        #expect(json["vote_average"] != nil)
        #expect(json["genre_ids"] != nil)
        #expect(json["saved_at"] != nil)
        #expect(json["releaseDate"] == nil)
    }

    @Test func cloudCopyKeepsEveryMovieField() {
        let movie = testMovies[0]
        let savedMovie = SavedMovie(
            movie: movie,
            savedAt: testDate(1),
            isInCloud: false
        )

        let copiedMovie = movieFromCloud(cloudMovieFromSaved(savedMovie))

        #expect(copiedMovie == movie)
    }
}

@MainActor
private func makeCloudMovie(
    _ movie: Movie,
    savedAt: Date
) -> CloudSavedMovie {
    return CloudSavedMovie(
        id: movie.id,
        title: movie.title,
        overview: movie.overview,
        releaseDate: movie.releaseDate,
        posterPath: movie.posterPath,
        voteAverage: movie.voteAverage,
        genreIds: movie.genreIds,
        savedAt: savedAt
    )
}

private func testDate(_ minute: Int) -> Date {
    return Date(timeIntervalSince1970: Double(minute) * 60)
}
