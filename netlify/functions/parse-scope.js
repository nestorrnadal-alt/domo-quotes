const Anthropic = require("@anthropic-ai/sdk");

exports.handler = async (event) => {
  if (event.httpMethod !== "POST") {
    return { statusCode: 405, body: "Method Not Allowed" };
  }

  const headers = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Content-Type": "application/json",
  };

  try {
    const { scope, catalog } = JSON.parse(event.body);
    if (!scope) return { statusCode: 400, headers, body: JSON.stringify({ error: "No scope provided" }) };

    const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

    const catalogRef = (catalog || [])
      .slice(0, 40)
      .map((c) => `${c.description} (${c.category}, $${c.unit_cost}/${c.unit})`)
      .join("\n");

    const prompt = `You are an expert construction and handyman estimator for Puerto Rico. Parse this scope of work into line items for a quote.

Scope: "${scope}"

Existing catalog items for reference (match these when relevant):
${catalogRef || "No catalog yet"}

Return ONLY a valid JSON array (no markdown, no explanation) with this exact format:
[{"description":"item description","category":"labor","quantity":1,"unit":"hr","unit_cost":45}]

Category must be exactly: "labor", "materials", or "equipment"
Use realistic Puerto Rico market rates in USD.
Always include at least one labor item.
Be specific and practical. If scope is vague, estimate conservatively.`;

    const response = await client.messages.create({
            model: "claude-sonnet-4-6",
      max_tokens: 1024,
      messages: [{ role: "user", content: prompt }],
    });

    const text = response.content[0].text;
    const clean = text.replace(/```json|```/g, "").trim();
    const items = JSON.parse(clean);

    return { statusCode: 200, headers, body: JSON.stringify({ items }) };
  } catch (err) {
    console.error(err);
    return { statusCode: 500, headers, body: JSON.stringify({ error: err.message }) };
  }
};
