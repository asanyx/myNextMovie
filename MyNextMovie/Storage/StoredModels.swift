import Foundation
import SwiftData

@Model
final class SavedMovie {
    @Attribute(.unique) var movieId: Int
    var title: String
    var overview: String
    var releaseDate: String
    var posterPath: String?
    var voteAverage: Double
    var genreIds: [Int]
    var savedAt: Date
    var isInCloud: Bool

    init(movie: Movie, savedAt: Date, isInCloud: Bool) {
        movieId = movie.id
        title = movie.title
        overview = movie.overview
        releaseDate = movie.releaseDate
        posterPath = movie.posterPath
        voteAverage = movie.voteAverage
        genreIds = movie.genreIds
        self.savedAt = savedAt
        self.isInCloud = isInCloud
    }
}

@Model
final class RemovedSavedMovie {
    @Attribute(.unique) var movieId: Int

    init(movieId: Int) {
        self.movieId = movieId
    }
}

@Model
final class SearchHistoryEntry {
    @Attribute(.unique) var query: String
    var searchedAt: Date

    init(query: String, searchedAt: Date) {
        self.query = query
        self.searchedAt = searchedAt
    }
}

@Model
final class CachedResponse {
    @Attribute(.unique) var key: String
    var data: Data
    var fetchedAt: Date

    init(key: String, data: Data, fetchedAt: Date) {
        self.key = key
        self.data = data
        self.fetchedAt = fetchedAt
    }
}

let storedModelTypes: [any PersistentModel.Type] = [
    SavedMovie.self,
    RemovedSavedMovie.self,
    SearchHistoryEntry.self,
    CachedResponse.self,
]
