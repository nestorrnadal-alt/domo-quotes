-- Optional firm/hard completion deadline on a contract.
-- When true, contract.html renders "the parties agree the completion date is a
-- firm deadline" instead of the good-faith-estimate language.
alter table public.contracts
  add column if not exists hard_deadline boolean not null default false;
