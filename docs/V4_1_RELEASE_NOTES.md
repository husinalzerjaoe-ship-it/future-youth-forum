# V4.1 incremental update

- Adds member profile activity metrics: account age in days, authored post count, and public chat message count.
- Adds a member points card on public profiles.
- The founder account can grant a positive integer point amount to another member.
- Founder grants are recorded in an append-only `pointGrants` collection.
- Adds Firestore rules restricting point balance changes and grants to the founder account.

## Scope and deployment notes

- Founder is displayed as having unlimited points; this does not silently alter unrelated game scoring.
- Profile message totals currently count public chat messages only, not private conversation messages.
- Historical longest-presence tracking is not implemented by this update.
- Native audio/video calling requires a configured RTC provider (for example, Agora, LiveKit, or a TURN-backed WebRTC service). No provider credentials are present in this repository, so this update does not claim to provide working in-app calls.
- Firestore rules must be published in Firebase Console separately from the GitHub commit.
