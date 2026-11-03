const LABELS = ['Village/Street', 'House No.', 'Mailing Address', 'Land Phone Number 1', 'Land Phone Number 2', 'Land Phone Number 3',
  'Mobile Phone Number 1', 'Mobile Phone Number 2', 'Official Contact No', 'Website URL', 'Latitude', 'Longitude',
  'Establishment Year', 'Latest Bed Count', 'Latest Bed Count (Paid)', 'Latest Bed Count (Free)', 'Facility Head Post', 'Ownership'];
const ALL = ['Organaization Name', 'Division', 'Organaization Name BN', 'District', 'Agency', 'City Corporation', 'Establishment Year',
  'Upazila', 'Village/Street', 'Paurasava', 'House No.', 'Union', 'Latitude', 'Ward', 'Longitude', 'Contact Information', 'Mailing Address',
  'Land Phone Number 1', 'Fax Number 1', 'Land Phone Number 2', 'Fax Number 2', 'Land Phone Number 3', 'Fax Number 3',
  'Mobile Phone Number 1', 'Website URL', 'Mobile Phone Number 2', 'Facebook', 'Official Contact No', 'Google+', 'Email Address 1',
  'Twitter', 'Email Address 2', 'Youtube', 'Email Address 3', 'Administrative Information', 'Private', 'Facility Health Care Level',
  'Ministry', 'Facility Level', 'Facility Function', 'Ownership', 'Location Type', 'Facility Head', 'Provider', 'Facility Type',
  'Facility Head Post', 'Facility Infrastructure', 'Physical Structure', 'Latest Bed Count (Paid)', 'Biometric Attendance System',
  'Latest Bed Count (Free)', 'Latest Bed Count', 'Latest Single Cabin Count', 'Latest Bed Count (Male)', 'Latest Bed Count (Female)', 'Latest Double Cabin Count', 'Latest Cabin Count', 'Source of Electricity'];

export function parse(html) {
  const text = html.replace(/<script[\s\S]*?<\/script>/g, '').replace(/<style[\s\S]*?<\/style>/g, '').replace(/<[^>]+>/g, ' ')
    .replace(/&amp;/g, '&').replace(/&#039;/g, "'").replace(/&quot;/g, '"').replace(/\s+/g, ' ');
  const start = text.indexOf('Basic Information');
  const body = text.slice(start, text.indexOf('Source of Electricity', start));
  // Split the "Label value Label value" text on the known labels (longest first).
  const labels = [...ALL].sort((a, b) => b.length - a.length);
  const out = {};
  let rest = body;
  const positions = [];
  for (const l of labels) {
    let from = 0;
    for (;;) {
      const i = rest.indexOf(' ' + l + ' ', from);
      if (i < 0) break;
      if (!positions.some((p) => i >= p.i && i < p.i + p.l.length + 1)) positions.push({ i, l });
      from = i + 1;
    }
  }
  positions.sort((a, b) => a.i - b.i);
  // drop labels that sit inside a longer label
  const clean = positions.filter((p, k) => !positions.some((q) => q !== p && q.i <= p.i && p.i + p.l.length <= q.i + q.l.length && q.l.length > p.l.length));
  for (let k = 0; k < clean.length; k++) {
    const p = clean[k]; const end = k + 1 < clean.length ? clean[k + 1].i : rest.length;
    const v = rest.slice(p.i + p.l.length + 1, end).trim();
    if (LABELS.includes(p.l) && v && !(p.l in out)) out[p.l] = v;
  }
  return out;
}

