-- Morning brief: pg_cron calls the brief edge function every hour; the function sends to users whose local time is 8 AM.
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- Private server-only values. RLS on with no policies: only the service role can read it.
create table if not exists public.app_secrets (name text primary key, value text not null);
alter table public.app_secrets enable row level security;
insert into public.app_secrets (name, value)
values ('brief', encode(extensions.gen_random_bytes(24), 'hex'))
on conflict (name) do nothing;

-- Remember the last day a brief went out, so a user never gets two on the same day.
alter table public.telegram_links add column if not exists last_brief date;

select cron.schedule('morning-brief', '0 * * * *', $$
  select net.http_post(
    url := 'https://pxvcweqpizrsvqsviiqs.supabase.co/functions/v1/brief',
    headers := jsonb_build_object('Content-Type', 'application/json',
      'x-brief-secret', (select value from public.app_secrets where name = 'brief')),
    body := '{}'::jsonb)
$$);
