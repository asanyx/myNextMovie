import Foundation
import Testing

@testable import MyNextMovie

private let matrixDetailsJSON = """
    {
      "id": 603,
      "tagline": "Believe the unbelievable.",
      "runtime": 136,
      "credits": {
        "cast": [
          {
            "id": 6384,
            "name": "Keanu Reeves",
            "character": "Neo",
            "profile_path": "/keanu.jpg"
          },
          {
            "id": 2975,
            "name": "Carrie-Anne Moss",
            "character": "Trinity",
            "profile_path": null
          }
        ],
        "crew": [
          {"id": 9340, "name": "Lana Wachowski", "job": "Director"},
          {"id": 9340, "name": "Lana Wachowski", "job": "Director"},
          {"id": 9341, "name": "Lilly Wachowski", "job": "Director"}
        ]
      },
      "videos": {
        "results": [
          {
            "key": "unofficial-key",
            "site": "YouTube",
            "type": "Trailer",
            "official": false
          },
          {
            "key": "official-key",
            "site": "YouTube",
            "type": "Trailer",
            "official": true
          }
        ]
      },
      "release_dates": {
        "results": [
          {
            "iso_3166_1": "PL",
            "release_dates": [
              {
                "certification": "",
                "release_date": "1999-03-31T00:00:00.000Z",
                "type": 3
              },
              {
                "certification": "16",
                "release_date": "1999-03-31T00:00:00.000Z",
                "type": 3
              }
            ]
          },
          {
            "iso_3166_1": "US",
            "release_dates": [{
              "certification": "R",
              "release_date": "1999-03-31T00:00:00.000Z",
              "type": 3
            }]
          }
        ]
      },
      "watch/providers": {
        "results": {
          "PL": {
            "link": "https://www.themoviedb.org/movie/603/watch?locale=PL",
            "flatrate": [
              {
                "provider_id": 119,
                "provider_name": "Amazon Prime Video",
                "logo_path": "/prime.png"
              }
            ],
            "rent": [
              {
                "provider_id": 2,
                "provider_name": "Apple TV",
                "logo_path": "/apple.png"
              }
            ]
          }
        }
      },
      "recommendations": {
        "results": [
          {
            "id": 27205,
            "title": "Inception",
            "overview": "A dream within a dream.",
            "release_date": "2010-07-15",
            "poster_path": "/inception.jpg",
            "vote_average": 8.4,
            "genre_ids": [28, 878]
          }
        ]
      }
    }
    """

private let announcedMovieDetailsJSON = """
    {
      "id": 999,
      "tagline": "",
      "runtime": null,
      "credits": {"cast": [], "crew": []},
      "videos": {"results": []},
      "release_dates": {"results": []},
      "watch/providers": {"results": {}},
      "recommendations": {"results": []}
    }
    """

@MainActor
struct MovieDetailsDecodingTests {
    @Test func decodesTaglineAndRuntime() throws {
        let details = try decodedMatrixDetails()

        #expect(details.id == 603)
        #expect(details.tagline == "Believe the unbelievable.")
        #expect(details.runtime == 136)
    }

    @Test func decodesCastWithAndWithoutPhoto() throws {
        let cast = try decodedMatrixDetails().credits.cast

        #expect(try #require(cast.first).profilePath == "/keanu.jpg")
        #expect(try #require(cast.last).profilePath == nil)
    }

    @Test func decodesWatchProvidersUnderSlashKey() throws {
        let providers = try #require(
            decodedMatrixDetails().watchProviders.results["PL"]
        )

        #expect(providers.flatrate?.count == 1)
        #expect(providers.rent?.count == 1)
        #expect(providers.buy == nil)
    }

    @Test func decodesCountryCodeOfReleaseDates() throws {
        let releaseDates = try decodedMatrixDetails().releaseDates.results

        #expect(try #require(releaseDates.first).countryCode == "PL")
    }

    @Test func decodesRecommendationsAsMovies() throws {
        let recommendations = try decodedMatrixDetails().recommendations.results

        #expect(try #require(recommendations.first).title == "Inception")
        #expect(try #require(recommendations.first).genreIds == [28, 878])
    }

    @Test func decodesAnnouncedMovieWithoutRuntime() throws {
        let details = try decodeTMDBMovieDetails(
            Data(announcedMovieDetailsJSON.utf8)
        )

        #expect(details.runtime == nil)
        #expect(formattedRuntime(details).isEmpty)
        #expect(
            !hasWatchProviders(
                watchProviders(details, regionCode: "PL")
            )
        )
    }
}

@MainActor
struct MovieDetailsTests {
    @Test func runtimeInHoursAndMinutes() {
        #expect(formattedRuntime(makeMovieDetails(runtime: 136)) == "2h 16m")
        #expect(formattedRuntime(makeMovieDetails(runtime: 120)) == "2h 0m")
    }

    @Test func runtimeUnderAnHourHasOnlyMinutes() {
        #expect(formattedRuntime(makeMovieDetails(runtime: 45)) == "45m")
    }

    @Test func runtimeIsEmptyWhenUnknown() {
        #expect(formattedRuntime(makeMovieDetails(runtime: nil)).isEmpty)
        #expect(formattedRuntime(makeMovieDetails(runtime: 0)).isEmpty)
    }

    @Test func directorsAreListedOnceEach() throws {
        #expect(
            directorNames(try decodedMatrixDetails())
                == "Lana Wachowski, Lilly Wachowski"
        )
    }

    @Test func directorsAreEmptyWithoutDirector() {
        let details = makeMovieDetails(
            crew: [CrewMember(id: 1, name: "Writer", job: "Writer")]
        )

        #expect(directorNames(details).isEmpty)
    }

    @Test func certificationSkipsEmptyOnes() throws {
        let details = try decodedMatrixDetails()

        #expect(ageCertification(details, regionCode: "PL") == "16")
        #expect(ageCertification(details, regionCode: "US") == "R")
    }

    @Test func certificationIsEmptyForOtherCountry() throws {
        #expect(
            ageCertification(try decodedMatrixDetails(), regionCode: "DE")
                .isEmpty
        )
    }

    @Test func officialTrailerWins() throws {
        #expect(trailerKey(try decodedMatrixDetails()) == "official-key")
    }

    @Test func unofficialTrailerWhenNoOfficial() {
        let details = makeMovieDetails(
            videos: [
                Video(
                    key: "unofficial-key",
                    site: "YouTube",
                    type: "Trailer",
                    official: false
                )
            ]
        )

        #expect(trailerKey(details) == "unofficial-key")
    }

    @Test func trailerOnOtherSiteIsSkipped() {
        let details = makeMovieDetails(
            videos: [
                Video(
                    key: "vimeo-key",
                    site: "Vimeo",
                    type: "Trailer",
                    official: true
                )
            ]
        )

        #expect(trailerKey(details).isEmpty)
        #expect(!hasTrailer(details))
    }

    @Test func trailerURLPointsToYouTube() throws {
        let address = try #require(trailerURL(try decodedMatrixDetails()))

        #expect(
            address.absoluteString
                == "https://www.youtube.com/watch?v=official-key"
        )
    }

    @Test func factsLineAddsRuntimeAndCertification() throws {
        let movie = makeMovie(
            releaseDate: "1999-03-31",
            voteAverage: 8.2
        )

        #expect(
            movieFactsLine(
                movie,
                try decodedMatrixDetails(),
                regionCode: "PL"
            ) == "1999 · ★ 8.2 · 2h 16m · 16"
        )
    }

    @Test func factsLineBeforeDetailsLoad() {
        let movie = makeMovie(
            releaseDate: "1999-03-31",
            voteAverage: 8.2
        )

        #expect(
            movieFactsLine(movie, emptyMovieDetails, regionCode: "PL")
                == "1999 · ★ 8.2"
        )
    }

    @Test func profileURLIsNilWithoutPhoto() throws {
        let cast = try decodedMatrixDetails().credits.cast

        #expect(
            profileURL(try #require(cast.first))?.absoluteString
                == "https://image.tmdb.org/t/p/w185/keanu.jpg"
        )
        #expect(profileURL(try #require(cast.last)) == nil)
    }
}

@MainActor
struct InCinemasTests {
    private let today = Date(timeIntervalSince1970: 1_793_923_200)

    @Test
    func recentCinemaPremiereIsInCinemas() {
        let details = detailsWithRelease(
            date: "2026-10-17T00:00:00.000Z",
            type: releaseTypeTheatrical,
            countryCode: "PL"
        )

        #expect(isInCinemas(details, regionCode: "PL", today: today))
    }

    @Test
    func limitedReleaseCountsToo() {
        let details = detailsWithRelease(
            date: "2026-10-01T00:00:00.000Z",
            type: releaseTypeTheatricalLimited,
            countryCode: "PL"
        )

        #expect(isInCinemas(details, regionCode: "PL", today: today))
    }

    @Test
    func oldPremiereIsNotInCinemas() {
        let details = detailsWithRelease(
            date: "2026-09-24T00:00:00.000Z",
            type: releaseTypeTheatrical,
            countryCode: "PL"
        )

        #expect(!isInCinemas(details, regionCode: "PL", today: today))
    }

    @Test
    func futurePremiereIsNotInCinemasYet() {
        let details = detailsWithRelease(
            date: "2026-11-07T00:00:00.000Z",
            type: releaseTypeTheatrical,
            countryCode: "PL"
        )

        #expect(!isInCinemas(details, regionCode: "PL", today: today))
    }

    @Test
    func digitalReleaseIsNotCinema() {
        let details = detailsWithRelease(
            date: "2026-10-17T00:00:00.000Z",
            type: 4,
            countryCode: "PL"
        )

        #expect(!isInCinemas(details, regionCode: "PL", today: today))
    }

    @Test
    func premiereInAnotherCountryDoesNotCount() {
        let details = detailsWithRelease(
            date: "2026-10-17T00:00:00.000Z",
            type: releaseTypeTheatrical,
            countryCode: "US"
        )

        #expect(!isInCinemas(details, regionCode: "PL", today: today))
    }

    @Test
    func unreadableDateIsNotInCinemas() {
        let details = detailsWithRelease(
            date: "not-a-date",
            type: releaseTypeTheatrical,
            countryCode: "PL"
        )

        #expect(!isInCinemas(details, regionCode: "PL", today: today))
    }

    private func detailsWithRelease(
        date: String,
        type: Int,
        countryCode: String
    ) -> MovieDetails {
        let release = ReleaseDate(
            certification: "",
            releaseDate: date,
            type: type
        )
        let country = CountryReleaseDates(
            countryCode: countryCode,
            releaseDates: [release]
        )
        return makeMovieDetails(releaseDates: [country])
    }
}

private func decodedMatrixDetails() throws -> MovieDetails {
    try decodeTMDBMovieDetails(Data(matrixDetailsJSON.utf8))
}

private func makeMovieDetails(
    runtime: Int? = nil,
    crew: [CrewMember] = [],
    videos: [Video] = [],
    releaseDates: [CountryReleaseDates] = []
) -> MovieDetails {
    MovieDetails(
        id: 1,
        tagline: "",
        runtime: runtime,
        credits: Credits(cast: [], crew: crew),
        videos: VideoList(results: videos),
        releaseDates: ReleaseDateList(results: releaseDates),
        watchProviders: WatchProviderList(results: [:]),
        recommendations: TMDBMoviePage(results: [])
    )
}
