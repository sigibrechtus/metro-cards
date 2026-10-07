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

-- Versioned whole-set synchronization; stale devices cannot replace newer data.
create table if not exists public.metro_card_sync_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  revision bigint not null default 1 check (revision >= 1),
  updated_at timestamptz not null default now()
);

alter table public.metro_card_sync_state enable row level security;

drop policy if exists "Users can read their own metro card sync state" on public.metro_card_sync_state;
create policy "Users can read their own metro card sync state"
  on public.metro_card_sync_state for select to authenticated
  using ((select auth.uid()) = user_id);

grant select on public.metro_card_sync_state to authenticated;

insert into public.metro_card_sync_state (user_id, revision)
select user_id, 1
from public.metro_cards
group by user_id
on conflict (user_id) do nothing;

create or replace function public.replace_metro_cards_if_revision(
  p_expected_revision bigint,
  p_cards jsonb
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_changed integer;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  if p_cards is null or jsonb_typeof(p_cards) <> 'array' or jsonb_array_length(p_cards) < 1 then
    raise exception 'At least one card is required';
  end if;

  if p_expected_revision = 0 then
    insert into public.metro_card_sync_state (user_id, revision, updated_at)
    values (v_user_id, 1, pg_catalog.now())
    on conflict (user_id) do nothing;
    get diagnostics v_changed = row_count;
    if v_changed = 0 then
      return false;
    end if;
  else
    update public.metro_card_sync_state
       set revision = revision + 1,
           updated_at = pg_catalog.now()
     where user_id = v_user_id
       and revision = p_expected_revision;
    get diagnostics v_changed = row_count;
    if v_changed = 0 then
      return false;
    end if;
  end if;

  delete from public.metro_cards
   where user_id = v_user_id;

  insert into public.metro_cards (id, user_id, name, rides, color, presets, log, position)
  select parsed.id,
         v_user_id,
         parsed.name,
         parsed.rides,
         parsed.color,
         parsed.presets,
         coalesce(parsed.log, '[]'::jsonb),
         parsed.position
    from pg_catalog.jsonb_to_recordset(p_cards) as parsed(
      id text,
      name text,
      rides integer,
      color text,
      presets integer[],
      log jsonb,
      position integer
    );

  return true;
end;
$function$;

revoke all on function public.replace_metro_cards_if_revision(bigint, jsonb) from public;
revoke all on function public.replace_metro_cards_if_revision(bigint, jsonb) from anon;
grant execute on function public.replace_metro_cards_if_revision(bigint, jsonb) to authenticated;
