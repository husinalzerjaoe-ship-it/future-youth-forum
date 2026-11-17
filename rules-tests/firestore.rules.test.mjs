import test, { before, after, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  doc, collection, getDoc, getDocs, query, where, or, setDoc, updateDoc, runTransaction, serverTimestamp, Timestamp
} from 'firebase/firestore';

const projectId = 'demo-futureyouth-rules';
let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: { rules: fs.readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') }
  });
});

after(async () => {
  if (env) await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

function user(uid) {
  return env.authenticatedContext(uid).firestore();
}
function founder(email = 'husinalzerjaoe@gmail.com') {
  return env.authenticatedContext('founder-uid', { email }).firestore();
}
async function seed(path, data) {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), path), data);
  });
}

test('the inbox OR query lists only conversations indexed to the signed-in member', async () => {
  await seed('conversations/dm-alice-bob', { members: ['alice', 'bob'], memberA: 'alice', memberB: 'bob', lastMessage: 'hello' });
  await seed('conversations/dm-alice-carol', { members: ['alice', 'carol'], memberA: 'alice', memberB: 'carol', lastMessage: 'hi' });
  await seed('conversations/dm-bob-carol', { members: ['bob', 'carol'], memberA: 'bob', memberB: 'carol', lastMessage: 'private' });

  const inboxQuery = (uid) => query(
    collection(user(uid), 'conversations'),
    or(where('memberA', '==', uid), where('memberB', '==', uid)),
  );
  const aliceInbox = await getDocs(inboxQuery('alice'));
  assert.equal(aliceInbox.size, 2);
  assert.deepEqual(
    aliceInbox.docs.map((entry) => entry.id).sort(),
    ['dm-alice-bob', 'dm-alice-carol'],
  );
  const bobInbox = await getDocs(inboxQuery('bob'));
  assert.equal(bobInbox.size, 2);
  const malloryInbox = await getDocs(inboxQuery('mallory'));
  assert.equal(malloryInbox.size, 0);
});

test('conversation members can pin and mute only their own inbox preferences', async () => {
  await seed('conversations/dm-prefs', { members: ['alice', 'bob'] });

  await assertSucceeds(updateDoc(doc(user('alice'), 'conversations/dm-prefs'), {
    pinnedBy: ['alice'],
  }));
  await assertSucceeds(updateDoc(doc(user('bob'), 'conversations/dm-prefs'), {
    mutedBy: ['bob'],
  }));
  await assertFails(updateDoc(doc(user('alice'), 'conversations/dm-prefs'), {
    pinnedBy: ['alice', 'bob'],
  }));
  await assertFails(updateDoc(doc(user('bob'), 'conversations/dm-prefs'), {
    mutedBy: ['alice', 'bob'],
  }));
});

test('founder chat controls are readable by members and writable only by the founder', async () => {
  await assertSucceeds(setDoc(doc(founder(), 'chatControls/main'), {
    allowLinks: false,
    allowMedia: false,
    directMessagesEnabled: false,
    publicChatEnabled: true,
    updatedAt: serverTimestamp(),
    updatedBy: 'founder-uid',
  }));
  await assertSucceeds(getDoc(doc(user('alice'), 'chatControls/main')));
  await assertFails(updateDoc(doc(user('alice'), 'chatControls/main'), {
    publicChatEnabled: false,
    updatedAt: serverTimestamp(),
    updatedBy: 'alice',
  }));

  await assertSucceeds(setDoc(doc(founder(), 'developerLinks/main'), {
    telegram: 'https://t.me/example',
    instagram: '',
    tiktok: '',
    youtube: '',
    website: '',
    updatedAt: serverTimestamp(),
  }));
  await assertSucceeds(getDoc(doc(user('bob'), 'developerLinks/main')));
  await assertFails(setDoc(doc(user('bob'), 'developerLinks/forged'), {
    telegram: 'https://t.me/forged',
    instagram: '',
    tiktok: '',
    youtube: '',
    website: '',
    updatedAt: serverTimestamp(),
  }));
});

test('founder controls can pause direct messages, public chat, media, and links', async () => {
  await seed('chatControls/main', {
    allowLinks: false,
    allowMedia: false,
    directMessagesEnabled: false,
    publicChatEnabled: false,
  });

  await assertFails(setDoc(doc(user('alice'), 'conversations/dm-disabled'), {
    members: ['alice', 'bob'],
  }));
  await assertFails(setDoc(doc(user('alice'), 'messages/public-disabled'), {
    senderId: 'alice', senderRole: 'member', type: 'text', text: 'hello',
  }));

  await seed('conversations/dm-media', { members: ['alice', 'bob'] });
  await assertFails(setDoc(doc(user('alice'), 'conversations/dm-media/messages/media-1'), {
    senderId: 'alice', senderRole: 'member', type: 'image', text: '',
    imageUrl: 'https://media.example.test/photo.jpg',
  }));
});

test('links and media are accepted when founder controls allow them', async () => {
  await seed('chatControls/main', {
    allowLinks: true,
    allowMedia: true,
    directMessagesEnabled: true,
    publicChatEnabled: true,
  });
  await assertSucceeds(setDoc(doc(user('alice'), 'messages/link-allowed'), {
    senderId: 'alice', senderRole: 'member', type: 'text',
    text: 'شاهد https://example.com',
  }));
  await assertSucceeds(setDoc(doc(user('alice'), 'messages/image-allowed'), {
    senderId: 'alice', senderRole: 'member', type: 'image', text: '',
    imageUrl: 'https://media.example.test/photo.jpg',
  }));
});

test('private conversation messages are readable only by the two members', async () => {
  await seed('conversations/dm-1', { members: ['alice', 'bob'] });
  await seed('conversations/dm-1/messages/msg-1', {
    senderId: 'alice', senderRole: 'member', type: 'text', text: 'hello'
  });

  await assertSucceeds(getDoc(doc(user('alice'), 'conversations/dm-1/messages/msg-1')));
  await assertSucceeds(getDoc(doc(user('bob'), 'conversations/dm-1/messages/msg-1')));
  await assertFails(getDoc(doc(user('mallory'), 'conversations/dm-1/messages/msg-1')));
});

test('a conversation member can send a message, a non-member and blocked pair cannot', async () => {
  await seed('conversations/dm-2', { members: ['alice', 'bob'] });
  const message = {
    senderId: 'alice', senderRole: 'member', type: 'text', text: 'hello'
  };
  await assertSucceeds(setDoc(doc(user('alice'), 'conversations/dm-2/messages/m-1'), message));
  await assertSucceeds(setDoc(doc(user('alice'), 'conversations/dm-2/messages/sticker-1'), {
    senderId: 'alice', senderRole: 'member', type: 'sticker', text: '😂'
  }));
  await assertSucceeds(setDoc(doc(user('bob'), 'conversations/dm-2/messages/gif-1'), {
    senderId: 'bob', senderRole: 'member', type: 'gif', text: 'GIF متحرك',
    gifUrl: 'https://media.example.test/funny.gif'
  }));
  await assertFails(setDoc(doc(user('mallory'), 'conversations/dm-2/messages/m-2'), {
    ...message, senderId: 'mallory'
  }));

  await seed('userBlocks/alice_bob', { blockerId: 'alice', blockedId: 'bob' });
  await assertFails(setDoc(doc(user('alice'), 'conversations/dm-2/messages/m-3'), {
    ...message, text: 'blocked'
  }));
});

test('private room messages remain limited to room members', async () => {
  await seed('privateRooms/room-1', {
    ownerId: 'alice', name: 'Private', members: ['alice', 'bob'], invitedUids: ['alice', 'bob']
  });
  await seed('privateRooms/room-1/messages/m-1', {
    senderId: 'alice', type: 'text', text: 'inside'
  });

  await assertSucceeds(getDoc(doc(user('alice'), 'privateRooms/room-1/messages/m-1')));
  await assertSucceeds(getDoc(doc(user('bob'), 'privateRooms/room-1/messages/m-1')));
  await assertFails(getDoc(doc(user('mallory'), 'privateRooms/room-1/messages/m-1')));
  await assertSucceeds(setDoc(doc(user('bob'), 'privateRooms/room-1/messages/m-2'), {
    senderId: 'bob', type: 'text', text: 'reply'
  }));
  await assertFails(setDoc(doc(user('mallory'), 'privateRooms/room-1/messages/m-3'), {
    senderId: 'mallory', type: 'text', text: 'intrusion'
  }));
});

test('private watch rooms are visible only to the host and invited members', async () => {
  await seed('watchRooms/private-1', {
    hostUid: 'alice', visibility: 'private', invitedUids: ['alice', 'bob'],
    name: 'private watch', url: 'https://example.com/video', sourceType: 'web',
    status: 'paused', active: true, roomCode: '123456'
  });

  await assertSucceeds(getDoc(doc(user('alice'), 'watchRooms/private-1')));
  await assertSucceeds(getDoc(doc(user('bob'), 'watchRooms/private-1')));
  await assertFails(getDoc(doc(user('mallory'), 'watchRooms/private-1')));
});

test('a banned account cannot create a public chat message', async () => {
  await seed('userSanctions/alice', { permanentBan: true });
  await assertFails(setDoc(doc(user('alice'), 'messages/banned-message'), {
    senderId: 'alice', senderRole: 'member', type: 'text', text: 'not allowed'
  }));
});

test('public chat accepts validated sticker and animated GIF messages', async () => {
  await assertSucceeds(setDoc(doc(user('alice'), 'messages/sticker-1'), {
    senderId: 'alice', senderRole: 'member', type: 'sticker', text: '🫶', createdAt: serverTimestamp()
  }));
  await assertSucceeds(setDoc(doc(user('alice'), 'messages/gif-1'), {
    senderId: 'alice', senderRole: 'member', type: 'gif', text: 'GIF متحرك',
    imageUrl: 'https://media.example.test/reaction.gif', createdAt: serverTimestamp()
  }));
  await assertFails(setDoc(doc(user('alice'), 'messages/bad-gif'), {
    senderId: 'alice', senderRole: 'member', type: 'gif', text: 'GIF', imageUrl: 'javascript:alert(1)'
  }));
});

test('only the founder can assign memberships', async () => {
  const membership = {
    uid: 'alice', tier: 'gold',
    expiresAt: Timestamp.fromDate(new Date('2030-01-01T00:00:00Z'))
  };
  await assertSucceeds(setDoc(doc(founder(), 'memberships/alice'), membership));
  await assertFails(setDoc(doc(user('bob'), 'memberships/bob'), {
    ...membership, uid: 'bob'
  }));
});

test('founder can assign and remove custom member titles with an audit record', async () => {
  await seed('publicProfiles/alice', {
    name: 'Alice', bio: '', photoUrl: '', createdAt: Timestamp.fromDate(new Date('2026-01-01T00:00:00Z'))
  });

  // The founder check must match the case-insensitive check used by the app UI.
  await assertSucceeds(updateDoc(doc(founder('HUSINALZERJAOE@GMAIL.COM'), 'publicProfiles/alice'), {
    customTitle: 'نجم الملتقى',
    customTitleColor: 0xFF6554D9,
    customTitleEndColor: 0xFF13A89E,
    customTitleFont: 'default',
    customTitleGradient: true,
    customTitleGlow: true,
    customTitleIcon: '⭐',
    customTitleExpiresAt: null,
    customTitleUpdatedAt: serverTimestamp()
  }));

  await assertSucceeds(setDoc(doc(founder(), 'adminLogs/title-grant-1'), {
    actorId: 'founder-uid', targetId: 'alice', targetName: 'Alice',
    action: 'set_custom_title', createdAt: serverTimestamp()
  }));

  await assertSucceeds(updateDoc(doc(user('alice'), 'publicProfiles/alice'), {
    customTitle: 'لقبي بنفسي',
    customTitleColor: 0xFF6554D9,
    customTitleEndColor: 0xFF168E9B,
    customTitleFont: 'default',
    customTitleGradient: true,
    customTitleGlow: false,
    customTitleIcon: '⭐',
    customTitleExpiresAt: null,
    customTitleUpdatedAt: serverTimestamp()
  }));
  await assertFails(updateDoc(doc(user('bob'), 'publicProfiles/alice'), {
    customTitle: 'محاولة تعديل ملف غيري',
    customTitleUpdatedAt: serverTimestamp()
  }));
});

test('members may spend coins but cannot mint or increase their own balance', async () => {
  await seed('coinWallets/alice', {
    coins: 50, updatedAt: Timestamp.fromDate(new Date('2026-01-01T00:00:00Z')),
    grantedBy: 'founder-uid'
  });
  await assertSucceeds(updateDoc(doc(user('alice'), 'coinWallets/alice'), {
    coins: 20, updatedAt: serverTimestamp()
  }));
  await assertFails(updateDoc(doc(user('alice'), 'coinWallets/alice'), {
    coins: 500, updatedAt: serverTimestamp()
  }));
  await assertSucceeds(setDoc(doc(founder(), 'coinWallets/bob'), {
    coins: 100, updatedAt: serverTimestamp(), grantedBy: 'founder-uid'
  }));
});

test('regional room messages are available to signed-in members but room bans are enforced', async () => {
  const iraqMessage = {
    senderId: 'alice', senderRole: 'member', type: 'text', text: 'تحية لأهل العراق',
  };
  await assertSucceeds(setDoc(doc(user('alice'), 'regionalChats/iraq/messages/hello-1'), iraqMessage));
  await assertSucceeds(getDoc(doc(user('bob'), 'regionalChats/iraq/messages/hello-1')));

  await seed('regionalChats/syria/bans/mallory', {
    permanent: true, by: 'moderator', expiresAt: null,
  });
  await assertFails(getDoc(doc(user('mallory'), 'regionalChats/syria/messages/hidden-1')));
  await assertFails(setDoc(doc(user('mallory'), 'regionalChats/syria/messages/blocked-1'), {
    senderId: 'mallory', senderRole: 'member', type: 'text', text: 'لا أستطيع الإرسال',
  }));
});

test('users cannot read another member private cinema favourites', async () => {
  await seed('users/alice/cinemaFavorites/film-1', {
    title: 'Example film', year: '2026', addedAt: Timestamp.fromDate(new Date('2026-01-01T00:00:00Z'))
  });
  await assertSucceeds(getDoc(doc(user('alice'), 'users/alice/cinemaFavorites/film-1')));
  await assertFails(getDoc(doc(user('bob'), 'users/alice/cinemaFavorites/film-1')));
});


test('private friends quiz room supports code join, member chat, and blocks outsiders after start', async () => {
  const room = doc(user('alice'), 'gameRooms/123456');
  await assertSucceeds(setDoc(room, {
    game: 'football_quiz',
    hostId: 'alice',
    roomCode: '123456',
    members: ['alice'],
    memberNames: { alice: 'Alice' },
    status: 'waiting',
    round: 0,
    answers: {},
    scores: { alice: 0 },
    mode: '1v1',
  }));

  // A signed-in friend who has the room code can open the waiting room and join.
  await assertSucceeds(getDoc(doc(user('bob'), 'gameRooms/123456')));
  await assertSucceeds(updateDoc(doc(user('bob'), 'gameRooms/123456'), {
    members: ['alice', 'bob'],
    memberNames: { alice: 'Alice', bob: 'Bob' },
    scores: { alice: 0, bob: 0 },
    updatedAt: serverTimestamp(),
  }));

  await assertSucceeds(setDoc(doc(user('bob'), 'gameRooms/123456/chat/bob-1'), {
    uid: 'bob', name: 'Bob', text: 'جاهز نبدأ؟', createdAt: serverTimestamp(),
  }));
  await assertFails(setDoc(doc(user('mallory'), 'gameRooms/123456/chat/outside-1'), {
    uid: 'mallory', name: 'Mallory', text: 'رسالة من خارج الغرفة',
  }));

  await assertSucceeds(updateDoc(doc(user('alice'), 'gameRooms/123456'), {
    status: 'playing',
    round: 0,
    answers: {},
    scores: { alice: 0, bob: 0 },
    updatedAt: serverTimestamp(),
  }));
  await assertFails(getDoc(doc(user('mallory'), 'gameRooms/123456')));
});


test('style store purchase atomically spends coins and grants account inventory', async () => {
  await seed('coinWallets/alice', {
    coins: 300, updatedAt: Timestamp.fromDate(new Date('2026-01-01T00:00:00Z')),
    grantedBy: 'founder-uid'
  });
  const alice = user('alice');
  await runTransaction(alice, async (tx) => {
    tx.update(doc(alice, 'coinWallets/alice'), { coins: 120, updatedAt: serverTimestamp() });
    tx.set(doc(alice, 'users/alice/styleInventory/crown'), {
      itemId: 'crown', name: 'تاج القائد', category: 'ألقاب',
      price: 180, purchasedAt: serverTimestamp()
    });
  });
  await assertSucceeds(getDoc(doc(alice, 'users/alice/styleInventory/crown')));
  await assertFails(getDoc(doc(user('bob'), 'users/alice/styleInventory/crown')));
  await assertFails(setDoc(doc(user('alice'), 'users/alice/styleInventory/legend'), {
    itemId: 'legend', name: 'أسطورة الملتقى', category: 'ألقاب',
    price: 1, purchasedAt: serverTimestamp()
  }));
});

test('founder can buy cosmetics without a wallet and gift cosmetics to members', async () => {
  const founderDb = founder();
  const founderItem = doc(founderDb, 'users/founder-uid/styleInventory/legend');
  await assertSucceeds(setDoc(founderItem, {
    itemId: 'legend', name: 'أسطورة الملتقى', category: 'ألقاب',
    price: 350, purchasedAt: serverTimestamp(), grantedBy: 'founder-uid'
  }));

  const giftedItem = doc(founderDb, 'users/alice/styleInventory/crown');
  await assertSucceeds(setDoc(giftedItem, {
    itemId: 'crown', name: 'تاج القائد', category: 'ألقاب',
    price: 180, purchasedAt: serverTimestamp(), grantedBy: 'founder-uid'
  }));
  await assertSucceeds(getDoc(doc(user('alice'), 'users/alice/styleInventory/crown')));

  await assertFails(setDoc(doc(user('alice'), 'users/alice/styleInventory/legend'), {
    itemId: 'legend', name: 'أسطورة الملتقى', category: 'ألقاب',
    price: 350, purchasedAt: serverTimestamp(), grantedBy: 'alice'
  }));
});

test('founder can top up a member wallet while members cannot mint coins', async () => {
  await seed('coinWallets/alice', {
    coins: 25, updatedAt: Timestamp.fromDate(new Date('2026-01-01T00:00:00Z')),
    grantedBy: 'founder-uid'
  });
  await assertSucceeds(updateDoc(doc(founder(), 'coinWallets/alice'), {
    coins: 525, updatedAt: serverTimestamp(), grantedBy: 'founder-uid'
  }));
  await assertSucceeds(getDoc(doc(user('alice'), 'coinWallets/alice')));
  await assertFails(updateDoc(doc(user('alice'), 'coinWallets/alice'), {
    coins: 900, updatedAt: serverTimestamp()
  }));
});

test('friends 2D room can be found by its single roomCode field and joined by a second member', async () => {
  await seed('arcadeRooms/room-2d-1', {
    hostId: 'alice', gameId: 'arcade_friend_world',
    members: ['alice'], memberNames: { alice: 'Alice' },
    roomCode: '654321', status: 'waiting', visibility: 'private',
    state: { mode: 'cooperative_2d', players: {}, stars: [], score: 0, moves: 0, wave: 1, finished: false }
  });
  await assertSucceeds(getDoc(doc(user('bob'), 'arcadeRooms/room-2d-1')));
  await assertSucceeds(updateDoc(doc(user('bob'), 'arcadeRooms/room-2d-1'), {
    members: ['alice', 'bob'], 'memberNames.bob': 'Bob', updatedAt: serverTimestamp()
  }));
  await assertSucceeds(setDoc(doc(user('bob'), 'arcadeRooms/room-2d-1/chat/hello-1'), { uid: 'bob', name: 'Bob', text: 'هلا', createdAt: serverTimestamp() }));
  // Waiting rooms are readable to signed-in users for code lookup; once the host starts, outsiders are blocked.
  await assertSucceeds(updateDoc(doc(user('alice'), 'arcadeRooms/room-2d-1'), { status: 'playing', updatedAt: serverTimestamp() }));
  await assertFails(getDoc(doc(user('mallory'), 'arcadeRooms/room-2d-1')));
});


test('post voice comments require an owned HTTPS audio URL', async () => {
  const valid = {
    authorId: 'alice',
    authorName: 'Alice',
    text: '',
    mediaType: 'audio',
    audioUrl: 'https://media.example.test/posts/voice-note.m4a',
    createdAt: serverTimestamp(),
  };
  await assertSucceeds(setDoc(doc(user('alice'), 'posts/post-voice/comments/voice-1'), valid));
  await assertFails(setDoc(doc(user('alice'), 'posts/post-voice/comments/voice-2'), {
    ...valid, audioUrl: 'http://media.example.test/voice-note.m4a',
  }));
  await assertFails(setDoc(doc(user('bob'), 'posts/post-voice/comments/voice-3'), valid));
});


test('founder can gift coins to a legacy wallet without deleting unrelated metadata', async () => {
  await seed('coinWallets/alice', {
    coins: 40,
    updatedAt: Timestamp.fromDate(new Date('2026-01-01T00:00:00Z')),
    grantedBy: 'founder-uid',
    legacyNote: 'keep-this-field',
    lifetimeEarned: 900,
  });
  await assertSucceeds(updateDoc(doc(founder(), 'coinWallets/alice'), {
    coins: 540,
    updatedAt: serverTimestamp(),
    grantedBy: 'founder-uid',
  }));
  await assertSucceeds(getDoc(doc(user('alice'), 'coinWallets/alice')));
});


test('members can activate multiple store titles without replacing existing custom titles', async () => {
  await seed('publicProfiles/alice', {
    name: 'Alice', bio: '', photoUrl: '', customTitle: 'لقب قديم',
    createdAt: Timestamp.fromDate(new Date('2026-01-01T00:00:00Z'))
  });
  await assertSucceeds(updateDoc(doc(user('alice'), 'publicProfiles/alice'), {
    activeStoreTitleIds: ['crown', 'star', 'creator'],
    customTitleUpdatedAt: serverTimestamp()
  }));
  const saved = await getDoc(doc(user('alice'), 'publicProfiles/alice'));
  assert.deepEqual(saved.data().activeStoreTitleIds, ['crown', 'star', 'creator']);
  assert.equal(saved.data().customTitle, 'لقب قديم');
});
