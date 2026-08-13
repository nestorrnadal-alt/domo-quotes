-- ============================================================================
-- Step 1 — Project record ("the spine").
-- One PROJ-### that links a quote, a contract, invoices, provider payments,
-- and profitability. ADDITIVE ONLY: existing quotes/bookings are untouched.
-- A quote with project_id = NULL behaves exactly as it does today.
-- ============================================================================

-- Sequential human-facing project numbers: PROJ-001, PROJ-002, ...
create sequence if not exists public.project_number_seq;

create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  project_number text unique,                 -- assigned by trigger: 'PROJ-001'
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- who / where (denormalized to match the quotes table's own pattern)
  client_id       uuid references public.clients(id),
  client_name     text,
  client_phone    text,
  client_email    text,
  client_property text,

  -- what
  title       text,                           -- e.g. 'Dorado kitchen renovation'
  description text,
  size    text not null default 'large',      -- 'small' | 'large' — gates the heavy machinery
  status  text not null default 'draft',      -- draft|quoting|contract_sent|active|on_hold|closeout|complete|cancelled

  -- the approved quote that drives this project
  primary_quote_id uuid references public.quotes(id),

  -- financial spine (planned now; actuals fill in later phases for profitability)
  budget_total     numeric,                   -- planned, from approved quote grand_total
  contract_signed_at timestamptz,
  deposit_amount   numeric,
  deposit_paid_at  timestamptz,

  -- compliance gate (item 5) — a project can't start until the relevant flags clear
  fondo_cleared    boolean not null default false,
  coi_cleared      boolean not null default false,
  permits_required boolean not null default false,
  permits_cleared  boolean not null default false,

  created_by     text,
  internal_notes text
);

create index if not exists projects_client_id_idx      on public.projects(client_id);
create index if not exists projects_status_idx         on public.projects(status);
create index if not exists projects_primary_quote_idx  on public.projects(primary_quote_id);

-- Assign PROJ-### on insert (only when not supplied) and stamp updated_at.
create or replace function public.projects_assign_number()
returns trigger language plpgsql as $$
begin
  if new.project_number is null then
    new.project_number := 'PROJ-' || lpad(nextval('public.project_number_seq')::text, 3, '0');
  end if;
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists projects_set_number on public.projects;
create trigger projects_set_number
  before insert on public.projects
  for each row execute function public.projects_assign_number();

-- Keep updated_at fresh on edits.
create or replace function public.projects_touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists projects_touch on public.projects;
create trigger projects_touch
  before update on public.projects
  for each row execute function public.projects_touch_updated_at();

-- Link a quote to its project. NULLABLE + no default => existing quotes and the
-- per-booking flow are completely unaffected.
alter table public.quotes add column if not exists project_id uuid references public.projects(id);
create index if not exists quotes_project_id_idx on public.quotes(project_id);

-- RLS: mirror the app's existing permissive model (anon key, browser-side queries).
alter table public.projects enable row level security;
drop policy if exists "allow all" on public.projects;
create policy "allow all" on public.projects for all to public using (true) with check (true);
