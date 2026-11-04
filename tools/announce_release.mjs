// Tells every phone about the newest GitHub release (meta/app in Firestore),
// the same as "Use latest release" + Save on the admin panel's App & updates
// page. The release scripts run it automatically: for 1.2.0 this manual step
// was forgotten and phones were never told about the update.
//
//   node tools/announce_release.mjs            (needs `firebase login` as an owner)
import { getDoc, commit } from './lib/firestore.mjs';

const REPO = 'Ashfaq1306/joruri-bd';
const DL = `https://github.com/${REPO}/releases/latest/download`;
const r = await fetch(`https://api.github.com/repos/${REPO}/releases/latest`, { headers: { accept: 'application/vnd.github+json' } });
if (!r.ok) throw new Error(`GitHub: ${r.status} (is the repository public and the release published?)`);
const rel = await r.json();
const m = /<!-- joruri (\{.*\}) -->/.exec(rel.body || '');
const info = m ? JSON.parse(m[1]) : {};
const code = info.versionCode || Number((/build(\d+)$/.exec(rel.tag_name) || [])[1]) || 0;
if (!code) throw new Error(`No build number in release ${rel.tag_name}`);
for (const a of ['joruri-bd.apk', 'joruri-bd-arm32.apk']) {
  if (!(rel.assets || []).some((x) => x.name === a)) throw new Error(`Release ${rel.tag_name} has no ${a}`);
}
const current = (await getDoc('meta/app')) || {};
if ((current.latestVersionCode || 0) > code) throw new Error(`Phones already know a newer build (${current.latestVersionCode})`);
const update = {
  latestVersionName: info.versionName || rel.tag_name, latestVersionCode: code,
  apkUrl: `${DL}/joruri-bd.apk`, apkUrlArm32: `${DL}/joruri-bd-arm32.apk`,
  notes: { en: info.notes?.en || '', bn: info.notes?.bn || '' }, updatedAt: new Date().toISOString(),
};
await commit([{ merge: ['meta/app', update] }]);
await commit([{ set: [`audit/release-${code}-${Date.now()}`, { action: 'edit', collection: 'meta', docId: 'app', summary: `App ${update.latestVersionName} (${code}) announced by release script`, at: update.updatedAt, by: 'release script' }] }]);
console.log(`Phones are now told: ${update.latestVersionName} (build ${code}) → ${update.apkUrl}`);
