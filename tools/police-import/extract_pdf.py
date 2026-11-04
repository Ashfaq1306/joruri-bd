import fitz, json, re, sys
d = fitz.open(sys.argv[1]); out = []
for pno, p in enumerate(d):
    mid = p.rect.width / 2
    words = p.get_text('words')
    for col in (0, 1):
        ws = [w for w in words if (w[0] < mid) == (col == 0)]
        rows = {}
        for w in ws:
            key = round((w[1] + w[3]) / 2 / 3)  # ~3pt buckets
            rows.setdefault(key, []).append(w)
        for key in sorted(rows):
            r = sorted(rows[key], key=lambda w: w[0])
            text = ' '.join(w[4] for w in r)
            m = re.search(r'(01\d{3})-?(\d{6})\s*$', text)
            if m:
                out.append({'page': pno + 1, 'col': col, 'name': text[:m.start()].strip(), 'phone': m.group(1) + m.group(2)})
            else:
                out.append({'page': pno + 1, 'col': col, 'header': text})
json.dump(out, open(sys.argv[2], 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
print(sum(1 for o in out if 'phone' in o), 'stations')
for o in out:
    if 'header' in o: print('H', o['page'], o['col'], o['header'])
