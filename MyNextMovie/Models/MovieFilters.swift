import Foundation

nonisolated struct MovieFilters: Codable, Equatable {
    let genreIds: [Int]
    let fromYear: Int
    let toYear: Int
    let people: [String]
    let keywords: [String]
    let title: String
}

let noYear = 0
let earliestMovieYear = 1880
let yearsAheadOfToday = 5
let maxFilterValues = 3

let noMovieFilters = MovieFilters(
    genreIds: [],
    fromYear: noYear,
    toYear: noYear,
    people: [],
    keywords: [],
    title: ""
)

func validatedFilters(_ filters: MovieFilters, currentYear: Int) -> MovieFilters {
    let validGenreIds = Set(genreTable.map(\.id))
    var seenGenreIds: Set<Int> = []
    let genreIds = filters.genreIds.filter { genreId in
        validGenreIds.contains(genreId) && seenGenreIds.insert(genreId).inserted
    }.prefix(maxFilterValues)

    let latestYear = currentYear + yearsAheadOfToday
    var fromYear = validYear(filters.fromYear, latestYear: latestYear)
    var toYear = validYear(filters.toYear, latestYear: latestYear)
    if fromYear != noYear && toYear != noYear && fromYear > toYear {
        swap(&fromYear, &toYear)
    }

    return MovieFilters(
        genreIds: Array(genreIds),
        fromYear: fromYear,
        toYear: toYear,
        people: cleanedNames(filters.people),
        keywords: cleanedNames(filters.keywords),
        title: filters.title.trimmingCharacters(in: .whitespacesAndNewlines)
    )
}

func hasAnyFilter(_ filters: MovieFilters) -> Bool {
    !filters.genreIds.isEmpty
        || filters.fromYear != noYear
        || filters.toYear != noYear
        || !filters.people.isEmpty
        || !filters.keywords.isEmpty
        || !filters.title.isEmpty
}

func moviesMatchingFilters(_ movies: [Movie], _ filters: MovieFilters) -> [Movie] {
    movies.filter { movie in
        let matchesGenre =
            filters.genreIds.isEmpty
            || movie.genreIds.contains(where: filters.genreIds.contains)
        guard matchesGenre else { return false }

        if filters.fromYear == noYear && filters.toYear == noYear {
            return true
        }
        guard let year = Int(releaseYear(movie)) else { return false }
        if filters.fromYear != noYear && year < filters.fromYear {
            return false
        }
        if filters.toYear != noYear && year > filters.toYear {
            return false
        }
        return true
    }
}

func filtersSummary(_ filters: MovieFilters) -> String {
    var parts = filters.genreIds.map(genreName)
    let years = yearRangeText(fromYear: filters.fromYear, toYear: filters.toYear)
    if !years.isEmpty {
        parts.append(years)
    }
    parts.append(contentsOf: filters.people)
    parts.append(contentsOf: filters.keywords)
    if !filters.title.isEmpty {
        parts.append(filters.title)
    }
    return parts.joined(separator: textSeparator)
}

func yearRangeText(fromYear: Int, toYear: Int) -> String {
    switch (fromYear, toYear) {
    case (noYear, noYear):
        return ""
    case (noYear, _):
        return "up to \(toYear)"
    case (_, noYear):
        return "\(fromYear) or later"
    case (let fromYear, let toYear) where fromYear == toYear:
        return String(fromYear)
    default:
        return "\(fromYear)–\(toYear)"
    }
}

private func validYear(_ year: Int, latestYear: Int) -> Int {
    (earliestMovieYear...latestYear).contains(year) ? year : noYear
}

private func cleanedNames(_ names: [String]) -> [String] {
    var seen: Set<String> = []
    var result: [String] = []
    for name in names {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { continue }
        let comparisonKey = cleaned.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: .current
        )
        guard seen.insert(comparisonKey).inserted else { continue }
        result.append(cleaned)
        if result.count == maxFilterValues {
            break
        }
    }
    return result
}
