// One-time setup (idempotent): lets the GitHub Actions alert watcher of
// Ashfaq1306/joruri-bd sign in to the joruri-bd Google Cloud project
// WITHOUT any stored key (Workload Identity Federation).
//
//  - service account alerts-watcher@joruri-bd.iam.gserviceaccount.com with
//    only two roles: Firestore read/write (roles/datastore.user) and FCM send
//    (roles/firebasecloudmessaging.admin)
//  - identity pool "github" + provider "joruri-bd" that trusts GitHub's OIDC
//    tokens only for the repository Ashfaq1306/joruri-bd
//
// Run from the repo root as a project owner signed in to the Firebase CLI:
//   node tools/alerts/setup_github_access.mjs
// Then the workflow needs no secrets: the values printed at the end are in
// .github/workflows/alerts.yml.
import fs from 'node:fs'; import os from 'node:os'; import path from 'node:path';

const PROJECT = 'joruri-bd';
const REPO = 'Ashfaq1306/joruri-bd';
const SA_ID = 'alerts-watcher';
const SA = `${SA_ID}@${PROJECT}.iam.gserviceaccount.com`;
const POOL = 'github', PROVIDER = 'joruri-bd';
const ROLES = ['roles/datastore.user', 'roles/firebasecloudmessaging.admin'];

const CLI = { id: '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com', secret: 'j9iVZfS8kkCEFUPaAeJV0sAi' };
const cfg = JSON.parse(fs.readFileSync(path.join(os.homedir(), '.config/configstore/firebase-tools.json'), 'utf8'));
const tok = (await (await fetch('https://oauth2.googleapis.com/token', { method: 'POST',
  body: new URLSearchParams({ grant_type: 'refresh_token', refresh_token: cfg.tokens.refresh_token, client_id: CLI.id, client_secret: CLI.secret }) })).json()).access_token;
if (!tok) throw new Error('run `firebase login` first');

async function api(method, url, body, okCodes = [200]) {
  const r = await fetch(url, { method, headers: { authorization: `Bearer ${tok}`, 'content-type': 'application/json', 'x-goog-user-project': PROJECT },
    body: body ? JSON.stringify(body) : undefined });
  const text = await r.text();
  if (!okCodes.includes(r.status)) throw new Error(`${method} ${url} → ${r.status} ${text.slice(0, 400)}`);
  return { status: r.status, json: text ? JSON.parse(text) : {} };
}
const wait = (ms) => new Promise((ok) => setTimeout(ok, ms));
async function operation(op) {
  for (let i = 0; op && op.name && !op.done && i < 60; i++) {
    await wait(3000);
    const base = op.name.startsWith('operations/') ? 'https://serviceusage.googleapis.com/v1/' : 'https://iam.googleapis.com/v1/';
    op = (await api('GET', base + op.name)).json;
  }
  return op;
}

const number = (await api('GET', `https://cloudresourcemanager.googleapis.com/v1/projects/${PROJECT}`)).json.projectNumber;
console.log('project number', number);

console.log('enabling APIs …');
await operation((await api('POST', `https://serviceusage.googleapis.com/v1/projects/${number}/services:batchEnable`, {
  serviceIds: ['iam.googleapis.com', 'iamcredentials.googleapis.com', 'sts.googleapis.com', 'fcm.googleapis.com', 'firestore.googleapis.com'],
})).json);

console.log('service account …');
const sa = await api('POST', `https://iam.googleapis.com/v1/projects/${PROJECT}/serviceAccounts`,
  { accountId: SA_ID, serviceAccount: { displayName: 'Joruri BD alert watcher (GitHub Actions)', description: `Used only by ${REPO} .github/workflows/alerts.yml` } }, [200, 409]);
console.log(sa.status === 409 ? '  exists' : '  created');
await wait(5000);

console.log('project roles …');
for (let attempt = 1; ; attempt++) {
  const policy = (await api('POST', `https://cloudresourcemanager.googleapis.com/v1/projects/${PROJECT}:getIamPolicy`, { options: { requestedPolicyVersion: 3 } })).json;
  let changed = false;
  for (const role of ROLES) {
    const member = `serviceAccount:${SA}`;
    let b = policy.bindings.find((x) => x.role === role && !x.condition);
    if (!b) { b = { role, members: [] }; policy.bindings.push(b); }
    if (!b.members.includes(member)) { b.members.push(member); changed = true; }
  }
  if (!changed) { console.log('  already granted'); break; }
  const r = await api('POST', `https://cloudresourcemanager.googleapis.com/v1/projects/${PROJECT}:setIamPolicy`, { policy }, [200, 409]);
  if (r.status === 200) { console.log('  granted', ROLES.join(', ')); break; }
  if (attempt > 4) throw new Error('IAM policy kept changing');
}

console.log('identity pool …');
const poolUrl = `https://iam.googleapis.com/v1/projects/${number}/locations/global/workloadIdentityPools`;
const pool = await api('POST', `${poolUrl}?workloadIdentityPoolId=${POOL}`, { displayName: 'GitHub Actions', description: `GitHub Actions of ${REPO}` }, [200, 409]);
await operation(pool.status === 200 ? pool.json : null);
console.log(pool.status === 409 ? '  exists' : '  created');

console.log('provider …');
const provider = {
  displayName: 'joruri-bd repository',
  attributeMapping: { 'google.subject': 'assertion.sub', 'attribute.repository': 'assertion.repository', 'attribute.ref': 'assertion.ref' },
  attributeCondition: `assertion.repository == '${REPO}'`,
  oidc: { issuerUri: 'https://token.actions.githubusercontent.com' },
};
const prov = await api('POST', `${poolUrl}/${POOL}/providers?workloadIdentityPoolProviderId=${PROVIDER}`, provider, [200, 409]);
await operation(prov.status === 200 ? prov.json : null);
console.log(prov.status === 409 ? '  exists' : '  created');

console.log('let the repository use the service account …');
const principal = `principalSet://iam.googleapis.com/projects/${number}/locations/global/workloadIdentityPools/${POOL}/attribute.repository/${REPO}`;
const saPolicy = (await api('POST', `https://iam.googleapis.com/v1/projects/${PROJECT}/serviceAccounts/${SA}:getIamPolicy`)).json;
saPolicy.bindings ??= [];
let wiu = saPolicy.bindings.find((b) => b.role === 'roles/iam.workloadIdentityUser');
if (!wiu) { wiu = { role: 'roles/iam.workloadIdentityUser', members: [] }; saPolicy.bindings.push(wiu); }
if (!wiu.members.includes(principal)) {
  wiu.members.push(principal);
  await api('POST', `https://iam.googleapis.com/v1/projects/${PROJECT}/serviceAccounts/${SA}:setIamPolicy`, { policy: saPolicy });
  console.log('  granted');
} else console.log('  already granted');

console.log('\nworkload_identity_provider: projects/%s/locations/global/workloadIdentityPools/%s/providers/%s', number, POOL, PROVIDER);
console.log('service_account: %s', SA);
