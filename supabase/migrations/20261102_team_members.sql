-- Phase 5, the team: people the manager gives tasks to. Already applied through the Supabase connector.
create table public.team_members (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null check (length(name) between 1 and 80),
  role text not null default '' check (length(role) <= 80),
  created_at timestamptz not null default now(),
  unique (user_id, name)
);
alter table public.team_members enable row level security;
create policy "own team select" on public.team_members for select to authenticated using ((select auth.uid()) = user_id);
create policy "own team insert" on public.team_members for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "own team update" on public.team_members for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "own team delete" on public.team_members for delete to authenticated using ((select auth.uid()) = user_id);

alter table public.tasks add column assignee_id uuid references public.team_members(id) on delete set null;
create index tasks_assignee_id_idx on public.tasks(assignee_id);
create index team_members_user_id_idx on public.team_members(user_id);
