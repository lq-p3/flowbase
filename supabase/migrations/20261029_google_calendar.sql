-- Google Calendar link per user. The refresh token lets the server read and add events for the user.
-- RLS on with no policies: only the server (service role) can read it, never the app.
create table if not exists public.google_links (
  user_id uuid primary key references auth.users (id) on delete cascade,
  refresh_token text not null,
  email text,
  created_at timestamptz not null default now()
);
alter table public.google_links enable row level security;

-- One-time "state" values for the Google sign-in link, so the callback knows which user it is for.
create table if not exists public.google_link_states (
  state text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  expires_at timestamptz not null
);
alter table public.google_link_states enable row level security;
