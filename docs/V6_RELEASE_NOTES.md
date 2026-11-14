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


## V6.2 — Friends battle arena and 2D treasure duel
- Adds 12 pass-and-play quiz arenas: general knowledge, science, geography and flags, history, football, anime, technology and safety, mathematics, language and literature, films and characters, riddles, and culture and arts.
- Each arena rotates turns between two named players, tracks scores, explains answers, and shows the winner.
- Adds a real-time online 2D treasure duel for two friends, with a 7×7 board, alternating moves, collectible gems, live scores, six-digit room codes, and direct friend invitations.
- Extends Firestore room and invitation rules for the new treasure duel while retaining existing XO and football quiz room paths.
- Android app version: 4.8.0+19.
- The new online treasure duel requires publishing the updated `firestore.rules` before use.

- Follow-up quality pass: removed an unused invitation helper; active invitations are sent from the waiting 2D room and are accepted only after a successful join.


## V6.3 — Arcade refresh
- Redesigned the game center with a polished hero banner, responsive two-column game cards, search, and filters for online, 2D, quiz, and solo games.
- Expanded the friends quiz arena from 12 to 18 categories, adding space and astronomy, animals, video games, food, Iraqi civilizations, and logic puzzles. Each new category includes five questions with explanations.
- Promoted the online 2D treasure duel to the featured game entry, with direct room creation, six-digit join codes, and friend invitations.
- Android app version: 4.9.0+20.
