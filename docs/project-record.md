# Project record — the spine (Step 1)

Part of the **project admin standardization** work. This is the foundation the
rest of the plan (contract, progress invoicing, compliance gate, per-project
profitability) hangs off. Blueprint of the full plan lives outside the repo;
this doc covers only what shipped in Step 1.

## What it is

A single `projects` record, numbered `PROJ-###`, that ties together everything
about one larger job: the driving quote, the (future) contract, the (future)
milestone invoices, provider payments, and profitability. Today the quote lives
in `domo-quotes`, invoices in BookingKoala, and provider pay in `domo-pagos`,
with **no shared id** linking them. This record is that shared id.

## Core principle: additive, never a rewrite

The per-booking / standalone-quote side of the business is **untouched**.

- A quote with `project_id = NULL` behaves exactly as it always has.
- The `projects` table is new and separate; nothing about the existing quote or
  booking flow changes.
- The `size` flag (`small` | `large`) is what will gate the "heavy machinery"
  (phases, draws, subcontract retention) in later steps — a small project stays
  light, a large one unlocks the extra structure.

## Schema (migration `20260813_project_record_spine.sql`)

`public.projects`

| Column | Purpose |
|---|---|
| `project_number` | `PROJ-###`, auto-assigned by trigger, sequential |
| `client_*` | denormalized client fields (mirrors the `quotes` pattern) |
| `title`, `description` | what the project is |
| `size` | `small` \| `large` — gates later heavy machinery |
| `status` | `draft` → `quoting` → `contract_sent` → `active` → `on_hold` → `closeout` → `complete` / `cancelled` |
| `primary_quote_id` | the approved quote driving the project |
| `budget_total` | planned total (from the approved quote); actuals come later |
| `contract_signed_at`, `deposit_amount`, `deposit_paid_at` | contract + deposit spine (Step 2) |
| `fondo_cleared`, `coi_cleared`, `permits_required`, `permits_cleared` | compliance gate (Step 5) |

`public.quotes` gains a nullable `project_id` FK → `projects(id)`.

### Numbering

A `project_number_seq` sequence + a `before insert` trigger assign `PROJ-001`,
`PROJ-002`, … when `project_number` is not supplied. The sequence is reset so the
first real project is `PROJ-001`.

### RLS

Enabled with a permissive `allow all` policy, matching the existing quote-app
model (anon key, browser-side queries). Tightening RLS across the quote app is a
separate, app-wide task.

## Status

- [x] Schema applied to the live `domo-quotes` Supabase project and verified
      (numbering, quote link, compliance defaults).
- [ ] App wiring — "Promote quote to project" action + a project list/detail view.
- [ ] Step 2: contract + deposit-on-signature (auto-generated from the quote).
