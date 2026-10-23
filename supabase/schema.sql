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

-- Migration shared_household_lists: all lists are shared by members of an email allowlist.
create table public.members (
  email text primary key check (email = lower(email) and email like '%@%'),
  added_by uuid references auth.users(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now()
);
alter table public.members enable row level security;

create or replace function public.is_member()
returns boolean language sql stable security definer set search_path = ''
as $$ select exists (select 1 from public.members where email = lower(auth.jwt() ->> 'email')) $$;
revoke execute on function public.is_member() from public, anon;
grant execute on function public.is_member() to authenticated;

-- The very first account becomes a member so the household can bootstrap itself.
create or replace function public.bootstrap_first_member()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if not exists (select 1 from public.members) and new.email is not null then
    insert into public.members (email, added_by) values (lower(new.email), new.id);
  end if;
  return new;
end $$;
revoke execute on function public.bootstrap_first_member() from public, anon, authenticated;
create trigger on_auth_user_created_bootstrap
  after insert on auth.users for each row execute function public.bootstrap_first_member();

alter table public.history drop constraint history_pkey, add primary key (key);
alter table public.lists alter column user_id drop not null;
alter table public.items alter column user_id drop not null;
alter table public.history alter column user_id drop not null;
alter table public.lists drop constraint lists_user_id_fkey,
  add constraint lists_user_id_fkey foreign key (user_id) references auth.users(id) on delete set null;
alter table public.items drop constraint items_user_id_fkey,
  add constraint items_user_id_fkey foreign key (user_id) references auth.users(id) on delete set null;
alter table public.history drop constraint history_user_id_fkey,
  add constraint history_user_id_fkey foreign key (user_id) references auth.users(id) on delete set null;

drop policy "own lists" on public.lists;
drop policy "own items" on public.items;
drop policy "own history" on public.history;

create policy "members share lists" on public.lists for all to authenticated
  using ((select public.is_member())) with check ((select public.is_member()));
create policy "members share items" on public.items for all to authenticated
  using ((select public.is_member())) with check ((select public.is_member()));
create policy "members share history" on public.history for all to authenticated
  using ((select public.is_member())) with check ((select public.is_member()));

create policy "members see members" on public.members for select to authenticated
  using ((select public.is_member()));
create policy "members add members" on public.members for insert to authenticated
  with check ((select public.is_member()));
create policy "members remove members" on public.members for delete to authenticated
  using ((select public.is_member()));

revoke all on public.members from anon;
grant select, insert, delete on public.members to authenticated;
