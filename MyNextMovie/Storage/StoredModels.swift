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

    init(movie: Movie, savedAt: Date) {
        movieId = movie.id
        title = movie.title
        overview = movie.overview
        releaseDate = movie.releaseDate
        posterPath = movie.posterPath
        voteAverage = movie.voteAverage
        genreIds = movie.genreIds
        self.savedAt = savedAt
        isInCloud = false
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

let storedModelTypes: [any PersistentModel.Type] = [
    SavedMovie.self,
    SearchHistoryEntry.self,
]
