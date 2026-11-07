# my-next-movie

Projekt startowy do laboratoriów z przedmiotu **Zaawansowane programowanie na platformę iOS**.

Aplikacja rekomenduje filmy. Dane pochodzą z TMDB, zapisane filmy są na telefonie w SwiftData, a konto i kopia zapisanych filmów w Supabase.

## Start

Robią to Państwo raz, na pierwszych zajęciach. Konto na GitHubie nie jest potrzebne.

1. Na stronie repozytorium proszę kliknąć Code, Download ZIP i rozpakować archiwum.
2. Proszę otworzyć `MyNextMovie.xcodeproj`. Przy pierwszym otwarciu Xcode sam pobiera pakiet Supabase, potrzebny jest internet.
3. Proszę uruchomić aplikację (⌘R) i testy (⌘U). Na starcie część testów nie przechodzi, a część jest pominięta. Tak ma być, opisuje to [lab 1](docs/lab1.md).

Kto chce pracować z Gitem, zamiast ZIP-a wybiera drogę z sekcji [GitHub, dla chętnych](#github-dla-chętnych).

## Zadania

Zadania na każde zajęcia są w folderze `docs/`:

- Lab 1: podstawy SwiftUI ([PDF](docs/lab1.pdf), [Markdown](docs/lab1.md))
- Lab 2: ekran wyszukiwania ([PDF](docs/lab2.pdf), [Markdown](docs/lab2.md))
- Lab 3: dane z TMDB ([PDF](docs/lab3.pdf), [Markdown](docs/lab3.md))
- Lab 4: dane na urządzeniu, SwiftData ([PDF](docs/lab4.pdf), [Markdown](docs/lab4.md))
- Lab 5: konto i synchronizacja, Supabase ([PDF](docs/lab5.pdf), [Markdown](docs/lab5.md))

PDF-y można też pobrać z [Releases, Instrukcje do laboratoriów](../../releases/tag/labs-pdf). Buduje je polecenie `scripts/build-docs.sh` (wymaga [pandoc](https://pandoc.org) i [Typst](https://typst.app)).

Diagramy całej aplikacji są w [docs/architecture.md](docs/architecture.md) (warstwy, klasy, przebieg logowania i synchronizacji) i [docs/database.md](docs/database.md) (tabele Supabase i modele SwiftData).

W lab 1 i lab 2 miejsca do uzupełnienia oznacza komentarz `// TODO: Lab N`. Listę wszystkich pokazuje Xcode: Find Navigator (⌘⇧F), hasło `TODO: Lab`. Od lab 3 cały kod piszą Państwo sami według instrukcji.

Testy w lab 1 i lab 2 są dwojakie:

- **gotowe**. Na starcie część z nich nie przechodzi. Przejdą, gdy kod będzie uzupełniony.
- **do napisania**. Mają `@Test(.disabled(...))` i pustą treść. Komentarz nad testem mówi, co sprawdzić. Proszę napisać test i usunąć `.disabled(...)`.

Od lab 3 testy też piszą Państwo sami. Instrukcja każdego labu wymienia, co mają sprawdzać.

## Nowe laboratoria

Instrukcja do kolejnych zajęć pojawia się w `docs/` w tym repozytorium i w Releases jako PDF. Od lab 3 kod piszą Państwo sami w swoim projekcie, więc projektu nie trzeba pobierać od nowa. Wystarczy przeczytać instrukcję.

## Oddanie projektu

Na koniec semestru projekt oddaje się jako ZIP z kodem na Moodle.

- Projekt buduje się bez ostrzeżeń (⌘B).
- Wszystkie testy przechodzą (⌘U).
- Plik `Config/Secrets.xcconfig` z Państwa kluczami nie jest potrzebny. Proszę go usunąć z kopii, którą Państwo pakują.

ZIP robi się w Finderze: prawy przycisk na folderze projektu, Compress.

Do zaliczenia przedmiotu potrzebne są oba elementy: ZIP z projektem i zdany egzamin z wykładu.

## Klucze API

Klucze wpisuje się w `Config/Secrets.xcconfig`. W projekcie jest tylko przykład, `Config/Secrets.xcconfig.example`:

1. Proszę skopiować `Config/Secrets.xcconfig.example` jako `Config/Secrets.xcconfig`. W Finderze: Duplicate, potem zmiana nazwy.
2. Klucz TMDB, potrzebny od lab 3: konto na [themoviedb.org](https://www.themoviedb.org), potem Settings, API. Do pliku idzie API Key, czyli krótszy klucz.
3. Adres projektu i klucz anon Supabase, potrzebne od lab 5: panel projektu, Project Settings, API. Opis jest w [lab 5](docs/lab5.md).
4. Po zmianie kluczy proszę zrobić Product, Clean Build Folder (⇧⌘K).

`Config/Secrets.xcconfig` jest w `.gitignore`, więc nie trafia do repozytorium.

W kodzie klucze odczytują funkcje z `MyNextMovie/Config/AppConfig.swift`:

```swift
tmdbAPIKey()
supabaseURL()
supabaseAnonKey()
```

## Wymagania

- Mac z Xcode 26 albo nowszym
- konto TMDB i klucz API, od lab 3
- konto Supabase i Supabase CLI, od lab 5
- konto GitHub nie jest potrzebne

## Co jest w projekcie

```
MyNextMovie/
  Models/        Movie, gatunki i funkcje pomocnicze
  Services/      MovieLoader, przykładowe filmy
  ViewModels/    stan ekranów listy i wyszukiwania
  Views/         lista, wyszukiwanie i szczegóły filmu, Components/ ze wspólnymi elementami
  Config/        odczyt kluczy API
MyNextMovieTests/        testy jednostkowe (Swift Testing)
docs/                    zadania na kolejne laboratoria i diagramy
supabase/                migracja bazy Supabase i konto testowe, od lab 5
MyNextMovie.xctestplan   plan testów
Config/                  ustawienia builda (.xcconfig), Info.plist
```

Architektura: SwiftUI + MVVM. Nowe pliki dodane do folderów `MyNextMovie/` i `MyNextMovieTests/` same trafiają do projektu.

## Konfiguracja Xcode

Ustawienia builda są w plikach `.xcconfig`, a nie w `project.pbxproj`. Łatwo je czytać i porównywać.

```
Config/Shared.xcconfig    wspólne dla całego projektu: wersja iOS, Swift 6, podpisywanie, ostrzeżenia są błędami
Config/Debug.xcconfig     szybki build bez optymalizacji, analizator przy każdym buildzie
Config/Release.xcconfig   build z optymalizacją
Config/App.xcconfig       aplikacja: bundle id, Info.plist, klucze API
Config/Tests.xcconfig     testy jednostkowe
```

Testy uruchamia plan `MyNextMovie.xctestplan`. Zbiera pokrycie kodu (Report navigator, Coverage) i uruchamia testy w losowej kolejności, żeby żaden test nie zależał od innego.

## GitHub, dla chętnych

Ta droga nie jest obowiązkowa. Daje historię zmian, kopię projektu w chmurze i nowe materiały jednym poleceniem zamiast ręcznego kopiowania. Projekt i tak oddaje się jako ZIP na Moodle.

### Start z Gitem

1. Na GitHubie proszę utworzyć **puste, prywatne** repozytorium, np. `my-next-movie`. Bez README i bez `.gitignore`.
2. Proszę sklonować repozytorium przedmiotu i podpiąć swoje:

```sh
git clone https://github.com/fwsoft/my-next-movie.git my-next-movie
cd my-next-movie
git remote rename origin upstream
git remote add origin https://github.com/LOGIN/my-next-movie.git
git push -u origin main
```

`LOGIN` to Państwa login na GitHubie.

### Nowe materiały z Gitem

```sh
git pull --no-rebase --no-edit upstream main
git push
```

`--no-rebase` łączy moje zmiany z Państwa commitami. Bez tej opcji Git zgłasza błąd `Need to specify how to reconcile divergent branches`. `--no-edit` pomija edytor z opisem commita.

Jeśli Git zgłosi konflikt, proszę poprawić zaznaczone pliki, potem `git add` i `git commit`.

### Gdy `pull` nie działa

Proszę sprawdzić, jakie repozytoria zna Państwa projekt:

```sh
git remote -v
```

Poprawnie wygląda to tak:

```
origin    https://github.com/LOGIN/my-next-movie.git
upstream  https://github.com/fwsoft/my-next-movie.git
```

**`origin` wskazuje na `fwsoft/my-next-movie`, a `upstream` nie ma.** To klon repozytorium przedmiotu bez kroku 2. Proszę utworzyć puste, prywatne repozytorium z kroku 1, potem:

```sh
git remote rename origin upstream
git remote add origin https://github.com/LOGIN/my-next-movie.git
git pull --no-rebase --no-edit upstream main
git push -u origin main
```

**`origin` wskazuje na Państwa forka, a `upstream` nie ma.** Proszę go dodać:

```sh
git remote add upstream https://github.com/fwsoft/my-next-movie.git
git pull --no-rebase --no-edit upstream main
git push
```

Fork publicznego repozytorium jest publiczny. Żeby mieć prywatne, proszę utworzyć puste, prywatne repozytorium i ustawić je jako `origin`:

```sh
git remote set-url origin https://github.com/LOGIN/my-next-movie.git
git push -u origin main
```

## Dokumentacja

- Swift: https://docs.swift.org/swift-book
- SwiftUI: https://developer.apple.com/documentation/swiftui
- Samouczki Apple: https://developer.apple.com/tutorials/develop-in-swift
- Swift Testing: https://developer.apple.com/documentation/testing
- SwiftData: https://developer.apple.com/documentation/swiftdata
- TMDB: https://developer.themoviedb.org/docs
- Supabase: https://supabase.com/docs/reference/swift

Pytania proszę wysyłać na filip.wandzio@wroclaw.merito.pl. W temacie proszę podać przedmiot i numer laboratorium, a przy pytaniu o kod dołączyć ZIP z projektem albo fragment kodu.
