# Public Chat Upgrade – Setup

## Included in this update
- New public chat screen with replies, reactions, message editing/deletion, pinning, online count and typing indicator.
- Chat background is saved per account in Firestore.
- Founder badge styling and a founder-only tools menu.
- Moderators can manage public messages after the founder grants the role.
- Founder can grant complimentary Premium membership for 1–365 days using a member UID.
- Founder can publish a seven-day contest, view entries and choose a winner to grant membership.
- Membership grants are stored in `memberships/{uid}`; the member can read their own record, but only the founder can create/update/delete it.
- Images and GIF files are uploaded to Supabase Storage.

## Firestore rules
The complete rules are in `firestore.rules`. From the repository root, deploy with:

```bash
firebase deploy --only firestore:rules
```

Do not deploy only selected snippets; publish the complete rules file so existing forum permissions remain intact.

## Supabase Storage policy
The app uses Supabase bucket `forum-media`, not Firebase Storage, for public-chat uploads. Open Supabase Dashboard → SQL Editor and run the complete contents of `supabase_public_chat_storage.sql`.

The `forum-media` bucket must be public for the current `getPublicUrl()` image display approach. Check that making this bucket public is appropriate for the stories/profile media already stored there.

## Founder and moderator controls
- Founder account is identified by `husinalzerjaoe@gmail.com`.
- Open the public chat and tap the admin shield icon.
- Membership gifts require the member's Firebase Auth UID, duration in days, and a reason.
- Weekly contest entries are stored under `weeklyContests/{contestId}/entries/{uid}`.
- Long-press an open contest card as founder to view entries and select a winner.
- Moderator assignment also requires the member's Firebase Auth UID.

## Important limitations
- The $1/month paid checkout is not connected in this update. Do not mark a payment as successful from the client; connect a payment provider and a trusted server/webhook before selling subscriptions.
- Membership expiration is stored as an `expiresAt` timestamp. Premium-only feature gates must check that timestamp against the current time before granting access.
- The SQL policy covers authenticated INSERT uploads for public-chat image/GIF files. Keep the existing bucket access policy appropriate for the rest of the forum.
- Build and test the APK after deploying the Firestore and Supabase policies. A GitHub commit alone does not prove that the APK builds or that Firebase/Supabase policies have been published.
