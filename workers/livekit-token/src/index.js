const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Authorization, Content-Type",
  "Access-Control-Max-Age": "86400",
};

const json = (body, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store" },
  });

function decodeSegment(segment) {
  const normalized = segment.replace(/-/g, "+").replace(/_/g, "/");
  const padded = normalized + "=".repeat((4 - (normalized.length % 4)) % 4);
  const binary = atob(padded);
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
}

function encodeSegment(value) {
  const bytes = new TextEncoder().encode(typeof value === "string" ? value : JSON.stringify(value));
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

async function verifyFirebaseIdToken(token, projectId) {
  const parts = token.split(".");
  if (parts.length !== 3) throw new Error("Invalid Firebase token.");
  const header = JSON.parse(new TextDecoder().decode(decodeSegment(parts[0])));
  const claims = JSON.parse(new TextDecoder().decode(decodeSegment(parts[1])));
  if (header.alg !== "RS256" || typeof header.kid !== "string") throw new Error("Invalid token algorithm.");

  const certResponse = await fetch(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
    { cf: { cacheTtl: 300, cacheEverything: true } },
  );
  if (!certResponse.ok) throw new Error("Could not verify Firebase signing keys.");
  const certs = await certResponse.json();
  const jwk = certs.keys?.find((key) => key.kid === header.kid && key.kty === "RSA");
  if (!jwk) throw new Error("Unknown Firebase signing key.");

  const publicKey = await crypto.subtle.importKey(
    "jwk", jwk, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["verify"],
  );
  const signingInput = new TextEncoder().encode(parts[0] + "." + parts[1]);
  const signatureValid = await crypto.subtle.verify(
    "RSASSA-PKCS1-v1_5", publicKey, decodeSegment(parts[2]), signingInput,
  );
  const now = Math.floor(Date.now() / 1000);
  if (!signatureValid
      || claims.iss !== `https://securetoken.google.com/${projectId}`
      || claims.aud !== projectId
      || typeof claims.sub !== "string" || claims.sub.length < 1 || claims.sub.length > 128
      || !Number.isFinite(claims.exp) || claims.exp <= now
      || !Number.isFinite(claims.iat) || claims.iat > now + 300
      || !Number.isFinite(claims.auth_time) || claims.auth_time > now + 300) {
    throw new Error("Firebase session is invalid or expired.");
  }
  return claims;
}

async function createLiveKitToken(env, uid, roomName, participantName, videoEnabled) {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "HS256", typ: "JWT" };
  const payload = {
    iss: env.LIVEKIT_API_KEY,
    sub: uid,
    nbf: now - 5,
    iat: now,
    exp: now + 3600,
    name: participantName,
    video: {
      roomJoin: true,
      room: roomName,
      canPublish: true,
      canSubscribe: true,
      canPublishData: true,
    },
    metadata: JSON.stringify({ app: "future-youth-forum", videoEnabled: !!videoEnabled }),
  };
  const unsigned = encodeSegment(header) + "." + encodeSegment(payload);
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(env.LIVEKIT_API_SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(unsigned));
  let binary = "";
  for (const byte of new Uint8Array(signature)) binary += String.fromCharCode(byte);
  const encodedSignature = btoa(binary).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  return unsigned + "." + encodedSignature;
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: corsHeaders });
    if (request.method !== "POST") return json({ error: "Method not allowed." }, 405);
    if (!env.FIREBASE_PROJECT_ID || !env.LIVEKIT_API_KEY || !env.LIVEKIT_API_SECRET || !env.LIVEKIT_URL) {
      return json({ error: "Token service is not configured." }, 503);
    }

    const authorization = request.headers.get("Authorization") || "";
    const match = authorization.match(/^Bearer\s+(.+)$/i);
    if (!match) return json({ error: "Firebase sign-in is required." }, 401);

    try {
      const claims = await verifyFirebaseIdToken(match[1], env.FIREBASE_PROJECT_ID);
      const body = await request.json();
      const roomName = typeof body.roomName === "string" ? body.roomName.trim() : "";
      const participantName = typeof body.participantName === "string"
        ? body.participantName.trim().slice(0, 48) : "عضو";
      if (!/^[A-Za-z0-9_-]{3,64}$/.test(roomName)) {
        return json({ error: "Room name must be 3-64 characters: letters, numbers, _ or -." }, 400);
      }
      const token = await createLiveKitToken(
        env, claims.sub, roomName, participantName || "عضو", body.videoEnabled === true,
      );
      return json({
        serverUrl: env.LIVEKIT_URL,
        participantToken: token,
        expiresAt: Math.floor(Date.now() / 1000) + 3600,
        roomName,
      });
    } catch (error) {
      return json({ error: error instanceof Error ? error.message : "Token request failed." }, 401);
    }
  },
};
