import Foundation
import Supabase
import Testing

@testable import MyNextMovie

@MainActor
struct MovieFiltersValidationTests {
    @Test func keepsValidFilters() {
        let filters = makeFilters(
            genreIds: [genreIdComedy],
            fromYear: 1990,
            toYear: 1999,
            people: ["Keanu Reeves"],
            keywords: ["time travel"],
            title: "The Matrix"
        )

        #expect(validatedFilters(filters, currentYear: 2026) == filters)
    }

    @Test func dropsUnknownAndRepeatedGenres() {
        let result = validatedFilters(
            makeFilters(genreIds: [genreIdComedy, -1, genreIdComedy, genreIdDrama]),
            currentYear: 2026
        )
        #expect(result.genreIds == [genreIdComedy, genreIdDrama])
    }

    @Test func keepsAtMostThreeOfEach() {
        let result = validatedFilters(
            makeFilters(
                genreIds: [28, 12, 16, 35],
                people: ["One", "Two", "Three", "Four"],
                keywords: ["one", "two", "three", "four"]
            ),
            currentYear: 2026
        )
        #expect(result.genreIds.count == maxFilterValues)
        #expect(result.people == ["One", "Two", "Three"])
        #expect(result.keywords == ["one", "two", "three"])
    }

    @Test func dropsYearsOutOfRange() {
        let tooEarly = validatedFilters(
            makeFilters(fromYear: earliestMovieYear - 1, toYear: 2000),
            currentYear: 2026
        )
        let tooLate = validatedFilters(
            makeFilters(fromYear: 2000, toYear: 2032),
            currentYear: 2026
        )
        #expect(tooEarly.fromYear == noYear)
        #expect(tooEarly.toYear == 2000)
        #expect(tooLate.fromYear == 2000)
        #expect(tooLate.toYear == noYear)
    }

    @Test func swapsYearsInWrongOrder() {
        let result = validatedFilters(
            makeFilters(fromYear: 2000, toYear: 1990),
            currentYear: 2026
        )
        #expect(result.fromYear == 1990)
        #expect(result.toYear == 2000)
    }

    @Test func trimsAndDropsEmptyOrRepeatedNames() {
        let result = validatedFilters(
            makeFilters(
                people: [" Keanu Reeves ", "", "keanu reeves", " Lana Wachowski "],
                keywords: [" time travel ", " ", "TIME TRAVEL", "simulation"],
                title: "  The Matrix  "
            ),
            currentYear: 2026
        )
        #expect(result.people == ["Keanu Reeves", "Lana Wachowski"])
        #expect(result.keywords == ["time travel", "simulation"])
        #expect(result.title == "The Matrix")
    }

    @Test func emptyFiltersHaveNoFilter() {
        #expect(!hasAnyFilter(noMovieFilters))
    }

    @Test func onlyUnknownGenresLeaveNoFilter() {
        let result = validatedFilters(makeFilters(genreIds: [-1]), currentYear: 2026)
        #expect(!hasAnyFilter(result))
    }
}

@MainActor
struct MovieFiltersTextTests {
    @Test func summaryListsEveryFilter() {
        let filters = makeFilters(
            genreIds: [genreIdComedy, genreIdDrama],
            fromYear: 1990,
            toYear: 1999,
            people: ["Keanu Reeves"],
            keywords: ["time travel"],
            title: "The Matrix"
        )
        #expect(
            filtersSummary(filters)
                == "Comedy · Drama · 1990–1999 · Keanu Reeves · time travel · The Matrix"
        )
    }

    @Test func yearRangeTextCoversEveryCase() {
        #expect(yearRangeText(fromYear: noYear, toYear: noYear) == "")
        #expect(yearRangeText(fromYear: 1990, toYear: noYear) == "1990 or later")
        #expect(yearRangeText(fromYear: noYear, toYear: 1999) == "up to 1999")
        #expect(yearRangeText(fromYear: 1990, toYear: 1999) == "1990–1999")
        #expect(yearRangeText(fromYear: 1999, toYear: 1999) == "1999")
    }

    @Test func decodesAnswerOfTheFunction() throws {
        let json = """
            {
              "genreIds": [35],
              "fromYear": 1990,
              "toYear": 1999,
              "people": ["Keanu Reeves"],
              "keywords": [],
              "title": ""
            }
            """
        let filters = try JSONDecoder().decode(MovieFilters.self, from: Data(json.utf8))
        #expect(filters.genreIds == [genreIdComedy])
        #expect(filters.fromYear == 1990)
        #expect(filters.toYear == 1999)
        #expect(filters.people == ["Keanu Reeves"])
    }

    @Test func errorAnswerShowsItsMessage() {
        let data = Data(#"{"message":"Sign in to search."}"#.utf8)
        let error = FunctionsError.httpError(code: 401, data: data)
        #expect(functionErrorMessage(error) == "Sign in to search.")
    }
}

@MainActor
private func makeFilters(
    genreIds: [Int] = [],
    fromYear: Int = noYear,
    toYear: Int = noYear,
    people: [String] = [],
    keywords: [String] = [],
    title: String = ""
) -> MovieFilters {
    MovieFilters(
        genreIds: genreIds,
        fromYear: fromYear,
        toYear: toYear,
        people: people,
        keywords: keywords,
        title: title
    )
}
