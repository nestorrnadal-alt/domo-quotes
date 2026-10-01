-- 2026-10-01 (APPLIED). lead-owner-tick (domo-leads) reconciles lead status from quote status.
-- Give it only source_lead_id/status/updated_at instead of anon read access to the whole quotes table.
create or replace function public.quote_lead_status_feed()
returns table (source_lead_id bigint, status text, updated_at timestamptz)
language sql stable security definer
set search_path = public
as $$
  select q.source_lead_id::bigint, q.status::text, q.updated_at
  from public.quotes q
  where q.source_lead_id is not null and q.status <> 'shadow'
  order by q.updated_at desc
$$;
revoke execute on function public.quote_lead_status_feed() from public;
grant execute on function public.quote_lead_status_feed() to anon, authenticated;
