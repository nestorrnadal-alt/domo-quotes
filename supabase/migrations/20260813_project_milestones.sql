-- ============================================================================
-- Step 3 — Progress invoicing (schedule of values).
-- A project bills in several milestones; each is tracked pending -> invoiced ->
-- paid, with the BookingKoala invoice # captured on the milestone. BK remains
-- the charging engine; this table is the line-item progress breakdown BK lacks.
-- ============================================================================

create table if not exists public.project_milestones (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  project_id uuid not null references public.projects(id) on delete cascade,
  sort_order int not null default 0,

  title       text not null,
  description text,
  amount      numeric not null default 0,
  status      text not null default 'pending',  -- pending | invoiced | paid

  bk_invoice_id text,
  invoiced_at  timestamptz,
  paid_at      timestamptz,
  notes        text
);

create index if not exists project_milestones_project_idx on public.project_milestones(project_id);

create or replace function public.project_milestones_touch()
returns trigger language plpgsql as $$
begin new.updated_at := now(); return new; end;
$$;
drop trigger if exists project_milestones_touch on public.project_milestones;
create trigger project_milestones_touch before update on public.project_milestones
  for each row execute function public.project_milestones_touch();

alter table public.project_milestones enable row level security;
drop policy if exists "allow all" on public.project_milestones;
create policy "allow all" on public.project_milestones for all to public using (true) with check (true);
