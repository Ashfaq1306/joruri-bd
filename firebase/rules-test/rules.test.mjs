import fs from 'node:fs';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, deleteDoc, collection, getDocs, query, where, limit, updateDoc } from 'firebase/firestore';

const env = await initializeTestEnvironment({
  projectId: 'demo-joruri',
  firestore: { rules: fs.readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'), host: '127.0.0.1', port: 8191 },
});
await env.withSecurityRulesDisabled(async (c) => {
  const db = c.firestore();
  await setDoc(doc(db, 'admins/owner@gmail.com'), { role: 'owner', email: 'owner@gmail.com' });
  await setDoc(doc(db, 'admins/editor@gmail.com'), { role: 'editor', email: 'editor@gmail.com' });
  await setDoc(doc(db, 'meta/content'), { version: 1 });
  await setDoc(doc(db, 'meta/app'), { latestVersionCode: 10 });
  await setDoc(doc(db, 'emergency_numbers/bd-999'), { number: '999', published: true });
  await setDoc(doc(db, 'announcements/a1'), { title: { en: 'Hi' }, published: true });
  await setDoc(doc(db, 'announcements/a2'), { title: { en: 'Draft' }, published: false });
  await setDoc(doc(db, 'donors/d1'), { name: 'X', shareConsent: true, hidden: false, bloodGroup: 'A+' });
});

const tok = (email, verified = true) => ({ email, email_verified: verified });
const owner = env.authenticatedContext('uidOwner', tok('Owner@gmail.com')).firestore();
const editor = env.authenticatedContext('uidEditor', tok('editor@gmail.com')).firestore();
const stranger = env.authenticatedContext('uidX', tok('x@gmail.com')).firestore();
const unverified = env.authenticatedContext('uidU', tok('owner@gmail.com', false)).firestore();
const anon = env.unauthenticatedContext().firestore();

const results = [];
async function t(name, p) { try { await p; results.push(['PASS', name]); } catch (e) { results.push(['FAIL', name, e.message]); } }

// public phones
await t('anon reads meta/app', assertSucceeds(getDoc(doc(anon, 'meta/app'))));
await t('anon reads published announcements', assertSucceeds(getDocs(query(collection(anon, 'announcements'), where('published', '==', true)))));
await t('anon cannot list all announcements', assertFails(getDocs(collection(anon, 'announcements'))));
await t('anon reads snapshots', assertSucceeds(getDoc(doc(anon, 'snapshots/hospitals-0'))));
await t('anon cannot write snapshots', assertFails(setDoc(doc(anon, 'snapshots/hospitals-0'), { json: '[]' })));
await t('editor writes snapshots', assertSucceeds(setDoc(doc(editor, 'snapshots/hospitals-0'), { json: '[]' })));
await t('anon cannot write content', assertFails(setDoc(doc(anon, 'emergency_numbers/x'), { number: '1', published: true })));
await t('anon reads published police stations', assertSucceeds(getDocs(query(collection(anon, 'police_stations'), where('published', '==', true)))));
await t('anon cannot change a police station', assertFails(setDoc(doc(anon, 'police_stations/ps1'), { name: 'X', phone: '+8801700000000', published: true })));
await t('stranger cannot change a police station', assertFails(setDoc(doc(stranger, 'police_stations/ps1'), { name: 'X', phone: '+8801700000000', published: true })));
await t('editor writes a police station', assertSucceeds(setDoc(doc(editor, 'police_stations/ps1'), { name: 'Ramna', phone: '+8801320039492', published: true })));
await t('anon reads published fire stations', assertSucceeds(getDocs(query(collection(anon, 'fire_stations'), where('published', '==', true)))));
await t('anon cannot change a fire station', assertFails(setDoc(doc(anon, 'fire_stations/fs1'), { name: 'X', phone: '+8801700000000', published: true })));
await t('stranger cannot change a fire station', assertFails(setDoc(doc(stranger, 'fire_stations/fs1'), { name: 'X', phone: '+8801700000000', published: true })));
await t('editor writes a fire station', assertSucceeds(setDoc(doc(editor, 'fire_stations/fs1'), { name: 'Fatullah Fire Station', phone: '+8801901020838', published: true })));
await t('anon cannot list donors', assertFails(getDocs(query(collection(anon, 'donors'), where('shareConsent', '==', true), where('hidden', '==', false), limit(10)))));
// admin checks
await t('owner (mixed-case email) reads own admin entry', assertSucceeds(getDoc(doc(owner, 'admins/owner@gmail.com'))));
await t('stranger can check own (missing) admin entry', assertSucceeds(getDoc(doc(stranger, 'admins/x@gmail.com'))));
await t('stranger cannot read others admin entry', assertFails(getDoc(doc(stranger, 'admins/owner@gmail.com'))));
await t('stranger cannot write content', assertFails(setDoc(doc(stranger, 'emergency_numbers/x'), { number: '1' })));
await t('stranger cannot make self admin', assertFails(setDoc(doc(stranger, 'admins/x@gmail.com'), { role: 'owner', email: 'x@gmail.com' })));
await t('unverified email is not admin', assertFails(setDoc(doc(unverified, 'meta/content'), { version: 2 })));
await t('editor writes content', assertSucceeds(setDoc(doc(editor, 'hospitals/h1'), { name: 'H', published: true })));
await t('editor writes announcement', assertSucceeds(setDoc(doc(editor, 'announcements/a3'), { title: { en: 'x' }, published: true })));
await t('editor bumps meta/content', assertSucceeds(setDoc(doc(editor, 'meta/content'), { version: 2 })));
await t('editor lists admins', assertSucceeds(getDocs(collection(editor, 'admins'))));
await t('editor cannot add admins', assertFails(setDoc(doc(editor, 'admins/new@gmail.com'), { role: 'editor', email: 'new@gmail.com' })));
await t('owner adds admin', assertSucceeds(setDoc(doc(owner, 'admins/new@gmail.com'), { role: 'editor', email: 'new@gmail.com', addedBy: 'owner@gmail.com', addedAt: 'x' })));
await t('owner cannot add bad role', assertFails(setDoc(doc(owner, 'admins/bad@gmail.com'), { role: 'god', email: 'bad@gmail.com' })));
await t('owner cannot add upper-case id', assertFails(setDoc(doc(owner, 'admins/Bad@gmail.com'), { role: 'editor', email: 'x' })));
await t('owner removes admin', assertSucceeds(deleteDoc(doc(owner, 'admins/new@gmail.com'))));
await t('owner cannot remove self', assertFails(deleteDoc(doc(owner, 'admins/owner@gmail.com'))));
await t('editor writes audit', assertSucceeds(setDoc(doc(editor, 'audit/e1'), { action: 'edit', collection: 'x', docId: '', summary: '', at: 'now', by: 'editor@gmail.com' })));
await t('editor cannot change audit', assertFails(updateDoc(doc(editor, 'audit/e1'), { summary: 'changed' })));
// donors
await t('signed-in user lists consented donors', assertSucceeds(getDocs(query(collection(stranger, 'donors'), where('shareConsent', '==', true), where('hidden', '==', false), where('bloodGroup', 'in', ['A+']), limit(300)))));
await t('user creates own listing', assertSucceeds(setDoc(doc(stranger, 'donors/uidX'), { id: 'uidX', uid: 'uidX', source: 'app', name: 'Me', bloodGroup: 'O+', phone: '+8801712345678', districtId: 'dhaka', area: '', available: true, shareConsent: true, hidden: false, verified: false })));
await t('user cannot verify self', assertFails(updateDoc(doc(stranger, 'donors/uidX'), { verified: true })));
await t('editor hides a donor', assertSucceeds(updateDoc(doc(editor, 'donors/uidX'), { hidden: true })));

await env.cleanup();
for (const r of results) console.log(r.join('  '));
console.log(results.filter((r) => r[0] === 'FAIL').length ? 'SOME FAILED' : `ALL ${results.length} PASSED`);
process.exit(0);
