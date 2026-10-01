-- PHASE 2 for domo-quotes — lock tables to signed-in staff. DO NOT APPLY until:
--   1. The Call Board and Pulse (domo-leads / domo-hub) are deployed with auth-gate.js
--      data-also="quotes", and the team has signed in to Cotizaciones from them once.
--   2. contract.html uses the token RPCs (contract_by_token / sign_contract /
--      company_public_settings) — deployed.
--   3. catalogo.html applies prices with the Cotizaciones login — deployed.
--   4. domo-leads lead-owner-tick reads rpc/quote_lead_status_feed instead of the quotes table
--      (repo: domo-leads/supabase/functions/lead-owner-tick/index.ts) — deployed.
-- Rollback: 20261001_staff_only_lockdown_rollback.sql
--
-- Stays open on purpose: catalog_reviews (shared price-review link), catalog_items read-only
-- (same page), the public quote PDFs bucket, and the RPCs used by customers/automations.

do $$
declare
  keep text[] := array['catalog_reviews', 'staff_allowlist'];
  t record; p record;
begin
  for t in
    select c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind in ('r','p') and c.relname <> all (keep)
  loop
    for p in select polname from pg_policy where polrelid = format('public.%I', t.relname)::regclass loop
      execute format('drop policy %I on public.%I', p.polname, t.relname);
    end loop;
    execute format('alter table public.%I enable row level security', t.relname);
    execute format('create policy staff_all on public.%I for all to authenticated using (public.is_staff()) with check (public.is_staff())', t.relname);
    execute format('revoke all on public.%I from anon', t.relname);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t.relname);
  end loop;
end $$;

-- The price-review page (no login) still needs to list the catalog.
create policy public_read on public.catalog_items for select to anon using (true);
grant select on public.catalog_items to anon;

-- Storage: quote photos are staff-only; quote PDFs stay publicly readable (customers get links),
-- but only staff can upload/replace them.
drop policy if exists "quote-photos all" on storage.objects;
create policy quote_photos_staff on storage.objects for all to authenticated
  using (bucket_id = 'quote-photos' and public.is_staff())
  with check (bucket_id = 'quote-photos' and public.is_staff());
alter policy quote_pdfs_auth_insert on storage.objects with check (bucket_id = 'quote-pdfs' and public.is_staff());
alter policy quote_pdfs_auth_update on storage.objects using (bucket_id = 'quote-pdfs' and public.is_staff())
  with check (bucket_id = 'quote-pdfs' and public.is_staff());
