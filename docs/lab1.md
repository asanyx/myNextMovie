# Lab 1: podstawy SwiftUI

Na tych zajęciach budują Państwo ekran główny z siatką filmów i ekran szczegółów filmu. Dane są przykładowe, z `Services/SampleMovies.swift`. Prawdziwe dane z TMDB dojdą na kolejnych zajęciach.

1. Proszę wykonać kroki z sekcji **Start** w [README](../README.md).
2. Proszę uruchomić aplikację (⌘R). Na ekranie widać tylko tytuł zamiast siatki. Tak ma być.
3. Proszę uruchomić testy (⌘U). Część testów nie przechodzi, a część jest pominięta. Tak też ma być.

## Zadanie 1: karta filmu i siatka

Funkcje w `Models/`:

- `releaseYear` w `Movie.swift`: rok z daty premiery.
- `formattedRating` w `Movie.swift`: ocena z jedną cyfrą po przecinku.
- `knownGenreIds` w `Genres.swift`: gatunki filmu znane TMDB.
- `mainGenreId` w `Genres.swift`: pierwszy znany gatunek.
- `movieSubtitle` w `Genres.swift`: podpis „1999 · Action”.

Widoki:

- `MovieCardView`: plakat z oceną w rogu, pod nim tytuł i podpis. Proszę użyć `VStack`, `Text` i modyfikatorów.
- `MovieListView`, właściwość `grid`: siatka `LazyVGrid` z `ForEach`.
- `MovieListView`, struktura `MovieGridItem`: `NavigationLink`, który otwiera szczegóły filmu.

Testy do napisania:

- `MovieTests/subtitleLeavesOutMissingParts`
- `GenreTests/mainGenreIdIsFirstKnownGenre`

Proszę sprawdzić podgląd (Canvas, ⌥⌘↩) w `MovieCardView.swift` i `MovieListView.swift`.

## Zadanie 2: szczegóły filmu

Funkcje w `Models/Movie.swift`:

- `ratingWithStar`: „★ 8.2”.
- `yearAndRating`: „2014 · ★ 8.4”, bez roku, gdy data jest nieznana.

Widoki w `MovieDetailView.swift`:

- `MovieInfo`: tytuł, rok i ocena, gatunki, opis.
- `GenreRow`: przewijany w bok wiersz `GenreChip`.

Tło z rozmytym plakatem (`MovieBackdrop`) jest gotowe.

Testy do napisania:

- `MovieTests/ratingWithStarStartsWithStar`
- `MovieTests/yearAndRatingLeavesOutUnknownYear`
- `MovieListViewModelTests/loadIfNeededLoadsOnlyOnce`

## Koniec zajęć

Proszę o zapisanie prac w dowolny sposób i oddanie ich na Moodle gdy będzie taka możliwość.

## Dokumentacja

- SwiftUI: https://developer.apple.com/documentation/swiftui
- Samouczki SwiftUI: https://developer.apple.com/tutorials/swiftui
- `LazyVGrid`: https://developer.apple.com/documentation/swiftui/lazyvgrid
- `NavigationLink`: https://developer.apple.com/documentation/swiftui/navigationlink
- Swift Testing: https://developer.apple.com/documentation/testing
