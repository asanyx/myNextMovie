-- Movies a signed-in user saved to watch later.
-- Columns mirror the Swift `Movie` struct, so the app can show the list
-- without asking TMDB again. Column names are snake_case like TMDB JSON,
-- so `convertFromSnakeCase` decodes both.

create table public.saved_movies (
    user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
    id integer not null, -- TMDB movie id
    title text not null,
    overview text not null default '',
    release_date text not null default '', -- "1999-03-31", empty when unknown
    poster_path text, -- null when TMDB has no poster
    vote_average double precision not null default 0,
    genre_ids integer[] not null default '{}',
    saved_at timestamptz not null default now(),
    primary key (user_id, id)
);

comment on table public.saved_movies is 'Movies a user saved in My Next Movie.';

-- Every user sees and changes only their own rows.
alter table public.saved_movies enable row level security;

create policy "Users read their saved movies"
    on public.saved_movies for select
    to authenticated
    using ((select auth.uid()) = user_id);

create policy "Users save movies for themselves"
    on public.saved_movies for insert
    to authenticated
    with check ((select auth.uid()) = user_id);

create policy "Users remove their saved movies"
    on public.saved_movies for delete
    to authenticated
    using ((select auth.uid()) = user_id);
