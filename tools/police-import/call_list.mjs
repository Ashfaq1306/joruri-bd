// Writes numbers_to_call.md: every number the app still shows as
// "not yet verified", for someone to call and then mark verified on the
// admin website (Emergency numbers / Fire stations).
//   node call_list.mjs
import fs from 'node:fs';
import { numbers } from './emergency_numbers.mjs';

const fire = fs.readFileSync(new URL('../fire-import/report.txt', import.meta.url), 'utf8');
const pretty = (n) => (/^01\d{9}$/.test(n) ? `${n.slice(0, 5)}-${n.slice(5)}` : n);
const open = numbers.filter((n) => n.verification?.status !== 'verified');
const done = numbers.filter((n) => n.verification?.status === 'verified');

const lines = [
  '# Numbers still to confirm by phone',
  '',
  `Made by \`tools/police-import/call_list.mjs\` on ${new Date().toISOString().slice(0, 10)}. ` +
    `${done.length} of ${numbers.length} emergency and ambulance numbers are verified; the ${open.length} below had no current official source online.`,
  '',
  '**How:** call, ask "Is this the ambulance / emergency number of …?", then on the admin website (Emergency numbers → Edit) set Status to *Verified*, the date, and a note such as "Called 2026-11-25, answered by the emergency desk". A wrong or dead number: change it or hide the entry.',
  '',
  '| ✓ | Name | District | Number | Other numbers | Why not verified |',
  '| --- | --- | --- | --- | --- | --- |',
  ...open.map((n) =>
    `| ☐ | ${n.name.en} | ${n.districtId ?? 'national'} | ${pretty(n.number)} | ${(n.otherNumbers ?? []).map(pretty).join(', ')} | ${n.verification?.note ?? ''} |`),
  '',
  '## Fire stations (from `tools/fire-import/report.txt`)',
  '',
  'These stations show "Number being checked. Call 999 or 102 meanwhile." until an admin enters the confirmed number on the **Fire stations** page.',
  '',
  '```',
  fire.slice(fire.indexOf('Number left blank'), fire.indexOf('Repeated row')).trim(),
  '```',
  '',
];
fs.writeFileSync(new URL('./numbers_to_call.md', import.meta.url), lines.join('\n'));
console.log(`${open.length} numbers to call written to numbers_to_call.md`);
