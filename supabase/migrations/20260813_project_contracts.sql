-- ============================================================================
-- Step 2 — Contracts. A simple client agreement generated from the approved
-- quote, signed via a tokenized public link, with a deposit captured on
-- signature. Terms are SNAPSHOTTED at generation so a signed contract never
-- drifts if the source quote is later edited.
-- ============================================================================

create table if not exists public.contracts (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  project_id uuid references public.projects(id) on delete cascade,
  quote_id   uuid references public.quotes(id),

  public_token uuid not null unique default gen_random_uuid(),
  status text not null default 'draft',       -- draft | sent | signed | void

  client_name      text,
  client_email     text,
  client_property  text,
  scope            text,
  contract_total   numeric,
  deposit_amount   numeric,
  deposit_percent  numeric,
  payment_terms      text,
  guarantee_terms    text,
  cancellation_terms text,
  change_order_terms text,

  sent_at         timestamptz,
  signed_at       timestamptz,
  signer_name     text,
  signature_data  text,
  deposit_paid_at timestamptz
);

create index if not exists contracts_project_id_idx on public.contracts(project_id);
create index if not exists contracts_token_idx      on public.contracts(public_token);

create or replace function public.contracts_touch()
returns trigger language plpgsql as $$
begin new.updated_at := now(); return new; end;
$$;
drop trigger if exists contracts_touch on public.contracts;
create trigger contracts_touch before update on public.contracts
  for each row execute function public.contracts_touch();

create or replace function public.contracts_propagate_sign()
returns trigger language plpgsql as $$
begin
  if new.signed_at is not null and old.signed_at is null and new.project_id is not null then
    update public.projects
       set contract_signed_at = new.signed_at,
           deposit_amount     = coalesce(new.deposit_amount, deposit_amount),
           updated_at         = now()
     where id = new.project_id;
  end if;
  return new;
end;
$$;
drop trigger if exists contracts_sign_propagate on public.contracts;
create trigger contracts_sign_propagate after update on public.contracts
  for each row execute function public.contracts_propagate_sign();

alter table public.contracts enable row level security;
drop policy if exists "allow all" on public.contracts;
create policy "allow all" on public.contracts for all to public using (true) with check (true);
