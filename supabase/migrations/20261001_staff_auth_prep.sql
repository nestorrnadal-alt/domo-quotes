-- 2026-10-01 (APPLIED). Staff allowlist, is_staff(), signup guard and the login-required flag
-- for domo-quotes (same design as domo-leads 0059). Additive; nothing that worked before changes.
create table if not exists public.staff_allowlist (
  email text primary key check (email = lower(email)),
  name  text,
  added_at timestamptz not null default now()
);
alter table public.staff_allowlist enable row level security;
revoke all on public.staff_allowlist from anon, authenticated;
insert into public.staff_allowlist (email, name) values
  ('nestor@domoyourhome.com',    'Néstor'),
  ('nestorrnadal@gmail.com',     'Néstor'),
  ('janet@domoyourhome.com',     'Janet'),
  ('alexander@domoyourhome.com', 'Alexander (Cotto)'),
  ('jenny@domoyourhome.com',     'Jenny')
on conflict (email) do nothing;

create or replace function public.is_staff()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from auth.users u join public.staff_allowlist s on s.email = lower(u.email)
                 where u.id = auth.uid() and u.email_confirmed_at is not null);
$$;
revoke execute on function public.is_staff() from public, anon;
grant execute on function public.is_staff() to authenticated;

create or replace function public.guard_staff_signup()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.email is null or not exists (select 1 from public.staff_allowlist where email = lower(new.email)) then
    raise exception 'Este correo no está autorizado para Domo.' using errcode = '42501';
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_staff_signup() from public, anon, authenticated;
drop trigger if exists guard_staff_signup on auth.users;
create trigger guard_staff_signup before insert on auth.users for each row execute function public.guard_staff_signup();

create or replace function public.staff_login_required()
returns boolean language sql stable security definer set search_path = '' as $$
  select not has_table_privilege('anon', 'public.quotes', 'SELECT')
$$;
revoke execute on function public.staff_login_required() from public;
grant execute on function public.staff_login_required() to anon, authenticated;
