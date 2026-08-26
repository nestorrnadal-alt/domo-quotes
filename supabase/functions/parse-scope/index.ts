// parse-scope (Supabase Edge Function)
// Public (verify_jwt=false) + CORS so the static frontend can call it directly.
// Mirrors the original Netlify function (netlify/functions/parse-scope.js): parses a
// free-text scope of work into quote line items. Provider-flexible: prefers Anthropic
// (ANTHROPIC_API_KEY) to match the repo design, falls back to OpenAI (OPENAI_API_KEY)
// which is already configured on this project.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const ANTHROPIC_KEY = Deno.env.get("ANTHROPIC_API_KEY") ?? "";
const OPENAI_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

function j(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: CORS });
}

function buildPrompt(scope: string, catalog: any[]): string {
  const catalogRef = (catalog || [])
    .slice(0, 40)
    .map((c) => `${c.description} (${c.category}, $${c.unit_cost}/${c.unit})`)
    .join("\n");
  return `You are an expert construction and handyman estimator for Puerto Rico. Parse this scope of work into line items for a quote.

Scope: "${scope}"

Existing catalog items for reference (match these when relevant):
${catalogRef || "No catalog yet"}

Return ONLY a valid JSON array (no markdown, no explanation) with this exact format:
[{"description":"item description","category":"labor","quantity":1,"unit":"hr","unit_cost":45}]

Category must be exactly: "labor", "materials", or "equipment"
Use realistic Puerto Rico market rates in USD.
Always include at least one labor item.
Be specific and practical. If scope is vague, estimate conservatively.`;
}

async function callAnthropic(prompt: string): Promise<string> {
  const r = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": ANTHROPIC_KEY,
      "anthropic-version": "2023-06-01",
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
            model: "claude-sonnet-4-6",
      max_tokens: 1024,
      messages: [{ role: "user", content: prompt }],
    }),
  });
  if (!r.ok) throw new Error(`Anthropic ${r.status}: ${await r.text()}`);
  const d = await r.json();
  return d.content[0].text;
}

async function callOpenAI(prompt: string): Promise<string> {
  const r = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: { "Authorization": `Bearer ${OPENAI_KEY}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      model: "gpt-4o-mini",
      temperature: 0.2,
      messages: [{ role: "user", content: prompt }],
    }),
  });
  if (!r.ok) throw new Error(`OpenAI ${r.status}: ${await r.text()}`);
  const d = await r.json();
  return d.choices[0].message.content;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return j({ error: "Method Not Allowed" }, 405);

  try {
    const { scope, catalog } = await req.json();
    if (!scope) return j({ error: "No scope provided" }, 400);

    const prompt = buildPrompt(scope, catalog);
    let text: string;
    if (ANTHROPIC_KEY) text = await callAnthropic(prompt);
    else if (OPENAI_KEY) text = await callOpenAI(prompt);
    else return j({ error: "No AI provider key configured (ANTHROPIC_API_KEY or OPENAI_API_KEY)" }, 500);

    const clean = text.replace(/```json|```/g, "").trim();
    const items = JSON.parse(clean);
    return j({ items });
  } catch (err) {
    console.error(err);
    return j({ error: (err as Error).message }, 500);
  }
});
