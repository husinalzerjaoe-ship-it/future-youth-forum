# V14 — Future Youth Forum scope and release checklist

## Branch safety
- V14 is developed on `feature/v14-build-on-user-v12`.
- Its parent is the user's V12 commit `2a0d85940c636f1fbb46b39b9abf7b9f6f8b903d` from `feature/v12-futuristic-all-in`.
- Never modify, merge into, or deploy from `main`. Do not open a PR targeting `main`.
- Keep V12 modules and existing entry points; new work is additive unless a separately reviewed bug fix is required.

## V14 changes in this first pass
- Add a unified Arabic RTL command center with searchable categories and shortcuts to existing modules.
- Keep the existing posts/chat/profile navigation and mini audio player intact.
- Restore the Jitsi backup-call shortcut inside watch rooms; the V12 room player, room model, sync logic, password flow, chat, image/voice messaging and membership logic are otherwise unchanged.
- Bump app version to `4.21.0+33`.

## Feature inventory carried forward from the user's requests

### Accounts, profiles and social community
- Public registration, profiles, avatars, profile editing, posts, comments, likes, saved posts, follows, ratings, notifications and member search.
- Founder identity and privileges: Alfredo founder label, gold badge/gradient styling, welcome message, founder-only moderation and reports.
- Interest clubs, member discussions, regional spaces, community events, polls, gratitude wall, daily missions, achievements and community search.

### Chat and messaging
- Public, private, group and regional chat.
- Private messages must remain restricted to the two conversation members; never make private messages publicly readable.
- Text, photos, video, voice notes, reactions, replies, search, mentions, typing/presence, member avatars, readable bubbles, pinned content and selectable chat backgrounds.
- Public chat moderation: timed/permanent mute, timed/permanent bans, reports, moderator log, blocked-user checks and profanity filtering.
- Founder-only moderation controls and member safety/reporting tools.

### Watch, cinema and calls
- Preserve the existing synchronized YouTube/direct/web watch rooms, room codes, private invitations, password-protected rooms, playback controls, participants, chat, image/voice sharing and legacy-room compatibility.
- Preserve the cinema room entry separately from the general watch-party entry.
- Preserve films, series, anime discovery, favorites/watchlists and Arabic-subtitle discovery links; never claim a title is Arabic-subtitled unless verified by its provider.
- Preserve LiveKit calling and the Jitsi browser fallback. Keep the Jitsi shortcut available from watch rooms.

### Media and libraries
- Preserve media uploads, stories, images, video, voice messages, stickers, GIFs, music catalogue, background audio, mini-player, seek/skip controls and Mix Player-related workflows.
- Preserve anime wallpapers and user uploads subject to rights checks.
- Preserve poetry, literary/folk writing, quotes, stories, greetings, heartbreak phrases, Quran, adhkar and duas.

### Games, sport and utilities
- Preserve game center, 2D adventure/arcade, quizzes, riddles, word games, XO, friend invitations/rooms, multiplayer battles, points, weekly contests and membership rewards.
- Preserve football news, live center, fixtures/results, team badges and match-related media.
- Preserve age calculator, zodiac section and other existing utility pages.

### Membership and rewards
- Preserve silver/gold/diamond/premium membership concepts, founder-granted rewards, expiry/entitlement handling, public award announcements, profile badges and weekly activity competitions.
- Do not add real payments or paid service dependencies without a separately reviewed user request.

## Firebase and storage release gate — do not deploy blindly
The current V12 `firestore.rules` already contains a `/conversations/{conversationId}` rule set and nested private-message/reaction rules. It checks conversation membership, sender identity/role, message type and HTTPS media URLs, and checks block relationships. This does not prove those rules are deployed to Firebase project `futureyouth-69f8a` or that every client write matches the schema.

Before publishing rules, test at least:
1. A signed-in user can query only conversations containing their UID.
2. A non-member cannot read a conversation or its nested messages/reactions.
3. A member can send text, image, video and voice messages with the expected fields.
4. A non-member cannot create messages, edit membership, or read message reactions.
5. Either direction of a user block prevents new private messages.
6. Banned/muted accounts cannot send chat messages.
7. Legacy watch rooms remain readable according to their legacy visibility behavior.
8. Public/private watch-room queries, invited users, room codes, password metadata, playback updates and nested room messages/participants are checked.
9. Storage/Supabase upload policies cover profile images, posts, stories, public chat, private chat, watch-room images and voice notes without allowing cross-user overwrite or public access to private media.
10. Firebase project ID, Firestore database, Storage bucket and Supabase Firebase-token trust configuration are confirmed before deployment.

The APK build workflow is not a Firebase rules deployment. Do not claim rules are live unless the dedicated rules workflow reports success against the intended Firebase project. Do not deploy Storage rules or change billing as part of this branch without verifying the configured bucket and permissions.

## Release acceptance
- Flutter tests pass.
- Flutter analyze completes without new errors.
- Android release APK builds and uploads as a real GitHub Actions artifact.
- Inspect the workflow run and artifact before sharing an APK.
- Install/runtime checks are still needed for Firebase auth, public/private chat, uploads, watch rooms, Jitsi/LiveKit, media playback and moderation.
