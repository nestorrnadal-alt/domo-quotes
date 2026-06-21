// price-band-live — live price-meter for the New Quote screen.
// Embeds the in-progress scope (OpenAI text-embedding-3-small, like the other
// functions) and calls the shared SQL core via compute_price_band_live, so Cotto
// sees the gauge BEFORE saving/sending. Returns the embedding so the client can
// cache it and skip re-embedding when only the price/line items change.
// Public (verify_jwt=false) + CORS; gateway still requires the apikey header.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const OPENAI_KEY   = Deno.env.get("OPENAI_API_KEY")!;
const MODEL        = "text-embedding-3-small";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Max-Age": "86400",
};
const supa = createClient(SUPABASE_URL, SERVICE_KEY, { auth: { persistSession: false } });

async function embed(text: string): Promise<number[]> {
  const r = await fetch("https://api.openai.com/v1/embeddings", {
    method: "POST",
    headers: { "Authorization": `Bearer ${OPENAI_KEY}`, "Content-Type": "application/json" },
    body: JSON.stringify({ model: MODEL, input: text }),
  });
  if (!r.ok) throw new Error(`OpenAI ${r.status}: ${await r.text()}`);
  const j = await r.json();
  return j.data[0].embedding;
}
function jsonResp(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { ...CORS, "Content-Type": "application/json" } });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: CORS });
  if (req.method !== "POST") return jsonResp({ error: "POST only" }, 405);
  try {
    const b = await req.json();
    const {
      scope, embedding, grand_total,
      total_labor = 0, total_materials = 0, total_equipment = 0,
      margin_labor = 0, margin_materials = 0, margin_equipment = 0,
    } = b ?? {};

    if (!grand_total || Number(grand_total) <= 0) {
      return jsonResp({ band: "no_data", note: "Sin precio para comparar" });
    }
    let emb: number[] | null = Array.isArray(embedding) ? embedding : null;
    if (!emb) {
      if (!scope || typeof scope !== "string" || !scope.trim()) {
        return jsonResp({ band: "no_data", note: "Sin scope para comparar" });
      }
      emb = await embed(scope.trim());
    }

    const { data, error } = await supa.rpc("compute_price_band_live", {
      p_embedding: emb,
      p_grand_total: Number(grand_total),
      p_total_labor: Number(total_labor) || 0,
      p_total_materials: Number(total_materials) || 0,
      p_total_equipment: Number(total_equipment) || 0,
      p_margin_labor: Number(margin_labor) || 0,
      p_margin_materials: Number(margin_materials) || 0,
      p_margin_equipment: Number(margin_equipment) || 0,
    });
    if (error) throw error;
    return jsonResp({ ...(data ?? {}), embedding: emb });
  } catch (e) {
    return jsonResp({ error: String((e as Error)?.message ?? e) }, 500);
  }
});
