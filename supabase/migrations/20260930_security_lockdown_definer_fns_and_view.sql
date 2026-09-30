-- 2026-09-30 security audit (applied via Supabase connector).
-- Destructive SECURITY DEFINER RPCs were callable by anyone with the anon key.
-- purge_shadows_for_lead stays open: the domo-leads cron (purge_cold_shadows) calls it with the anon key.
revoke execute on function public.purge_shadow(uuid) from public, anon;
revoke execute on function public.purge_stale_shadows(integer) from public, anon;
-- Trigger-only functions: no reason to expose as /rpc endpoints (trigger firing ignores EXECUTE).
revoke execute on function public.notify_lead_of_quote_change() from public, anon, authenticated;
revoke execute on function public.tg_drop_shadow_on_sent() from public, anon, authenticated;
-- View should respect caller's RLS rather than the owner's.
alter view public.shadow_quote_eval set (security_invoker = on);
