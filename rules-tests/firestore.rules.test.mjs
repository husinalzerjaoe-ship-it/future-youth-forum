import test, { before, after, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, serverTimestamp, Timestamp
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
function founder() {
  return env.authenticatedContext('founder-uid', { email: 'husinalzerjaoe@gmail.com' }).firestore();
}
async function seed(path, data) {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), path), data);
  });
}

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

test('users cannot read another member private cinema favourites', async () => {
  await seed('users/alice/cinemaFavorites/film-1', {
    title: 'Example film', year: '2026', addedAt: Timestamp.fromDate(new Date('2026-01-01T00:00:00Z'))
  });
  await assertSucceeds(getDoc(doc(user('alice'), 'users/alice/cinemaFavorites/film-1')));
  await assertFails(getDoc(doc(user('bob'), 'users/alice/cinemaFavorites/film-1')));
});
