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
  window.JoruriBackend = {
    configured: true,
    onAuth: (cb) => onAuthStateChanged(auth, cb),
    signIn: (email, password) => signInWithEmailAndPassword(auth, email, password),
    // Recommended for admins: the Google account's own 2-Step Verification
    // protects the website. Signing in grants nothing by itself; only UIDs
    // listed in /admins (created by hand in the console) are admins.
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
    isAdmin: async (uid) => (await getDoc(doc(db, 'admins', uid))).exists(),
    list: async (col) => (await getDocs(collection(db, col))).docs.map((d) => ({ ...d.data(), id: d.id })),
    newId: (col) => doc(collection(db, col)).id,
    set: (col, id, data) => setDoc(doc(db, col, id), data),
    del: (col, id) => deleteDoc(doc(db, col, id)),
    batchSet: async (col, items) => {
      for (let i = 0; i < items.length; i += 400) {
        const batch = writeBatch(db);
        for (const item of items.slice(i, i + 400)) batch.set(doc(db, col, item.id), item);
        await batch.commit();
      }
    },
    getMeta: async () => (await getDoc(doc(db, 'meta', 'content'))).data() || {},
    bumpContent: () => setDoc(doc(db, 'meta', 'content'), { version: increment(1), updatedAt: new Date().toISOString() }, { merge: true }),
    audit: (entry) => addDoc(collection(db, 'audit'), { ...entry, at: new Date().toISOString(), by: auth.currentUser?.email || '' }),
    listAudit: async () => (await getDocs(query(collection(db, 'audit'), orderBy('at', 'desc'), limit(150)))).docs.map((d) => d.data()),
  };
} else {
  window.JoruriBackend = { configured: false };
}
window.dispatchEvent(new Event('backend-ready'));
