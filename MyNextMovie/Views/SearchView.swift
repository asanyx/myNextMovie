import SwiftData
import SwiftUI

/// How long to wait after the last keystroke before searching.
private let searchDelayAfterTyping = Duration.milliseconds(300)
private let searchInputKeySeparator = "|"

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: SearchViewModel
    @State private var wishViewModel: WishSearchViewModel
    @State private var isShowingAIResults = false
    private let loadDetails: MovieDetailsLoader

    init(
        viewModel: SearchViewModel,
        wishViewModel: WishSearchViewModel,
        loadDetails: @escaping MovieDetailsLoader
    ) {
        _viewModel = State(initialValue: viewModel)
        _wishViewModel = State(initialValue: wishViewModel)
        self.loadDetails = loadDetails
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GenreFilter(
                    selectedGenreId: viewModel.selectedGenreId,
                    toggleGenre: viewModel.toggleGenre
                )
                if !viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    WishSearchControl(
                        isShowingResults: isShowingAIResults,
                        summary: wishSearchSummary,
                        canSearch: wishViewModel.state != .loading,
                        askAI: askAI
                    )
                }
                SearchContent(
                    searchViewModel: viewModel,
                    wishViewModel: wishViewModel,
                    isShowingAIResults: isShowingAIResults,
                    selectQuery: selectQuery
                )
                .frame(maxHeight: .infinity)
            }
            .navigationTitle("Search")
            .searchable(
                text: $viewModel.query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Title or keyword"
            )
            .onSubmit(of: .search, askAI)
            .onChange(of: viewModel.query) {
                isShowingAIResults = false
            }
            .onChange(of: viewModel.selectedGenreId) {
                isShowingAIResults = false
            }
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailView(movie: movie, loadDetails: loadDetails)
            }
            .task(id: searchInputKey(viewModel.query, viewModel.selectedGenreId)) {
                await searchAfterPause()
            }
        }
    }

    private var wishSearchSummary: String {
        if wishViewModel.isPlainSearch {
            return wishViewModel.plainSearchReason
        }
        let summary = filtersSummary(wishViewModel.filters)
        return summary.isEmpty ? "Finding filters…" : summary
    }

    private func searchAfterPause() async {
        try? await Task.sleep(for: searchDelayAfterTyping)
        if Task.isCancelled {
            return
        }
        await viewModel.search()
    }

    private func selectQuery(_ query: String) {
        viewModel.query = query
        recordSearch(modelContext, query: query, now: .now)
    }

    private func askAI() {
        let trimmedQuery = viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty, wishViewModel.state != .loading else {
            return
        }

        let limitedWish = String(trimmedQuery.prefix(maxWishLength))
        wishViewModel.wish = limitedWish
        isShowingAIResults = true
        recordSearch(modelContext, query: limitedWish, now: .now)
        Task {
            await wishViewModel.search()
        }
    }
}

/// Changes whenever the search input changes, which restarts the search task.
private func searchInputKey(_ query: String, _ selectedGenreId: Int) -> String {
    return String(selectedGenreId) + searchInputKeySeparator + query
}

private struct SearchContent: View {
    let searchViewModel: SearchViewModel
    let wishViewModel: WishSearchViewModel
    let isShowingAIResults: Bool
    let selectQuery: (String) -> Void

    var body: some View {
        if isShowingAIResults {
            WishSearchContent(viewModel: wishViewModel)
        } else {
            StandardSearchContent(viewModel: searchViewModel, selectQuery: selectQuery)
        }
    }
}

private struct StandardSearchContent: View {
    let viewModel: SearchViewModel
    let selectQuery: (String) -> Void

    var body: some View {
        switch viewModel.state {
        case .idle:
            SearchStartView(selectQuery: selectQuery)
        case .loading:
            ProgressView()
        case .loaded:
            SearchResults(movies: viewModel.movies, query: viewModel.query)
        case .failed:
            ErrorView(title: "Search failed", message: viewModel.errorMessage) {
                Task { await viewModel.search() }
            }
        }
    }
}

private struct WishSearchContent: View {
    let viewModel: WishSearchViewModel

    var body: some View {
        switch viewModel.state {
        case .idle:
            ProgressView()
        case .loading:
            ProgressView()
        case .loaded:
            SearchResults(movies: viewModel.movies, query: viewModel.wish)
        case .failed:
            ErrorView(title: "Search failed", message: viewModel.errorMessage) {
                Task { await viewModel.search() }
            }
        }
    }
}

private struct WishSearchControl: View {
    let isShowingResults: Bool
    let summary: String
    let canSearch: Bool
    let askAI: () -> Void

    var body: some View {
        if isShowingResults {
            Label(summary, systemImage: symbolNameWish)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, spacingSmall)
        } else {
            Button(action: askAI) {
                Label("Ask AI", systemImage: symbolNameWish)
            }
            .buttonStyle(.bordered)
            .disabled(!canSearch)
            .padding(.bottom, spacingSmall)
        }
    }
}

private struct SearchStartView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SearchHistoryEntry.searchedAt, order: .reverse)
    private var searchHistory: [SearchHistoryEntry]

    let selectQuery: (String) -> Void

    var body: some View {
        if searchHistory.isEmpty {
            ContentUnavailableView(
                "Find a movie",
                systemImage: symbolNameSearch,
                description: Text("Search by title or keyword, or pick a genre.")
            )
        } else {
            List {
                Section {
                    ForEach(searchHistory) { entry in
                        SearchHistoryRow(query: entry.query, selectQuery: selectQuery)
                    }
                } header: {
                    SearchHistoryHeader(clear: clearHistory)
                }
            }
            .listStyle(.plain)
        }
    }

    private func clearHistory() {
        clearSearchHistory(modelContext)
    }
}

private struct SearchHistoryHeader: View {
    let clear: () -> Void

    var body: some View {
        HStack {
            Text("Recent Searches")
            Spacer()
            Button("Clear", action: clear)
                .textCase(nil)
        }
    }
}

private struct SearchHistoryRow: View {
    let query: String
    let selectQuery: (String) -> Void

    var body: some View {
        Button {
            selectQuery(query)
        } label: {
            Label(query, systemImage: "clock.arrow.circlepath")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

/// Every genre as a chip in one row that scrolls sideways.
/// Tapping a chip selects its genre, tapping it again clears the selection.
private struct GenreFilter: View {
    let selectedGenreId: Int
    let toggleGenre: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacingSmall) {
                ForEach(genreTable) { genre in
                    genreFilterChip(genre.id)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, spacingSmall)
        }
        .scrollClipDisabled()
    }

    private func genreFilterChip(_ genreId: Int) -> some View {
        Button {
            toggleGenre(genreId)
        } label: {
            GenreChip(genreId: genreId, isSelected: genreId == selectedGenreId)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SearchView(
        viewModel: SearchViewModel(searchMovies: searchTMDBMovies),
        wishViewModel: WishSearchViewModel(
            parseWish: parseWishWithAI,
            searchByFilters: searchTMDBMoviesByFilters,
            searchByText: searchTMDBMovies
        ),
        loadDetails: fetchMovieDetails
    )
    .modelContainer(for: storedModelTypes, inMemory: true)
}
