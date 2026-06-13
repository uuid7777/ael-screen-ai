-- ============================================
-- AEL Screen AI - Supabase Database Schema
-- ============================================
-- Run this in Supabase SQL Editor to create all tables.

-- 1. Users (extends Supabase auth.users)
create table if not exists public.profiles (
    id uuid references auth.users on delete cascade primary key,
    email text,
    display_name text,
    avatar_url text,
    is_premium boolean default false,
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

alter table public.profiles enable row level security;

create policy "Users can view own profile"
    on public.profiles for select
    using (auth.uid() = id);

create policy "Users can update own profile"
    on public.profiles for update
    using (auth.uid() = id);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
    insert into public.profiles (id, email, display_name, avatar_url)
    values (
        new.id,
        new.email,
        new.raw_user_meta_data->>'display_name',
        new.raw_user_meta_data->>'avatar_url'
    );
    return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();


-- 2. Translations
create table if not exists public.translations (
    id uuid default gen_random_uuid() primary key,
    user_id uuid references public.profiles(id) on delete cascade,
    original_text text not null,
    translated_text text not null,
    source_lang text default 'auto',
    target_lang text default 'zh-CN',
    ocr_used boolean default false,
    screenshot_url text,
    processing_time_ms integer default 0,
    created_at timestamptz default now()
);

create index idx_translations_user_id on public.translations(user_id);
create index idx_translations_created_at on public.translations(created_at desc);

alter table public.translations enable row level security;

create policy "Users can view own translations"
    on public.translations for select
    using (auth.uid() = user_id);

create policy "Users can insert own translations"
    on public.translations for insert
    with check (auth.uid() = user_id);

create policy "Users can delete own translations"
    on public.translations for delete
    using (auth.uid() = user_id);


-- 3. Favorites
create table if not exists public.favorites (
    id uuid default gen_random_uuid() primary key,
    user_id uuid references public.profiles(id) on delete cascade not null,
    translation_id uuid references public.translations(id) on delete cascade not null,
    note text,
    created_at timestamptz default now(),
    unique(user_id, translation_id)
);

create index idx_favorites_user_id on public.favorites(user_id);

alter table public.favorites enable row level security;

create policy "Users can view own favorites"
    on public.favorites for select
    using (auth.uid() = user_id);

create policy "Users can insert own favorites"
    on public.favorites for insert
    with check (auth.uid() = user_id);

create policy "Users can delete own favorites"
    on public.favorites for delete
    using (auth.uid() = user_id);


-- 4. Subscriptions
create type plan_type as enum ('monthly', 'yearly');
create type subscription_status as enum ('active', 'expired', 'cancelled');
create type payment_provider as enum ('apple', 'google');

create table if not exists public.subscriptions (
    id uuid default gen_random_uuid() primary key,
    user_id uuid references public.profiles(id) on delete cascade not null,
    plan_type plan_type default 'monthly',
    status subscription_status default 'active',
    start_date timestamptz default now(),
    end_date timestamptz not null,
    auto_renew boolean default true,
    payment_provider payment_provider default 'apple',
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

create index idx_subscriptions_user_id on public.subscriptions(user_id);
create index idx_subscriptions_status on public.subscriptions(status);

alter table public.subscriptions enable row level security;

create policy "Users can view own subscriptions"
    on public.subscriptions for select
    using (auth.uid() = user_id);


-- 5. User settings
create table if not exists public.user_settings (
    id uuid default gen_random_uuid() primary key,
    user_id uuid references public.profiles(id) on delete cascade unique not null,
    default_source_lang text default 'auto',
    default_target_lang text default 'zh-CN',
    ocr_on_device boolean default true,
    auto_translate boolean default false,
    theme text default 'system',
    updated_at timestamptz default now()
);

alter table public.user_settings enable row level security;

create policy "Users can view own settings"
    on public.user_settings for select
    using (auth.uid() = user_id);

create policy "Users can upsert own settings"
    on public.user_settings for insert
    with check (auth.uid() = user_id);

create policy "Users can update own settings"
    on public.user_settings for update
    using (auth.uid() = user_id);


-- 6. Translation logs (analytics)
create table if not exists public.translation_logs (
    id bigint generated always as identity primary key,
    user_id uuid references public.profiles(id),
    action text not null, -- 'translate', 'ocr', 'screen_translate'
    source_lang text,
    target_lang text,
    text_length integer,
    processing_time_ms integer,
    success boolean default true,
    created_at timestamptz default now()
);

create index idx_logs_created_at on public.translation_logs(created_at desc);


-- Seed: Default user settings trigger
create or replace function public.handle_new_user_settings()
returns trigger as $$
begin
    insert into public.user_settings (user_id)
    values (new.id);
    return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_profile_created
    after insert on public.profiles
    for each row execute function public.handle_new_user_settings();
