# V6 — Complete community suite

## New in V6
- Adds a unified V6 community suite entry to the Community Hub.
- Adds interest clubs with creation, category, description, member joining, and member-only club discussions.
- Adds daily personal missions with check-off progress saved locally on the device.
- Adds a public gratitude wall for short positive messages.
- Adds a safety and privacy guide inside the app.
- Adds Firestore security rules for club creation, self-service membership changes, member-only club discussions, and gratitude posts. Users can only edit/delete their own permitted content; moderators retain moderation delete access.

## Retained from earlier versions
The V6 branch retains the existing V4.4/V5 application areas, including public and private chat, media and stories, local music playback, profile and points features, games, watch parties, events, polls, anime experience, creative library, daily world, match center, and LiveKit calling UI.

## Important setup
Publish the updated `firestore.rules` in Firebase Console before testing club creation, joining, club discussions, or gratitude posts. Do not loosen the existing rules to make these features work.

## Validation
The CI workflow runs Flutter dependency resolution, static analysis, syntax checks, and release APK compilation. A successful build verifies compilation, not live Firebase/LiveKit/Supabase behavior; test multi-account interactions on real devices.


## V6.1 — Knowledge and chat polish
- Adds a knowledge and entertainment corner with a daily fact, general knowledge, digital safety, study tips, language and literature, riddles, discussion prompts, and creative writing challenges.
- Adds local bookmarks, copy actions, category filters, and a random discovery action; saved items remain on the device.
- Improves public chat interaction with swipe-to-reply, double-tap heart reactions, a wider quick-reaction set, and a refreshed composer surface.
- Adds the new section to the Community Hub and bumps the Android app version to 4.7.0+18.
