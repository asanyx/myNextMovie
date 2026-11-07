/// Any function that returns movies.
/// View models take one as a parameter, so tests and previews
/// can pass sample data while the app passes a TMDB request.
typealias MovieLoader = () async throws -> [Movie]

/// Any function that searches movies by text and genre id. `noGenreId` means any genre.
typealias MovieSearch = (_ query: String, _ genreId: Int) async throws -> [Movie]

/// Any function that loads the appended details for one movie.
typealias MovieDetailsLoader = (_ movieId: Int) async throws -> MovieDetails
