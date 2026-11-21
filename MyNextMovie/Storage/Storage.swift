import Foundation
import SwiftData

let maxSearchHistoryCount = 10

func fetchSavedMovies(_ context: ModelContext, movieId: Int) -> [SavedMovie] {
    let descriptor = FetchDescriptor<SavedMovie>(
        predicate: #Predicate { savedMovie in
            savedMovie.movieId == movieId
        }
    )
    return (try? context.fetch(descriptor)) ?? []
}

func isMovieSaved(_ context: ModelContext, movieId: Int) -> Bool {
    return !fetchSavedMovies(context, movieId: movieId).isEmpty
}

func toggleSavedMovie(_ context: ModelContext, _ movie: Movie, now: Date) {
    let savedCopies = fetchSavedMovies(context, movieId: movie.id)
    if savedCopies.isEmpty {
        deleteRemovalMarks(context, movieId: movie.id)
        context.insert(SavedMovie(movie: movie, savedAt: now, isInCloud: false))
    } else {
        let shouldRemoveFromCloud = savedCopies.contains { $0.isInCloud }
        for savedCopy in savedCopies {
            context.delete(savedCopy)
        }
        if shouldRemoveFromCloud && fetchRemovalMarks(context, movieId: movie.id).isEmpty {
            context.insert(RemovedSavedMovie(movieId: movie.id))
        }
    }
}

func clearSavedMovies(_ context: ModelContext) {
    let savedMovies = (try? context.fetch(FetchDescriptor<SavedMovie>())) ?? []
    for savedMovie in savedMovies {
        context.delete(savedMovie)
    }

    let removalMarks = (try? context.fetch(FetchDescriptor<RemovedSavedMovie>())) ?? []
    for removalMark in removalMarks {
        context.delete(removalMark)
    }
}

private func fetchRemovalMarks(
    _ context: ModelContext,
    movieId: Int
) -> [RemovedSavedMovie] {
    let descriptor = FetchDescriptor<RemovedSavedMovie>(
        predicate: #Predicate { removalMark in
            removalMark.movieId == movieId
        }
    )
    return (try? context.fetch(descriptor)) ?? []
}

private func deleteRemovalMarks(_ context: ModelContext, movieId: Int) {
    for removalMark in fetchRemovalMarks(context, movieId: movieId) {
        context.delete(removalMark)
    }
}

func movieFromSaved(_ savedMovie: SavedMovie) -> Movie {
    return Movie(
        id: savedMovie.movieId,
        title: savedMovie.title,
        overview: savedMovie.overview,
        releaseDate: savedMovie.releaseDate,
        posterPath: savedMovie.posterPath,
        voteAverage: savedMovie.voteAverage,
        genreIds: savedMovie.genreIds
    )
}

func moviesFromSaved(_ savedMovies: [SavedMovie]) -> [Movie] {
    return savedMovies.map(movieFromSaved)
}

func recordSearch(_ context: ModelContext, query: String, now: Date) {
    let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedQuery.isEmpty {
        return
    }

    let descriptor = FetchDescriptor<SearchHistoryEntry>(
        predicate: #Predicate { entry in
            entry.query == trimmedQuery
        }
    )
    if let existingEntry = try? context.fetch(descriptor).first {
        existingEntry.searchedAt = now
    } else {
        context.insert(SearchHistoryEntry(query: trimmedQuery, searchedAt: now))
    }
    removeOldSearches(context)
}

func recentSearches(_ context: ModelContext) -> [SearchHistoryEntry] {
    let descriptor = FetchDescriptor<SearchHistoryEntry>(
        sortBy: [SortDescriptor(\.searchedAt, order: .reverse)]
    )
    let allEntries = (try? context.fetch(descriptor)) ?? []
    return Array(allEntries.prefix(maxSearchHistoryCount))
}

func clearSearchHistory(_ context: ModelContext) {
    let descriptor = FetchDescriptor<SearchHistoryEntry>()
    let entries = (try? context.fetch(descriptor)) ?? []
    for entry in entries {
        context.delete(entry)
    }
}

private func removeOldSearches(_ context: ModelContext) {
    let sortedEntries = recentSearchesWithoutLimit(context)
    for oldEntry in sortedEntries.dropFirst(maxSearchHistoryCount) {
        context.delete(oldEntry)
    }
}

private func recentSearchesWithoutLimit(_ context: ModelContext) -> [SearchHistoryEntry] {
    let descriptor = FetchDescriptor<SearchHistoryEntry>(
        sortBy: [SortDescriptor(\.searchedAt, order: .reverse)]
    )
    return (try? context.fetch(descriptor)) ?? []
}

func storeCachedResponse(_ context: ModelContext, key: String, data: Data, now: Date) {
    let descriptor = FetchDescriptor<CachedResponse>(
        predicate: #Predicate { response in
            response.key == key
        }
    )
    if let cachedResponse = try? context.fetch(descriptor).first {
        cachedResponse.data = data
        cachedResponse.fetchedAt = now
    } else {
        context.insert(CachedResponse(key: key, data: data, fetchedAt: now))
    }
}

func cachedResponseData(_ context: ModelContext, key: String) -> Data {
    let descriptor = FetchDescriptor<CachedResponse>(
        predicate: #Predicate { response in
            response.key == key
        }
    )
    return (try? context.fetch(descriptor).first?.data) ?? Data()
}

func fetchWithCacheFallback(
    _ context: ModelContext,
    key: String,
    fetch: () async throws -> Data
) async throws -> Data {
    do {
        let data = try await fetch()
        storeCachedResponse(context, key: key, data: data, now: .now)
        return data
    } catch {
        let cachedData = cachedResponseData(context, key: key)
        if !cachedData.isEmpty {
            return cachedData
        }
        throw error
    }
}
