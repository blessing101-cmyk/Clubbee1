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
-- CLUB BEE · Phase 2: games, Honey wallet, daily missions (server-validated) — safe to run more than once
do $$ declare tb text; begin
  foreach tb in array array['wallets','wallet_transactions','game_scores','mission_claims'] loop
    execute format('create table if not exists public.%I (id uuid primary key default gen_random_uuid(), data jsonb not null default ''{}'', created_at timestamptz not null default now(), updated_at timestamptz not null default now())', tb);
    execute format('alter table public.%I add column if not exists user_id uuid generated always as ((data->>''user_id'')::uuid) stored', tb);
    execute format('create index if not exists %I on public.%I(user_id)', tb || '_user_idx', tb);
    execute format('alter table public.%I enable row level security', tb);
    execute format('drop trigger if exists trg_touch on public.%I', tb);
    execute format('create trigger trg_touch before update on public.%I for each row execute function public.cb_touch()', tb);
  end loop;
end $$;
alter table public.game_scores add column if not exists game text generated always as (data->>'game') stored;
alter table public.mission_claims add column if not exists mission text generated always as (data->>'mission') stored;
alter table public.mission_claims add column if not exists day text generated always as (data->>'day') stored;
create unique index if not exists wallets_user_uq on public.wallets(user_id);
create unique index if not exists mission_once_uq on public.mission_claims(user_id, mission, day);
create index if not exists game_scores_recent_idx on public.game_scores(user_id, created_at desc);

-- read-only for members; every write goes through the functions below
drop policy if exists w_read on public.wallets;            create policy w_read  on public.wallets for select to authenticated using (user_id = auth.uid() or public.is_admin());
drop policy if exists wt_read on public.wallet_transactions; create policy wt_read on public.wallet_transactions for select to authenticated using (user_id = auth.uid() or public.is_admin());
drop policy if exists gs_read on public.game_scores;        create policy gs_read on public.game_scores for select to authenticated using (true);
drop policy if exists mc_read on public.mission_claims;     create policy mc_read on public.mission_claims for select to authenticated using (user_id = auth.uid() or public.is_admin());

create or replace function public.hive_day() returns text language sql stable as $$ select to_char(now() at time zone 'Asia/Bangkok', 'YYYY-MM-DD') $$;

create or replace function public.hive_credit(u uuid, amount int, reason text, ref text) returns int language plpgsql security definer set search_path = public as $$
declare w wallets; bal int;
begin
  select * into w from wallets where user_id = u for update;
  if w.id is null then
    insert into wallets (id, data) values (gen_random_uuid(), jsonb_build_object('user_id', u, 'balance', amount, 'created_at', now())); bal := amount;
  else
    bal := coalesce((w.data->>'balance')::int, 0) + amount;
    update wallets set data = data || jsonb_build_object('balance', bal, 'updated_at', now()) where id = w.id;
  end if;
  insert into wallet_transactions (id, data) values (gen_random_uuid(), jsonb_build_object('user_id', u, 'amount', amount, 'reason', reason, 'ref', ref, 'balance_after', bal, 'created_at', now()));
  return bal;
end $$;

create or replace function public.hive_game_finish(p_game text, p_score int, p_ms int) returns jsonb language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid(); mx int; minms int; sc int; n int; honey int := 0; xp int := 0; capped boolean := false; bal int; best int;
begin
  if u is null then raise exception 'not signed in'; end if;
  select m, t into mx, minms from (values ('match',2600,8000),('quiz',3600,15000),('heart',1200,8000),('race',1600,4000),('challenge',3000,12000),('puzzle',3000,8000)) v(g, m, t) where g = p_game;
  if mx is null then raise exception 'unknown game'; end if;
  if coalesce(p_ms, 0) < minms then raise exception 'That was too fast to count.'; end if;
  if exists (select 1 from game_scores where user_id = u and created_at > now() - make_interval(secs => minms / 1000.0)) then raise exception 'Slow down a little'; end if;
  sc := greatest(0, least(mx, coalesce(p_score, 0)));
  select count(*) into n from game_scores where user_id = u and game = p_game and to_char(created_at at time zone 'Asia/Bangkok', 'YYYY-MM-DD') = hive_day()
    and (coalesce((data->>'honey')::int, 0) > 0 or coalesce((data->>'xp')::int, 0) > 0);
  if n >= 10 then capped := true; else honey := least(50, sc / 50); xp := least(100, sc / 20); end if;
  insert into game_scores (id, data) values (gen_random_uuid(), jsonb_build_object('user_id', u, 'game', p_game, 'score', sc, 'xp', xp, 'honey', honey, 'ms', p_ms, 'created_at', now()));
  if honey > 0 then bal := hive_credit(u, honey, 'GAME', p_game); else select coalesce((data->>'balance')::int, 0) into bal from wallets where user_id = u; end if;
  select max((data->>'score')::int) into best from game_scores where user_id = u and game = p_game;
  return jsonb_build_object('honey', honey, 'xp', xp, 'capped', capped, 'balance', coalesce(bal, 0), 'best', best);
end $$;

create or replace function public.hive_claim_mission(p_key text) returns jsonb language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid(); d text := hive_day(); prog int := 0; goal int; honey int := 0; xp int := 0;
begin
  if u is null then raise exception 'not signed in'; end if;
  if exists (select 1 from mission_claims where user_id = u and mission = p_key and day = d) then raise exception 'Already claimed today'; end if;
  case p_key
    when 'login' then goal := 1; prog := 1; honey := 10;
    when 'play3' then goal := 3; honey := 30;
    when 'play5' then goal := 5; honey := 20 + floor(random() * 61)::int;
    when 'like3' then goal := 3; honey := 15;
      select count(*) into prog from likes where from_id = u and type in ('like','super') and to_char(created_at at time zone 'Asia/Bangkok', 'YYYY-MM-DD') = d;
    when 'friend' then goal := 1; honey := 20;
      select count(*) into prog from friends where u in (a, b) and data->>'status' = 'accepted' and to_char(updated_at at time zone 'Asia/Bangkok', 'YYYY-MM-DD') = d;
    when 'event' then goal := 1; xp := 50;
      select count(*) into prog from event_members where user_id = u and to_char(created_at at time zone 'Asia/Bangkok', 'YYYY-MM-DD') = d;
    else raise exception 'unknown mission';
  end case;
  if p_key in ('play3', 'play5') then
    select count(*) into prog from game_scores where user_id = u and to_char(created_at at time zone 'Asia/Bangkok', 'YYYY-MM-DD') = d;
  end if;
  if prog < goal then raise exception 'Not finished yet'; end if;
  insert into mission_claims (id, data) values (gen_random_uuid(), jsonb_build_object('user_id', u, 'mission', p_key, 'day', d, 'honey', honey, 'xp', xp, 'created_at', now()));
  if honey > 0 then perform hive_credit(u, honey, 'MISSION', p_key); end if;
  return jsonb_build_object('honey', honey, 'xp', xp);
end $$;

revoke execute on function public.hive_credit(uuid, int, text, text) from public, anon, authenticated;
grant execute on function public.hive_game_finish(text, int, int), public.hive_claim_mission(text) to authenticated;

update public.feature_flags set data = data || '{"enabled":true}' where key in ('ENABLE_GAMES', 'ENABLE_HONEY');
insert into public.feature_flags (id, data)
select gen_random_uuid(), jsonb_build_object('key', k, 'enabled', false, 'created_at', now())
from (values ('ENABLE_KARAOKE'), ('ENABLE_BEE_ART'), ('ENABLE_PETS')) v(k)
where not exists (select 1 from public.feature_flags f where f.key = v.k);

do $$ begin
  begin alter publication supabase_realtime add table public.wallets; exception when duplicate_object then null; end;
end $$;
-- CLUB BEE · Phase 3: Honey Shop, inventory, gifts (server-priced) — safe to run more than once
create table if not exists public.shop_items (id text primary key, cat text not null, price int not null check (price > 0), rarity text not null, active boolean not null default true);
alter table public.shop_items enable row level security;
drop policy if exists si_read on public.shop_items; create policy si_read on public.shop_items for select to anon, authenticated using (true);
drop policy if exists si_write on public.shop_items; create policy si_write on public.shop_items for all to authenticated using (public.has_perm('credits')) with check (public.has_perm('credits'));
insert into public.shop_items (id, cat, price, rarity) values
  ('acc_crown','fashion',300,'epic'),
  ('acc_antenna','fashion',40,'common'),
  ('acc_flower','fashion',50,'common'),
  ('acc_cap','fashion',90,'rare'),
  ('acc_bow','fashion',90,'rare'),
  ('fit_gold','fashion',600,'legendary'),
  ('frame_honey','vip',120,'rare'),
  ('frame_rose','vip',280,'epic'),
  ('frame_royal','vip',1500,'royal'),
  ('pet_bee','pets',80,'common'),
  ('pet_cat','pets',160,'rare'),
  ('pet_dog','pets',160,'rare'),
  ('pet_rabbit','pets',180,'rare'),
  ('pet_panda','pets',350,'epic'),
  ('pet_butterfly','pets',320,'epic'),
  ('pet_dragon','pets',900,'legendary'),
  ('fx_spark','effects',150,'rare'),
  ('fx_hearts','effects',260,'epic'),
  ('room_sofa','room',60,'common'),
  ('room_plant','room',30,'common'),
  ('room_lamp','room',40,'common'),
  ('room_tv','room',140,'rare'),
  ('room_piano','room',400,'epic'),
  ('room_trophy','room',120,'rare'),
  ('room_painting','room',110,'rare'),
  ('room_aquarium','room',700,'legendary'),
  ('gift_rose','gifts',20,'common'),
  ('gift_honey','gifts',30,'common'),
  ('gift_cake','gifts',80,'rare'),
  ('gift_diamond','gifts',500,'legendary')
on conflict (id) do update set price = excluded.price, cat = excluded.cat, rarity = excluded.rarity;

create table if not exists public.user_inventory (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.user_inventory add column if not exists user_id uuid generated always as ((data->>'user_id')::uuid) stored;
alter table public.user_inventory add column if not exists item text generated always as (data->>'item') stored;
create unique index if not exists inv_user_item_uq on public.user_inventory(user_id, item);
alter table public.user_inventory enable row level security;
drop trigger if exists trg_touch on public.user_inventory; create trigger trg_touch before update on public.user_inventory for each row execute function public.cb_touch();
drop policy if exists inv_read on public.user_inventory; create policy inv_read on public.user_inventory for select to authenticated using (user_id = auth.uid() or public.is_admin());

create or replace function public.hive_add_item(u uuid, p_item text, p_from uuid) returns void language plpgsql security definer set search_path = public as $$
begin
  update user_inventory set data = data || jsonb_build_object('qty', coalesce((data->>'qty')::int, 0) + 1) where user_id = u and item = p_item;
  if not found then insert into user_inventory (id, data) values (gen_random_uuid(), jsonb_build_object('user_id', u, 'item', p_item, 'qty', 1, 'from', p_from, 'created_at', now())); end if;
end $$;

create or replace function public.hive_buy(p_item text) returns jsonb language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid(); it shop_items; bal int;
begin
  if u is null then raise exception 'not signed in'; end if;
  select * into it from shop_items where id = p_item and active; if it.id is null then raise exception 'item not available'; end if;
  if it.cat = 'gifts' then raise exception 'gifts are sent to other members'; end if;
  select coalesce((data->>'balance')::int, 0) into bal from wallets where user_id = u for update;
  if coalesce(bal, 0) < it.price then raise exception 'Not enough Honey'; end if;
  bal := hive_credit(u, -it.price, 'SHOP', p_item);
  perform hive_add_item(u, p_item, null);
  return jsonb_build_object('balance', bal);
end $$;

create or replace function public.hive_gift(p_to uuid, p_item text) returns jsonb language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid(); it shop_items; bal int; nm text;
begin
  if u is null or p_to is null or p_to = u then raise exception 'not allowed'; end if;
  if exists (select 1 from blocks where (blocker_id = u and blocked_id = p_to) or (blocker_id = p_to and blocked_id = u)) then raise exception 'not allowed'; end if;
  select * into it from shop_items where id = p_item and active; if it.id is null then raise exception 'item not available'; end if;
  select coalesce((data->>'balance')::int, 0) into bal from wallets where user_id = u for update;
  if coalesce(bal, 0) < it.price then raise exception 'Not enough Honey'; end if;
  bal := hive_credit(u, -it.price, 'GIFT', p_item);
  perform hive_add_item(p_to, p_item, u);
  select data->>'display_name' into nm from profiles where user_id = u;
  insert into notifications (id, data) values (gen_random_uuid(), jsonb_build_object('user_id', p_to, 'type', 'gift', 'vars', jsonb_build_object('name', nm, 'item', p_item), 'read', false, 'created_at', now()));
  return jsonb_build_object('balance', bal);
end $$;

revoke execute on function public.hive_add_item(uuid, text, uuid) from public, anon, authenticated;
grant execute on function public.hive_buy(text), public.hive_gift(uuid, text) to authenticated;
update public.feature_flags set data = data || '{"enabled":true}' where key in ('ENABLE_SHOP', 'ENABLE_VIRTUAL_DATE', 'ENABLE_PETS');
