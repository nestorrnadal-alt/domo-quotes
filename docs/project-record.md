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

## App wiring (Step 1b)

Added to the quote tool (`index.html`), all additive — the existing quote flow
is untouched:

- **Proyectos** nav item + page (mirrors the Cotizaciones layout: stats, search,
  status filter, card list).
- **Convertir en proyecto** action on an *approved* quote — creates the
  `PROJ-###`, copies client + `grand_total` → `budget_total`, sets
  `quotes.project_id`, and defaults `size` to `large` at ≥ $15k. A quote already
  promoted shows a `PROJ-###` chip instead.
- **Project card** with inline editing: status, size, and the compliance gate
  (Fondo/CFSE, Seguro/COI, permisos). A **🔒 Bloqueado / ✅ Listo para empezar**
  badge reflects the gate — a project isn't "ready to start" until Fondo + COI
  (+ permits, if required) clear. "Ver cotización" opens the source quote;
  "Eliminar" removes the project and unlinks (never deletes) the quote.

## Contracts (Step 2)

A simple **English** service agreement, generated from the project/quote and
signed by the client through a **tokenized public link** (the main app is
login-gated, so signing lives on its own page).

- **`contracts` table** (migration `20260813_project_contracts.sql`): snapshots
  the terms at generation (`scope`, `contract_total`, `deposit_amount`,
  `deposit_percent`, `payment_terms`, and standard guarantee / change-order /
  cancellation text) so a signed contract never drifts if the quote is later
  edited. Carries a `public_token` (uuid) as the signing-link key and a
  `status` (`draft` → `sent` → `signed` / `void`).
- **Sign propagation trigger**: when a contract first becomes `signed`, the
  linked project's `contract_signed_at` and `deposit_amount` are stamped
  automatically. Verified end-to-end.
- **Admin** (in the project card): **Generar contrato** modal (total + deposit %
  → deposit amount + editable payment schedule), then **copy sign link**, mark
  sent, and a **deposit-cobrado** toggle once signed.
- **Client page** (`contract.html?t=<token>`): Domo-branded agreement with
  scope, price, deposit, payment schedule, and standard terms; captures a typed
  name + **drawn signature** + agreement checkbox, then writes the signature
  back. Already-signed links render read-only.

**Deposit note:** Step 2 *captures* the deposit and lets ops mark it collected.
Actually charging it (Stripe/BK) is a later hook, deliberately out of scope here.

**Security follow-up (tracked):** `contracts` uses the app's permissive
`allow all` RLS, reachable only via the unguessable `public_token`. Tightening
to token-scoped policies is a planned hardening pass across the quote app.

## Status

- [x] Schema applied to the live `domo-quotes` Supabase project and verified
      (numbering, quote link, compliance defaults).
- [x] App wiring — "Convertir en proyecto" action + Proyectos list with the
      compliance gate. Syntax + headless load verified.
- [x] Step 2: contracts table + sign trigger (verified) + admin generate/send +
      public signing page (`contract.html`). Syntax + headless load verified.
- [x] Step 3: progress invoicing — `project_milestones` (schedule of values),
      billing modal with roll-up (total / invoiced / collected / remaining),
      per-milestone pending→invoiced→paid with the BK invoice # captured,
      "generate from contract" seed. Roll-up verified against the DB.
- [x] Multi-phase projects — a project holds many quotes as ordered **phases**
      (`quotes.phase_name` / `phase_order`). Promote flow now offers **new vs.
      existing project**; phases can be added, moved, or unlinked; project
      revenue rolls up from all phases. Compliance softened to optional tracking
      (no hard gate, no blocked counter — per Nestor).
- [x] Step 5: per-project **profitability** — `project_costs` (actual costs by
      category) vs planned cost derived from the quotes (`Σ priced×(1−margin)`).
      Rentabilidad modal shows revenue / collected / planned vs actual cost and
      margin with ✅≥40 / ⚠️33–40 / ❌<33 banding. Verified against the DB.
- [ ] Step 4: compliance package assembly (Fondo/CFSE + COI + permits + docs) —
      deferred; Nestor not ready for a hard compliance gate yet.

## Multi-phase + profitability

**Phases:** a project is now many quotes. Each linked quote is a phase
(`phase_name`, `phase_order`); revenue = Σ phase `grand_total`, cached on
`projects.budget_total` via `syncProjectBudget()` whenever phases change.

**Profitability (Step 5):** planned cost comes from each phase's quote — stored
category totals are *priced*, so cost basis = `Σ total_cat × (1 − margin_cat)`.
Actual cost is logged in `project_costs`. The modal compares planned vs actual
margin (banded 40 / 33) and shows the cost variance.

## Progress invoicing (Step 3)

`project_milestones` is the schedule of values BookingKoala lacks: one project,
many billing milestones, each `pending → invoiced → paid`. BK stays the charging
engine — marking a milestone *invoiced* captures its **BK invoice #** (manual for
now; automating the BK push via the BK API is the follow-on). The billing modal
rolls up **total / invoiced / collected / remaining**, and "Generar desde
contrato" seeds a Depósito + Balance from the contract to start.
