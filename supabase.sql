-- «Мои деньги»: одна таблица документов, у каждого пользователя свои строки.
-- Вставьте целиком в Supabase → SQL Editor → New query → Run.

create table if not exists public.docs (
  user_id    uuid        not null default auth.uid() references auth.users(id) on delete cascade,
  id         text        not null,
  body       jsonb       not null default '{}'::jsonb,
  deleted    boolean     not null default false,
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);

create index if not exists docs_user_updated on public.docs (user_id, updated_at);

-- Время изменения ставит сервер: по нему устройства забирают новое.
create or replace function public.docs_touch() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists docs_touch on public.docs;
create trigger docs_touch before insert or update on public.docs
for each row execute function public.docs_touch();

-- Каждый видит и меняет только свои строки.
alter table public.docs enable row level security;

drop policy if exists "own rows" on public.docs;
create policy "own rows" on public.docs
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

grant select, insert, update, delete on public.docs to authenticated;
