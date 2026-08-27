-- IVU (PR sales tax) on contracts. contract_total is the SUBTOTAL (pre-IVU);
-- contract.html adds IVU on top when iva_applies and shows Subtotal / IVU / Total.
alter table public.contracts add column if not exists iva_applies boolean not null default true;
alter table public.contracts add column if not exists iva_rate    numeric not null default 0.115;

-- One-time cleanup for contracts created before the revised clauses existed:
-- drop the old snapshotted clause text so drafts render the current standard clauses.
-- (Applied to draft/sent only; signed/void contracts are left untouched.)
-- update public.contracts
--   set guarantee_terms=null, change_order_terms=null, cancellation_terms=null, payment_terms=null
--  where status in ('draft','sent');
