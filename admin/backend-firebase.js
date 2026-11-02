// Connects the admin website to Firebase (sign-in + database).
// app.js only talks to window.JoruriBackend, never to Firebase directly.
import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js';
import {
  getAuth, onAuthStateChanged, signInWithEmailAndPassword, signOut,
  GoogleAuthProvider, signInWithPopup, signInWithRedirect, getRedirectResult,
} from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-auth.js';
import {
  getFirestore, collection, doc, getDoc, getDocs, setDoc, deleteDoc, addDoc, writeBatch,
  increment, query, orderBy, limit,
} from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js';
import { firebaseConfig } from './firebase-config.js';

const configured = !String(firebaseConfig.apiKey || '').startsWith('PASTE');

if (configured) {
  const app = initializeApp(firebaseConfig);
  const auth = getAuth(app);
  const db = getFirestore(app);
  // Finishes a Google sign-in that had to use a full-page redirect.
  getRedirectResult(auth).catch((e) => console.error('Google redirect sign-in failed', e));

  // Reads admins/{id}; null when missing. The rules let anyone signed in
  // read only their own entry, so this answers "am I an admin?".
  const adminEntry = async (id) => {
    const snap = await getDoc(doc(db, 'admins', id));
    return snap.exists() ? { id, ...snap.data() } : null;
  };

  window.JoruriBackend = {
    configured: true,
    onAuth: (cb) => onAuthStateChanged(auth, cb),
    signIn: (email, password) => signInWithEmailAndPassword(auth, email, password),
    // Signing in grants nothing by itself; only accounts listed in /admins
    // (by Google e-mail, added by an owner on this website) are admins.
    signInWithGoogle: async () => {
      const provider = new GoogleAuthProvider();
      provider.setCustomParameters({ prompt: 'select_account' });
      try {
        await signInWithPopup(auth, provider);
      } catch (e) {
        if (e && e.code === 'auth/popup-blocked') return signInWithRedirect(auth, provider);
        throw e;
      }
    },
    signOut: () => signOut(auth),
    /** 'owner' | 'editor' | null */
    role: async (user) => {
      const byEmail = user.email && user.emailVerified ? await adminEntry(user.email.toLowerCase()) : null;
      const entry = byEmail || await adminEntry(user.uid);
      return entry ? (entry.role === 'owner' ? 'owner' : 'editor') : null;
    },
    list: async (col) => (await getDocs(collection(db, col))).docs.map((d) => ({ ...d.data(), id: d.id })),
    get: async (col, id) => { const s = await getDoc(doc(db, col, id)); return s.exists() ? { ...s.data(), id: s.id } : null; },
    newId: (col) => doc(collection(db, col)).id,
    set: (col, id, data) => setDoc(doc(db, col, id), data),
    merge: (col, id, data) => setDoc(doc(db, col, id), data, { merge: true }),
    del: (col, id) => deleteDoc(doc(db, col, id)),
    batchSet: async (col, items) => {
      for (let i = 0; i < items.length; i += 400) {
        const batch = writeBatch(db);
        for (const item of items.slice(i, i + 400)) batch.set(doc(db, col, item.id), item);
        await batch.commit();
      }
    },
    getMeta: async (id = 'content') => (await getDoc(doc(db, 'meta', id))).data() || {},
    bumpContent: () => setDoc(doc(db, 'meta', 'content'), { version: increment(1), updatedAt: new Date().toISOString() }, { merge: true }),
    audit: (entry) => addDoc(collection(db, 'audit'), { ...entry, at: new Date().toISOString(), by: auth.currentUser?.email || '' }),
    listAudit: async () => (await getDocs(query(collection(db, 'audit'), orderBy('at', 'desc'), limit(200)))).docs.map((d) => d.data()),
  };
} else {
  window.JoruriBackend = { configured: false };
}
window.dispatchEvent(new Event('backend-ready'));
