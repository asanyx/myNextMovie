-- One row per "I'm in the mood for..." request, so the movie-filters Edge Function
-- can limit how many requests one account sends in a day. Every request costs money
-- at the AI provider, and the account is the only thing that identifies the caller.

create table public.ai_requests (
    id bigint generated always as identity primary key,
    user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
    requested_at timestamptz not null default now()
);

comment on table public.ai_requests is 'AI requests of My Next Movie users, for the daily limit.';

create index ai_requests_user_id_requested_at_idx
    on public.ai_requests (user_id, requested_at);

-- Users add rows only for themselves and see only their own rows.
-- There is no update or delete policy, so nobody can reset their own count.
alter table public.ai_requests enable row level security;

create policy "Users read their AI requests"
    on public.ai_requests for select
    to authenticated
    using ((select auth.uid()) = user_id);

create policy "Users add their AI requests"
    on public.ai_requests for insert
    to authenticated
    with check ((select auth.uid()) = user_id);

-- Records one request of the signed-in user and returns how many requests
-- the user sent in the last 24 hours, this one included.
-- security invoker: runs with the rights of the caller, so RLS applies.
create function public.record_ai_request()
returns integer
language sql
security invoker
set search_path = ''
as $$
    insert into public.ai_requests default values;
    select count(*)::integer
    from public.ai_requests
    where user_id = (select auth.uid())
        and requested_at > now() - interval '24 hours';
$$;

revoke execute on function public.record_ai_request() from public, anon;
grant execute on function public.record_ai_request() to authenticated;
