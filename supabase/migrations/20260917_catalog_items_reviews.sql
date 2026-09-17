-- Structured price catalog (15 trades / 132 partidas) + reviewer feedback.
-- Replaces the JS-embedded catalog in the Catálogo artifact; catalogo.html reads/writes these.
-- Applied to mpgljurndbfusxtcrogr on 2026-09-17 (execute_sql); seed in ../seed/catalog_items_seed.sql.

create table if not exists public.catalog_items (
  id          text primary key,                 -- e.g. t04-i01 (trade 04, item 01)
  trade_order int  not null,
  trade       text not null,
  trade_hue   text,
  sort        int  not null default 0,
  service     text not null,
  unit        text not null,
  basis       text not null check (basis in ('labor','allin','material','equip')),
  rate        numeric not null default 0,       -- base rate: condición Bueno / complejidad Baja
  profile     text not null default 'flat',     -- restore | area | install | demo | diag | flat
  cond_reg    numeric not null default 1,       -- condición Regular multiplier
  cond_bad    numeric not null default 1,       -- condición Malo multiplier
  cx_med      numeric not null default 1,       -- complejidad Media multiplier
  cx_high     numeric not null default 1,       -- complejidad Alta multiplier
  note        text,
  status      text not null default 'draft' check (status in ('draft','approved','retired')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- One row per (item, reviewer). Upserted by catalogo.html.
create table if not exists public.catalog_reviews (
  id             uuid primary key default gen_random_uuid(),
  item_id        text not null references public.catalog_items(id) on delete cascade,
  reviewer       text not null,
  verdict        text not null check (verdict in ('ok','alto','bajo')),
  suggested      numeric,                       -- what the reviewer would charge
  note           text,
  rate_at_review numeric,                       -- rate shown when they answered
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  unique (item_id, reviewer)
);

-- Audit trail when a rate is changed from the Resumen (admin "Aplicar").
create table if not exists public.catalog_rate_history (
  id          uuid primary key default gen_random_uuid(),
  item_id     text not null references public.catalog_items(id) on delete cascade,
  old_rate    numeric,
  new_rate    numeric not null,
  changed_by  text,
  reason      text,
  created_at  timestamptz not null default now()
);

alter table public.catalog_items        enable row level security;
alter table public.catalog_reviews      enable row level security;
alter table public.catalog_rate_history enable row level security;
do $$ begin
  if not exists (select 1 from pg_policies where tablename='catalog_items' and policyname='allow all') then
    create policy "allow all" on public.catalog_items for all to public using (true) with check (true); end if;
  if not exists (select 1 from pg_policies where tablename='catalog_reviews' and policyname='allow all') then
    create policy "allow all" on public.catalog_reviews for all to public using (true) with check (true); end if;
  if not exists (select 1 from pg_policies where tablename='catalog_rate_history' and policyname='allow all') then
    create policy "allow all" on public.catalog_rate_history for all to public using (true) with check (true); end if;
end $$;

create or replace function public.tg_touch_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;
drop trigger if exists touch_catalog_items on public.catalog_items;
create trigger touch_catalog_items before update on public.catalog_items for each row execute function public.tg_touch_updated_at();
drop trigger if exists touch_catalog_reviews on public.catalog_reviews;
create trigger touch_catalog_reviews before update on public.catalog_reviews for each row execute function public.tg_touch_updated_at();
