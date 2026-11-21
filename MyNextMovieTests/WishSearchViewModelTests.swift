import Testing

@testable import MyNextMovie

@MainActor
struct WishSearchViewModelTests {
    @Test func searchesWithTheFiltersOfTheModel() async {
        let expectedFilters = makeWishFilters(
            genreIds: [genreIdComedy],
            fromYear: 1990,
            toYear: 1999,
            people: ["Keanu Reeves"]
        )
        var searchedFilters = noMovieFilters
        let viewModel = WishSearchViewModel(
            parseWish: { _ in expectedFilters },
            searchByFilters: { filters in
                searchedFilters = filters
                return [testMovies[0]]
            },
            searchByText: { _, _ in [] },
            currentYear: 2026
        )
        viewModel.wish = "something light with Keanu from the 90s"

        await viewModel.search()

        #expect(searchedFilters == expectedFilters)
        #expect(viewModel.filters == expectedFilters)
        #expect(viewModel.movies == [testMovies[0]])
        #expect(viewModel.state == .loaded)
        #expect(!viewModel.isPlainSearch)
    }

    @Test func checksTheModelAnswerBeforeSearching() async {
        let modelAnswer = makeWishFilters(
            genreIds: [genreIdComedy, -1, genreIdComedy],
            fromYear: 2000,
            toYear: 1990,
            people: [" Keanu Reeves ", "", "keanu reeves"]
        )
        var searchedFilters = noMovieFilters
        let viewModel = WishSearchViewModel(
            parseWish: { _ in modelAnswer },
            searchByFilters: { filters in
                searchedFilters = filters
                return []
            },
            searchByText: { _, _ in [] },
            currentYear: 2026
        )
        viewModel.wish = "a wish"

        await viewModel.search()

        #expect(searchedFilters.genreIds == [genreIdComedy])
        #expect(searchedFilters.fromYear == 1990)
        #expect(searchedFilters.toYear == 2000)
        #expect(searchedFilters.people == ["Keanu Reeves"])
    }

    @Test func fallsBackToTextSearchWhenTheModelFails() async {
        var receivedQuery = ""
        var receivedGenre = genreIdAction
        let viewModel = WishSearchViewModel(
            parseWish: { _ in throw NoConnection() },
            searchByFilters: { _ in [] },
            searchByText: { query, genreId in
                receivedQuery = query
                receivedGenre = genreId
                return [testMovies[0]]
            },
            currentYear: 2026
        )
        viewModel.wish = "  matrix\n"

        await viewModel.search()

        #expect(receivedQuery == "matrix")
        #expect(receivedGenre == noGenreId)
        #expect(viewModel.movies == [testMovies[0]])
        #expect(viewModel.plainSearchReason == "No connection")
        #expect(viewModel.isPlainSearch)
        #expect(viewModel.state == .loaded)
    }

    @Test func fallsBackToTextSearchWithoutFilters() async {
        var textSearchCount = 0
        let viewModel = WishSearchViewModel(
            parseWish: { _ in noMovieFilters },
            searchByFilters: { _ in [] },
            searchByText: { _, _ in
                textSearchCount += 1
                return []
            },
            currentYear: 2026
        )
        viewModel.wish = "matrix"

        await viewModel.search()

        #expect(textSearchCount == 1)
        #expect(viewModel.isPlainSearch)
        #expect(!viewModel.plainSearchReason.isEmpty)
        #expect(viewModel.state == .loaded)
    }

    @Test func showsErrorWhenTheMovieSearchFails() async {
        let viewModel = WishSearchViewModel(
            parseWish: { _ in makeWishFilters(genreIds: [genreIdDrama]) },
            searchByFilters: { _ in throw NoConnection() },
            searchByText: { _, _ in [] },
            currentYear: 2026
        )
        viewModel.wish = "a drama"

        await viewModel.search()

        #expect(viewModel.state == .failed)
        #expect(viewModel.errorMessage == "No connection")
    }

    @Test func emptyWishDoesNothing() async {
        var parseCount = 0
        let viewModel = WishSearchViewModel(
            parseWish: { _ in
                parseCount += 1
                return noMovieFilters
            },
            searchByFilters: { _ in [] },
            searchByText: { _, _ in [] },
            currentYear: 2026
        )
        viewModel.wish = " \n "

        await viewModel.search()

        #expect(parseCount == 0)
        #expect(viewModel.state == .idle)
    }

    @Test func nextSearchForgetsThePlainSearchReason() async {
        let parser = TestWishParser()
        let viewModel = WishSearchViewModel(
            parseWish: parser.parse,
            searchByFilters: { _ in [] },
            searchByText: { _, _ in [] },
            currentYear: 2026
        )
        viewModel.wish = "first"

        await viewModel.search()
        #expect(viewModel.isPlainSearch)

        viewModel.wish = "second"
        await viewModel.search()

        #expect(!viewModel.isPlainSearch)
        #expect(viewModel.plainSearchReason.isEmpty)
        #expect(viewModel.filters.genreIds == [genreIdComedy])
    }
}

@MainActor
private final class TestWishParser {
    private var callCount = 0

    func parse(_ wish: String) async throws -> MovieFilters {
        callCount += 1
        if callCount == 1 {
            throw NoConnection()
        }
        return makeWishFilters(genreIds: [genreIdComedy])
    }
}

@MainActor
private func makeWishFilters(
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
