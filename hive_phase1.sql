-- CLUB BEE · The Hive Phase 1 (virtual world, friends, follow, presence)  — safe to run more than once
create table if not exists public.friends (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.friends add column if not exists a uuid generated always as ((data->>'a')::uuid) stored;
alter table public.friends add column if not exists b uuid generated always as ((data->>'b')::uuid) stored;
create unique index if not exists friends_pair_uq on public.friends (least(a,b), greatest(a,b));
create table if not exists public.followers (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.followers add column if not exists follower_id uuid generated always as ((data->>'follower_id')::uuid) stored;
alter table public.followers add column if not exists followee_id uuid generated always as ((data->>'followee_id')::uuid) stored;
create unique index if not exists followers_uq on public.followers (follower_id, followee_id);
create table if not exists public.virtual_locations (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.virtual_locations add column if not exists user_id uuid generated always as ((data->>'user_id')::uuid) stored;
create unique index if not exists vloc_user_uq on public.virtual_locations (user_id);

do $$ declare tb text; begin
  foreach tb in array array['friends','followers','virtual_locations'] loop
    execute format('alter table public.%I enable row level security', tb);
    execute format('drop trigger if exists trg_touch on public.%I', tb);
    execute format('create trigger trg_touch before update on public.%I for each row execute function public.cb_touch()', tb);
  end loop;
end $$;

-- friends: only the two people involved; the requester cannot accept their own request
create or replace function public.g_friends() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    if (new.data->>'requested_by')::uuid is distinct from auth.uid() or (new.data->>'a')::uuid is distinct from auth.uid() or (new.data->>'b')::uuid = auth.uid() then raise exception 'not allowed'; end if;
    new.data := new.data || '{"status":"pending"}';
    return new;
  end if;
  if new.data->>'status' = 'accepted' and old.data->>'status' = 'pending' and (old.data->>'requested_by')::uuid = auth.uid() then raise exception 'cannot accept your own request'; end if;
  new.data := new.data || jsonb_build_object('a', old.data->'a', 'b', old.data->'b', 'requested_by', old.data->'requested_by');
  return new;
end $$;
drop trigger if exists g_friends on public.friends;
create trigger g_friends before insert or update on public.friends for each row execute function public.g_friends();

drop policy if exists fr_read on public.friends;   drop policy if exists fr_insert on public.friends;
drop policy if exists fr_update on public.friends; drop policy if exists fr_delete on public.friends;
create policy fr_read   on public.friends for select to authenticated using (auth.uid() in (a, b) or public.is_admin());
create policy fr_insert on public.friends for insert to authenticated with check (a = auth.uid());
create policy fr_update on public.friends for update to authenticated using (auth.uid() in (a, b));
create policy fr_delete on public.friends for delete to authenticated using (auth.uid() in (a, b));

drop policy if exists fo_read on public.followers; drop policy if exists fo_insert on public.followers; drop policy if exists fo_delete on public.followers;
create policy fo_read   on public.followers for select to authenticated using (true);
create policy fo_insert on public.followers for insert to authenticated with check (follower_id = auth.uid() and followee_id <> auth.uid());
create policy fo_delete on public.followers for delete to authenticated using (follower_id = auth.uid());

drop policy if exists vl_read on public.virtual_locations; drop policy if exists vl_write on public.virtual_locations;
create policy vl_read  on public.virtual_locations for select to authenticated using (true);
create policy vl_write on public.virtual_locations for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

do $$ declare tb text; begin
  foreach tb in array array['friends','followers','virtual_locations'] loop
    begin execute format('alter publication supabase_realtime add table public.%I', tb); exception when duplicate_object then null; end;
  end loop;
end $$;

insert into public.feature_flags (id, data)
select gen_random_uuid(), jsonb_build_object('key', k, 'enabled', e, 'created_at', now())
from (values ('ENABLE_VIRTUAL_WORLD', true), ('ENABLE_AVATAR', true), ('ENABLE_DATING', true), ('ENABLE_GAMES', false),
             ('ENABLE_HONEY', false), ('ENABLE_SHOP', false), ('ENABLE_VIRTUAL_DATE', false)) v(k, e)
where not exists (select 1 from public.feature_flags f where f.key = v.k);
