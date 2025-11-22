const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');


admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();


(async () => {
const ref = db.collection('test_connections').doc('ping');
await ref.set({ ok: true, ts: new Date() });
const snap = await ref.get();
console.log('Firestore test read:', snap.data());
})();