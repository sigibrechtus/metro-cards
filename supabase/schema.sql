create table if not exists public.metro_cards (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 18),
  rides integer not null default 0 check (rides >= 0 and rides <= 999),
  color text not null,
  presets integer[] not null default array[10,20,30],
  log jsonb not null default '[]'::jsonb,
  position integer not null default 0,
  updated_at timestamptz not null default now()
);

alter table public.metro_cards enable row level security;

drop policy if exists "Users can read their own metro cards" on public.metro_cards;
create policy "Users can read their own metro cards"
  on public.metro_cards for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can insert their own metro cards" on public.metro_cards;
create policy "Users can insert their own metro cards"
  on public.metro_cards for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their own metro cards" on public.metro_cards;
create policy "Users can update their own metro cards"
  on public.metro_cards for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can delete their own metro cards" on public.metro_cards;
create policy "Users can delete their own metro cards"
  on public.metro_cards for delete to authenticated
  using ((select auth.uid()) = user_id);

create index if not exists metro_cards_user_position_idx
  on public.metro_cards(user_id, position);

grant select, insert, update, delete on public.metro_cards to authenticated;
