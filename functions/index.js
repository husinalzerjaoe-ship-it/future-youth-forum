const crypto = require("crypto");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { onUserCreated } = require("firebase-functions/v2/identity");

initializeApp();

const { onCall, HttpsError } = require("firebase-functions/v2/https");

// Existing accounts can request the minimal Supabase authenticated role for
// their own Firebase identity. This does not grant founder/admin privileges.
exports.ensureSupabaseAuthenticatedRole = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in is required.");
  }
  const auth = getAuth();
  const user = await auth.getUser(request.auth.uid);
  const claims = user.customClaims || {};
  if (claims.role !== "authenticated") {
    await auth.setCustomUserClaims(user.uid, {
      ...claims,
      role: "authenticated",
    });
  }
  return { role: "authenticated" };
});


// Adds the role Supabase needs to recognize Firebase users as authenticated.
// This grants no administrative privileges in either Firebase or Supabase.
exports.addSupabaseAuthenticatedRole = onUserCreated(async (event) => {
  const user = event.data;
  const existingClaims = user.customClaims || {};
  if (existingClaims.role === "authenticated") return;

  await getAuth().setCustomUserClaims(user.uid, {
    ...existingClaims,
    role: "authenticated",
  });
});


// Claim the daily check-in reward on the trusted server. The unique
// per-user/per-Baghdad-date marker makes repeated taps and retries idempotent.
exports.claimDailyCheckIn = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in is required.");
  }
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Baghdad",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(new Date());
  const values = Object.fromEntries(parts.map((part) => [part.type, part.value]));
  const dateKey = `${values.year}-${values.month}-${values.day}`;
  const uid = request.auth.uid;
  const marker = adminDb.collection("dailyCheckIns").doc(`${uid}_${dateKey}`);
  const profile = adminDb.collection("publicProfiles").doc(uid);
  let awarded = false;
  await adminDb.runTransaction(async (tx) => {
    const seen = await tx.get(marker);
    if (seen.exists) return;
    tx.create(marker, {
      uid,
      date: dateKey,
      points: 10,
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.set(profile, {
      points: FieldValue.increment(10),
      checkInCount: FieldValue.increment(1),
      lastCheckIn: dateKey,
    }, { merge: true });
    awarded = true;
  });
  return { awarded, points: awarded ? 10 : 0, date: dateKey };
});

// Award engagement points on the trusted server, not from the mobile client.
// Event markers make retries idempotent. Weekly totals use an ISO-like Monday key.
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const adminDb = getFirestore();

exports.verifyPrivateRoomPasscode = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in is required.");
  }
  const roomId = request.data?.roomId;
  const passcode = request.data?.passcode;
  if (typeof roomId !== "string" || roomId.length < 1 || roomId.length > 128
      || typeof passcode !== "string" || passcode.length < 4 || passcode.length > 64) {
    throw new HttpsError("invalid-argument", "Invalid room or passcode.");
  }
  const roomRef = adminDb.collection("privateRooms").doc(roomId);
  const roomSnap = await roomRef.get();
  if (!roomSnap.exists) throw new HttpsError("not-found", "Room not found.");
  const room = roomSnap.data();
  if (!Array.isArray(room.members) || !room.members.includes(request.auth.uid)) {
    throw new HttpsError("permission-denied", "You are not invited to this room.");
  }
  const expected = crypto.createHash("sha256")
    .update(String(room.passcodeSalt) + "|" + passcode)
    .digest("hex");
  const stored = String(room.passcodeHash || "");
  const a = Buffer.from(expected, "hex");
  const b = Buffer.from(stored, "hex");
  if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) {
    throw new HttpsError("permission-denied", "Incorrect room passcode.");
  }
  await roomRef.collection("access").doc(request.auth.uid).set({
    uid: request.auth.uid,
    verifiedAt: FieldValue.serverTimestamp(),
  });
  return { ok: true };
});


function weekKey(date = new Date()) {
  const d = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  const day = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() - day + 1);
  return d.toISOString().slice(0, 10);
}

async function awardPoints(eventId, uid, points, counter) {
  if (!uid || typeof uid !== "string") return;
  const marker = adminDb.collection("engagementEvents").doc(eventId);
  const profile = adminDb.collection("publicProfiles").doc(uid);
  await adminDb.runTransaction(async (tx) => {
    const seen = await tx.get(marker);
    if (seen.exists) return;
    tx.create(marker, { uid, points, counter, createdAt: FieldValue.serverTimestamp() });
    const wk = weekKey();
    tx.set(profile, {
      points: FieldValue.increment(points),
      weeklyPoints: { [wk]: FieldValue.increment(points) },
      [counter]: FieldValue.increment(1),
    }, { merge: true });
  });
}

exports.trackPublicChatMessage = onDocumentCreated("messages/{messageId}", async (event) => {
  const data = event.data?.data();
  if (!data || !data.senderId) return;
  await awardPoints("message_" + event.params.messageId, data.senderId, 2, "messageCount");
});

exports.trackPostCreation = onDocumentCreated("posts/{postId}", async (event) => {
  const data = event.data?.data();
  if (!data || !data.authorId) return;
  await awardPoints("post_" + event.params.postId, data.authorId, 5, "postCount");
});

exports.trackPostLike = onDocumentCreated("posts/{postId}/likes/{userId}", async (event) => {
  const liker = event.params.userId;
  const post = await adminDb.collection("posts").doc(event.params.postId).get();
  const authorId = post.data()?.authorId;
  if (!authorId || authorId === liker) return;
  await awardPoints("like_" + event.params.postId + "_" + liker, authorId, 1, "receivedLikes");
});
