-- ROLLBACK for 20261001_staff_only_lockdown.sql — restores the pre-lockdown state
-- (generated from the live DB on 2026-10-01). Re-opens every table to the anon key.
drop policy if exists staff_all on public.catalog;
drop policy if exists staff_all on public.catalog_items;
drop policy if exists staff_all on public.catalog_rate_history;
drop policy if exists staff_all on public.clients;
drop policy if exists staff_all on public.contracts;
drop policy if exists staff_all on public.pattern_library;
drop policy if exists staff_all on public.project_costs;
drop policy if exists staff_all on public.project_milestones;
drop policy if exists staff_all on public.projects;
drop policy if exists staff_all on public.quote_emails;
drop policy if exists staff_all on public.quote_line_items;
drop policy if exists staff_all on public.quote_patterns;
drop policy if exists staff_all on public.quote_photos;
drop policy if exists staff_all on public.quotes;
drop policy if exists staff_all on public.settings;
drop policy if exists public_read on public.catalog_items;
create policy "Allow all operations" on public.pattern_library for all to public using (true) with check (true);
create policy "allow all" on public.catalog for all to public using (true) with check (true);
create policy "allow all" on public.catalog_items for all to public using (true) with check (true);
create policy "allow all" on public.catalog_rate_history for all to public using (true) with check (true);
create policy "allow all" on public.clients for all to public using (true) with check (true);
create policy "allow all" on public.contracts for all to public using (true) with check (true);
create policy "allow all" on public.project_costs for all to public using (true) with check (true);
create policy "allow all" on public.project_milestones for all to public using (true) with check (true);
create policy "allow all" on public.projects for all to public using (true) with check (true);
create policy "allow all" on public.quote_line_items for all to public using (true) with check (true);
create policy "allow all" on public.quote_photos for all to public using (true) with check (true);
create policy "allow all" on public.quotes for all to public using (true) with check (true);
create policy "allow all" on public.settings for all to public using (true) with check (true);
create policy quote_emails_all on public.quote_emails for all to public using (true) with check (true);
create policy quote_patterns_all on public.quote_patterns for all to public using (true) with check (true);
grant SELECT, INSERT, UPDATE, DELETE on public.catalog, public.catalog_items, public.catalog_rate_history,
  public.clients, public.contracts, public.pattern_library, public.project_costs, public.project_milestones,
  public.projects, public.quote_emails, public.quote_line_items, public.quote_patterns, public.quote_photos,
  public.quotes, public.settings to anon, authenticated;

drop policy if exists quote_photos_staff on storage.objects;
create policy "quote-photos all" on storage.objects for all to public
  using (bucket_id = 'quote-photos') with check (bucket_id = 'quote-photos');
alter policy quote_pdfs_auth_insert on storage.objects with check (bucket_id = 'quote-pdfs');
alter policy quote_pdfs_auth_update on storage.objects using (bucket_id = 'quote-pdfs') with check (bucket_id = 'quote-pdfs');
