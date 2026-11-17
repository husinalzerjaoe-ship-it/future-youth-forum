# V4.3.0 — LiveKit calling foundation

- Added LiveKit Flutter SDK 2.13.2.
- Added Arabic call screen with audio/video selection, room code joining, mic mute, camera toggle and hang-up.
- Added Firebase ID token verification and short-lived LiveKit token issuance in a Cloudflare Workers-compatible endpoint.
- Kept the LiveKit API secret server-side; Firebase Blaze/Cloud Functions are not required for this route.
- Added Android microphone, camera, audio routing and Bluetooth permissions to the generated manifest setup.
- Updated app version to 4.3.0+14.
- Existing V4.2 profile, points, game room and community features remain in the same feature branch.

External setup still required before calls can connect: deploy the Cloudflare Worker, configure LIVEKIT_API_KEY and LIVEKIT_API_SECRET as Cloudflare secrets, and paste its workers.dev URL into the app. Then test with two signed-in devices.
