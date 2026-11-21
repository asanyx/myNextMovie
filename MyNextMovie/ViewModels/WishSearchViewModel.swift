import Foundation
import Observation

let maxWishLength = 200
let noFiltersPlainSearchReason = "The AI search did not find any filters."

func yearOfToday() -> Int {
    Calendar.current.component(.year, from: .now)
}

@Observable
final class WishSearchViewModel {
    var wish = ""
    private(set) var state = LoadState.idle
    private(set) var movies: [Movie] = []
    private(set) var errorMessage = ""
    private(set) var filters = noMovieFilters
    private(set) var plainSearchReason = ""

    private let parseWish: MovieWishParser
    private let searchByFilters: FilteredMovieSearch
    private let searchByText: MovieSearch
    private let currentYear: Int

    init(
        parseWish: @escaping MovieWishParser,
        searchByFilters: @escaping FilteredMovieSearch,
        searchByText: @escaping MovieSearch,
        currentYear: Int = yearOfToday()
    ) {
        self.parseWish = parseWish
        self.searchByFilters = searchByFilters
        self.searchByText = searchByText
        self.currentYear = currentYear
    }

    var isPlainSearch: Bool {
        !plainSearchReason.isEmpty
    }

    var canSearch: Bool {
        !wish.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && state != .loading
    }

    func search() async {
        let trimmedWish = wish.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedWish.isEmpty else {
            return
        }

        state = .loading
        errorMessage = ""
        plainSearchReason = ""
        filters = noMovieFilters

        do {
            let modelFilters: MovieFilters
            do {
                modelFilters = try await parseWish(trimmedWish)
                filters = validatedFilters(modelFilters, currentYear: currentYear)
            } catch {
                plainSearchReason = error.localizedDescription
                movies = try await searchByText(trimmedWish, noGenreId)
                state = .loaded
                return
            }

            if hasAnyFilter(filters) {
                movies = try await searchByFilters(filters)
            } else {
                plainSearchReason = noFiltersPlainSearchReason
                movies = try await searchByText(trimmedWish, noGenreId)
            }
            state = .loaded
        } catch {
            errorMessage = error.localizedDescription
            state = .failed
        }
    }
}
