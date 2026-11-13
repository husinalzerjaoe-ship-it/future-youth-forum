const { initializeApp, applicationDefault } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");

initializeApp({ credential: applicationDefault() });

async function main() {
  const auth = getAuth();
  let pageToken;
  let updated = 0;
  do {
    const page = await auth.listUsers(1000, pageToken);
    for (const user of page.users) {
      const claims = user.customClaims || {};
      if (claims.role === "authenticated") continue;
      await auth.setCustomUserClaims(user.uid, { ...claims, role: "authenticated" });
      updated += 1;
    }
    pageToken = page.pageToken;
  } while (pageToken);
  process.stdout.write(`Updated ${updated} Firebase users with role=authenticated.\\n`);
}

main().catch((error) => {
  process.stderr.write(`${error.stack || error}\\n`);
  process.exitCode = 1;
});
