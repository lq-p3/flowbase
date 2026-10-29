# FlowBase notes for Claude sessions

## Supabase is already deployed: do not deploy it from this machine
- Everything under `supabase/` (edge functions `assistant`, `telegram`, `brief`, `remind` and the SQL in
  `supabase/migrations/`) is deployed straight to the Supabase project through the Supabase connector,
  from the cloud session that writes it. It is live as soon as it is pushed here.
- The files in `supabase/migrations/` are a record of SQL that has **already been applied**. Never run them
  again, never run `supabase db push`, and never deploy functions from this Mac.
- So never ask Ali to run `supabase login`, create an access token, or paste code into the dashboard.

## Commits
- Commit as `lq-p3 <Mz5040zm@gmail.com>`, with no Co-Authored-By, Claude-Session or other Claude attribution.

## Installing on Ali's iPhone
`cd ~/development/flowbase && git pull && flutter pub get && flutter build ios --release && flutter install --release`
(free signing expires every 7 days; reinstalling renews it)
