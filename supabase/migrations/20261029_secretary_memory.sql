-- Things the secretary remembers about the user: preferences, people, habits.
create table if not exists public.memories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  text text not null check (length(text) between 1 and 500),
  created_at timestamptz not null default now()
);
create index if not exists memories_user_id_idx on public.memories (user_id);
alter table public.memories enable row level security;

-- Each user sees and manages only their own memories (for a future screen in the app).
create policy "own memories: read" on public.memories for select to authenticated using ((select auth.uid()) = user_id);
create policy "own memories: add" on public.memories for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "own memories: delete" on public.memories for delete to authenticated using ((select auth.uid()) = user_id);
