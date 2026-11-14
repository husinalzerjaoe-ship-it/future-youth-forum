# LiveKit token worker (Cloudflare Workers Free)

This worker issues short-lived LiveKit participant JWTs only after verifying a Firebase Authentication ID token. It keeps the LiveKit API secret on the server and does not use Firebase Cloud Functions or Firebase Blaze billing.

## Required Cloudflare Worker secrets

Set these as **Secret** values in Workers & Pages → this Worker → Settings → Variables and Secrets:

- `LIVEKIT_API_KEY`: LiveKit API key identifier.
- `LIVEKIT_API_SECRET`: LiveKit API secret. Never put this value in Flutter, Git, or a public variable.

The non-secret settings are already in `wrangler.toml`:

- `FIREBASE_PROJECT_ID=futureyouth-69f8a`
- `LIVEKIT_URL=wss://youth-forum-future-lu43byvc.livekit.cloud`

## Deploy from the Cloudflare dashboard (recommended on mobile)

1. Open https://dash.cloudflare.com/ and sign in or create a free account.
2. Open **Workers & Pages** → **Create** → **Create Worker**. Name it `future-youth-forum-livekit-token`, then deploy the starter Worker.
3. Open the new Worker and choose **Edit code**.
4. Replace the starter code with the complete contents of `src/index.js` from this folder:
   https://github.com/husinalzerjaoe-ship-it/future-youth-forum/blob/feature/v4-complete-profile-stats/workers/livekit-token/src/index.js
5. Save and deploy.
6. Open **Settings → Variables and Secrets**. Add these as plain-text variables:
   - `FIREBASE_PROJECT_ID` = `futureyouth-69f8a`
   - `LIVEKIT_URL` = `wss://youth-forum-future-lu43byvc.livekit.cloud`
7. Add these two as **Secret** values, not plain-text variables:
   - `LIVEKIT_API_KEY` = your LiveKit API key identifier
   - `LIVEKIT_API_SECRET` = the matching LiveKit API secret
8. Save and deploy again. Copy the Worker URL shown by Cloudflare (usually `https://future-youth-forum-livekit-token.<account>.workers.dev`).

Do not send the LiveKit secret in chat or put it in the app. Cloudflare Workers Free currently includes up to 100,000 requests/day, subject to CPU and platform limits.

## Optional deploy from a desktop or compatible Linux shell

From this folder, use Wrangler:

```bash
npm install -g wrangler
wrangler login
wrangler secret put LIVEKIT_API_KEY
wrangler secret put LIVEKIT_API_SECRET
wrangler deploy
```

After deployment, open الأقسام → مكالمات الصوت والفيديو → إعداد رابط خادم المكالمات and paste the Worker URL exactly as provided, without `/token`.

## Endpoint contract

POST JSON: `{ "roomName": "room-code", "participantName": "display name", "videoEnabled": true }`

Header: `Authorization: Bearer <Firebase ID token>`

Response: `{ "serverUrl": "wss://...", "participantToken": "<short-lived JWT>" }`

The worker verifies the Firebase token signature, issuer, audience, subject and expiry before creating a one-hour LiveKit token. It grants room join, publish, subscribe and data permissions only for the requested room.
