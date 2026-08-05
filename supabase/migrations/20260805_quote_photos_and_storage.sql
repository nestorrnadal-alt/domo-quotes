-- Reference photos attached to a quote (client's to-do list / work site).
-- Internal use only (not shown to clients). Manual uploads today; the same
-- table + bucket are the target for future WhatsApp auto-capture (source='whatsapp').

create table if not exists public.quote_photos (
  id uuid primary key default gen_random_uuid(),
  quote_id uuid not null references public.quotes(id) on delete cascade,
  storage_path text not null,
  caption text,
  source text not null default 'upload',   -- 'upload' | 'whatsapp'
  created_at timestamptz not null default now()
);
create index if not exists quote_photos_quote_id_idx on public.quote_photos(quote_id);

alter table public.quote_photos enable row level security;
drop policy if exists "allow all" on public.quote_photos;
create policy "allow all" on public.quote_photos for all to public using (true) with check (true);

-- Private storage bucket for the images.
insert into storage.buckets (id, name, public)
values ('quote-photos', 'quote-photos', false)
on conflict (id) do nothing;

-- Access scoped to this bucket only (mirrors the app's permissive model).
drop policy if exists "quote-photos all" on storage.objects;
create policy "quote-photos all" on storage.objects for all to public
  using (bucket_id = 'quote-photos') with check (bucket_id = 'quote-photos');
