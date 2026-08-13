-- ============================================================================
-- Multi-phase projects + Step 5 profitability inputs.
-- A project holds many quotes as ordered PHASES. Actual costs are logged in
-- project_costs so profitability can compare planned (from the quotes) vs actual.
-- ============================================================================

alter table public.quotes add column if not exists phase_name  text;
alter table public.quotes add column if not exists phase_order int;

create table if not exists public.project_costs (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  project_id uuid not null references public.projects(id) on delete cascade,
  category    text not null default 'materials', -- labor | materials | subcontractor | equipment | other
  description text,
  vendor      text,
  amount      numeric not null default 0,
  incurred_on date,
  notes       text
);
create index if not exists project_costs_project_idx on public.project_costs(project_id);

create or replace function public.project_costs_touch()
returns trigger language plpgsql as $$
begin new.updated_at := now(); return new; end;
$$;
drop trigger if exists project_costs_touch on public.project_costs;
create trigger project_costs_touch before update on public.project_costs
  for each row execute function public.project_costs_touch();

alter table public.project_costs enable row level security;
drop policy if exists "allow all" on public.project_costs;
create policy "allow all" on public.project_costs for all to public using (true) with check (true);
