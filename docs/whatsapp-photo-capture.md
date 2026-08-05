# WhatsApp → Quote Photos (auto-capture) — n8n spec

Goal: when a client sends a photo over WhatsApp, store it and attach it to that
client's open quote/shadow automatically — landing in the **same** `quote_photos`
table + `quote-photos` bucket the manual uploader already uses.

No app code is required for the core flow. The only app-side follow-up is display
(see §7): WhatsApp photos attach to the **shadow**, and shadows aren't opened in
the photo-enabled editor yet.

---

## 0. Prerequisites / secrets (store in n8n credentials, never client-side)

| Name | What | Where to get it |
|---|---|---|
| `WHATSAPP_TOKEN` | Meta WhatsApp Cloud API token | Meta app → WhatsApp → API setup |
| `SUPABASE_URL` | `https://mpgljurndbfusxtcrogr.supabase.co` | Supabase project |
| `SUPABASE_SERVICE_ROLE` | **service_role** key (bypasses RLS; server-only) | Supabase → Settings → API |

> Provider note: this spec assumes **Meta WhatsApp Cloud API**. If the bot uses
> Twilio or 360dialog, only the "get media" steps (§3) change — the media already
> arrives as a fetchable URL there; the Supabase steps (§4–5) are identical.

---

## 1. One-time DB helper (phone → open quote)

Client phone formats differ (`(787) 555-0142` vs WhatsApp's `17875550142`), so match
on the **last 10 digits**. Add this RPC once:

```sql
create or replace function public.find_open_quote_for_phone(p_phone text)
returns uuid language sql stable as $$
  select id from public.quotes
  where right(regexp_replace(coalesce(client_phone,''), '\D', '', 'g'), 10)
      = right(regexp_replace(coalesce(p_phone,''),     '\D', '', 'g'), 10)
    and right(regexp_replace(coalesce(p_phone,''), '\D', '', 'g'), 10) <> ''
    and status in ('shadow','draft','sent')
  order by created_at desc
  limit 1
$$;
```

Optional dedup (WhatsApp re-delivers webhooks): add a source ref + unique index so the
same media can't be inserted twice:

```sql
alter table public.quote_photos add column if not exists source_ref text;
create unique index if not exists quote_photos_source_ref_uidx
  on public.quote_photos(source_ref) where source_ref is not null;
```

---

## 2. Trigger — inbound WhatsApp message

Hook into the **existing** bot webhook (the one that already creates shadows). Add a
branch that runs when the message is an image.

- **Filter node:** continue only if `messages[0].type === 'image'`
  (also handle `document` if clients sometimes send photos as files).
- Pull these fields for later:
  - `mediaId`   = `messages[0].image.id`
  - `phone`     = `messages[0].from`            (E.164 digits)
  - `wamid`     = `messages[0].id`              (for dedup)
  - `caption`   = `messages[0].image.caption`   (optional)

---

## 3. Get the media bytes (Meta Cloud API — two calls)

**3a. Resolve the media URL** — HTTP Request node:
```
GET https://graph.facebook.com/v20.0/{{$json.mediaId}}
Headers: Authorization: Bearer {{$credentials.WHATSAPP_TOKEN}}
→ returns { url, mime_type, ... }
```

**3b. Download the binary** — HTTP Request node (response = File/Binary):
```
GET {{ url from 3a }}
Headers: Authorization: Bearer {{$credentials.WHATSAPP_TOKEN}}
→ binary property e.g. `data`
```

*(Optional) Compress:* WhatsApp images are already ~100–300 KB, so this is optional.
If you want parity with the app, add an **Edit Image → Resize** node (max 1600px,
quality ~70) before uploading.

---

## 4. Find the target quote (RPC from §1)

HTTP Request node:
```
POST {{SUPABASE_URL}}/rest/v1/rpc/find_open_quote_for_phone
Headers:
  apikey: {{SUPABASE_SERVICE_ROLE}}
  Authorization: Bearer {{SUPABASE_SERVICE_ROLE}}
  Content-Type: application/json
Body: { "p_phone": "{{$json.phone}}" }
→ returns "<uuid>"  (or null)
```

- **If null:** no open quote for that phone. Recommended: let the bot's existing
  shadow-creation run first, then attach — i.e. order the workflow so the shadow
  exists before this branch. Fallback: skip + log (don't create orphan photos).

Set `quoteId` = the returned uuid.

---

## 5. Upload to Storage + insert the row

**5a. Upload the object** (path convention the app expects — `{quoteId}/{uuid}.jpg`,
bucket name in the URL, **not** in the stored path):
```
POST {{SUPABASE_URL}}/storage/v1/object/quote-photos/{{quoteId}}/{{uuid}}.jpg
Headers:
  apikey: {{SUPABASE_SERVICE_ROLE}}
  Authorization: Bearer {{SUPABASE_SERVICE_ROLE}}
  Content-Type: image/jpeg
Body: <binary from step 3b>
```
Generate `{{uuid}}` with an n8n `$randomString`/crypto step (any unique token).

**5b. Insert the DB row** (`storage_path` has NO bucket prefix):
```
POST {{SUPABASE_URL}}/rest/v1/quote_photos
Headers:
  apikey: {{SUPABASE_SERVICE_ROLE}}
  Authorization: Bearer {{SUPABASE_SERVICE_ROLE}}
  Content-Type: application/json
  Prefer: return=representation
Body:
{
  "quote_id":     "{{quoteId}}",
  "storage_path": "{{quoteId}}/{{uuid}}.jpg",
  "source":       "whatsapp",
  "caption":      "{{caption}}",
  "source_ref":   "{{wamid}}"
}
```
With the §1 dedup index, a re-delivered `wamid` returns a 409 — treat as success/skip.

---

## 6. (Optional) Acknowledge to the client
Send a WhatsApp text back: *"¡Recibimos tu foto! 📸"* so the client knows it landed.

---

## 7. App-side companion (needed for these to be *visible*)

WhatsApp photos attach to the client's **shadow**. Shadows open via "Cotizar →"
(`startFromShadow`) as a *new* quote template — which does **not** currently load or
carry photos. So two small app changes make them useful:

1. **Carry shadow photos forward on "Cotizar →":** when converting a shadow to a real
   quote, copy its `quote_photos` rows (and objects, or just re-point rows) to the new
   `quote_id`. ~30 min.
2. **(Optional) Show photos on the shadow card / a shadow preview** so you can see what
   the client sent before quoting. ~30–60 min.

Both are small and I can implement them on request.

---

## 8. Effort & security
- **n8n:** ~½–1 day (mostly the Meta media fetch + auth + the linking branch).
- **DB helper (§1):** 2 minutes.
- **App companion (§7):** ~1 hour, optional but recommended.
- **Security:** the `service_role` key lives only in n8n. Never ship it to the browser.
  The bucket stays private; the app reads via short-lived signed URLs.
