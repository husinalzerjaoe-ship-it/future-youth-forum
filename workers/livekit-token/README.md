# LiveKit token worker (Cloudflare Workers Free)

This worker issues short-lived LiveKit participant JWTs only after verifying a Firebase Authentication ID token. It keeps the LiveKit API secret on the server and does not use Firebase Cloud Functions or Firebase Blaze billing.

## Required Cloudflare Worker secrets

Set these as **Secret** values in Workers & Pages → this Worker → Settings → Variables and Secrets:

- `LIVEKIT_API_KEY`: LiveKit API key identifier.
- `LIVEKIT_API_SECRET`: LiveKit API secret. Never put this value in Flutter, Git, or a public variable.

The non-secret settings are already in `wrangler.toml`:

- `FIREBASE_PROJECT_ID=futureyouth-69f8a`
- `LIVEKIT_URL=wss://youth-forum-future-lu43byvc.livekit.cloud`

## Deploy from Termux

From the repository root:

```bash
cd workers/livekit-token
npm install -g wrangler
wrangler login
wrangler secret put LIVEKIT_API_KEY
wrangler secret put LIVEKIT_API_SECRET
wrangler deploy
```

Paste each value only into the matching Termux prompt. Do not send the secret to anyone. Cloudflare Workers Free currently includes 100,000 requests/day; fair-use and CPU limits apply.

After deployment, copy the Worker URL (usually `https://future-youth-forum-livekit-token.<account>.workers.dev`). In the app, open الأقسام → مكالمات الصوت والفيديو → إعداد رابط خادم المكالمات, paste the Worker URL followed by `/token` only if you later configure a route; by default use the Worker URL as-is.

## Endpoint contract

POST JSON: `{ "roomName": "room-code", "participantName": "display name", "videoEnabled": true }`

Header: `Authorization: Bearer <Firebase ID token>`

Response: `{ "serverUrl": "wss://...", "participantToken": "<short-lived JWT>" }`

The worker verifies the Firebase token signature, issuer, audience, subject and expiry before creating a one-hour LiveKit token. It grants room join, publish, subscribe and data permissions only for the requested room.
