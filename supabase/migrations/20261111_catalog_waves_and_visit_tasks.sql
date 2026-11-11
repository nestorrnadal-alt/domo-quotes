-- 2026-11-11 (APPLIED via execute_sql). Catalog review in priority waves + handyman visit tasks reviewed in minutes.
--
-- Why: 132 flat items stalled the review at 17. Quote data (6 mo) shows six trades carry ~40% of quoted
-- dollars (the rest is lump-sum / subcontract); booking data (1,058 handyman visits) shows ~20 task types
-- cover ~65% of what customers ask for. The review page now shows waves in order and hides the long tail.
--
-- Waves: 1 = handyman visit tasks (minutes, feeds the task-based booking flow and the quote builder)
--        2 = Pintura · Empañetado · Albañilería   3 = Plomería   4 = Eléctrico   5 = Impermeabilización
--        9 = later (AC, techos, puertas, lavado, losa, demolición, carpintería, jardinería)

alter table public.catalog_items add column if not exists review_wave     int     not null default 9;
alter table public.catalog_items add column if not exists minutes         int;              -- visit tasks only
alter table public.catalog_items add column if not exists complexity_flag boolean not null default false; -- +$100 (plomería / eléctrico / empañetado)

update public.catalog_items set review_wave = case trade
  when 'Pintura' then 2 when 'Empañetado / Drywall' then 2 when 'Albañilería / Concreto' then 2
  when 'Plomería' then 3 when 'Eléctrico' then 4 when 'Impermeabilización / Sellado' then 5 else 9 end
where review_wave = 9;

-- Superseded by the visit-task list (trade_order 0, ids h01–h27): the old 6-item handyman trade and the duplicate TV line.
update public.catalog_items set status='retired' where trade='Trabajos varios (Handyman)' or id='t05-i12';

-- Visit tasks seed: see ../seed/catalog_visit_tasks_seed.sql (h01–h27, minutes from booking data + trade norms).
-- Tier rules used by the booking flow (not stored yet): ≤3.5h media visita $250 · ≤6.5h día completo $385 · >6.5h = 2 visitas;
-- complexity_flag adds +$100; helper +$200; shopping $25.
