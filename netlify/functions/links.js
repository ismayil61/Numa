const { getStore } = require("@netlify/blobs");

const headers = { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store" };
const respond = (statusCode, data) => ({ statusCode, headers, body: JSON.stringify(data) });
const store = () => getStore("numa-customer-links");

function authorized(event) {
  const expected = process.env.ADMIN_PASSWORD;
  const supplied = event.headers?.authorization?.replace(/^Bearer\s+/i, "");
  return Boolean(expected && supplied && supplied === expected);
}

exports.handler = async (event) => {
  if (!authorized(event)) return respond(401, { error: "Admin sign-in failed. Check the ADMIN_PASSWORD Netlify environment variable." });
  const links = store();

  try {
    if (event.httpMethod === "GET") {
      const page = await links.list();
      const records = await Promise.all((page.blobs || []).map(async ({ key }) => {
        const record = await links.get(key, { type: "json" });
        return record ? { ...record, token: key } : null;
      }));
      return respond(200, { links: records.filter(Boolean) });
    }

    const input = JSON.parse(event.body || "{}");
    if (event.httpMethod === "POST") {
      const tier = ["starter", "standard", "premium"].includes(input.tier) ? input.tier : null;
      const messageLimit = Number(input.messageLimit);
      if (!tier || !Number.isInteger(messageLimit) || messageLimit < 1 || messageLimit > 100000) {
        return respond(400, { error: "Choose a valid plan and message limit." });
      }
      const bytes = new Uint8Array(24);
      crypto.getRandomValues(bytes);
      const token = "NUMA-" + Array.from(bytes, value => value.toString(16).padStart(2, "0")).join("").toUpperCase();
      const record = {
        tier,
        customerName: String(input.customerName || "").slice(0, 120),
        customerEmail: String(input.customerEmail || "").slice(0, 200),
        note: String(input.note || "").slice(0, 500),
        messageLimit,
        messagesUsed: 0,
        expiresAt: input.expiresAt || null,
        state: "active",
        createdAt: new Date().toISOString()
      };
      await links.set(token, JSON.stringify(record), { metadata: { tier } });
      return respond(201, { link: { ...record, token } });
    }

    if (event.httpMethod === "PATCH") {
      const token = String(input.token || "");
      if (!token || !["active", "revoked"].includes(input.state)) return respond(400, { error: "A valid link token and state are required." });
      const record = await links.get(token, { type: "json" });
      if (!record) return respond(404, { error: "Link not found." });
      const updated = { ...record, state: input.state };
      await links.set(token, JSON.stringify(updated), { metadata: { tier: updated.tier } });
      return respond(200, { link: { ...updated, token } });
    }

    if (event.httpMethod === "DELETE") {
      const token = String(event.queryStringParameters?.token || "");
      if (!token) return respond(400, { error: "A link token is required." });
      await links.delete(token);
      return respond(200, { ok: true });
    }

    return respond(405, { error: "Method not allowed." });
  } catch (error) {
    console.error("Customer links function failed", error.message);
    return respond(500, { error: "Could not access saved customer links. Check Netlify Blobs setup and function logs." });
  }
};
