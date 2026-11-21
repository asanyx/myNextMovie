import Foundation
import SwiftData

func syncSavedMovies(
    _ context: ModelContext,
    cloud: SavedMoviesCloud
) async throws {
    try await removeMarkedMovies(context, cloud: cloud)
    try await mergeCloudMovies(context, cloud: cloud)
    try await uploadNewMovies(context, cloud: cloud)
}

func cloudMovieFromSaved(_ savedMovie: SavedMovie) -> CloudSavedMovie {
    return CloudSavedMovie(
        id: savedMovie.movieId,
        title: savedMovie.title,
        overview: savedMovie.overview,
        releaseDate: savedMovie.releaseDate,
        posterPath: savedMovie.posterPath,
        voteAverage: savedMovie.voteAverage,
        genreIds: savedMovie.genreIds,
        savedAt: savedMovie.savedAt
    )
}

func movieFromCloud(_ cloudMovie: CloudSavedMovie) -> Movie {
    return Movie(
        id: cloudMovie.id,
        title: cloudMovie.title,
        overview: cloudMovie.overview,
        releaseDate: cloudMovie.releaseDate,
        posterPath: cloudMovie.posterPath,
        voteAverage: cloudMovie.voteAverage,
        genreIds: cloudMovie.genreIds
    )
}

private func removeMarkedMovies(
    _ context: ModelContext,
    cloud: SavedMoviesCloud
) async throws {
    let movieIds = fetchAllRemovalMarks(context).map(\.movieId)

    for movieId in movieIds {
        try await cloud.removeMovie(movieId)
        for currentMark in fetchRemovalMarks(context, movieId: movieId) {
            context.delete(currentMark)
        }
    }
}

private func mergeCloudMovies(
    _ context: ModelContext,
    cloud: SavedMoviesCloud
) async throws {
    let cloudMovies = try await cloud.fetchMovies()
    let cloudMovieIds = Set(cloudMovies.map(\.id))
    let removalMarkIds = Set(fetchAllRemovalMarks(context).map(\.movieId))
    let localMovies = fetchAllSavedMovies(context)

    for localMovie in localMovies
    where localMovie.isInCloud
        && !cloudMovieIds.contains(localMovie.movieId)
        && !removalMarkIds.contains(localMovie.movieId)
    {
        context.delete(localMovie)
    }

    for cloudMovie in cloudMovies {
        if !fetchRemovalMarks(context, movieId: cloudMovie.id).isEmpty {
            continue
        }

        let savedCopies = fetchSavedMovies(context, movieId: cloudMovie.id)
        if savedCopies.isEmpty {
            context.insert(
                SavedMovie(
                    movie: movieFromCloud(cloudMovie),
                    savedAt: cloudMovie.savedAt,
                    isInCloud: true
                )
            )
        } else {
            for savedCopy in savedCopies {
                savedCopy.isInCloud = true
            }
        }
    }
}

private func uploadNewMovies(
    _ context: ModelContext,
    cloud: SavedMoviesCloud
) async throws {
    let unsyncedMovies = fetchAllSavedMovies(context).filter { !$0.isInCloud }
    if unsyncedMovies.isEmpty {
        return
    }

    let movieIds = unsyncedMovies.map(\.movieId)
    let cloudMovies = unsyncedMovies.map(cloudMovieFromSaved)

    try await cloud.uploadMovies(cloudMovies)

    for movieId in movieIds {
        let currentCopies = fetchSavedMovies(context, movieId: movieId)
        if currentCopies.isEmpty {
            if fetchRemovalMarks(context, movieId: movieId).isEmpty {
                context.insert(RemovedSavedMovie(movieId: movieId))
            }
        } else {
            for currentCopy in currentCopies {
                currentCopy.isInCloud = true
            }
        }
    }
}

private func fetchAllSavedMovies(_ context: ModelContext) -> [SavedMovie] {
    return (try? context.fetch(FetchDescriptor<SavedMovie>())) ?? []
}

private func fetchAllRemovalMarks(_ context: ModelContext) -> [RemovedSavedMovie] {
    return (try? context.fetch(FetchDescriptor<RemovedSavedMovie>())) ?? []
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
