# Architektura (UML)

Diagramy są w Mermaid. GitHub rysuje je sam, w Xcode widać sam tekst. Opisują całą aplikację, czyli stan po lab 5.

Projekt jest napisany proceduralnie. Większość kodu to struktury bez metod i zwykłe funkcje. Na diagramach klas:

- `<<struct>>` to struktura z danymi,
- `<<functions>>` to plik ze zwykłymi funkcjami, a nie klasa,
- `<<typealias>>` to typ funkcji przekazywanej jako zależność,
- `<<Observable>>` i `<<Model>>` to jedyne prawdziwe klasy w aplikacji.

Bazy danych opisuje `docs/database.md`.

## Warstwy

```mermaid
flowchart TD
    subgraph App["Aplikacja MyNextMovie"]
        Views["Views<br/>ekrany SwiftUI"]
        ViewModels["ViewModels<br/>stan ekranów"]
        Models["Models<br/>Movie, MovieDetails, gatunki"]
        Services["Services<br/>TMDB.swift, Supabase.swift"]
        Storage["Storage<br/>SwiftData i synchronizacja"]
        Config["Config<br/>klucze API"]
    end
    Tests["MyNextMovieTests<br/>102 testy jednostkowe"]
    TMDB[("TMDB API")]
    Supabase[("Supabase<br/>Auth i saved_movies")]
    Device[("SwiftData<br/>baza na urządzeniu")]

    Views --> ViewModels
    Views --> Storage
    ViewModels --> Models
    ViewModels -. "typy funkcji" .-> Services
    ViewModels -. "typy funkcji" .-> Storage
    Services --> Models
    Services --> Config
    Services --> Storage
    Storage --> Models
    Services --> TMDB
    Services --> Supabase
    Storage --> Device
    Tests -. "zamiast sieci podaje closure" .-> ViewModels
    Tests -.-> Models
    Tests -.-> Services
    Tests -.-> Storage
```

View model nie zna TMDB ani Supabase. Dostaje funkcje w `init`. Aplikacja podaje prawdziwe zapytania, testy podają closure.

## Modele

```mermaid
classDiagram
    class Movie {
        <<struct>>
        id: Int
        title: String
        overview: String
        releaseDate: String
        posterPath: String?
        voteAverage: Double
        genreIds: [Int]
    }
    class MovieFunctions {
        <<functions>>
        releaseYear(movie) String
        formattedRating(movie) String
        ratingWithStar(movie) String
        yearAndRating(movie) String
        posterURL(movie) URL?
        hasPoster(movie) Bool
    }
    class Genre {
        <<struct>>
        id: Int
        name: String
        symbolName: String
    }
    class GenreFunctions {
        <<functions>>
        genreTable: [Genre]
        positionInGenreTable(genreId) Int
        genreName(genreId) String
        genreSymbolName(genreId) String
        knownGenreIds(movie) [Int]
        mainGenreId(movie) Int
        movieSubtitle(movie) String
    }
    class SearchFunctions {
        <<functions>>
        filterMovies(movies, query, genreId) [Movie]
    }
    class MovieDetails {
        <<struct>>
        id: Int
        tagline: String
        runtime: Int?
    }
    class MovieDetailsFunctions {
        <<functions>>
        formattedRuntime(details) String
        directorNames(details) String
        ageCertification(details, regionCode) String
        trailerKey(details) String
        trailerURL(details) URL?
        movieFactsLine(movie, details, regionCode) String
        watchProviders(details, regionCode) CountryWatchProviders
        profileURL(castMember) URL?
        logoURL(provider) URL?
    }
    class Credits {
        <<struct>>
    }
    class CastMember {
        <<struct>>
        id: Int
        name: String
        character: String
        profilePath: String?
    }
    class CrewMember {
        <<struct>>
        id: Int
        name: String
        job: String
    }
    class VideoList {
        <<struct>>
    }
    class Video {
        <<struct>>
        key: String
        site: String
        type: String
        official: Bool
    }
    class ReleaseDateList {
        <<struct>>
    }
    class CountryReleaseDates {
        <<struct>>
        countryCode: String
    }
    class ReleaseDate {
        <<struct>>
        certification: String
    }
    class WatchProviderList {
        <<struct>>
        results: słownik kraj - serwisy
    }
    class CountryWatchProviders {
        <<struct>>
        link: String
    }
    class WatchProvider {
        <<struct>>
        providerId: Int
        providerName: String
        logoPath: String?
    }
    class TMDBMoviePage {
        <<struct>>
    }

    MovieFunctions ..> Movie
    GenreFunctions ..> Genre
    GenreFunctions ..> Movie
    SearchFunctions ..> Movie
    MovieDetailsFunctions ..> MovieDetails
    Movie ..> Genre : genreIds
    MovieDetails *-- Credits : credits
    MovieDetails *-- VideoList : videos
    MovieDetails *-- ReleaseDateList : releaseDates
    MovieDetails *-- WatchProviderList : watchProviders
    MovieDetails *-- TMDBMoviePage : recommendations
    Credits *-- "0..*" CastMember : cast
    Credits *-- "0..*" CrewMember : crew
    VideoList *-- "0..*" Video : results
    ReleaseDateList *-- "0..*" CountryReleaseDates : results
    CountryReleaseDates *-- "0..*" ReleaseDate : releaseDates
    WatchProviderList *-- "0..*" CountryWatchProviders : results
    CountryWatchProviders *-- "0..*" WatchProvider : flatrate, rent, buy
    TMDBMoviePage *-- "0..*" Movie : results
```

## Serwisy i przechowywanie

```mermaid
classDiagram
    class MovieLoader {
        <<typealias>>
        () async throws [Movie]
    }
    class MovieSearch {
        <<typealias>>
        (query, genreId) async throws [Movie]
    }
    class MovieDetailsLoader {
        <<typealias>>
        (movieId) async throws MovieDetails
    }
    class AccountRequest {
        <<typealias>>
        (email, password) async throws String
    }
    class AccountService {
        <<struct>>
        signedInEmail: () String
        signIn: AccountRequest
        signUp: AccountRequest
        signOut: () async throws
    }
    class SavedMoviesCloud {
        <<struct>>
        fetchMovies: () async throws [CloudSavedMovie]
        uploadMovies: ([CloudSavedMovie]) async throws
        removeMovie: (movieId) async throws
    }
    class CloudSavedMovie {
        <<struct>>
        id: Int
        title: String
        overview: String
        releaseDate: String
        posterPath: String?
        voteAverage: Double
        genreIds: [Int]
        savedAt: Date
    }
    class TMDB {
        <<functions>>
        loadPopularMovies(cache) [Movie]
        fetchPopularMovies() [Movie]
        searchTMDBMovies(query, genreId) [Movie]
        loadTMDBMovieDetails(movieId, cache) MovieDetails
        fetchMovieDetails(movieId) MovieDetails
        tmdbURL(path, parameters, apiKey) URL?
        decodeTMDBMovies(data) [Movie]
        decodeTMDBMovieDetails(data) MovieDetails
        checkTMDBResponse(response)
    }
    class Supabase {
        <<functions>>
        supabaseAccountService: AccountService
        supabaseSavedMoviesCloud: SavedMoviesCloud
        supabaseSignedInEmail() String
        signInToSupabase(email, password) String
        signUpToSupabase(email, password) String
        signOutOfSupabase()
        fetchCloudSavedMovies() [CloudSavedMovie]
        uploadCloudSavedMovies(cloudMovies)
        removeCloudSavedMovie(movieId)
    }
    class AppConfig {
        <<functions>>
        tmdbAPIKey() String
        supabaseURL() String
        supabaseAnonKey() String
    }
    class TMDBError {
        <<struct>>
        message: String
    }
    class SupabaseError {
        <<struct>>
        message: String
    }
    class StorageFunctions {
        <<functions>>
        isMovieSaved(context, movieId) Bool
        toggleSavedMovie(context, movie, now)
        clearSavedMovies(context)
        moviesFromSaved(savedMovies) [Movie]
        recordSearch(context, query, now)
        recentSearches(context) [SearchHistoryEntry]
        clearSearchHistory(context)
        cachedResponseData(context, key) Data
        storeCachedResponse(context, key, data, now)
        fetchWithCacheFallback(context, key, fetch) Data
    }
    class SavedMoviesSync {
        <<functions>>
        syncSavedMovies(context, cloud)
        cloudMovieFromSaved(savedMovie) CloudSavedMovie
        movieFromCloud(cloudMovie) Movie
    }
    class SavedMovie {
        <<Model>>
        movieId: Int
        title: String
        savedAt: Date
        isInCloud: Bool
    }
    class RemovedSavedMovie {
        <<Model>>
        movieId: Int
    }
    class SearchHistoryEntry {
        <<Model>>
        query: String
        searchedAt: Date
    }
    class CachedResponse {
        <<Model>>
        key: String
        data: Data
        fetchedAt: Date
    }

    TMDB ..|> MovieLoader : loadPopularMovies
    TMDB ..|> MovieSearch : searchTMDBMovies
    TMDB ..|> MovieDetailsLoader : loadTMDBMovieDetails
    TMDB ..> AppConfig
    TMDB ..> TMDBError : throws
    TMDB ..> StorageFunctions : fetchWithCacheFallback
    Supabase ..> AppConfig
    Supabase ..> SupabaseError : throws
    Supabase ..> AccountService : wypełnia
    Supabase ..> SavedMoviesCloud : wypełnia
    AccountService o-- AccountRequest
    SavedMoviesCloud ..> CloudSavedMovie
    SavedMoviesSync ..> SavedMoviesCloud : używa
    SavedMoviesSync ..> SavedMovie
    SavedMoviesSync ..> RemovedSavedMovie
    StorageFunctions ..> SavedMovie
    StorageFunctions ..> RemovedSavedMovie
    StorageFunctions ..> SearchHistoryEntry
    StorageFunctions ..> CachedResponse
```

## View modele i ekrany

```mermaid
classDiagram
    class LoadState {
        <<enumeration>>
        idle
        loading
        loaded
        failed
    }
    class MovieListViewModel {
        <<Observable>>
        state: LoadState
        movies: [Movie]
        errorMessage: String
        loadIfNeeded()
        load()
    }
    class MovieDetailViewModel {
        <<Observable>>
        movieId: Int
        state: LoadState
        details: MovieDetails
        errorMessage: String
        loadIfNeeded()
        load()
    }
    class SearchViewModel {
        <<Observable>>
        query: String
        selectedGenreId: Int
        state: LoadState
        movies: [Movie]
        errorMessage: String
        search()
        toggleGenre(genreId)
    }
    class AccountViewModel {
        <<Observable>>
        email: String
        password: String
        signedInEmail: String
        state: LoadState
        errorMessage: String
        isWaitingForEmailConfirmation: Bool
        syncState: LoadState
        syncErrorMessage: String
        isSignedIn: Bool
        canSignIn: Bool
        canSignUp: Bool
        signIn()
        signUp()
        signOut()
        syncSavedMovies()
    }
    class MyNextMovieApp {
        <<App>>
    }
    class RootView {
        <<View>>
        modelContext
    }
    class AppTabs {
        <<View>>
        moviesNotInCloud: Query
        removedMovies: Query
    }
    class SignInView {
        <<View>>
    }
    class AccountView {
        <<View>>
    }
    class MovieListView {
        <<View>>
    }
    class SavedMoviesView {
        <<View>>
        savedMovies: Query
    }
    class SearchView {
        <<View>>
    }
    class MovieDetailView {
        <<View>>
    }
    class MovieDetailSections {
        <<View>>
    }
    class MovieGrid {
        <<View>>
    }
    class MovieCardView {
        <<View>>
    }
    class SaveMovieButton {
        <<View>>
    }
    class Components {
        <<View>>
        PosterView
        RatingBadge
        GenreChip
        ErrorView
    }
    class MovieLoader {
        <<typealias>>
    }
    class MovieSearch {
        <<typealias>>
    }
    class MovieDetailsLoader {
        <<typealias>>
    }
    class AccountService {
        <<struct>>
    }

    MovieListViewModel --> LoadState
    MovieDetailViewModel --> LoadState
    SearchViewModel --> LoadState
    AccountViewModel --> LoadState
    MovieListViewModel o-- MovieLoader : loadMovies
    MovieDetailViewModel o-- MovieDetailsLoader : loadDetails
    SearchViewModel o-- MovieSearch : searchMovies
    AccountViewModel o-- AccountService : account
    AccountViewModel ..> SavedMoviesSync : syncSavedMovies jako closure

    MyNextMovieApp *-- RootView
    RootView *-- AppTabs
    AppTabs *-- AccountViewModel
    AppTabs *-- SignInView : niezalogowany
    AppTabs *-- MovieListView : zakładka Movies
    AppTabs *-- SavedMoviesView : zakładka Saved
    AppTabs *-- AccountView : zakładka Account
    AppTabs *-- SearchView : zakładka Search
    SignInView --> AccountViewModel
    AccountView --> AccountViewModel
    MovieListView *-- MovieListViewModel
    SearchView *-- SearchViewModel
    MovieDetailView *-- MovieDetailViewModel
    MovieListView *-- MovieGrid
    SavedMoviesView *-- MovieGrid
    MovieGrid *-- MovieCardView
    MovieListView ..> MovieDetailView : nawigacja
    SavedMoviesView ..> MovieDetailView : nawigacja
    SearchView ..> MovieDetailView : nawigacja
    MovieDetailView *-- MovieDetailSections
    MovieDetailView *-- SaveMovieButton
    MovieDetailSections *-- MovieCardView : polecane
    MovieCardView ..> Components
    MovieDetailView ..> Components
    SearchView ..> Components
    SaveMovieButton ..> StorageFunctions : toggleSavedMovie
    SearchView ..> StorageFunctions : recordSearch
```

`RootView` ma kontekst SwiftData. Opakowuje nim funkcje, które go potrzebują: cache TMDB i synchronizację. Dzięki temu view modele dostają zwykłe typy funkcji.

## Start aplikacji i logowanie

```mermaid
sequenceDiagram
    actor User as Użytkownik
    participant AppTabs
    participant VM as AccountViewModel
    participant Auth as Supabase Auth
    participant Sync as syncSavedMovies

    AppTabs->>VM: init
    VM->>Auth: signedInEmail() z keychaina
    Auth-->>VM: "" albo email
    alt nikt nie jest zalogowany
        AppTabs-->>User: SignInView
        User->>VM: signIn()
        VM->>Auth: signIn(email, password)
        Auth-->>VM: email
        VM->>Sync: syncSavedMovies()
        AppTabs-->>User: zakładki
    else sesja z poprzedniego razu
        AppTabs-->>User: zakładki
        AppTabs->>VM: syncSavedMovies()
        VM->>Sync: syncSavedMovies()
    end
    User->>VM: signOut()
    VM->>Sync: syncSavedMovies(), ostatnie zmiany
    VM->>Auth: signOut()
    VM->>VM: clearSavedMovies()
    AppTabs-->>User: SignInView
```

## Synchronizacja listy zapisanych filmów

Lista działa bez sieci. Zmiany czekają na urządzeniu, aż synchronizacja je wyśle. `AppTabs` uruchamia ją przy starcie, po powrocie do aplikacji i gdy pojawi się niewysłana zmiana.

```mermaid
sequenceDiagram
    participant Sync as syncSavedMovies
    participant Device as SwiftData
    participant Cloud as SavedMoviesCloud
    participant DB as saved_movies

    Note over Sync,DB: 1. usunięcia z urządzenia idą na konto
    Sync->>Device: pobierz RemovedSavedMovie
    loop każdy movieId
        Sync->>Cloud: removeMovie(movieId)
        Cloud->>DB: delete where id = movieId
        Sync->>Device: usuń znacznik
    end

    Note over Sync,DB: 2. konto jest wzorem dla urządzenia
    Sync->>Cloud: fetchMovies()
    Cloud->>DB: select
    DB-->>Sync: lista CloudSavedMovie
    Sync->>Device: usuń filmy z isInCloud, których konto już nie ma
    Sync->>Device: dodaj filmy z konta, ustaw isInCloud = true

    Note over Sync,DB: 3. nowe filmy z urządzenia idą na konto
    Sync->>Device: pobierz SavedMovie z isInCloud = false
    Sync->>Cloud: uploadMovies(lista)
    Cloud->>DB: upsert, duplikaty pomijane
    Sync->>Device: ustaw isInCloud = true
```

Gdy zapytanie się nie uda, funkcja rzuca błąd. Znaczniki zostają i następna synchronizacja wyśle resztę.

## Pobranie filmów z cache

```mermaid
sequenceDiagram
    participant VM as MovieListViewModel
    participant TMDB as loadPopularMovies
    participant Cache as fetchWithCacheFallback
    participant API as TMDB API
    participant Device as CachedResponse

    VM->>TMDB: loadMovies()
    TMDB->>Cache: fetch, key = popular
    Cache->>API: GET /3/movie/popular
    alt jest sieć
        API-->>Cache: JSON
        Cache->>Device: zapisz JSON
        Cache-->>TMDB: świeży JSON
    else brak sieci
        API--xCache: błąd
        Cache->>Device: odczytaj JSON
        Device-->>Cache: ostatnia odpowiedź albo nic
        Cache-->>TMDB: JSON z cache albo ten sam błąd
    end
    TMDB-->>VM: lista Movie
```

## Testy jednostkowe

Testy są w `MyNextMovieTests/` i używają Swift Testing. Jest ich 102 w 15 zestawach. Żaden nie łączy się z siecią. Plan `MyNextMovie.xctestplan` uruchamia je w losowej kolejności i zbiera pokrycie kodu.

```mermaid
classDiagram
    class MovieTests {
        <<suite>>
        10 testów
    }
    class GenreTests {
        <<suite>>
        6 testów
    }
    class FilterMoviesTests {
        <<suite>>
        7 testów
    }
    class MovieDetailsDecodingTests {
        <<suite>>
        6 testów
    }
    class MovieDetailsTests {
        <<suite>>
        14 testów
    }
    class TMDBTests {
        <<suite>>
        11 testów
    }
    class SavedMovieTests {
        <<suite>>
        5 testów
    }
    class SearchHistoryTests {
        <<suite>>
        5 testów
    }
    class ResponseCacheTests {
        <<suite>>
        5 testów
    }
    class SavedMoviesSyncTests {
        <<suite>>
        8 testów
    }
    class CloudSavedMovieTests {
        <<suite>>
        2 testy
    }
    class MovieListViewModelTests {
        <<suite>>
        4 testy
    }
    class MovieDetailViewModelTests {
        <<suite>>
        4 testy
    }
    class SearchViewModelTests {
        <<suite>>
        4 testy
    }
    class AccountViewModelTests {
        <<suite>>
        11 testów
    }
    class TestMovies {
        <<data>>
        testMovies: [Movie]
        testMovieDetails: MovieDetails
        makeMovie()
    }
    class NoConnection {
        <<error>>
    }
    class TestCloud {
        <<fake>>
        movies: [CloudSavedMovie]
        isOffline: Bool
    }
    class TestAccount {
        <<fake>>
        signedInEmail: String
        isOffline: Bool
        needsEmailConfirmation: Bool
        syncCount: Int
        clearCount: Int
    }
    class makeTestContainer {
        <<helper>>
        baza SwiftData w pamięci
    }

    MovieTests ..> MovieFunctions : testuje
    GenreTests ..> GenreFunctions : testuje
    FilterMoviesTests ..> SearchFunctions : testuje
    MovieDetailsDecodingTests ..> MovieDetails : dekodowanie JSON
    MovieDetailsTests ..> MovieDetailsFunctions : testuje
    TMDBTests ..> TMDB : adresy, dekodowanie, statusy HTTP
    SavedMovieTests ..> StorageFunctions : lista zapisanych
    SearchHistoryTests ..> StorageFunctions : historia
    ResponseCacheTests ..> StorageFunctions : cache
    SavedMoviesSyncTests ..> SavedMoviesSync : testuje
    CloudSavedMovieTests ..> CloudSavedMovie : nazwy kolumn
    MovieListViewModelTests ..> MovieListViewModel : testuje
    MovieDetailViewModelTests ..> MovieDetailViewModel : testuje
    SearchViewModelTests ..> SearchViewModel : testuje
    AccountViewModelTests ..> AccountViewModel : testuje

    SavedMoviesSyncTests ..> TestCloud : zamiast Supabase
    AccountViewModelTests ..> TestAccount : zamiast Supabase
    SavedMovieTests ..> makeTestContainer
    SearchHistoryTests ..> makeTestContainer
    ResponseCacheTests ..> makeTestContainer
    SavedMoviesSyncTests ..> makeTestContainer
    MovieListViewModelTests ..> NoConnection
    AccountViewModelTests ..> NoConnection
    ResponseCacheTests ..> NoConnection
    SavedMoviesSyncTests ..> NoConnection
    MovieListViewModelTests ..> TestMovies
    FilterMoviesTests ..> TestMovies
    SavedMoviesSyncTests ..> TestMovies
```

| Zestaw | Plik | Testów | Co sprawdza |
| --- | --- | --- | --- |
| `MovieTests` | `MovieTests.swift` | 10 | rok, ocena, adres plakatu, podtytuł |
| `GenreTests` | `MovieTests.swift` | 6 | tabela gatunków, nieznane id |
| `FilterMoviesTests` | `SearchTests.swift` | 7 | filtrowanie po tekście i gatunku |
| `SearchViewModelTests` | `SearchTests.swift` | 4 | stan ekranu Search |
| `MovieDetailsDecodingTests` | `MovieDetailsTests.swift` | 6 | dekodowanie szczegółów z JSON |
| `MovieDetailsTests` | `MovieDetailsTests.swift` | 14 | czas trwania, reżyserzy, zwiastun, kategoria wiekowa |
| `TMDBTests` | `TMDBTests.swift` | 11 | adresy zapytań, dekodowanie, błędy HTTP |
| `SavedMovieTests` | `StorageTests.swift` | 5 | zapis, usunięcie, znaczniki, czyszczenie |
| `SearchHistoryTests` | `StorageTests.swift` | 5 | kolejność, limit, czyszczenie historii |
| `ResponseCacheTests` | `StorageTests.swift` | 5 | cache i praca bez sieci |
| `SavedMoviesSyncTests` | `SavedMoviesSyncTests.swift` | 8 | synchronizacja w obie strony, zmiany offline |
| `CloudSavedMovieTests` | `SavedMoviesSyncTests.swift` | 2 | nazwy kolumn, kopia pól filmu |
| `MovieListViewModelTests` | `MovieListViewModelTests.swift` | 4 | stan listy filmów |
| `MovieDetailViewModelTests` | `MovieDetailViewModelTests.swift` | 4 | stan ekranu szczegółów |
| `AccountViewModelTests` | `AccountViewModelTests.swift` | 11 | logowanie, rejestracja, wylogowanie, synchronizacja |

Czego testy nie obejmują:

- widoków SwiftUI,
- prawdziwych zapytań do TMDB i Supabase (`Supabase.swift` jest tylko cienką warstwą nad SDK),
- zasad Row Level Security w bazie.
