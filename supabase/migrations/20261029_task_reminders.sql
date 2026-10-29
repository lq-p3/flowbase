-- Task reminders: pg_cron calls the remind edge function every 5 minutes; it sends a Telegram
-- message with "done" / "snooze" buttons for tasks starting in the next 30 minutes.

-- When the Telegram reminder for a task went out (null = not yet).
alter table public.tasks add column if not exists tg_reminded timestamptz;

-- If the task moves to another day or time, it deserves a fresh reminder.
create or replace function public.reset_tg_reminded() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.date is distinct from old.date or new.time is distinct from old.time then
    new.tg_reminded := null;
  end if;
  return new;
end $$;
create or replace trigger tasks_reset_tg_reminded before update on public.tasks
  for each row execute function public.reset_tg_reminded();

insert into public.app_secrets (name, value)
values ('remind', encode(extensions.gen_random_bytes(24), 'hex'))
on conflict (name) do nothing;

select cron.schedule('task-reminders', '*/5 * * * *', $$
  select net.http_post(
    url := 'https://pxvcweqpizrsvqsviiqs.supabase.co/functions/v1/remind',
    headers := jsonb_build_object('Content-Type', 'application/json',
      'x-cron-secret', (select value from public.app_secrets where name = 'remind')),
    body := '{}'::jsonb)
$$);
