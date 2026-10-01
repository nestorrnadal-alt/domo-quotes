-- 2026-10-01 (APPLIED). Customer-facing contract.html: read/sign ONE agreement by its secret
-- link token, instead of anon access to the whole contracts/settings tables.
create or replace function public.contract_by_token(p_token uuid)
returns jsonb
language sql stable security definer
set search_path = public
as $$ select to_jsonb(c) - 'signature_data' from public.contracts c where c.public_token = p_token $$;

create or replace function public.sign_contract(p_token uuid, p_signer_name text, p_signature_data text)
returns boolean
language plpgsql security definer
set search_path = public
as $$
declare n int;
begin
  if coalesce(trim(p_signer_name), '') = '' then raise exception 'signer name required'; end if;
  update public.contracts
     set status = 'signed', signed_at = now(), signer_name = trim(p_signer_name), signature_data = p_signature_data
   where public_token = p_token and status <> 'signed';   -- never overwrite an existing signature
  get diagnostics n = row_count;
  return n = 1;
end;
$$;

create or replace function public.company_public_settings()
returns jsonb
language sql stable security definer
set search_path = public
as $$
  select coalesce(jsonb_object_agg(key, value), '{}'::jsonb) from public.settings
  where key in ('company_name','company_email','company_phone','company_website','company_address','company_daco_reg','company_license')
$$;

revoke execute on function public.contract_by_token(uuid), public.sign_contract(uuid, text, text), public.company_public_settings() from public;
grant execute on function public.contract_by_token(uuid), public.sign_contract(uuid, text, text), public.company_public_settings() to anon, authenticated;
