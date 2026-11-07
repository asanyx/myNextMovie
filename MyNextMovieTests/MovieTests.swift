import Foundation
import Testing

@testable import MyNextMovie

/// A genre id that TMDB does not use.
let genreIdUnknownToTMDB = 1

@MainActor
struct MovieTests {
    @Test func releaseYearIsFirstFourCharactersOfDate() {
        #expect(releaseYear(makeMovie(releaseDate: "1999-03-31")) == "1999")
    }

    @Test func releaseYearIsEmptyWithoutDate() {
        #expect(releaseYear(makeMovie(releaseDate: "")) == "")
    }

    @Test func releaseYearIsEmptyForTooShortDate() {
        #expect(releaseYear(makeMovie(releaseDate: "199")) == "")
    }

    @Test func ratingHasOneDecimal() {
        #expect(formattedRating(makeMovie(voteAverage: 8.24)) == "8.2")
        #expect(formattedRating(makeMovie(voteAverage: 7)) == "7.0")
    }

    @Test
    func ratingWithStarStartsWithStar() {
        #expect(ratingWithStar(makeMovie(voteAverage: 8.24)) == "★ 8.2")
    }

    @Test
    func yearAndRatingLeavesOutUnknownYear() {
        let movieWithYear = makeMovie(releaseDate: "2014-11-05", voteAverage: 8.4)
        let movieWithoutYear = makeMovie(releaseDate: "", voteAverage: 8.4)

        #expect(yearAndRating(movieWithYear) == "2014 · ★ 8.4")
        #expect(yearAndRating(movieWithoutYear) == "★ 8.4")
    }

    @Test func posterURLUsesTMDBImageHost() {
        let posterAddress = posterURL(makeMovie(posterPath: "/poster.jpg"))
        #expect(posterAddress == URL(string: tmdbPosterBaseURL + "/poster.jpg"))
    }

    @Test func movieWithoutPosterPathHasNoPoster() {
        #expect(posterURL(makeMovie(posterPath: nil)) == nil)
        #expect(!hasPoster(makeMovie(posterPath: nil)))
        #expect(!hasPoster(makeMovie(posterPath: "")))
    }

    @Test func subtitleJoinsYearAndMainGenre() {
        let actionMovieFrom1999 = makeMovie(
            releaseDate: "1999-03-31",
            genreIds: [genreIdAction, genreIdScienceFiction]
        )
        #expect(movieSubtitle(actionMovieFrom1999) == "1999 · Action")
    }

    @Test func subtitleLeavesOutMissingParts() {
        // Only a genre gives "Science Fiction"
        let onlyGenre = makeMovie(
            releaseDate: "",
            genreIds: [genreIdScienceFiction]
        )
        #expect(movieSubtitle(onlyGenre) == "Science Fiction")

        // Only a date gives "1999"
        let onlyDate = makeMovie(
            releaseDate: "1999-03-31",
            genreIds: []
        )
        #expect(movieSubtitle(onlyDate) == "1999")

        // Neither gives an empty subtitle
        let neither = makeMovie(
            releaseDate: "",
            genreIds: []
        )
        #expect(movieSubtitle(neither) == "")
    }
}

@MainActor
struct GenreTests {
    @Test func tableHasEveryTMDBGenre() {
        let numberOfTMDBMovieGenres = 19
        #expect(genreTable.count == numberOfTMDBMovieGenres)
    }

    @Test func tableIsSortedByName() {
        for tablePosition in 1..<genreTable.count {
            let previousGenreName = genreTable[tablePosition - 1].name
            #expect(previousGenreName < genreTable[tablePosition].name)
        }
    }

    @Test func nameAndSymbolForKnownGenreId() {
        #expect(genreName(genreIdScienceFiction) == "Science Fiction")
        #expect(genreSymbolName(genreIdScienceFiction) == "atom")
    }

    @Test func fallbacksForUnknownGenreId() {
        #expect(positionInGenreTable(genreIdUnknownToTMDB) == genreNotInTable)
        #expect(genreName(genreIdUnknownToTMDB) == unknownGenreName)
        #expect(genreSymbolName(genreIdUnknownToTMDB) == unknownGenreSymbolName)
    }

    @Test func knownGenreIdsSkipUnknownIds() {
        let movieWithUnknownGenre = makeMovie(
            genreIds: [genreIdAction, genreIdUnknownToTMDB, genreIdScienceFiction]
        )
        #expect(knownGenreIds(movieWithUnknownGenre) == [genreIdAction, genreIdScienceFiction])
    }

    @Test
    func mainGenreIdIsFirstKnownGenre() {
        let movieWithMixedGenres = makeMovie(
            genreIds: [genreIdUnknownToTMDB, genreIdScienceFiction, genreIdAction]
        )
        #expect(mainGenreId(movieWithMixedGenres) == genreIdScienceFiction)

        let movieWithOnlyUnknown = makeMovie(
            genreIds: [genreIdUnknownToTMDB]
        )
        #expect(mainGenreId(movieWithOnlyUnknown) == noGenreId)
    }
}

func makeMovie(
    releaseDate: String = "",
    posterPath: String? = nil,
    voteAverage: Double = 0,
    genreIds: [Int] = []
) -> Movie {
    return Movie(
        id: 1,
        title: "Test",
        overview: "",
        releaseDate: releaseDate,
        posterPath: posterPath,
        voteAverage: voteAverage,
        genreIds: genreIds
    )
}
