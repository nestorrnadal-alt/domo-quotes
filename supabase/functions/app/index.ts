// app (Supabase Edge Function) — serves the DomoQuote frontend as a public webpage.
// Proxies index.html from the public GitHub repo and serves it as text/html, so the
// app is reachable at a public URL with no repo/dashboard access required.
// Public (verify_jwt=false). Same origin as the parse-scope function + Supabase API.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const RAW =
  "https://raw.githubusercontent.com/nestorrnadal-alt/domo-quotes/claude/domoquotes-build-deploy-0o7pkw/index.html";

let cache: { html: string; at: number } | null = null;
const TTL_MS = 60_000;

Deno.serve(async (_req: Request) => {
  try {
    if (!cache || Date.now() - cache.at > TTL_MS) {
      const r = await fetch(RAW, { cache: "no-store" });
      if (!r.ok) throw new Error(`source ${r.status}`);
      cache = { html: await r.text(), at: Date.now() };
    }
    return new Response(cache.html, {
      status: 200,
      headers: {
        "Content-Type": "text/html; charset=utf-8",
        "Cache-Control": "public, max-age=60",
        "X-Content-Type-Options": "nosniff",
      },
    });
  } catch (e) {
    return new Response(`Failed to load app: ${(e as Error).message}`, {
      status: 502,
      headers: { "Content-Type": "text/plain" },
    });
  }
});
