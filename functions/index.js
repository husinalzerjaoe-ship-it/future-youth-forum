const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { onUserCreated } = require("firebase-functions/v2/identity");

initializeApp();

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
