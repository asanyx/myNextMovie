-- Test account for development: test@test.test, password "test".
-- Debug builds of the app fill the sign in screen with it.
--
-- The password is shorter than `minimum_password_length`, so the sign up form
-- cannot create this account. That limit is checked only when an account is
-- created through the API, so the row is written here directly.
--
--   supabase db reset                 local database, runs this file
--   supabase db push --include-seed   hosted project
--
-- Running it again changes nothing.

do $$
declare
    test_user_id uuid := gen_random_uuid();
begin
    if exists (select 1 from auth.users where email = 'test@test.test') then
        return;
    end if;

    -- The auth server expects empty strings, not null, in the token columns.
    insert into auth.users (
        instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
        confirmation_token, recovery_token, email_change, email_change_token_new
    ) values (
        '00000000-0000-0000-0000-000000000000', test_user_id, 'authenticated', 'authenticated',
        'test@test.test', extensions.crypt('test', extensions.gen_salt('bf')), now(),
        '{"provider": "email", "providers": ["email"]}', '{}', now(), now(),
        '', '', '', ''
    );

    insert into auth.identities (
        id, user_id, provider_id, provider, identity_data,
        last_sign_in_at, created_at, updated_at
    ) values (
        gen_random_uuid(), test_user_id, test_user_id::text, 'email',
        jsonb_build_object(
            'sub', test_user_id::text, 'email', 'test@test.test', 'email_verified', true
        ),
        now(), now(), now()
    );
end $$;
