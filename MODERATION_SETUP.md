# Moderation and safety update

## Added to the Flutter client
- Tap a sender name in the public chat to open member actions.
- Members can report another account and block private messages.
- Founder and assigned chat moderators can apply 1-minute, 1-hour, 1-day, or permanent chat mutes; a 24-hour temporary suspension; a permanent account ban; or clear sanctions.
- Report review displays the reporter and reported account, and lets the founder review, mute for one day, permanently ban, or clear sanctions.
- Every moderation action writes an append-only `adminLogs` record.
- The founder has a quick link to the moderation log.
- Public chat input has a basic Arabic profanity filter.
- Light/dark appearance follows the device setting; Arabic UI typography uses Noto Sans Arabic.

## Firestore deployment
The updated full rules are in `firestore.rules`. Deploy from the project root:

```bash
firebase deploy --only firestore:rules
```

The rules check `userSanctions/{uid}` before allowing new public-chat messages, posts, comments, and stories. A temporary ban expires automatically according to its timestamp; a permanent ban remains until an authorized administrator clears it. Chat mutes affect public chat messages.

## Device-ban limitation
A reliable device ban must use a privacy-respecting app-installation identifier and be enforced by trusted backend code (for example, Firebase App Check plus a callable Cloud Function). A hardware serial/IMEI should not be collected. This repository update does **not** claim to implement device-level enforcement yet; a client-only device ID check can be bypassed.

## Profanity-filter limitation
The current Arabic word filter is a client-side first layer, not a complete intelligent moderation service. It can be bypassed by modified clients and needs a trusted Cloud Function or moderation provider for server-side text screening, normalization, and appeals.

## Fonts and emoji
The app uses Noto Sans Arabic and system light/dark themes. It cannot bundle Apple's proprietary San Francisco font or Apple emoji artwork as a guaranteed Android-wide replacement. iOS emoji rendering is controlled by the operating system; Android uses the device's emoji font.

## Build and verification
A GitHub commit is not proof that an APK builds or that Firebase rules are deployed. Run Flutter analyze/build and test the flows using a non-founder test account after deploying the rules.
