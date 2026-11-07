# Bazy danych

Aplikacja ma dwie bazy:

- **Supabase** (PostgreSQL w chmurze): konta i zapisane filmy użytkownika.
- **SwiftData** (na urządzeniu): zapisane filmy, historia wyszukiwania i cache odpowiedzi TMDB.

Diagramy są w Mermaid. GitHub rysuje je sam, w Xcode widać sam tekst. Opisują całą aplikację, czyli stan po lab 5.

## Supabase

Schemat tworzy migracja `supabase/migrations/20261007214802_create_saved_movies.sql`.
Tabela `auth.users` należy do Supabase Auth. Aplikacja jej nie zmienia.

```mermaid
erDiagram
    auth_users["auth.users"] {
        uuid id PK
        text email
        text encrypted_password
        timestamptz email_confirmed_at
        timestamptz created_at
    }
    saved_movies["public.saved_movies"] {
        uuid user_id PK, FK "domyślnie auth.uid()"
        integer id PK "id filmu w TMDB"
        text title
        text overview "domyślnie pusty"
        text release_date "1999-03-31, pusty gdy nieznana"
        text poster_path "null gdy TMDB nie ma plakatu"
        float8 vote_average "domyślnie 0"
        integer_array genre_ids "integer[], domyślnie pusta"
        timestamptz saved_at "domyślnie now()"
    }
    auth_users ||--o{ saved_movies : "zapisuje"
```

Zasady:

- Klucz główny to para `(user_id, id)`. Jeden użytkownik ma dany film najwyżej raz.
- `user_id` wskazuje `auth.users(id)` z `on delete cascade`. Usunięcie konta usuwa jego filmy.
- Kolumny mają te same nazwy co JSON z TMDB (snake_case). Wiersz to pola struktury `Movie` plus `saved_at`.
- Film nie ma własnej tabeli. Dane filmu są kopią z TMDB, żeby lista działała bez pytania TMDB.

Row Level Security jest włączone. Każdy widzi i zmienia tylko swoje wiersze:

| Operacja | Rola | Warunek |
| --- | --- | --- |
| `select` | `authenticated` | `auth.uid() = user_id` |
| `insert` | `authenticated` | `auth.uid() = user_id` |
| `delete` | `authenticated` | `auth.uid() = user_id` |

Nie ma zasady dla `update`. Aplikacja tylko dodaje i usuwa wiersze.

Konto testowe `test@test.test` z hasłem `test` tworzy `supabase/seed.sql`.

## SwiftData

Modele są w `MyNextMovie/Storage/StoredModels.swift`. Między modelami nie ma relacji SwiftData. Łączy je tylko `movieId`, czyli id filmu w TMDB.

```mermaid
erDiagram
    SavedMovie {
        Int movieId UK "id filmu w TMDB"
        String title
        String overview
        String releaseDate
        String posterPath "opcjonalny"
        Double voteAverage
        IntArray genreIds
        Date savedAt
        Bool isInCloud "konto ma już ten film"
    }
    RemovedSavedMovie {
        Int movieId UK "usunięty tu, jeszcze nie z konta"
    }
    SearchHistoryEntry {
        String query UK
        Date searchedAt
    }
    CachedResponse {
        String key UK "popular albo movie/603"
        Data data "surowy JSON z TMDB"
        Date fetchedAt
    }
    SavedMovie ||..o| RemovedSavedMovie : "ten sam movieId, nigdy naraz"
    CachedResponse ||..o| SavedMovie : "movie/ID to szczegóły filmu"
```

Co trzyma każdy model:

| Model | Po co | Limit |
| --- | --- | --- |
| `SavedMovie` | lista do obejrzenia, działa bez sieci | brak |
| `RemovedSavedMovie` | znacznik: usuń ten film także z konta | znika po synchronizacji |
| `SearchHistoryEntry` | ostatnie wyszukiwania na ekranie Search | 10 najnowszych |
| `CachedResponse` | ostatnia odpowiedź TMDB, pokazywana bez sieci | jedna na klucz |

## Jak obie bazy się łączą

Wiersz `saved_movies` i obiekt `SavedMovie` opisują ten sam film. Pośredniczy struktura `CloudSavedMovie`.

```mermaid
erDiagram
    SavedMovie ||--|| CloudSavedMovie : "cloudMovieFromSaved()"
    CloudSavedMovie ||--|| saved_movies : "JSON, CodingKeys"
    RemovedSavedMovie ||..|| saved_movies : "delete where id = movieId"
    SavedMovie {
        Int movieId
        Bool isInCloud
        Date savedAt
    }
    CloudSavedMovie {
        Int id
        Date savedAt
    }
    saved_movies {
        uuid user_id
        integer id
        timestamptz saved_at
    }
    RemovedSavedMovie {
        Int movieId
    }
```

| SwiftData `SavedMovie` | `CloudSavedMovie` | kolumna `saved_movies` |
| --- | --- | --- |
| `movieId` | `id` | `id` |
| `title` | `title` | `title` |
| `overview` | `overview` | `overview` |
| `releaseDate` | `releaseDate` | `release_date` |
| `posterPath` | `posterPath` | `poster_path` |
| `voteAverage` | `voteAverage` | `vote_average` |
| `genreIds` | `genreIds` | `genre_ids` |
| `savedAt` | `savedAt` | `saved_at` |
| `isInCloud` | brak | brak, wynika z istnienia wiersza |
| brak | brak | `user_id`, wpisuje baza |

Synchronizację opisuje `docs/architecture.md`.
