-- =====================================================================
--  CLUB BEE — ผึ้งน้อยรุมล้อม · Supabase setup (run once in SQL Editor)
--  1) Change the SUPER_ADMIN email on the line marked ★ below
--  2) Paste this whole file into Supabase → SQL Editor → Run
--  Safe to run again (idempotent). Creates tables, security (RLS),
--  triggers, RPC functions, storage bucket, realtime and launch config.
-- =====================================================================
create extension if not exists pgcrypto;

create table if not exists public.app_config (key text primary key, value text not null);
alter table public.app_config enable row level security;   -- no policies: only SECURITY DEFINER functions read it
insert into public.app_config(key, value) values
  ('super_admin_email', 'happysolarth@gmail.com')          -- ★ SUPER_ADMIN email
on conflict (key) do update set value = excluded.value;

create sequence if not exists public.case_no_seq start 1001;

create or replace function public.cb_touch() returns trigger language plpgsql as $$
begin new.updated_at := now(); return new; end $$;
create table if not exists public.users (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.users add column if not exists status text generated always as ((data->>'status')) stored;
create index if not exists users_status_idx on public.users(status);
alter table public.users enable row level security;
drop trigger if exists trg_touch on public.users; create trigger trg_touch before update on public.users for each row execute function public.cb_touch();

create table if not exists public.profiles (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.profiles add column if not exists user_id uuid generated always as (((data->>'user_id')::uuid)) stored;
create index if not exists profiles_user_id_idx on public.profiles(user_id);
alter table public.profiles enable row level security;
drop trigger if exists trg_touch on public.profiles; create trigger trg_touch before update on public.profiles for each row execute function public.cb_touch();

create table if not exists public.photos (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.photos add column if not exists user_id uuid generated always as (((data->>'user_id')::uuid)) stored;
create index if not exists photos_user_id_idx on public.photos(user_id);
alter table public.photos enable row level security;
drop trigger if exists trg_touch on public.photos; create trigger trg_touch before update on public.photos for each row execute function public.cb_touch();

create table if not exists public.preferences (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.preferences add column if not exists user_id uuid generated always as (((data->>'user_id')::uuid)) stored;
create index if not exists preferences_user_id_idx on public.preferences(user_id);
alter table public.preferences enable row level security;
drop trigger if exists trg_touch on public.preferences; create trigger trg_touch before update on public.preferences for each row execute function public.cb_touch();

create table if not exists public.interests (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.interests add column if not exists user_id uuid generated always as (((data->>'user_id')::uuid)) stored;
create index if not exists interests_user_id_idx on public.interests(user_id);
alter table public.interests enable row level security;
drop trigger if exists trg_touch on public.interests; create trigger trg_touch before update on public.interests for each row execute function public.cb_touch();

create table if not exists public.likes (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.likes add column if not exists from_id uuid generated always as (((data->>'from_id')::uuid)) stored;
create index if not exists likes_from_id_idx on public.likes(from_id);
alter table public.likes add column if not exists to_id uuid generated always as (((data->>'to_id')::uuid)) stored;
create index if not exists likes_to_id_idx on public.likes(to_id);
alter table public.likes add column if not exists type text generated always as ((data->>'type')) stored;
create index if not exists likes_type_idx on public.likes(type);
alter table public.likes enable row level security;
drop trigger if exists trg_touch on public.likes; create trigger trg_touch before update on public.likes for each row execute function public.cb_touch();

create table if not exists public.super_likes (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.super_likes add column if not exists from_id uuid generated always as (((data->>'from_id')::uuid)) stored;
create index if not exists super_likes_from_id_idx on public.super_likes(from_id);
alter table public.super_likes add column if not exists to_id uuid generated always as (((data->>'to_id')::uuid)) stored;
create index if not exists super_likes_to_id_idx on public.super_likes(to_id);
alter table public.super_likes enable row level security;
drop trigger if exists trg_touch on public.super_likes; create trigger trg_touch before update on public.super_likes for each row execute function public.cb_touch();

create table if not exists public.matches (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.matches add column if not exists user_a uuid generated always as (((data->>'user_a')::uuid)) stored;
create index if not exists matches_user_a_idx on public.matches(user_a);
alter table public.matches add column if not exists user_b uuid generated always as (((data->>'user_b')::uuid)) stored;
create index if not exists matches_user_b_idx on public.matches(user_b);
alter table public.matches enable row level security;
drop trigger if exists trg_touch on public.matches; create trigger trg_touch before update on public.matches for each row execute function public.cb_touch();

create table if not exists public.blocks (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.blocks add column if not exists blocker_id uuid generated always as (((data->>'blocker_id')::uuid)) stored;
create index if not exists blocks_blocker_id_idx on public.blocks(blocker_id);
alter table public.blocks add column if not exists blocked_id uuid generated always as (((data->>'blocked_id')::uuid)) stored;
create index if not exists blocks_blocked_id_idx on public.blocks(blocked_id);
alter table public.blocks enable row level security;
drop trigger if exists trg_touch on public.blocks; create trigger trg_touch before update on public.blocks for each row execute function public.cb_touch();

create table if not exists public.conversations (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.conversations add column if not exists match_id uuid generated always as (((data->>'match_id')::uuid)) stored;
create index if not exists conversations_match_id_idx on public.conversations(match_id);
alter table public.conversations enable row level security;
drop trigger if exists trg_touch on public.conversations; create trigger trg_touch before update on public.conversations for each row execute function public.cb_touch();

create table if not exists public.messages (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.messages add column if not exists conversation_id uuid generated always as (((data->>'conversation_id')::uuid)) stored;
create index if not exists messages_conversation_id_idx on public.messages(conversation_id);
alter table public.messages add column if not exists sender_id uuid generated always as (((data->>'sender_id')::uuid)) stored;
create index if not exists messages_sender_id_idx on public.messages(sender_id);
alter table public.messages enable row level security;
drop trigger if exists trg_touch on public.messages; create trigger trg_touch before update on public.messages for each row execute function public.cb_touch();

create table if not exists public.date_requests (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.date_requests add column if not exists conversation_id uuid generated always as (((data->>'conversation_id')::uuid)) stored;
create index if not exists date_requests_conversation_id_idx on public.date_requests(conversation_id);
alter table public.date_requests add column if not exists from_id uuid generated always as (((data->>'from_id')::uuid)) stored;
create index if not exists date_requests_from_id_idx on public.date_requests(from_id);
alter table public.date_requests add column if not exists to_id uuid generated always as (((data->>'to_id')::uuid)) stored;
create index if not exists date_requests_to_id_idx on public.date_requests(to_id);
alter table public.date_requests enable row level security;
drop trigger if exists trg_touch on public.date_requests; create trigger trg_touch before update on public.date_requests for each row execute function public.cb_touch();

create table if not exists public.date_events (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.date_events add column if not exists date_request_id uuid generated always as (((data->>'date_request_id')::uuid)) stored;
create index if not exists date_events_date_request_id_idx on public.date_events(date_request_id);
alter table public.date_events enable row level security;
drop trigger if exists trg_touch on public.date_events; create trigger trg_touch before update on public.date_events for each row execute function public.cb_touch();

create table if not exists public.memberships (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.memberships add column if not exists user_id uuid generated always as (((data->>'user_id')::uuid)) stored;
create index if not exists memberships_user_id_idx on public.memberships(user_id);
alter table public.memberships add column if not exists plan_code text generated always as ((data->>'plan_code')) stored;
create index if not exists memberships_plan_code_idx on public.memberships(plan_code);
alter table public.memberships add column if not exists status text generated always as ((data->>'status')) stored;
create index if not exists memberships_status_idx on public.memberships(status);
alter table public.memberships enable row level security;
drop trigger if exists trg_touch on public.memberships; create trigger trg_touch before update on public.memberships for each row execute function public.cb_touch();

create table if not exists public.membership_plans (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.membership_plans add column if not exists code text generated always as ((data->>'code')) stored;
create index if not exists membership_plans_code_idx on public.membership_plans(code);
alter table public.membership_plans enable row level security;
drop trigger if exists trg_touch on public.membership_plans; create trigger trg_touch before update on public.membership_plans for each row execute function public.cb_touch();

create table if not exists public.membership_permissions (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.membership_permissions add column if not exists plan_code text generated always as ((data->>'plan_code')) stored;
create index if not exists membership_permissions_plan_code_idx on public.membership_permissions(plan_code);
alter table public.membership_permissions add column if not exists key text generated always as ((data->>'key')) stored;
create index if not exists membership_permissions_key_idx on public.membership_permissions(key);
alter table public.membership_permissions enable row level security;
drop trigger if exists trg_touch on public.membership_permissions; create trigger trg_touch before update on public.membership_permissions for each row execute function public.cb_touch();

create table if not exists public.subscriptions (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.subscriptions add column if not exists user_id uuid generated always as (((data->>'user_id')::uuid)) stored;
create index if not exists subscriptions_user_id_idx on public.subscriptions(user_id);
alter table public.subscriptions enable row level security;
drop trigger if exists trg_touch on public.subscriptions; create trigger trg_touch before update on public.subscriptions for each row execute function public.cb_touch();

create table if not exists public.waitlist (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.waitlist add column if not exists user_id uuid generated always as (((data->>'user_id')::uuid)) stored;
create index if not exists waitlist_user_id_idx on public.waitlist(user_id);
alter table public.waitlist enable row level security;
drop trigger if exists trg_touch on public.waitlist; create trigger trg_touch before update on public.waitlist for each row execute function public.cb_touch();

create table if not exists public.credits (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.credits add column if not exists user_id uuid generated always as (((data->>'user_id')::uuid)) stored;
create index if not exists credits_user_id_idx on public.credits(user_id);
alter table public.credits enable row level security;
drop trigger if exists trg_touch on public.credits; create trigger trg_touch before update on public.credits for each row execute function public.cb_touch();

create table if not exists public.credit_packages (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.credit_packages enable row level security;
drop trigger if exists trg_touch on public.credit_packages; create trigger trg_touch before update on public.credit_packages for each row execute function public.cb_touch();

create table if not exists public.credit_transactions (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.credit_transactions add column if not exists user_id uuid generated always as (((data->>'user_id')::uuid)) stored;
create index if not exists credit_transactions_user_id_idx on public.credit_transactions(user_id);
alter table public.credit_transactions enable row level security;
drop trigger if exists trg_touch on public.credit_transactions; create trigger trg_touch before update on public.credit_transactions for each row execute function public.cb_touch();

create table if not exists public.boosts (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.boosts add column if not exists user_id uuid generated always as (((data->>'user_id')::uuid)) stored;
create index if not exists boosts_user_id_idx on public.boosts(user_id);
alter table public.boosts enable row level security;
drop trigger if exists trg_touch on public.boosts; create trigger trg_touch before update on public.boosts for each row execute function public.cb_touch();

create table if not exists public.payments (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.payments add column if not exists user_id uuid generated always as (((data->>'user_id')::uuid)) stored;
create index if not exists payments_user_id_idx on public.payments(user_id);
alter table public.payments enable row level security;
drop trigger if exists trg_touch on public.payments; create trigger trg_touch before update on public.payments for each row execute function public.cb_touch();

create table if not exists public.promotions (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.promotions add column if not exists code text generated always as ((data->>'code')) stored;
create index if not exists promotions_code_idx on public.promotions(code);
alter table public.promotions enable row level security;
drop trigger if exists trg_touch on public.promotions; create trigger trg_touch before update on public.promotions for each row execute function public.cb_touch();

create table if not exists public.referrals (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.referrals add column if not exists referrer_id uuid generated always as (((data->>'referrer_id')::uuid)) stored;
create index if not exists referrals_referrer_id_idx on public.referrals(referrer_id);
alter table public.referrals add column if not exists new_user_id uuid generated always as (((data->>'new_user_id')::uuid)) stored;
create index if not exists referrals_new_user_id_idx on public.referrals(new_user_id);
alter table public.referrals enable row level security;
drop trigger if exists trg_touch on public.referrals; create trigger trg_touch before update on public.referrals for each row execute function public.cb_touch();

create table if not exists public.notifications (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.notifications add column if not exists user_id uuid generated always as (((data->>'user_id')::uuid)) stored;
create index if not exists notifications_user_id_idx on public.notifications(user_id);
alter table public.notifications enable row level security;
drop trigger if exists trg_touch on public.notifications; create trigger trg_touch before update on public.notifications for each row execute function public.cb_touch();

create table if not exists public.reports (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.reports add column if not exists reporter_id uuid generated always as (((data->>'reporter_id')::uuid)) stored;
create index if not exists reports_reporter_id_idx on public.reports(reporter_id);
alter table public.reports add column if not exists target_user_id uuid generated always as (((data->>'target_user_id')::uuid)) stored;
create index if not exists reports_target_user_id_idx on public.reports(target_user_id);
alter table public.reports enable row level security;
drop trigger if exists trg_touch on public.reports; create trigger trg_touch before update on public.reports for each row execute function public.cb_touch();

create table if not exists public.moderation_cases (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.moderation_cases add column if not exists target_user_id uuid generated always as (((data->>'target_user_id')::uuid)) stored;
create index if not exists moderation_cases_target_user_id_idx on public.moderation_cases(target_user_id);
alter table public.moderation_cases add column if not exists conversation_id uuid generated always as (((data->>'conversation_id')::uuid)) stored;
create index if not exists moderation_cases_conversation_id_idx on public.moderation_cases(conversation_id);
alter table public.moderation_cases enable row level security;
drop trigger if exists trg_touch on public.moderation_cases; create trigger trg_touch before update on public.moderation_cases for each row execute function public.cb_touch();

create table if not exists public.moderation_actions (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.moderation_actions add column if not exists case_id uuid generated always as (((data->>'case_id')::uuid)) stored;
create index if not exists moderation_actions_case_id_idx on public.moderation_actions(case_id);
alter table public.moderation_actions enable row level security;
drop trigger if exists trg_touch on public.moderation_actions; create trigger trg_touch before update on public.moderation_actions for each row execute function public.cb_touch();

create table if not exists public.verification_requests (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.verification_requests add column if not exists user_id uuid generated always as (((data->>'user_id')::uuid)) stored;
create index if not exists verification_requests_user_id_idx on public.verification_requests(user_id);
alter table public.verification_requests enable row level security;
drop trigger if exists trg_touch on public.verification_requests; create trigger trg_touch before update on public.verification_requests for each row execute function public.cb_touch();

create table if not exists public.admin_users (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.admin_users add column if not exists email text generated always as ((lower(data->>'email'))) stored;
create index if not exists admin_users_email_idx on public.admin_users(email);
alter table public.admin_users add column if not exists role text generated always as ((data->>'role')) stored;
create index if not exists admin_users_role_idx on public.admin_users(role);
alter table public.admin_users add column if not exists auth_id uuid generated always as (((data->>'auth_id')::uuid)) stored;
create index if not exists admin_users_auth_id_idx on public.admin_users(auth_id);
alter table public.admin_users add column if not exists status text generated always as ((data->>'status')) stored;
create index if not exists admin_users_status_idx on public.admin_users(status);
alter table public.admin_users enable row level security;
drop trigger if exists trg_touch on public.admin_users; create trigger trg_touch before update on public.admin_users for each row execute function public.cb_touch();

create table if not exists public.roles (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.roles add column if not exists code text generated always as ((data->>'code')) stored;
create index if not exists roles_code_idx on public.roles(code);
alter table public.roles enable row level security;
drop trigger if exists trg_touch on public.roles; create trigger trg_touch before update on public.roles for each row execute function public.cb_touch();

create table if not exists public.permissions (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.permissions add column if not exists key text generated always as ((data->>'key')) stored;
create index if not exists permissions_key_idx on public.permissions(key);
alter table public.permissions enable row level security;
drop trigger if exists trg_touch on public.permissions; create trigger trg_touch before update on public.permissions for each row execute function public.cb_touch();

create table if not exists public.audit_logs (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.audit_logs add column if not exists action text generated always as ((data->>'action')) stored;
create index if not exists audit_logs_action_idx on public.audit_logs(action);
alter table public.audit_logs enable row level security;
drop trigger if exists trg_touch on public.audit_logs; create trigger trg_touch before update on public.audit_logs for each row execute function public.cb_touch();

create table if not exists public.consents (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.consents add column if not exists user_id uuid generated always as (((data->>'user_id')::uuid)) stored;
create index if not exists consents_user_id_idx on public.consents(user_id);
alter table public.consents enable row level security;
drop trigger if exists trg_touch on public.consents; create trigger trg_touch before update on public.consents for each row execute function public.cb_touch();

create table if not exists public.terms_versions (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.terms_versions add column if not exists type text generated always as ((data->>'type')) stored;
create index if not exists terms_versions_type_idx on public.terms_versions(type);
alter table public.terms_versions enable row level security;
drop trigger if exists trg_touch on public.terms_versions; create trigger trg_touch before update on public.terms_versions for each row execute function public.cb_touch();

create table if not exists public.privacy_versions (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.privacy_versions add column if not exists type text generated always as ((data->>'type')) stored;
create index if not exists privacy_versions_type_idx on public.privacy_versions(type);
alter table public.privacy_versions enable row level security;
drop trigger if exists trg_touch on public.privacy_versions; create trigger trg_touch before update on public.privacy_versions for each row execute function public.cb_touch();

create table if not exists public.safety_acknowledgements (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.safety_acknowledgements add column if not exists user_id uuid generated always as (((data->>'user_id')::uuid)) stored;
create index if not exists safety_acknowledgements_user_id_idx on public.safety_acknowledgements(user_id);
alter table public.safety_acknowledgements enable row level security;
drop trigger if exists trg_touch on public.safety_acknowledgements; create trigger trg_touch before update on public.safety_acknowledgements for each row execute function public.cb_touch();

create table if not exists public.communities (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.communities enable row level security;
drop trigger if exists trg_touch on public.communities; create trigger trg_touch before update on public.communities for each row execute function public.cb_touch();

create table if not exists public.community_members (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.community_members add column if not exists community_id uuid generated always as (((data->>'community_id')::uuid)) stored;
create index if not exists community_members_community_id_idx on public.community_members(community_id);
alter table public.community_members add column if not exists user_id uuid generated always as (((data->>'user_id')::uuid)) stored;
create index if not exists community_members_user_id_idx on public.community_members(user_id);
alter table public.community_members enable row level security;
drop trigger if exists trg_touch on public.community_members; create trigger trg_touch before update on public.community_members for each row execute function public.cb_touch();

create table if not exists public.events (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.events enable row level security;
drop trigger if exists trg_touch on public.events; create trigger trg_touch before update on public.events for each row execute function public.cb_touch();

create table if not exists public.event_members (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.event_members add column if not exists event_id uuid generated always as (((data->>'event_id')::uuid)) stored;
create index if not exists event_members_event_id_idx on public.event_members(event_id);
alter table public.event_members add column if not exists user_id uuid generated always as (((data->>'user_id')::uuid)) stored;
create index if not exists event_members_user_id_idx on public.event_members(user_id);
alter table public.event_members enable row level security;
drop trigger if exists trg_touch on public.event_members; create trigger trg_touch before update on public.event_members for each row execute function public.cb_touch();

create table if not exists public.content (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.content enable row level security;
drop trigger if exists trg_touch on public.content; create trigger trg_touch before update on public.content for each row execute function public.cb_touch();

create table if not exists public.system_settings (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.system_settings add column if not exists key text generated always as ((data->>'key')) stored;
create index if not exists system_settings_key_idx on public.system_settings(key);
alter table public.system_settings enable row level security;
drop trigger if exists trg_touch on public.system_settings; create trigger trg_touch before update on public.system_settings for each row execute function public.cb_touch();

create table if not exists public.feature_flags (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.feature_flags add column if not exists key text generated always as ((data->>'key')) stored;
create index if not exists feature_flags_key_idx on public.feature_flags(key);
alter table public.feature_flags enable row level security;
drop trigger if exists trg_touch on public.feature_flags; create trigger trg_touch before update on public.feature_flags for each row execute function public.cb_touch();

create table if not exists public.otp_codes (id uuid primary key default gen_random_uuid(), data jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
alter table public.otp_codes enable row level security;
drop trigger if exists trg_touch on public.otp_codes; create trigger trg_touch before update on public.otp_codes for each row execute function public.cb_touch();

alter table public.conversations add column if not exists u1 uuid generated always as ((data->'members'->>0)::uuid) stored;
alter table public.conversations add column if not exists u2 uuid generated always as ((data->'members'->>1)::uuid) stored;
create index if not exists conversations_u1_idx on public.conversations(u1);
create index if not exists conversations_u2_idx on public.conversations(u2);
create unique index if not exists matches_pair_uq on public.matches (least(user_a,user_b), greatest(user_a,user_b)) where coalesce((data->>'unmatched')::boolean,false) = false;
create unique index if not exists likes_once_uq on public.likes (from_id, to_id, type);
create unique index if not exists admin_email_uq on public.admin_users (email);
create unique index if not exists one_super_admin on public.admin_users (role) where role = 'SUPER_ADMIN';
create unique index if not exists flags_key_uq on public.feature_flags (key);
create unique index if not exists settings_key_uq on public.system_settings (key);
create unique index if not exists plans_code_uq on public.membership_plans (code);
create unique index if not exists promo_code_uq on public.promotions (code);
create unique index if not exists roles_code_uq on public.roles (code);
create index if not exists messages_conv_created_idx on public.messages (conversation_id, created_at desc);
create index if not exists audit_created_idx on public.audit_logs (created_at desc);

-- =====================================================================
-- Helper functions
-- =====================================================================
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from admin_users where auth_id = auth.uid() and status = 'active') $$;
create or replace function public.has_perm(p text) returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from admin_users a join roles r on r.code = a.role
                 where a.auth_id = auth.uid() and a.status = 'active' and ((r.data->'permissions') ? '*' or (r.data->'permissions') ? p)) $$;
create or replace function public.has_any(ps text[]) returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from unnest(ps) p where public.has_perm(p)) $$;
create or replace function public.in_conv(cid uuid) returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from conversations c where c.id = cid and auth.uid() in (c.u1, c.u2)) $$;
create or replace function public.flag_on(k text) returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select (data->>'enabled')::boolean from feature_flags where key = k limit 1), false) $$;
create or replace function public.client_ip() returns text language sql stable as $$
  select split_part(coalesce(current_setting('request.headers', true)::json->>'x-forwarded-for', ''), ',', 1) $$;
create or replace function public.plan_perm(u uuid, k text) returns jsonb language plpgsql stable security definer set search_path = public as $$
declare pc text := 'FREE'; v jsonb;
begin
  if public.flag_on('ENABLE_PREMIUM') then
    select plan_code into pc from memberships where user_id = u and status = 'active'
      and (data->>'expires_at' is null or (data->>'expires_at')::timestamptz > now()) limit 1;
    pc := coalesce(pc, 'FREE');
  end if;
  select data->'value' into v from membership_permissions where plan_code = pc and key = k limit 1;
  if v is null then select data->'permissions'->k into v from membership_plans where code = pc limit 1; end if;
  return v;
end $$;
create or replace function public.bkk_today(ts timestamptz) returns boolean language sql stable as $$
  select (ts at time zone 'Asia/Bangkok')::date = (now() at time zone 'Asia/Bangkok')::date $$;
create or replace function public.quota_ok(u uuid, k text, used int) returns boolean language plpgsql stable security definer set search_path = public as $$
declare lim jsonb := public.plan_perm(u, k); base int := 0; rs jsonb;
begin
  if lim is null or lim = 'false'::jsonb then return false; end if;
  if lim = 'true'::jsonb or lim = '-1'::jsonb then return true; end if;
  select data->'value' into rs from system_settings where key = 'quota_reset:' || u::text limit 1;
  if rs is not null and public.bkk_today((rs->>'at')::timestamptz) then base := coalesce((rs->>k)::int, 0); end if;
  return (used - base) < (lim #>> '{}')::int;
end $$;

-- =====================================================================
-- Guard triggers (server-side rules the client cannot bypass)
-- =====================================================================
create or replace function public.g_users() returns trigger language plpgsql security definer set search_path = public as $$
begin
  new.data := new.data - 'password_hash' - 'password_salt';
  if current_setting('clubbee.bypass', true) = 'on' or public.is_admin() then return new; end if;
  if tg_op = 'INSERT' then
    if new.id <> auth.uid() then raise exception 'not allowed'; end if;
    new.data := new.data || jsonb_build_object('status', 'onboarding', 'is_demo', false, 'referred_by', new.data->'referred_by');
    return new;
  end if;
  if (old.data->>'status') in ('banned','suspended','restricted','deleted') and new.data->>'status' is distinct from old.data->>'status' then raise exception 'account status locked'; end if;
  if (new.data->>'status') not in ('onboarding','active','deactivated') and new.data->>'status' is distinct from old.data->>'status' then raise exception 'status change not allowed'; end if;
  new.data := new.data || jsonb_build_object('is_demo', false, 'referral_code', old.data->'referral_code', 'phone_verified', old.data->'phone_verified');
  if old.data->>'referred_by' is not null then new.data := jsonb_set(new.data, '{referred_by}', old.data->'referred_by'); end if;
  return new;
end $$;
drop trigger if exists g_users on public.users; create trigger g_users before insert or update on public.users for each row execute function public.g_users();

create or replace function public.g_profiles() returns trigger language plpgsql security definer set search_path = public as $$
declare ov jsonb;
begin
  if public.has_any(array['users.edit','verification']) then return new; end if;
  ov := case when tg_op = 'UPDATE' then coalesce(old.data->'verification', '{}') else '{}' end;
  new.data := jsonb_set(new.data, '{verification}', coalesce(new.data->'verification','{}') || jsonb_build_object(
    'identity', coalesce((ov->>'identity')::boolean, false), 'profile', coalesce((ov->>'profile')::boolean, false)));
  if tg_op = 'INSERT' and (new.data->>'user_id')::uuid is distinct from auth.uid() then raise exception 'not allowed'; end if;
  return new;
end $$;
drop trigger if exists g_profiles on public.profiles; create trigger g_profiles before insert or update on public.profiles for each row execute function public.g_profiles();

create or replace function public.g_memberships() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if public.has_any(array['users.edit','membership.edit']) then return new; end if;
  if new.data->>'plan_code' <> 'FREE' or new.data->>'expires_at' is not null or (new.data->>'user_id')::uuid is distinct from auth.uid() then raise exception 'plan change requires payment'; end if;
  return new;
end $$;
drop trigger if exists g_memberships on public.memberships; create trigger g_memberships before insert on public.memberships for each row execute function public.g_memberships();

create or replace function public.g_credits() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if public.has_perm('users.edit') then return new; end if;
  if tg_op = 'INSERT' and coalesce((new.data->>'balance')::int, 0) <> 0 then raise exception 'not allowed'; end if;
  if tg_op = 'UPDATE' and coalesce((new.data->>'balance')::int, 0) > coalesce((old.data->>'balance')::int, 0) then raise exception 'credits can only be added by purchase'; end if;
  return new;
end $$;
drop trigger if exists g_credits on public.credits; create trigger g_credits before insert or update on public.credits for each row execute function public.g_credits();

create or replace function public.g_credit_tx() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if not public.has_perm('users.edit') and coalesce((new.data->>'amount')::int, 0) >= 0 then raise exception 'not allowed'; end if;
  return new;
end $$;
drop trigger if exists g_credit_tx on public.credit_transactions; create trigger g_credit_tx before insert on public.credit_transactions for each row execute function public.g_credit_tx();

create or replace function public.g_likes() returns trigger language plpgsql security definer set search_path = public as $$
declare n int; f uuid := (new.data->>'from_id')::uuid; ty text := new.data->>'type';
begin
  if f is distinct from auth.uid() then raise exception 'not allowed'; end if;
  if ty in ('like','super') then
    select count(*) into n from likes where from_id = f and type in ('like','super') and public.bkk_today(created_at);
    if ty = 'like' and not public.quota_ok(f, 'daily_likes', n) then raise exception 'daily like limit reached'; end if;
    if ty = 'super' and not coalesce((new.data->>'paid')::boolean, false) then
      select count(*) into n from likes where from_id = f and type = 'super' and not coalesce((data->>'paid')::boolean,false) and public.bkk_today(created_at);
      if not public.quota_ok(f, 'super_likes', n) then raise exception 'daily Super Like limit reached'; end if;
    end if;
  end if;
  return new;
end $$;
drop trigger if exists g_likes on public.likes; create trigger g_likes before insert on public.likes for each row execute function public.g_likes();

create or replace function public.g_matches() returns trigger language plpgsql security definer set search_path = public as $$
declare a uuid := (new.data->>'user_a')::uuid; b uuid := (new.data->>'user_b')::uuid;
begin
  if public.is_admin() then return new; end if;
  if auth.uid() is distinct from a and auth.uid() is distinct from b then raise exception 'not allowed'; end if;
  if not exists (select 1 from likes where from_id = a and to_id = b and type in ('like','super'))
     or not exists (select 1 from likes where from_id = b and to_id = a and type in ('like','super')) then
    raise exception 'a match needs likes from both sides';
  end if;
  return new;
end $$;
drop trigger if exists g_matches on public.matches; create trigger g_matches before insert on public.matches for each row execute function public.g_matches();

create or replace function public.g_conversations() returns trigger language plpgsql security definer set search_path = public as $$
declare x uuid := (new.data->'members'->>0)::uuid; y uuid := (new.data->'members'->>1)::uuid;
begin
  if not exists (select 1 from matches m where m.id = (new.data->>'match_id')::uuid and least(m.user_a,m.user_b) = least(x,y) and greatest(m.user_a,m.user_b) = greatest(x,y)) then
    raise exception 'conversation needs a match';
  end if;
  return new;
end $$;
drop trigger if exists g_conversations on public.conversations; create trigger g_conversations before insert on public.conversations for each row execute function public.g_conversations();

create or replace function public.g_messages() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if current_setting('clubbee.bypass', true) = 'on' then return new; end if;
  if tg_op = 'INSERT' then
    if (new.data->>'sender_id')::uuid is distinct from auth.uid() then raise exception 'not allowed'; end if;
    if coalesce(new.data->>'type','text') not in ('text','image','date') then raise exception 'bad type'; end if;
    if new.data->>'type' = 'text' and length(coalesce(new.data->>'body','')) > 2000 then raise exception 'message too long'; end if;
    if exists (select 1 from blocks b join conversations c on c.id = (new.data->>'conversation_id')::uuid
               where (b.blocker_id = c.u1 and b.blocked_id = c.u2) or (b.blocker_id = c.u2 and b.blocked_id = c.u1)) then raise exception 'blocked'; end if;
    new.data := new.data || '{"read_at":null,"removed":false}';
    return new;
  end if;
  -- updates by members: only read receipts (receiver) may change
  new.data := old.data || jsonb_build_object('read_at', coalesce(old.data->'read_at', new.data->'read_at'), 'updated_at', new.data->'updated_at');
  return new;
end $$;
drop trigger if exists g_messages on public.messages; create trigger g_messages before insert or update on public.messages for each row execute function public.g_messages();

create or replace function public.g_dates() returns trigger language plpgsql security definer set search_path = public as $$
declare n int; f uuid := (new.data->>'from_id')::uuid;
begin
  if f is distinct from auth.uid() or not public.in_conv((new.data->>'conversation_id')::uuid) then raise exception 'not allowed'; end if;
  if not coalesce((new.data->>'safety_ack')::boolean, false) then raise exception 'safety acknowledgement required'; end if;
  select count(*) into n from date_requests where from_id = f and public.bkk_today(created_at);
  if not public.quota_ok(f, 'date_requests', n) then raise exception 'daily date request limit reached'; end if;
  return new;
end $$;
drop trigger if exists g_dates on public.date_requests; create trigger g_dates before insert on public.date_requests for each row execute function public.g_dates();

create or replace function public.g_boosts() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() and ((new.data->>'user_id')::uuid is distinct from auth.uid() or not public.flag_on('ENABLE_BOOST')) then raise exception 'boost is not available'; end if;
  return new;
end $$;
drop trigger if exists g_boosts on public.boosts; create trigger g_boosts before insert on public.boosts for each row execute function public.g_boosts();

create or replace function public.g_cases() returns trigger language plpgsql security definer set search_path = public as $$
begin
  new.data := new.data || jsonb_build_object('case_no', 'CB-' || nextval('public.case_no_seq'));
  if not public.is_admin() then new.data := new.data || '{"status":"open","assigned_to":null}'; end if;
  return new;
end $$;
drop trigger if exists g_cases on public.moderation_cases; create trigger g_cases before insert on public.moderation_cases for each row execute function public.g_cases();

create or replace function public.g_audit() returns trigger language plpgsql security definer set search_path = public as $$
declare a record;
begin
  select id, email into a from admin_users where auth_id = auth.uid() and status = 'active' limit 1;
  if a.id is not null then new.data := new.data || jsonb_build_object('actor_type','admin','actor_id',a.id,'actor_email',a.email);
  else new.data := new.data || jsonb_build_object('actor_type','user','actor_id',auth.uid(),'actor_email',null); end if;
  new.data := new.data || jsonb_build_object('ip_address', public.client_ip(), 'server_time', now());
  return new;
end $$;
drop trigger if exists g_audit on public.audit_logs; create trigger g_audit before insert on public.audit_logs for each row execute function public.g_audit();

create or replace function public.g_consents() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if (new.data->>'user_id')::uuid is distinct from auth.uid() then raise exception 'not allowed'; end if;
  new.data := new.data || jsonb_build_object('ip_address', public.client_ip(), 'accepted_at', now());
  return new;
end $$;
drop trigger if exists g_consents on public.consents; create trigger g_consents before insert on public.consents for each row execute function public.g_consents();

-- SUPER_ADMIN protection: nobody else can edit, demote, disable, delete it or change its password
create or replace function public.g_admins() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'DELETE' then
    if old.role = 'SUPER_ADMIN' then raise exception 'SUPER_ADMIN cannot be deleted'; end if;
    return old;
  end if;
  if tg_op = 'INSERT' then
    if new.data->>'role' = 'SUPER_ADMIN' and current_setting('clubbee.claim', true) is distinct from 'on' then raise exception 'SUPER_ADMIN cannot be created here'; end if;
    return new;
  end if;
  if old.role = 'SUPER_ADMIN' then
    if old.auth_id is null and lower(auth.jwt()->>'email') = old.email then null;                 -- first claim
    elsif old.auth_id is distinct from auth.uid() then raise exception 'SUPER_ADMIN is protected';
    end if;
    if new.data->>'role' <> 'SUPER_ADMIN' or new.data->>'status' <> 'active' or lower(new.data->>'email') <> old.email then raise exception 'SUPER_ADMIN is protected'; end if;
  elsif new.data->>'role' = 'SUPER_ADMIN' then raise exception 'SUPER_ADMIN cannot be assigned';
  end if;
  if old.auth_id is not null and (new.data->>'auth_id')::uuid is distinct from old.auth_id then raise exception 'login link cannot change'; end if;
  return new;
end $$;
drop trigger if exists g_admins on public.admin_users; create trigger g_admins before insert or update or delete on public.admin_users for each row execute function public.g_admins();

-- =====================================================================
-- Row Level Security policies
-- =====================================================================
do $$ declare p record; begin
  for p in select policyname, tablename from pg_policies where schemaname = 'public' loop
    execute format('drop policy if exists %I on public.%I', p.policyname, p.tablename);
  end loop;
end $$;

-- public configuration (readable by everyone, written by admins with the right permission)
do $$ declare r record; begin
  for r in select * from (values
    ('feature_flags','{feature_flags,referral}'), ('system_settings','{settings,pricing,credits,users.edit}'),
    ('membership_plans','{pricing,membership.edit}'), ('membership_permissions','{pricing,membership.edit}'),
    ('permissions','{admin_roles}'), ('credit_packages','{credits}'), ('terms_versions','{legal}'), ('privacy_versions','{legal}'),
    ('communities','{communities}'), ('events','{events}'), ('content','{content}'), ('roles','{admin_roles}')) v(tb, perms) loop
    execute format('create policy cfg_read on public.%I for select to anon, authenticated using (true)', r.tb);
    execute format('create policy cfg_write on public.%I for all to authenticated using (public.has_any(%L::text[])) with check (public.has_any(%L::text[]))', r.tb, r.perms, r.perms);
  end loop;
end $$;
create policy promo_read  on public.promotions for select to authenticated using (true);
create policy promo_write on public.promotions for all to authenticated using (public.has_perm('promotion')) with check (public.has_perm('promotion'));

-- members' own rows (+ admin read)
do $$ declare tb text; begin
  foreach tb in array array['photos','preferences','interests','waitlist','verification_requests','consents','safety_acknowledgements','community_members','event_members','boosts','memberships','subscriptions','credits','credit_transactions','payments','notifications'] loop
    execute format('create policy own_read on public.%I for select to authenticated using (user_id = auth.uid() or public.is_admin())', tb);
  end loop;
  foreach tb in array array['photos','preferences','interests','waitlist','verification_requests','consents','safety_acknowledgements','community_members','event_members','boosts','memberships','credits','credit_transactions'] loop
    execute format('create policy own_insert on public.%I for insert to authenticated with check (user_id = auth.uid() or public.is_admin())', tb);
  end loop;
  foreach tb in array array['photos','preferences','interests','waitlist','community_members','event_members'] loop
    execute format('create policy own_delete on public.%I for delete to authenticated using (user_id = auth.uid() or public.is_admin())', tb);
  end loop;
  foreach tb in array array['photos','preferences','interests','credits'] loop
    execute format('create policy own_update on public.%I for update to authenticated using (user_id = auth.uid() or public.is_admin()) with check (user_id = auth.uid() or public.is_admin())', tb);
  end loop;
end $$;
create policy all_read on public.photos            for select to authenticated using (true);
create policy all_read on public.boosts            for select to authenticated using (true);
create policy all_read on public.community_members for select to authenticated using (true);
create policy all_read on public.event_members     for select to authenticated using (true);
create policy admin_update on public.event_members for update to authenticated using (public.has_perm('events'));
create policy admin_write on public.memberships    for update to authenticated using (public.has_any('{users.edit,membership.edit}'));
create policy admin_write on public.subscriptions  for all to authenticated using (public.has_perm('users.edit')) with check (public.has_perm('users.edit'));
create policy admin_write on public.payments       for all to authenticated using (public.has_perm('payments')) with check (public.has_perm('payments'));
create policy admin_update on public.verification_requests for update to authenticated using (public.has_perm('verification'));
create policy notif_insert on public.notifications for insert to authenticated with check (true);
create policy notif_update on public.notifications for update to authenticated using (user_id = auth.uid());
create policy notif_delete on public.notifications for delete to authenticated using (user_id = auth.uid());

create policy users_read   on public.users for select to authenticated using (id = auth.uid() or public.is_admin());
create policy users_insert on public.users for insert to authenticated with check (id = auth.uid());
create policy users_update on public.users for update to authenticated using (id = auth.uid() or public.has_any('{users.edit,users.sanction,verification,reports.act}'));

create policy prof_read   on public.profiles for select to authenticated using (user_id = auth.uid() or public.is_admin());
create policy prof_insert on public.profiles for insert to authenticated with check (user_id = auth.uid());
create policy prof_update on public.profiles for update to authenticated using (user_id = auth.uid() or public.has_any('{users.edit,verification}'));

create policy likes_read   on public.likes for select to authenticated using (auth.uid() in (from_id, to_id) or public.is_admin());
create policy likes_insert on public.likes for insert to authenticated with check (from_id = auth.uid());
create policy likes_delete on public.likes for delete to authenticated using (from_id = auth.uid());
create policy sl_read      on public.super_likes for select to authenticated using (auth.uid() in (from_id, to_id) or public.is_admin());
create policy sl_insert    on public.super_likes for insert to authenticated with check (from_id = auth.uid());

create policy match_read   on public.matches for select to authenticated using (auth.uid() in (user_a, user_b) or public.is_admin());
create policy match_insert on public.matches for insert to authenticated with check (auth.uid() in (user_a, user_b));
create policy match_update on public.matches for update to authenticated using (auth.uid() in (user_a, user_b));

create policy block_read   on public.blocks for select to authenticated using (auth.uid() in (blocker_id, blocked_id) or public.is_admin());
create policy block_insert on public.blocks for insert to authenticated with check (blocker_id = auth.uid());
create policy block_delete on public.blocks for delete to authenticated using (blocker_id = auth.uid());

-- chats: members only. Admins have NO direct access (see moderator_read_conversation)
create policy conv_read   on public.conversations for select to authenticated using (auth.uid() in (u1, u2));
create policy conv_insert on public.conversations for insert to authenticated with check (auth.uid() in (u1, u2));
create policy conv_update on public.conversations for update to authenticated using (auth.uid() in (u1, u2));
create policy msg_read    on public.messages for select to authenticated using (public.in_conv(conversation_id));
create policy msg_insert  on public.messages for insert to authenticated with check (sender_id = auth.uid() and public.in_conv(conversation_id));
create policy msg_update  on public.messages for update to authenticated using (public.in_conv(conversation_id));

create policy date_read   on public.date_requests for select to authenticated using (auth.uid() in (from_id, to_id) or public.is_admin());
create policy date_insert on public.date_requests for insert to authenticated with check (from_id = auth.uid());
create policy date_update on public.date_requests for update to authenticated using (auth.uid() in (from_id, to_id));
create policy dev_read    on public.date_events for select to authenticated using (exists (select 1 from date_requests d where d.id = date_request_id and auth.uid() in (d.from_id, d.to_id)) or public.is_admin());
create policy dev_insert  on public.date_events for insert to authenticated with check (exists (select 1 from date_requests d where d.id = date_request_id and auth.uid() in (d.from_id, d.to_id)));

create policy ref_read   on public.referrals for select to authenticated using (auth.uid() in (referrer_id, new_user_id) or public.is_admin());
create policy ref_insert on public.referrals for insert to authenticated with check (new_user_id = auth.uid());
create policy ref_update on public.referrals for update to authenticated using (new_user_id = auth.uid() or public.has_perm('referral'));

create policy rep_read   on public.reports for select to authenticated using (reporter_id = auth.uid() or public.is_admin());
create policy rep_insert on public.reports for insert to authenticated with check (reporter_id = auth.uid());
create policy rep_update on public.reports for update to authenticated using (reporter_id = auth.uid() or public.has_perm('reports.act'));
create policy case_read   on public.moderation_cases for select to authenticated using (public.is_admin());
create policy case_insert on public.moderation_cases for insert to authenticated with check (true);
create policy case_update on public.moderation_cases for update to authenticated using (public.has_perm('reports.act'));
create policy act_read    on public.moderation_actions for select to authenticated using (public.is_admin());
create policy act_insert  on public.moderation_actions for insert to authenticated with check (public.has_perm('reports.act'));

create policy adm_read   on public.admin_users for select to authenticated using (auth_id = auth.uid() or public.is_admin());
create policy adm_self   on public.admin_users for update to authenticated using (auth_id = auth.uid());
create policy adm_manage on public.admin_users for all to authenticated using (public.has_perm('admin_roles')) with check (public.has_perm('admin_roles'));

create policy audit_insert on public.audit_logs for insert to authenticated with check (true);
create policy audit_read   on public.audit_logs for select to authenticated using (public.has_perm('audit_logs'));
-- (no update/delete policies on audit_logs → append-only)

-- =====================================================================
-- Public views for other members (private fields stripped)
-- =====================================================================
create or replace view public.users_public as
  select id, data - 'email' - 'phone' - 'password_hash' - 'password_salt' - 'auth_provider' as data from public.users where status is distinct from 'deleted';
create or replace view public.profiles_public as
  select id, data - 'name' as data from public.profiles p
  where exists (select 1 from public.users u where u.id = p.user_id and u.status in ('active','restricted'));
create or replace view public.memberships_public as
  select id, jsonb_build_object('user_id', data->'user_id', 'plan_code', data->'plan_code', 'status', data->'status', 'expires_at', data->'expires_at') as data
  from public.memberships where status = 'active';
create or replace view public.plan_seat_counts as
  select plan_code, count(*)::int as used from public.memberships where status = 'active' group by plan_code;
revoke all on public.users_public, public.profiles_public, public.memberships_public from anon;
grant select on public.users_public, public.profiles_public, public.memberships_public to authenticated;
grant select on public.plan_seat_counts to anon, authenticated;

-- =====================================================================
-- RPC functions
-- =====================================================================
create or replace function public.link_admin() returns jsonb language plpgsql security definer set search_path = public as $$
declare em text := lower(auth.jwt()->>'email'); r admin_users;
begin
  if em is null or auth.uid() is null then return null; end if;
  if not exists (select 1 from admin_users where role = 'SUPER_ADMIN')
     and em = lower((select value from app_config where key = 'super_admin_email')) then
    perform set_config('clubbee.claim', 'on', true);
    insert into admin_users (id, data) values (gen_random_uuid(), jsonb_build_object('email', em, 'name', 'Super Admin', 'role', 'SUPER_ADMIN',
      'must_change_password', false, 'status', 'active', 'protected', true, 'auth_id', null, 'created_at', now()));
    perform set_config('clubbee.claim', 'off', true);
  end if;
  update admin_users set data = data || jsonb_build_object('auth_id', auth.uid())
   where email = em and status = 'active' and (auth_id is null or auth_id = auth.uid())
   returning * into r;
  if r.id is null then return null; end if;
  insert into audit_logs (data) values (jsonb_build_object('action','ADMIN_LINKED','target',em,'meta','{}'::jsonb,'created_at',now()));
  return r.data || jsonb_build_object('id', r.id);
end $$;

create or replace function public.moderator_read_conversation(p_case uuid, p_reason text, p_emergency boolean default false)
returns setof public.messages language plpgsql security definer set search_path = public as $$
declare c moderation_cases; a admin_users;
begin
  if not public.flag_on('ENABLE_CHAT_MODERATION') then raise exception 'chat moderation disabled'; end if;
  if not public.has_perm(case when p_emergency then 'EMERGENCY_ACCESS' else 'CHAT_MODERATION_VIEW' end) then raise exception 'permission denied'; end if;
  if length(trim(coalesce(p_reason,''))) < 15 then raise exception 'give a specific reason (15+ characters)'; end if;
  select * into c from moderation_cases where id = p_case;
  if c.id is null or c.conversation_id is null then raise exception 'case has no linked conversation'; end if;
  select * into a from admin_users where auth_id = auth.uid();
  insert into audit_logs (data) values (jsonb_build_object('action', case when p_emergency then 'EMERGENCY_CHAT_ACCESS' else 'CHAT_MODERATION_VIEW' end,
    'target', c.conversation_id, 'created_at', now(),
    'meta', jsonb_build_object('moderator_id', a.id, 'conversation_id', c.conversation_id, 'case_id', c.data->>'case_no', 'reason', p_reason, 'access_time', now(), 'scope', 'last 30 messages')));
  return query select * from (select * from messages where conversation_id = c.conversation_id order by created_at desc limit 30) m order by m.created_at;
end $$;

create or replace function public.moderator_remove_content(p_case uuid) returns int language plpgsql security definer set search_path = public as $$
declare c moderation_cases; n int;
begin
  if not public.has_perm('reports.act') then raise exception 'permission denied'; end if;
  select * into c from moderation_cases where id = p_case;
  perform set_config('clubbee.bypass', 'on', true);
  update messages set data = data || '{"removed":true}' where id in (
    select id from messages where conversation_id = c.conversation_id and sender_id = c.target_user_id order by created_at desc limit 3);
  get diagnostics n = row_count;
  perform set_config('clubbee.bypass', 'off', true);
  insert into audit_logs (data) values (jsonb_build_object('action','CONTENT_REMOVED','target',c.data->>'case_no','meta',jsonb_build_object('messages',n),'created_at',now()));
  return n;
end $$;

create or replace function public.delete_my_account() returns void language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid();
begin
  if u is null then raise exception 'not signed in'; end if;
  delete from profiles where user_id = u; delete from photos where user_id = u; delete from preferences where user_id = u; delete from interests where user_id = u;
  delete from likes where from_id = u or to_id = u; delete from super_likes where from_id = u or to_id = u;
  delete from notifications where user_id = u; delete from community_members where user_id = u; delete from event_members where user_id = u;
  delete from verification_requests where user_id = u; delete from boosts where user_id = u; delete from waitlist where user_id = u;
  delete from credits where user_id = u; delete from credit_transactions where user_id = u;
  perform set_config('clubbee.bypass', 'on', true);
  update messages set data = data || '{"body":"[deleted]","removed":true}' where sender_id = u;
  update matches set data = data || '{"unmatched":true}' where u in (user_a, user_b);
  update users set data = (data - 'email' - 'phone') || jsonb_build_object('status','deleted','deleted_at',now(),'online',false) where id = u;
  perform set_config('clubbee.bypass', 'off', true);
  insert into audit_logs (data) values (jsonb_build_object('action','ACCOUNT_DELETED','target',u,'meta','{}'::jsonb,'created_at',now()));
  begin delete from auth.users where id = u;   -- removes the login itself (PDPA right to erasure)
  exception when others then null; end;
end $$;

create or replace function public.admin_counts() returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then return null; end if;
  return jsonb_build_object('messages', (select count(*) from messages), 'conversations', (select count(*) from conversations));
end $$;

revoke execute on function public.moderator_read_conversation(uuid, text, boolean), public.moderator_remove_content(uuid), public.delete_my_account(), public.admin_counts(), public.link_admin() from anon;
grant execute on function public.moderator_read_conversation(uuid, text, boolean), public.moderator_remove_content(uuid), public.delete_my_account(), public.admin_counts(), public.link_admin() to authenticated;

-- =====================================================================
-- Storage (photos & chat images) — files live under <auth uid>/<id>.jpg
-- =====================================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('media', 'media', true, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = true, file_size_limit = 5242880, allowed_mime_types = array['image/jpeg','image/png','image/webp'];
drop policy if exists "clubbee media read" on storage.objects;
drop policy if exists "clubbee media write" on storage.objects;
drop policy if exists "clubbee media update" on storage.objects;
drop policy if exists "clubbee media delete" on storage.objects;
create policy "clubbee media read"   on storage.objects for select using (bucket_id = 'media');
create policy "clubbee media write"  on storage.objects for insert to authenticated with check (bucket_id = 'media' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "clubbee media update" on storage.objects for update to authenticated using (bucket_id = 'media' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "clubbee media delete" on storage.objects for delete to authenticated using (bucket_id = 'media' and (storage.foldername(name))[1] = auth.uid()::text);

-- =====================================================================
-- Realtime
-- =====================================================================
do $$ declare tb text; begin
  foreach tb in array array['messages','conversations','likes','matches','date_requests','notifications','memberships','credits','reports','moderation_cases','verification_requests','feature_flags','event_members'] loop
    begin execute format('alter publication supabase_realtime add table public.%I', tb);
    exception when duplicate_object then null; end;
  end loop;
end $$;

-- =====================================================================
-- Launch configuration (FREE FIRST) — generated from the app's own defaults
-- =====================================================================
insert into public.feature_flags (id, data) values
  ('96d2101e-7407-41fd-8e81-e4485bf10724','{"created_at":"2026-09-24T23:55:01.586Z","key":"ENABLE_PREMIUM","enabled":false}'::jsonb),
  ('d867fd76-be91-49f3-ac71-c185ac5521c0','{"created_at":"2026-09-24T23:55:01.586Z","key":"ENABLE_CREDITS","enabled":false}'::jsonb),
  ('458de9da-5a0f-4ae5-a683-95e94f9ed7eb','{"created_at":"2026-09-24T23:55:01.586Z","key":"ENABLE_BOOST","enabled":false}'::jsonb),
  ('786c3600-de2f-48b5-bac2-a432b4953d0e','{"created_at":"2026-09-24T23:55:01.586Z","key":"ENABLE_REFERRAL","enabled":true}'::jsonb),
  ('8fc64f82-3e01-4a0b-96cb-56acb0864194','{"created_at":"2026-09-24T23:55:01.586Z","key":"ENABLE_EVENTS","enabled":true}'::jsonb),
  ('6ba9216a-b69d-4c32-9cad-1b0a045d9652','{"created_at":"2026-09-24T23:55:01.586Z","key":"ENABLE_COMMUNITIES","enabled":true}'::jsonb),
  ('ecd2c1bc-0c58-45a1-8be7-f219a1075a9c','{"created_at":"2026-09-24T23:55:01.586Z","key":"ENABLE_ID_VERIFICATION","enabled":true}'::jsonb),
  ('f60dab40-6839-4eb1-a6bb-f8c9597b946b','{"created_at":"2026-09-24T23:55:01.586Z","key":"ENABLE_CHAT_MODERATION","enabled":true}'::jsonb)
on conflict (id) do nothing;

insert into public.system_settings (id, data) values
  ('1c22c6ee-ac82-4c0f-88f0-4c0ee2303b42','{"created_at":"2026-09-24T23:55:01.586Z","key":"currency","value":"THB"}'::jsonb),
  ('f6150b60-15f4-47a8-8d45-0d85ffb8252a','{"created_at":"2026-09-24T23:55:01.586Z","key":"referral_reward_credits","value":20}'::jsonb),
  ('1bb3948a-e187-4585-98a7-07a2f2535c68','{"created_at":"2026-09-24T23:55:01.586Z","key":"welcome_credits","value":10}'::jsonb),
  ('54123e32-7b92-43f1-9e75-40349f4b7273','{"created_at":"2026-09-24T23:55:01.586Z","key":"min_age","value":18}'::jsonb),
  ('305f1382-4401-49dd-bfbe-c1ea39459204','{"created_at":"2026-09-24T23:55:01.586Z","key":"boost_prices","value":{"15":10,"30":18,"60":30,"120":50}}'::jsonb),
  ('0b530dcd-4b6a-4454-a59c-01db6b2747d9','{"created_at":"2026-09-24T23:55:01.586Z","key":"super_like_credit_cost","value":5}'::jsonb)
on conflict (id) do nothing;

insert into public.permissions (id, data) values
  ('7ac19029-003e-46bb-9101-789adb7ff0ac','{"created_at":"2026-09-24T23:55:01.586Z","key":"daily_likes","type":"number","label":"Likes per day (-1 = unlimited)","scope":"member"}'::jsonb),
  ('fc34868a-8931-4b99-b1d7-f204a83f457d','{"created_at":"2026-09-24T23:55:01.586Z","key":"monthly_likes","type":"number","label":"Likes per month (-1 = unlimited)","scope":"member"}'::jsonb),
  ('32e5a31d-dfe4-494a-a4dc-f1b61bf0b21d','{"created_at":"2026-09-24T23:55:01.586Z","key":"super_likes","type":"number","label":"Super Likes per day","scope":"member"}'::jsonb),
  ('0a25026f-594f-47df-951b-13bc0c0bb7b7','{"created_at":"2026-09-24T23:55:01.586Z","key":"boosts","type":"number","label":"Free boosts per month","scope":"member"}'::jsonb),
  ('b59331b0-dbee-4049-a320-eebf28e34b3e','{"created_at":"2026-09-24T23:55:01.586Z","key":"date_requests","type":"number","label":"Date requests per day","scope":"member"}'::jsonb),
  ('09bab87d-e396-4597-b1c9-7e0335c1ca2d','{"created_at":"2026-09-24T23:55:01.586Z","key":"advanced_search","type":"bool","label":"Advanced search & filters","scope":"member"}'::jsonb),
  ('62c13d62-f2b5-4105-80e4-a59e58391fb2','{"created_at":"2026-09-24T23:55:01.586Z","key":"see_likes","type":"bool","label":"See who liked you","scope":"member"}'::jsonb),
  ('c4f6448b-ac46-4b71-9ec0-c1bbe061cf89','{"created_at":"2026-09-24T23:55:01.586Z","key":"priority_matching","type":"bool","label":"Priority in Discover ranking","scope":"member"}'::jsonb),
  ('9ffd4f71-7006-41bc-8874-ffde3c67f6f2','{"created_at":"2026-09-24T23:55:01.586Z","key":"profile_boost","type":"bool","label":"Profile boost feature","scope":"member"}'::jsonb),
  ('4629a28e-5b5d-458b-ae20-d89d75d34a53','{"created_at":"2026-09-24T23:55:01.586Z","key":"events","type":"bool","label":"Access to events","scope":"member"}'::jsonb),
  ('bf34df2e-ab64-4869-90a6-93b5a4d60962','{"created_at":"2026-09-24T23:55:01.586Z","key":"matchmaking","type":"bool","label":"Matchmaking requests","scope":"member"}'::jsonb),
  ('04772e04-df3a-42eb-8ec3-b83b8a5eb91d','{"created_at":"2026-09-24T23:55:01.586Z","key":"chat_features","type":"text","label":"Chat feature level","scope":"member"}'::jsonb),
  ('6cd357fe-276e-4f39-a114-1f21521836af','{"created_at":"2026-09-24T23:55:01.586Z","key":"dashboard","type":"bool","label":"dashboard","scope":"admin"}'::jsonb),
  ('05bf0525-0877-4bc7-b8e1-712b064dff48','{"created_at":"2026-09-24T23:55:01.586Z","key":"users.view","type":"bool","label":"users.view","scope":"admin"}'::jsonb),
  ('72f1a79b-4169-458d-b016-cb15332ffa7d','{"created_at":"2026-09-24T23:55:01.586Z","key":"users.edit","type":"bool","label":"users.edit","scope":"admin"}'::jsonb),
  ('541cc2f7-2a09-4dcb-a7d6-8446c45c5168','{"created_at":"2026-09-24T23:55:01.586Z","key":"users.sanction","type":"bool","label":"users.sanction","scope":"admin"}'::jsonb),
  ('77714938-cbdf-4481-8387-eb957d1bec7a','{"created_at":"2026-09-24T23:55:01.586Z","key":"membership.view","type":"bool","label":"membership.view","scope":"admin"}'::jsonb),
  ('c4f33f4f-7408-46b8-9ea1-84f350f28288','{"created_at":"2026-09-24T23:55:01.586Z","key":"membership.edit","type":"bool","label":"membership.edit","scope":"admin"}'::jsonb),
  ('ceb8c3e5-6c33-4560-a690-393f754d6e99','{"created_at":"2026-09-24T23:55:01.586Z","key":"pricing","type":"bool","label":"pricing","scope":"admin"}'::jsonb),
  ('ae4cd061-a2f8-4cd1-aa05-ca40f8309e03','{"created_at":"2026-09-24T23:55:01.586Z","key":"credits","type":"bool","label":"credits","scope":"admin"}'::jsonb),
  ('38c643ab-fb00-40a8-8504-a7db8ac0e2b4','{"created_at":"2026-09-24T23:55:01.586Z","key":"payments","type":"bool","label":"payments","scope":"admin"}'::jsonb),
  ('e391c9a4-8e28-45ca-a0c7-0ef8bafeb608','{"created_at":"2026-09-24T23:55:01.586Z","key":"reports.view","type":"bool","label":"reports.view","scope":"admin"}'::jsonb),
  ('ac9f2781-b1e2-4ddd-932a-3fcd7fa15533','{"created_at":"2026-09-24T23:55:01.586Z","key":"reports.act","type":"bool","label":"reports.act","scope":"admin"}'::jsonb),
  ('cb33d2bd-86f8-4e0b-bd51-9df1add04f8c','{"created_at":"2026-09-24T23:55:01.586Z","key":"CHAT_MODERATION_VIEW","type":"bool","label":"CHAT_MODERATION_VIEW","scope":"admin"}'::jsonb),
  ('e86543f0-2971-4af9-9a79-69837583a905','{"created_at":"2026-09-24T23:55:01.586Z","key":"EMERGENCY_ACCESS","type":"bool","label":"EMERGENCY_ACCESS","scope":"admin"}'::jsonb),
  ('44539c6e-e02d-43ff-979f-9125f7ed8eae','{"created_at":"2026-09-24T23:55:01.586Z","key":"verification","type":"bool","label":"verification","scope":"admin"}'::jsonb),
  ('ccf86f06-8cde-44db-9880-7c9b89f78451','{"created_at":"2026-09-24T23:55:01.586Z","key":"content","type":"bool","label":"content","scope":"admin"}'::jsonb),
  ('a1bb949c-5c11-4a2b-9eeb-2fc149efb7c8','{"created_at":"2026-09-24T23:55:01.586Z","key":"promotion","type":"bool","label":"promotion","scope":"admin"}'::jsonb),
  ('ec4f0558-8aa3-4023-ac0e-0342df7ee78e','{"created_at":"2026-09-24T23:55:01.586Z","key":"referral","type":"bool","label":"referral","scope":"admin"}'::jsonb),
  ('2d4a704c-89fa-4ee6-91a3-7e7e665741ee','{"created_at":"2026-09-24T23:55:01.586Z","key":"analytics","type":"bool","label":"analytics","scope":"admin"}'::jsonb),
  ('1822ed03-f56c-4ed8-8129-f9c4216d9f25','{"created_at":"2026-09-24T23:55:01.586Z","key":"notifications","type":"bool","label":"notifications","scope":"admin"}'::jsonb),
  ('b71dfa1b-ca3d-4c07-944a-fa7ffa97a104','{"created_at":"2026-09-24T23:55:01.586Z","key":"events","type":"bool","label":"events","scope":"admin"}'::jsonb),
  ('a1ce9d6d-8d99-45b3-8c37-f6a43b6ec01c','{"created_at":"2026-09-24T23:55:01.586Z","key":"communities","type":"bool","label":"communities","scope":"admin"}'::jsonb),
  ('8ab94e6a-4ace-4f09-86e2-7069202a717d','{"created_at":"2026-09-24T23:55:01.586Z","key":"settings","type":"bool","label":"settings","scope":"admin"}'::jsonb),
  ('e0fb74ca-e90d-4473-855a-0e7bd4d3d8a3','{"created_at":"2026-09-24T23:55:01.586Z","key":"feature_flags","type":"bool","label":"feature_flags","scope":"admin"}'::jsonb),
  ('7f8719b5-217c-4306-aedf-ffdd114d7cab','{"created_at":"2026-09-24T23:55:01.586Z","key":"admin_roles","type":"bool","label":"admin_roles","scope":"admin"}'::jsonb),
  ('df2e3d73-8e80-425c-9bd8-5aed92cf2430','{"created_at":"2026-09-24T23:55:01.586Z","key":"audit_logs","type":"bool","label":"audit_logs","scope":"admin"}'::jsonb),
  ('687c532d-0488-40a8-ac07-6f081c85a23e','{"created_at":"2026-09-24T23:55:01.586Z","key":"legal","type":"bool","label":"legal","scope":"admin"}'::jsonb)
on conflict (id) do nothing;

insert into public.membership_plans (id, data) values
  ('31430ba8-664b-4772-9777-a9bf01e4229a','{"created_at":"2026-09-24T23:55:01.586Z","code":"FREE","name":"Free","price":0,"duration_days":0,"member_limit":0,"sort":0,"desc":"Everything you need to meet people — free during launch.","permissions":{"daily_likes":100,"monthly_likes":3000,"super_likes":1,"boosts":0,"date_requests":10,"advanced_search":false,"see_likes":false,"priority_matching":false,"profile_boost":false,"events":true,"matchmaking":false,"chat_features":"standard"},"currency":"THB","status":"active"}'::jsonb),
  ('28eb1e3c-5af7-4974-baeb-cd7dcd56bb13','{"created_at":"2026-09-24T23:55:01.586Z","code":"BASIC","name":"Basic","price":199,"duration_days":30,"member_limit":0,"sort":1,"desc":"More likes and Super Likes every day.","permissions":{"daily_likes":250,"monthly_likes":7500,"super_likes":3,"boosts":0,"date_requests":20,"advanced_search":false,"see_likes":false,"priority_matching":false,"profile_boost":false,"events":true,"matchmaking":false,"chat_features":"standard"},"currency":"THB","status":"active"}'::jsonb),
  ('a4f47ba1-13af-464c-9794-61ca294f554f','{"created_at":"2026-09-24T23:55:01.586Z","code":"PREMIUM","name":"Premium","price":399,"duration_days":30,"member_limit":0,"sort":2,"desc":"Advanced search, see who liked you, monthly boost.","permissions":{"daily_likes":-1,"monthly_likes":-1,"super_likes":5,"boosts":1,"date_requests":30,"advanced_search":true,"see_likes":true,"priority_matching":false,"profile_boost":true,"events":true,"matchmaking":false,"chat_features":"plus"},"currency":"THB","status":"active"}'::jsonb),
  ('c8bdfa43-0925-4e83-a2dc-3a19fc628700','{"created_at":"2026-09-24T23:55:01.587Z","code":"VIP","name":"VIP","price":899,"duration_days":30,"member_limit":0,"sort":3,"desc":"Priority matching, VIP badge, priority support.","permissions":{"daily_likes":-1,"monthly_likes":-1,"super_likes":10,"boosts":3,"date_requests":50,"advanced_search":true,"see_likes":true,"priority_matching":true,"profile_boost":true,"events":true,"matchmaking":false,"chat_features":"plus"},"currency":"THB","status":"active"}'::jsonb),
  ('a6acf2f8-9264-42aa-b8ce-2ee3ebe66980','{"created_at":"2026-09-24T23:55:01.587Z","code":"ELITE","name":"Elite","price":2990,"duration_days":30,"member_limit":500,"reserved_seats":0,"sort":4,"desc":"Limited seats. Matchmaking, premium placement, concierge, exclusive events.","permissions":{"daily_likes":-1,"monthly_likes":-1,"super_likes":25,"boosts":8,"date_requests":-1,"advanced_search":true,"see_likes":true,"priority_matching":true,"profile_boost":true,"events":true,"matchmaking":true,"chat_features":"concierge"},"currency":"THB","status":"active"}'::jsonb)
on conflict (id) do nothing;

insert into public.membership_permissions (id, data) values
  ('6af18992-158e-4777-b931-9b14a11ad2cb','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"FREE","key":"daily_likes","value":100}'::jsonb),
  ('e68d35d4-add0-4abc-a527-fae253fbb55a','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"FREE","key":"monthly_likes","value":3000}'::jsonb),
  ('21e14b5d-c5c1-4b23-9b08-f2d02a1551b4','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"FREE","key":"super_likes","value":1}'::jsonb),
  ('3a7b742f-52c2-4fe5-9ecd-6b6fc0e9fe7b','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"FREE","key":"boosts","value":0}'::jsonb),
  ('41d97435-7fb4-4544-a113-1673345ff7cc','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"FREE","key":"date_requests","value":10}'::jsonb),
  ('0c842956-6509-49d4-8004-5c2661b5cfe0','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"FREE","key":"advanced_search","value":false}'::jsonb),
  ('7877f941-de28-4913-baab-6a67c8179c80','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"FREE","key":"see_likes","value":false}'::jsonb),
  ('5cca8ead-1289-4022-a2f2-c96af8190f30','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"FREE","key":"priority_matching","value":false}'::jsonb),
  ('95a337d3-c726-4e09-b0ea-1b1f03a3e6ac','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"FREE","key":"profile_boost","value":false}'::jsonb),
  ('a0902539-04f3-43ad-b6ab-b27e6875fa8d','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"FREE","key":"events","value":true}'::jsonb),
  ('456dce00-8601-4627-81a8-4af6692bb658','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"FREE","key":"matchmaking","value":false}'::jsonb),
  ('a5afb62e-906f-4cf7-b2fe-0343ac156b71','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"FREE","key":"chat_features","value":"standard"}'::jsonb),
  ('d7e810ed-7c0e-4e12-a90c-4a7f125ff435','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"BASIC","key":"daily_likes","value":250}'::jsonb),
  ('5cb6a116-1cfb-4896-a312-5725431803cc','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"BASIC","key":"monthly_likes","value":7500}'::jsonb),
  ('bf8d5802-b1e8-4828-9d78-9f9b5353caf9','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"BASIC","key":"super_likes","value":3}'::jsonb),
  ('3f48573e-75ab-4822-b5ed-172dde2c13a3','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"BASIC","key":"boosts","value":0}'::jsonb),
  ('7d5ea9a2-5efb-43d4-8116-11f7a67571a3','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"BASIC","key":"date_requests","value":20}'::jsonb),
  ('624a6e62-ecd8-4f2b-8536-6071e3777b35','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"BASIC","key":"advanced_search","value":false}'::jsonb),
  ('9136c148-8447-4abc-a191-812c732d4b99','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"BASIC","key":"see_likes","value":false}'::jsonb),
  ('0de219c7-0729-4306-ab11-f5b6d471ed28','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"BASIC","key":"priority_matching","value":false}'::jsonb),
  ('7f69660b-d07c-46a4-a606-ac57bc8d23c5','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"BASIC","key":"profile_boost","value":false}'::jsonb),
  ('3a820e74-84de-435f-9f52-57313682440d','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"BASIC","key":"events","value":true}'::jsonb),
  ('6e06ce43-d8f7-4c21-9785-bd3e7dfce0f4','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"BASIC","key":"matchmaking","value":false}'::jsonb),
  ('1985bc68-5d1d-4e76-80bc-57faf3ea7b5f','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"BASIC","key":"chat_features","value":"standard"}'::jsonb),
  ('aeb5cfc6-35ca-429b-b965-1c775708156b','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"PREMIUM","key":"daily_likes","value":-1}'::jsonb),
  ('a79f9547-fbc6-42b5-809a-abecb9e6e33a','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"PREMIUM","key":"monthly_likes","value":-1}'::jsonb),
  ('2896c426-7099-48c2-a69c-f11663753035','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"PREMIUM","key":"super_likes","value":5}'::jsonb),
  ('2def6bba-0178-4c34-902e-f5e92552ed6b','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"PREMIUM","key":"boosts","value":1}'::jsonb),
  ('0f2dfb61-1adb-4292-af26-04496a38f3fe','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"PREMIUM","key":"date_requests","value":30}'::jsonb),
  ('c918636d-08ab-427f-8908-8b2bfca86519','{"created_at":"2026-09-24T23:55:01.586Z","plan_code":"PREMIUM","key":"advanced_search","value":true}'::jsonb),
  ('4b605c2e-7200-4614-8a62-ef60b0ead2d2','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"PREMIUM","key":"see_likes","value":true}'::jsonb),
  ('e982d4c1-1ede-4cac-bb01-a01b0e91f1c7','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"PREMIUM","key":"priority_matching","value":false}'::jsonb),
  ('610d5fb0-20e5-4b72-bd0f-e54e2a1c5383','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"PREMIUM","key":"profile_boost","value":true}'::jsonb),
  ('7842c8ad-ba90-4e81-8ef7-775da2a17b1e','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"PREMIUM","key":"events","value":true}'::jsonb),
  ('9f348d2e-2fe4-4c9a-b618-2bc5f6373f99','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"PREMIUM","key":"matchmaking","value":false}'::jsonb),
  ('f00386da-0706-4c3b-aeec-4d107f8c50bb','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"PREMIUM","key":"chat_features","value":"plus"}'::jsonb),
  ('d2286195-58f2-4e5b-a8bf-27dfeb07ab52','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"VIP","key":"daily_likes","value":-1}'::jsonb),
  ('1998a24c-7f0a-48da-8d2f-5e1ac2184218','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"VIP","key":"monthly_likes","value":-1}'::jsonb),
  ('930d6915-9dbc-49a7-90c5-0d66407d41d7','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"VIP","key":"super_likes","value":10}'::jsonb),
  ('c0d6968c-3960-4f0b-92cd-e9ee2de14e4a','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"VIP","key":"boosts","value":3}'::jsonb),
  ('139f97b2-87e1-4203-bb95-66438ffc0d5a','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"VIP","key":"date_requests","value":50}'::jsonb),
  ('1213c644-4aac-433c-91e4-dfbc38c0c914','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"VIP","key":"advanced_search","value":true}'::jsonb),
  ('7e28529b-09e6-4b35-b999-e9806740c5cc','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"VIP","key":"see_likes","value":true}'::jsonb),
  ('f9a904a7-3f48-485d-accd-d4721b170fbb','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"VIP","key":"priority_matching","value":true}'::jsonb),
  ('f8fd5afb-2514-48cd-adcc-09f700b14e44','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"VIP","key":"profile_boost","value":true}'::jsonb),
  ('036534cc-8bf1-474d-b160-793eefb5a109','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"VIP","key":"events","value":true}'::jsonb),
  ('d1d0c1a0-0ba2-469f-a44f-e497c202bb36','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"VIP","key":"matchmaking","value":false}'::jsonb),
  ('5e2b9f65-0376-432f-b643-b7ef96158d05','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"VIP","key":"chat_features","value":"plus"}'::jsonb),
  ('329665d2-a379-46e0-8379-3fa3dd9503e6','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"ELITE","key":"daily_likes","value":-1}'::jsonb),
  ('689923d9-6dcb-4256-98bb-c21c95ad0fe7','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"ELITE","key":"monthly_likes","value":-1}'::jsonb),
  ('7c1aa549-9e1a-480e-9efd-05c1315b6813','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"ELITE","key":"super_likes","value":25}'::jsonb),
  ('35b3ea9a-507b-42a2-9196-bf547bf6f03c','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"ELITE","key":"boosts","value":8}'::jsonb),
  ('68008226-6bed-4872-8a77-44ad7b1858ee','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"ELITE","key":"date_requests","value":-1}'::jsonb),
  ('ccf5cd70-5e4b-44a4-b444-ecb021480f0d','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"ELITE","key":"advanced_search","value":true}'::jsonb),
  ('b5fe0af2-4e1d-40bc-b39f-679c15a587b2','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"ELITE","key":"see_likes","value":true}'::jsonb),
  ('6593382a-d507-4191-9d8b-53ce31b3f6c5','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"ELITE","key":"priority_matching","value":true}'::jsonb),
  ('52f28987-16f7-4f74-ae8f-e673271aced7','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"ELITE","key":"profile_boost","value":true}'::jsonb),
  ('7717f4fc-6920-47b0-91a6-d1081e4e3fbd','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"ELITE","key":"events","value":true}'::jsonb),
  ('1857238d-ae6a-4aa8-af99-ec93f7ebfe9d','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"ELITE","key":"matchmaking","value":true}'::jsonb),
  ('89f0ab93-6bfe-4f6c-91b0-d8b041ecf302','{"created_at":"2026-09-24T23:55:01.587Z","plan_code":"ELITE","key":"chat_features","value":"concierge"}'::jsonb)
on conflict (id) do nothing;

insert into public.credit_packages (id, data) values
  ('74fe8393-bc37-4048-86aa-179c2656fd8a','{"created_at":"2026-09-24T23:55:01.587Z","name":"50 Honey Credits","amount":50,"price":49,"currency":"THB","bonus":0,"active":true}'::jsonb),
  ('7e0a1f7f-b1aa-4b95-9775-2ec5bbf3e7b7','{"created_at":"2026-09-24T23:55:01.587Z","name":"120 Honey Credits","amount":120,"price":99,"currency":"THB","bonus":10,"active":true}'::jsonb),
  ('69fa3da5-4533-411b-a127-f6887e1ac869','{"created_at":"2026-09-24T23:55:01.587Z","name":"300 Honey Credits","amount":300,"price":219,"currency":"THB","bonus":40,"active":true}'::jsonb),
  ('3592b260-6c85-428c-b691-b5de33479ec5','{"created_at":"2026-09-24T23:55:01.587Z","name":"800 Honey Credits","amount":800,"price":499,"currency":"THB","bonus":150,"active":true}'::jsonb)
on conflict (id) do nothing;

insert into public.terms_versions (id, data) values
  ('3b81ae19-cc75-4644-8bed-b9419c31dee3','{"created_at":"2026-09-24T23:55:01.587Z","type":"TERMS","version":"1.0","code":"TERMS_V1.0","body":"CLUB BEE — ข้อกำหนดการใช้งาน (Terms of Use)\n\n1. Club Bee เป็นแพลตฟอร์มสำหรับให้สมาชิกสร้างโปรไฟล์ ติดต่อ สื่อสาร และทำความรู้จักกัน สำหรับผู้ที่มีอายุ 18 ปีขึ้นไปเท่านั้น\n2. สมาชิกแต่ละคนเป็นผู้รับผิดชอบข้อมูล การตัดสินใจ การสื่อสาร การทำธุรกรรม และการนัดพบของตนเอง\n3. Club Bee ไม่สามารถรับรองตัวตน เจตนา พฤติกรรม หรือความน่าเชื่อถือของสมาชิกทุกคนได้ เว้นแต่ในส่วนที่แพลตฟอร์มระบุว่าได้ตรวจสอบหรือยืนยันไว้โดยเฉพาะ\n4. สมาชิกควรใช้วิจารณญาณ ไม่เปิดเผยข้อมูลสำคัญ และไม่โอนเงินให้บุคคลที่รู้จักผ่านแพลตฟอร์มโดยไม่ตรวจสอบอย่างเหมาะสม\n5. หากเกิดข้อพิพาท การหลอกลวง การคุกคาม การผิดนัด หรือเหตุการณ์อื่นระหว่างสมาชิก สมาชิกสามารถแจ้ง Club Bee ผ่านระบบ Report เพื่อให้แพลตฟอร์มดำเนินการตามนโยบายที่เกี่ยวข้อง ทั้งนี้ ขอบเขตความรับผิดของ Club Bee เป็นไปตามข้อกำหนดการใช้งานและกฎหมายที่ใช้บังคับ\n6. ห้ามใช้แพลตฟอร์มเพื่อหลอกลวง คุกคาม ส่งสแปม เผยแพร่เนื้อหาไม่เหมาะสม หรือกระทำผิดกฎหมาย\n7. Club Bee อาจเตือน จำกัดการใช้งาน ระงับ หรือแบนบัญชีที่ละเมิดข้อกำหนด\n\n[DRAFT v1.0 — ต้องได้รับการตรวจสอบโดยผู้เชี่ยวชาญด้านกฎหมายก่อนเปิดให้บริการจริง]","hash":"sha256-mock:392592839c35d6eb","active":true,"published_at":"2026-09-24T23:55:01.587Z"}'::jsonb),
  ('23b6b69d-25d8-4103-ab9d-8f77a952a7a5','{"created_at":"2026-09-24T23:55:01.588Z","type":"SAFETY","version":"1.0","code":"SAFETY_V1.0","body":"CLUB BEE — แนวทางความปลอดภัย (Safety Guidelines)\n\n✓ นัดในสถานที่สาธารณะ\n✓ อย่าโอนเงินให้คนที่เพิ่งรู้จัก\n✓ อย่าแชร์ OTP / Password\n✓ แจ้งคนที่ไว้ใจได้ว่าคุณจะไปที่ไหน\n✓ หากรู้สึกไม่ปลอดภัยให้ยกเลิกทันที\n✓ ใช้ปุ่ม Block และ Report เมื่อพบพฤติกรรมน่าสงสัย","hash":"sha256-mock:8d766a5d8d447d6d","active":true,"published_at":"2026-09-24T23:55:01.588Z"}'::jsonb),
  ('09dbbf38-293a-4059-bd2b-1a5fab981069','{"created_at":"2026-09-24T23:55:01.588Z","type":"GUIDELINES","version":"1.0","code":"GUIDELINES_V1.0","body":"แนวปฏิบัติชุมชน: เคารพกัน ใช้รูปของตัวเอง ไม่คุกคาม ไม่ขายของ ไม่ชวนลงทุน ไม่เผยแพร่เนื้อหาทางเพศหรือความรุนแรง","hash":"sha256-mock:0fe9d2c8ae57f194","active":true,"published_at":"2026-09-24T23:55:01.588Z"}'::jsonb),
  ('6d549eb3-6e2e-4b6f-885c-3f159f8a5e6a','{"created_at":"2026-09-24T23:55:01.588Z","type":"REFUND","version":"1.0","code":"REFUND_V1.0","body":"นโยบายการคืนเงิน: บริการดิจิทัลที่เริ่มใช้งานแล้วไม่สามารถคืนเงินได้ ยกเว้นกรณีระบบผิดพลาดหรือตามที่กฎหมายกำหนด ติดต่อฝ่ายช่วยเหลือภายใน 7 วัน [DRAFT]","hash":"sha256-mock:b608fc7545770aed","active":true,"published_at":"2026-09-24T23:55:01.588Z"}'::jsonb),
  ('4bbe8e2c-cfb5-4635-bde1-4f24e9818d68','{"created_at":"2026-09-24T23:55:01.588Z","type":"MEMBERSHIP","version":"1.0","code":"MEMBERSHIP_V1.0","body":"เงื่อนไขสมาชิก: แพ็กเกจมีระยะเวลาตามที่ระบุ สิทธิ์แต่ละระดับกำหนดโดยระบบ Membership และอาจปรับปรุงได้โดยแจ้งล่วงหน้า ELITE มีจำนวนจำกัด [DRAFT]","hash":"sha256-mock:a2d557762e3368b2","active":true,"published_at":"2026-09-24T23:55:01.588Z"}'::jsonb),
  ('2e1dc0aa-0011-48c4-9856-3874c97c5d24','{"created_at":"2026-09-24T23:55:01.590Z","type":"COOKIE","version":"1.0","code":"COOKIE_V1.0","body":"นโยบายคุกกี้: ใช้คุกกี้ที่จำเป็นต่อการเข้าสู่ระบบและความปลอดภัยเท่านั้นในช่วงเปิดตัว [DRAFT]","hash":"sha256-mock:baef3f699be66bd5","active":true,"published_at":"2026-09-24T23:55:01.590Z"}'::jsonb)
on conflict (id) do nothing;

insert into public.privacy_versions (id, data) values
  ('eff1cd1d-3f61-447b-85d9-782c94e01c7a','{"created_at":"2026-09-24T23:55:01.587Z","type":"PRIVACY","version":"1.0","code":"PRIVACY_V1.0","body":"CLUB BEE — นโยบายความเป็นส่วนตัว (Privacy Policy)\n\n1. ข้อมูลที่เก็บ: ข้อมูลบัญชี (เบอร์โทร/อีเมล) ข้อมูลโปรไฟล์ รูปภาพ ความชอบ กิจกรรมการใช้งาน และบันทึกการยินยอม\n2. ข้อมูลที่ไม่แสดงต่อสมาชิกอื่น: ชื่อจริง บ้านเลขที่ เบอร์โทร อีเมล และพิกัดที่อยู่แบบละเอียด\n3. แชทเป็นพื้นที่ส่วนตัวของสมาชิก Club Bee อาจเข้าถึงการสื่อสารบางส่วน เฉพาะเมื่อมีเหตุอันควรตามนโยบายความปลอดภัย การร้องเรียน การตรวจสอบการละเมิด หรือหน้าที่ตามกฎหมาย โดยผู้ดูแลที่ได้รับอนุญาตเท่านั้น และทุกการเข้าถึงถูกบันทึก (Audit Log)\n4. ข้อมูลบัตรเครดิตไม่ถูกเก็บโดย Club Bee — การชำระเงินผ่านผู้ให้บริการ Payment Gateway\n5. สิทธิของสมาชิก: ขอดาวน์โหลดข้อมูล แก้ไข ปิดบัญชีชั่วคราว หรือลบบัญชี ได้จากหน้าตั้งค่า\n6. การจัดการข้อมูลเป็นไปตาม พ.ร.บ.คุ้มครองข้อมูลส่วนบุคคล พ.ศ. 2562 (PDPA)\n\n[DRAFT v1.0 — ต้องได้รับการตรวจสอบโดยผู้เชี่ยวชาญด้านกฎหมายก่อนเปิดให้บริการจริง]","hash":"sha256-mock:12674fcfb5b4ce97","active":true,"published_at":"2026-09-24T23:55:01.587Z"}'::jsonb)
on conflict (id) do nothing;

insert into public.roles (id, data) values
  ('ffd8bbd0-d476-4d89-9f07-47028c533224','{"created_at":"2026-09-24T23:55:01.590Z","code":"SUPER_ADMIN","name":"SUPER ADMIN","permissions":["*"],"system":true}'::jsonb),
  ('c5934203-2fdd-4b34-bf58-69e71f9b7184','{"created_at":"2026-09-24T23:55:01.590Z","code":"ADMIN","name":"ADMIN","permissions":["dashboard","users.view","users.edit","users.sanction","membership.view","reports.view","reports.act","verification","content","promotion","referral","analytics","notifications","events","communities"],"system":true}'::jsonb),
  ('e33bf057-a3b6-4998-b560-f0be766167d3','{"created_at":"2026-09-24T23:55:01.590Z","code":"MODERATOR","name":"MODERATOR","permissions":["dashboard","users.view","users.sanction","reports.view","reports.act","CHAT_MODERATION_VIEW","EMERGENCY_ACCESS","communities"],"system":true}'::jsonb),
  ('1cae45b6-0911-4dd2-9450-b87dd612b3ab','{"created_at":"2026-09-24T23:55:01.590Z","code":"CUSTOMER_SUPPORT","name":"CUSTOMER SUPPORT","permissions":["dashboard","users.view","reports.view","notifications","membership.view"],"system":true}'::jsonb),
  ('cac6f06c-e829-48a1-98c0-d8d0fb945469','{"created_at":"2026-09-24T23:55:01.590Z","code":"FINANCE","name":"FINANCE","permissions":["dashboard","payments","credits","membership.view","promotion","analytics"],"system":true}'::jsonb),
  ('9503872e-9bed-4c5b-ba8c-39f3d561cd8b','{"created_at":"2026-09-24T23:55:01.590Z","code":"CONTENT_MANAGER","name":"CONTENT MANAGER","permissions":["dashboard","content","events","communities","notifications"],"system":true}'::jsonb),
  ('91ae3d67-14b3-450a-9fc7-e98eba0894af','{"created_at":"2026-09-24T23:55:01.590Z","code":"VERIFICATION_MANAGER","name":"VERIFICATION MANAGER","permissions":["dashboard","users.view","verification"],"system":true}'::jsonb)
on conflict (id) do nothing;

insert into public.communities (id, data) values
  ('2b80a356-6de8-4e6e-9b95-e6c0e42350b5','{"created_at":"2026-09-24T23:55:01.590Z","name":"Bangkok Hive","emoji":"🏙️","kind":"city","ref":"bkk","description":"Meet bees in your city.","status":"active","moderated":true}'::jsonb),
  ('49b3f25c-6ce2-4ffa-824c-f3dc6b385ec1','{"created_at":"2026-09-24T23:55:01.590Z","name":"Chiang Mai Hive","emoji":"⛰️","kind":"city","ref":"cnx","description":"Meet bees in your city.","status":"active","moderated":true}'::jsonb),
  ('e5ffaf96-15c3-488d-ba9c-f34a9e8c563b','{"created_at":"2026-09-24T23:55:01.590Z","name":"Business Hive","emoji":"💼","kind":"interest","ref":"business","description":"For people who love business.","status":"active","moderated":true}'::jsonb),
  ('fd820c23-4cb8-4e78-a83f-6875f1888fca','{"created_at":"2026-09-24T23:55:01.590Z","name":"Travel Hive","emoji":"✈️","kind":"interest","ref":"travel","description":"For people who love travel.","status":"active","moderated":true}'::jsonb),
  ('9fbff9b7-826f-402a-bbfb-9b123fa0f185','{"created_at":"2026-09-24T23:55:01.590Z","name":"Coffee Hive","emoji":"☕","kind":"interest","ref":"coffee","description":"For people who love coffee.","status":"active","moderated":true}'::jsonb),
  ('0f050955-3248-4b42-a674-e9762ba3001d','{"created_at":"2026-09-24T23:55:01.590Z","name":"Fitness Hive","emoji":"🏃","kind":"interest","ref":"fitness","description":"For people who love fitness.","status":"active","moderated":true}'::jsonb)
on conflict (id) do nothing;

insert into public.events (id, data) values
  ('dcf70c6b-7901-4f04-8329-ff67b0366d12','{"created_at":"2026-09-24T23:55:01.590Z","title":"Speed Dating Night","kind":"speed_dating","starts_at":"2026-09-30T10:55:01.590Z","place":"Honeycomb Bar, Ari, Bangkok","seats":24,"price":590,"currency":"THB","status":"published","description":"A relaxed, hosted Club Bee event. Photo ID checked at the door."}'::jsonb),
  ('86fdaa7a-6764-4ba7-bc61-db42c1e36377','{"created_at":"2026-09-24T23:55:01.590Z","title":"Sunday Coffee Meetup","kind":"coffee","starts_at":"2026-10-04T10:55:01.590Z","place":"Nimman Roastery, Chiang Mai","seats":30,"price":0,"currency":"THB","status":"published","description":"A relaxed, hosted Club Bee event. Photo ID checked at the door."}'::jsonb),
  ('2369f5c3-0865-48d5-87bd-3464f4539a63','{"created_at":"2026-09-24T23:55:01.590Z","title":"Rooftop Dinner Social","kind":"dinner","starts_at":"2026-10-09T10:55:01.590Z","place":"Skyline Terrace, Sathorn, Bangkok","seats":40,"price":1290,"currency":"THB","status":"published","description":"A relaxed, hosted Club Bee event. Photo ID checked at the door."}'::jsonb),
  ('70f4ff63-fe30-4f92-8cd1-0b9a9569dafc','{"created_at":"2026-09-24T23:55:01.591Z","title":"Lumpini Morning Run & Brunch","kind":"activity","starts_at":"2026-10-15T10:55:01.591Z","place":"Lumpini Park, Bangkok","seats":60,"price":0,"currency":"THB","status":"published","description":"A relaxed, hosted Club Bee event. Photo ID checked at the door."}'::jsonb)
on conflict (id) do nothing;

insert into public.content (id, data) values
  ('3aa1181c-363d-4724-8040-2619339a72aa','{"created_at":"2026-09-24T23:55:01.591Z","kind":"banner","title":"Free during launch 🐝","body":"Discover, like, match, chat and send date requests — all free while the hive grows.","active":true}'::jsonb),
  ('584c51c9-e1cf-4059-a627-dbb0b2194902','{"created_at":"2026-09-24T23:55:01.591Z","kind":"tip","title":"Write a real first message","body":"Mention something from their profile. It beats “hi” every time.","active":true}'::jsonb),
  ('b61eabd2-a47a-4a7f-b1e5-f3268ff974a1','{"created_at":"2026-09-24T23:55:01.591Z","kind":"tip","title":"Pick a public first date","body":"Coffee in daylight is the classic first date for a reason.","active":true}'::jsonb),
  ('563e1082-d516-4ee2-b4d6-7ac984100356','{"created_at":"2026-09-24T23:55:01.591Z","kind":"safety","title":"Never send money","body":"If someone you just met asks for money or investments, report them.","active":true}'::jsonb),
  ('ea9e5e9e-6732-44d8-8ce3-c307792f7eac','{"created_at":"2026-09-24T23:55:01.591Z","kind":"announcement","title":"Chiang Mai Hive is open","body":"Northern bees, your hive is live. Join and say hi.","active":true}'::jsonb)
on conflict (id) do nothing;

insert into public.promotions (id, data) values
  ('07853c7e-2942-44be-9d0b-abb874d4c4bb','{"created_at":"2026-09-24T23:55:01.591Z","code":"HELLOHIVE","name":"Welcome Offer","type":"percent","value":30,"starts_at":"2026-09-14T23:55:01.591Z","ends_at":"2026-11-23T23:55:01.591Z","usage_limit":1000,"used":0,"eligible":["BASIC","PREMIUM","VIP"],"applies_to":"membership","first_purchase_only":true,"active":true}'::jsonb),
  ('3f1a0c51-afcb-48f6-917d-ad51980229c3','{"created_at":"2026-09-24T23:55:01.591Z","code":"HONEY50","name":"Credit Bonus","type":"fixed","value":50,"starts_at":"2026-09-19T23:55:01.591Z","ends_at":"2026-10-24T23:55:01.591Z","usage_limit":300,"used":0,"eligible":[],"applies_to":"credits","first_purchase_only":false,"active":true}'::jsonb)
on conflict (id) do nothing;


-- Done. Next: open your site → /#/admin → type the ★ email + a strong password → "Create admin login".
