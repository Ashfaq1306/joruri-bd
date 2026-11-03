// Downloads the DGHS Facility Registry rows for every hospital-type facility.
import fs from 'node:fs';
const UA = 'Mozilla/5.0 (JoruriBD emergency app data import; contact ashfaqur87654@gmail.com)';
// facility_type_id → kept
const TYPES = {
  2: 'Postgraduate Institute & Hospital', 5: 'Medical College Hospital', 7: 'Dental College Hospital',
  28: 'District/General Hospital', 94: 'General Hospital', 24: '50-bed Hospital', 25: '31-bed Hospital',
  26: '20-bed Hospital', 27: '10-bed Hospital', 73: '25-bed Hospital', 74: '30-bed Hospital',
  19: 'Specialized Hospital', 20: 'Special Purpose Hospital', 21: 'Specialized Health Center',
  33: 'Infectious Disease Hospital', 34: 'Chest Disease Hospital', 35: 'Leprosy Hospital', 36: 'Trauma Center',
  41: 'City Corporation / Municipality Hospital', 31: 'Maternal & Child Welfare Centre', 97: 'Combined Military Hospital',
  61: 'Other Hospital', 9: 'Hospital of Alternative Medicine', 29: 'Upazila Health Complex',
  43: 'Private Hospital / Clinic', 44: 'NGO Hospital/Clinic', 70: 'Blood Bank',
};
const strip = (s) => String(s ?? '').replace(/<[^>]+>/g, '').trim();
const out = [];
for (const t of Object.keys(TYPES)) {
  for (let start = 0; ; start += 500) {
    const url = `https://hris.mohfw.gov.bd/public/facility-registry/facilities/datatable/json?draw=1&start=${start}&length=500&facility_type_id[]=${t}`;
    let j;
    for (let attempt = 1; ; attempt++) {
      try {
        const r = await fetch(url, { headers: { 'user-agent': UA, 'x-requested-with': 'XMLHttpRequest' } });
        j = await r.json(); break;
      } catch (e) { if (attempt > 4) throw e; await new Promise((ok) => setTimeout(ok, 3000 * attempt)); }
    }
    for (const r of j.data) out.push({ ...r, id: strip(r.id), name: strip(r.name) });
    process.stdout.write(`type ${t}: ${Math.min(start + 500, j.recordsFiltered)}/${j.recordsFiltered}\n`);
    if (start + 500 >= j.recordsFiltered) break;
    await new Promise((ok) => setTimeout(ok, 700));
  }
}
fs.writeFileSync('dghs_list.json', JSON.stringify(out));
console.log('rows', out.length, 'unique', new Set(out.map((r) => r.id)).size);
