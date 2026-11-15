# V4.2 — multiplayer room creation permission fix

## Fix
- Removed the preflight read of a not-yet-created `gameRooms/{roomCode}` document from XO and football quiz room creation.
- The old flow called `get()` before `set()`. The Firestore read rule intentionally allows reads only for waiting rooms or existing room members; a missing room therefore failed the read authorization check before the create rule could run.
- Both room types now write directly to the randomly generated six-digit document ID. Existing create validation remains enforced by `firestore.rules`.

## Existing room security
- XO room creation still requires the authenticated host, exactly one initial member, a 9-cell board, matching turn UID, empty winner, and a six-digit room code.
- Football quiz room creation still requires an authenticated host, one initial member, round zero, answers map, and scores map.
- Room joining and gameplay updates remain constrained by the existing room-member rules.

## Release
- App version: 4.2.0+13
- Publish the current `firestore.rules` from this branch in Firebase Console to retain the current application security policies. No broader public read/write rule was added to fix this client-side pre-read issue.
