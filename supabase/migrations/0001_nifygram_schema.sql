-- NifyGram initial Supabase schema.
-- Run in Supabase SQL Editor or with `supabase db push`.
-- IMPORTANT: never expose the service_role key in Flutter/mobile clients.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null check (char_length(username) between 4 and 32),
  display_name text not null default '',
  avatar_url text,
  bio text not null default '',
  is_verified boolean not null default false,
  is_banned boolean not null default false,
  premium_until timestamptz,
  fufcoin bigint not null default 15 check (fufcoin >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint username_latin check (username ~ '^[a-zA-Z0-9_]{4,32}$')
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  kind text not null default 'direct' check (kind in ('direct','group','support')),
  title text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists public.conversation_members (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  last_read_at timestamptz,
  primary key (conversation_id, user_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null default auth.uid() references public.profiles(id),
  body text not null check (char_length(body) between 1 and 10000),
  created_at timestamptz not null default now(),
  edited_at timestamptz,
  deleted_at timestamptz
);

create table if not exists public.gift_catalog (
  id text primary key,
  name text not null,
  description text not null default '',
  svg_asset text not null,
  price_fufcoin integer not null check (price_fufcoin >= 0),
  is_nft boolean not null default false,
  upgrade_price_fufcoin integer,
  active boolean not null default true
);

insert into public.gift_catalog(id,name,description,svg_asset,price_fufcoin,is_nft,upgrade_price_fufcoin)
values
 ('rose','Роза','Обычный подарок','rose.svg',3,false,null),
 ('star','Звезда','Обычный подарок','star.svg',4,false,null),
 ('planet','Планета','Обычный подарок','planet.svg',5,false,null),
 ('crown','Корона','Обычный подарок','crown.svg',7,false,null),
 ('crystal','Кристалл','Улучшаемый подарок','crystal.svg',6,false,5),
 ('comet','Комета','Улучшаемый подарок','comet.svg',8,false,5),
 ('nft_aurora','NFT: Аврора','Коллекционный NFT','nft_aurora.svg',12,true,null),
 ('nft_phantom','NFT: Фантом','Коллекционный NFT','nft_phantom.svg',15,true,null),
 ('nft_orbit','NFT: Орбита','Коллекционный NFT','nft_orbit.svg',18,true,null),
 ('nft_celestial','NFT: Небожитель','Коллекционный NFT','nft_celestial.svg',20,true,null)
on conflict (id) do nothing;

create table if not exists public.gifts (
  id uuid primary key default gen_random_uuid(),
  catalog_id text not null references public.gift_catalog(id),
  owner_id uuid not null references public.profiles(id),
  gifted_by uuid references public.profiles(id),
  is_nft boolean not null default false,
  equipped_badge boolean not null default false,
  acquired_at timestamptz not null default now()
);

create table if not exists public.market_listings (
  id uuid primary key default gen_random_uuid(),
  gift_id uuid not null unique references public.gifts(id),
  seller_id uuid not null references public.profiles(id),
  price_fufcoin integer not null check (price_fufcoin > 0),
  status text not null default 'active' check (status in ('active','sold','cancelled')),
  created_at timestamptz not null default now()
);

create table if not exists public.coin_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id),
  amount bigint not null check (amount <> 0),
  reason text not null,
  reference_id uuid,
  created_at timestamptz not null default now()
);

create table if not exists public.premium_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id),
  username_snapshot text not null,
  amount_rub integer not null default 10 check (amount_rub = 10),
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  payment_note text,
  created_at timestamptz not null default now(),
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz
);

create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id),
  subject text not null default 'Поддержка',
  status text not null default 'open' check (status in ('open','closed')),
  created_at timestamptz not null default now()
);

create table if not exists public.admin_audit_log (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id),
  action text not null,
  target_user_id uuid references public.profiles(id),
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- Create profile with 15 Fufcoin on auth signup. Username is checked again here.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
declare uname text;
begin
  uname := lower(coalesce(new.raw_user_meta_data->>'username', ''));
  if uname !~ '^[a-zA-Z0-9_]{4,32}$' then
    uname := 'user_' || substr(replace(new.id::text, '-', ''), 1, 12);
  end if;
  insert into public.profiles(id, username, display_name, fufcoin)
  values(new.id, uname, uname, 15)
  on conflict (id) do nothing;
  insert into public.coin_ledger(user_id, amount, reason)
  values(new.id, 15, 'welcome_bonus');
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_nifygram on auth.users;
create trigger on_auth_user_created_nifygram
after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.gift_catalog enable row level security;
alter table public.gifts enable row level security;
alter table public.market_listings enable row level security;
alter table public.coin_ledger enable row level security;
alter table public.premium_requests enable row level security;
alter table public.support_tickets enable row level security;
alter table public.admin_audit_log enable row level security;

-- Profile directory is readable to signed-in users; only owner updates own public fields.
create policy "profiles readable by authenticated" on public.profiles
for select to authenticated using (true);
create policy "profile owner updates profile" on public.profiles
for update to authenticated using (id = auth.uid())
with check (id = auth.uid() and is_verified = (select p.is_verified from public.profiles p where p.id = auth.uid())
  and is_banned = (select p.is_banned from public.profiles p where p.id = auth.uid())
  and fufcoin = (select p.fufcoin from public.profiles p where p.id = auth.uid())
  and premium_until is not distinct from (select p.premium_until from public.profiles p where p.id = auth.uid()));

create policy "members see conversations" on public.conversations
for select to authenticated using (
  exists(select 1 from public.conversation_members m where m.conversation_id = id and m.user_id = auth.uid())
);
create policy "members see membership" on public.conversation_members
for select to authenticated using (user_id = auth.uid() or exists (
  select 1 from public.conversation_members m where m.conversation_id = conversation_id and m.user_id = auth.uid()
));
create policy "members read messages" on public.messages
for select to authenticated using (exists (
  select 1 from public.conversation_members m where m.conversation_id = messages.conversation_id and m.user_id = auth.uid()
));
create policy "members send messages" on public.messages
for insert to authenticated with check (
  sender_id = auth.uid()
  and exists(select 1 from public.conversation_members m where m.conversation_id = messages.conversation_id and m.user_id = auth.uid())
  and not exists(select 1 from public.profiles p where p.id = auth.uid() and p.is_banned)
);
create policy "members edit own messages" on public.messages
for update to authenticated using (sender_id = auth.uid()) with check (sender_id = auth.uid());

create policy "catalog visible" on public.gift_catalog
for select to authenticated using (active = true);
create policy "users see owned gifts" on public.gifts
for select to authenticated using (owner_id = auth.uid());
create policy "market listings visible" on public.market_listings
for select to authenticated using (status = 'active' or seller_id = auth.uid());
create policy "ledger owner reads" on public.coin_ledger
for select to authenticated using (user_id = auth.uid());
create policy "premium request owner reads" on public.premium_requests
for select to authenticated using (user_id = auth.uid());
create policy "premium request owner creates" on public.premium_requests
for insert to authenticated with check (user_id = auth.uid() and status = 'pending' and amount_rub = 10);
create policy "support owner reads" on public.support_tickets
for select to authenticated using (user_id = auth.uid());
create policy "support owner creates" on public.support_tickets
for insert to authenticated with check (user_id = auth.uid());
-- No client policies for audit log. Admin-only actions belong in Edge Functions
-- that verify a server-side role/secret and append to this table.
