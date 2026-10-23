-- Applied to Supabase project "inhouse" (oonezttazqelfrxzqoop) as migration init_lists_items_history.
create table public.lists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null check (length(name) between 1 and 100),
  created_at timestamptz not null default now()
);
create index lists_user_id_idx on public.lists(user_id);

create table public.items (
  id uuid primary key default gen_random_uuid(),
  list_id uuid not null references public.lists(id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null check (length(name) between 1 and 200),
  qty text not null default '',
  cat text not null default 'Other',
  done boolean not null default false,
  created_at timestamptz not null default now()
);
create index items_list_id_idx on public.items(list_id);
create index items_user_id_idx on public.items(user_id);

create table public.history (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  key text not null,
  name text not null,
  cat text,
  count integer not null default 1,
  last timestamptz not null default now(),
  primary key (user_id, key)
);

alter table public.lists enable row level security;
alter table public.items enable row level security;
alter table public.history enable row level security;

create policy "own lists" on public.lists for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "own items" on public.items for all to authenticated
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid())
    and exists (select 1 from public.lists l where l.id = list_id and l.user_id = (select auth.uid()))
  );

create policy "own history" on public.history for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

revoke all on public.lists, public.items, public.history from anon;
grant select, insert, update, delete on public.lists, public.items, public.history to authenticated;

alter publication supabase_realtime add table public.lists, public.items;
