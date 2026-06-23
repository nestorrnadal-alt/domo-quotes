// send-quote-email v13
// Lump-sum body — scope + Subtotal / IVU / Total only. No line items.
// v13: forwards the client-generated PDF (pdf_base64 / pdf_filename) to the Make
// webhook so the quote PDF is attached to the email.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const WEBHOOK_URL  = Deno.env.get("MAKE_WEBHOOK_URL")!;
const SENDER_EMAIL = "info@domoyourhome.com";
const SENDER_NAME  = "Domo";
const PHONE        = "+1 787-419-0300";
const WEBSITE      = "www.domoyourhome.com";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Max-Age": "86400",
};

const supa = createClient(SUPABASE_URL, SERVICE_KEY, { auth: { persistSession: false } });

function money(n: number): string {
  return n.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function computeBreakdown(grand: number, ivaRate: number, ivaApplies: boolean) {
  if (!ivaApplies || ivaRate <= 0) return { subtotal: grand, iva: 0, total: grand };
  const iva = grand * ivaRate;
  return { subtotal: grand, iva, total: grand + iva };
}

function escapeHtml(s: string): string {
  return s.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]!));
}

function defaultBodyHtml(quote: any, b: { subtotal: number; iva: number; total: number }, ivaRate: number): string {
  const ivaPct = (ivaRate * 100).toFixed(1).replace(/\.0$/, "");
  const showIva = b.iva > 0;
  return `
<div style="font-family: Arial, Helvetica, sans-serif; color:#222; line-height:1.5; max-width:640px;">
  <p>Hola ${escapeHtml(quote.client_name ?? "")},</p>
  <p>A continuación el estimado <strong>${escapeHtml(quote.quote_number)}</strong> con el detalle de los trabajos solicitados.</p>
  ${quote.scope ? `<div style="white-space:pre-wrap; color:#444; margin:16px 0; padding:12px 14px; background:#fafafa; border-left:3px solid #ddd;">${escapeHtml(quote.scope)}</div>` : ""}
  <table cellpadding="4" cellspacing="0" style="border-collapse:collapse; margin:16px 0 20px auto;">
    ${showIva ? `
      <tr><td style="color:#555; padding-right:24px;">Subtotal</td><td style="text-align:right;">$${money(b.subtotal)}</td></tr>
      <tr><td style="color:#555; padding-right:24px;">IVU (${ivaPct}%)</td><td style="text-align:right;">$${money(b.iva)}</td></tr>
      <tr><td style="border-top:1px solid #ccc; padding-top:6px; padding-right:24px;"><strong>Total</strong></td><td style="text-align:right; border-top:1px solid #ccc; padding-top:6px;"><strong>$${money(b.total)}</strong></td></tr>
    ` : `
      <tr><td style="padding-right:24px;"><strong>Total</strong></td><td style="text-align:right;"><strong>$${money(b.total)}</strong></td></tr>
    `}
  </table>
  <p>Cualquier pregunta nos puede llamar al <strong>${PHONE}</strong> o responder este email.</p>
  <p style="margin-top:24px;">Gracias,<br/>Equipo Domo<br/>${WEBSITE}</p>
</div>`.trim();
}

function defaultBodyText(quote: any, b: { subtotal: number; iva: number; total: number }, ivaRate: number): string {
  const ivaPct = (ivaRate * 100).toFixed(1).replace(/\.0$/, "");
  const showIva = b.iva > 0;
  const lines: string[] = [
    `Hola ${quote.client_name ?? ""},`,
    "",
    `A continuación el estimado ${quote.quote_number} con el detalle de los trabajos solicitados.`,
    "",
  ];
  if (quote.scope) lines.push(quote.scope, "");
  if (showIva) {
    lines.push(`Subtotal:    $${money(b.subtotal)}`);
    lines.push(`IVU (${ivaPct}%):  $${money(b.iva)}`);
    lines.push(`Total:       $${money(b.total)}`);
  } else {
    lines.push(`Total: $${money(b.total)}`);
  }
  lines.push("", `Cualquier pregunta nos puede llamar al ${PHONE} o responder este email.`, "", "Gracias,", "Equipo Domo", WEBSITE);
  return lines.join("\n");
}

function jsonResp(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { ...CORS, "Content-Type": "application/json" } });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: CORS });
  if (req.method !== "POST") return jsonResp({ error: "POST only" }, 405);

  let logRowId: string | null = null;
  try {
    const body = await req.json();
    const {
      quote_id, to, cc, subject, body_html, body_text, mark_sent = true,
      iva_applies_override, iva_rate_override, pdf_base64, pdf_filename,
    } = body;

    if (!quote_id || !to) return jsonResp({ error: "quote_id and to are required" }, 400);

    const { data: quote, error: qErr } = await supa
      .from("quotes")
      .select("id, quote_number, client_name, client_email, scope, grand_total, status, iva_applies, iva_rate")
      .eq("id", quote_id)
      .maybeSingle();
    if (qErr) throw qErr;
    if (!quote) throw new Error("quote not found");

    const grand = Number(quote.grand_total ?? 0);
    const ivaApplies = iva_applies_override !== undefined ? !!iva_applies_override : !!quote.iva_applies;
    const ivaRate = iva_rate_override !== undefined ? Number(iva_rate_override) : Number(quote.iva_rate ?? 0.115);
    const breakdown = computeBreakdown(grand, ivaRate, ivaApplies);

    const finalSubject = subject ?? `Estimado ${quote.quote_number} — Domo`;
    const finalHtml    = body_html ?? defaultBodyHtml(quote, breakdown, ivaRate);
    const finalText    = body_text ?? defaultBodyText(quote, breakdown, ivaRate);
    const finalPdfName = (pdf_filename && String(pdf_filename).trim())
      ? String(pdf_filename).trim()
      : `${quote.quote_number}.pdf`;
    const finalPdfB64  = typeof pdf_base64 === "string" ? pdf_base64 : "";

    const { data: logRow, error: logErr } = await supa
      .from("quote_emails")
      .insert({
        quote_id, to_email: to,
        cc_emails: cc ? [cc] : null,
        subject: finalSubject,
        body_preview: finalText.slice(0, 500),
        status: "queued",
      }).select("id").single();
    if (logErr) throw logErr;
    logRowId = logRow.id;

    const payload = {
      quote_id,
      quote_number: quote.quote_number,
      to,
      cc: cc ?? "",
      from_email: SENDER_EMAIL,
      from_name: SENDER_NAME,
      reply_to: SENDER_EMAIL,
      subject: finalSubject,
      body_html: finalHtml,
      body_text: finalText,
      pdf_filename: finalPdfB64 ? finalPdfName : "",
      pdf_base64: finalPdfB64,
      subtotal: Number(breakdown.subtotal.toFixed(2)),
      iva: Number(breakdown.iva.toFixed(2)),
      total: Number(breakdown.total.toFixed(2)),
      iva_rate: ivaRate,
      iva_applies: ivaApplies,
    };

    const makeRes = await fetch(WEBHOOK_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const makeText = await makeRes.text();
    if (!makeRes.ok) throw new Error(`Make webhook ${makeRes.status}: ${makeText.slice(0, 300)}`);

    await supa.from("quote_emails").update({
      status: "sent",
      sent_at: new Date().toISOString(),
    }).eq("id", logRowId);

    if (mark_sent && quote.status !== "approved" && quote.status !== "rejected") {
      await supa.from("quotes").update({
        status: "sent",
        sent_to_email: to,
      }).eq("id", quote_id);
    }

    return jsonResp({ ok: true, quote_email_id: logRowId });
  } catch (e: any) {
    const msg = String(e?.message ?? e);
    if (logRowId) await supa.from("quote_emails").update({ status: "failed", error: msg }).eq("id", logRowId);
    return jsonResp({ error: msg }, 500);
  }
});
