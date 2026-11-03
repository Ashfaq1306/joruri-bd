/// A registered medicine brand and its DGDA-approved price.
///
/// Source: Directorate General of Drug Administration (DGDA) medicine price
/// list. The price is the maximum retail price a shop may charge.
class Medicine {
  Medicine({
    required this.brand,
    required this.generic,
    required this.strength,
    required this.form,
    required this.company,
    this.dar = '',
    this.packs = const [],
  })  : brandLower = brand.toLowerCase(),
        genericLower = generic.toLowerCase(),
        genericKey = '${_norm(generic)}|${_norm(strength)}|${formGroup(form)}';

  /// One row of assets/seed/medicines.json:
  /// `[brand, generic, strength, form, companyIndex, dar, [[pack, price], …]]`.
  factory Medicine.fromRow(List<dynamic> row, List<String> companies) {
    final ci = (row[4] as num).toInt();
    return Medicine(
      brand: row[0] as String,
      generic: row[1] as String,
      strength: row[2] as String,
      form: row[3] as String,
      company: ci >= 0 && ci < companies.length ? companies[ci] : '',
      dar: row[5] as String,
      packs: [
        for (final p in (row.length > 6 ? row[6] as List : const []))
          if (p is List && p.length >= 2 && p[1] is num) MedicinePack(p[0] as String, (p[1] as num).toDouble()),
      ],
    );
  }

  final String brand;
  final String generic;
  final String strength;

  /// Tablet, Capsule, Syrup, Injection …
  final String form;
  final String company;

  /// DGDA registration (DAR) number.
  final String dar;
  final List<MedicinePack> packs;

  /// Lowest unit price over all pack sizes, or null when DGDA lists none.
  double? get lowestPrice {
    double? low;
    for (final p in packs) {
      if (low == null || p.priceBdt < low) low = p.priceBdt;
    }
    return low;
  }

  /// "paracetamol|500 mg|tablet": what makes two brands the same medicine.
  final String genericKey;
  final String brandLower;
  final String genericLower;
}

/// One pack size and its price per unit (per tablet, bottle, vial …).
class MedicinePack {
  const MedicinePack(this.pack, this.priceBdt);

  /// e.g. "10 x 10 in Blister Pack", "100 ml in Bottle".
  final String pack;
  final double priceBdt;
}

String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

/// Forms that are interchangeable for comparing prices ("Tablet" and
/// "Film Coated Tablet" yes; "Tablet" and "Xr Tablet" no).
String formGroup(String form) {
  final f = _norm(form);
  if (f == 'tablet' || f == 'film coated tablet') return 'tablet';
  if (f == 'capsule') return 'capsule';
  if (f == 'syrup' || f == 'oral solution' || f == 'suspension' || f == 'oral suspension') return 'liquid';
  return f;
}

/// Brands matching [query], best match first: brand starts with the query,
/// then brand contains it, then the generic name contains it.
List<Medicine> searchMedicines(List<Medicine> all, String query, {int limit = 200}) {
  final q = _norm(query);
  if (q.isEmpty) return const [];
  final starts = <Medicine>[], brandHas = <Medicine>[], genericHas = <Medicine>[];
  for (final m in all) {
    if (m.brandLower.startsWith(q)) {
      starts.add(m);
    } else if (m.brandLower.contains(q)) {
      brandHas.add(m);
    } else if (m.genericLower.contains(q)) {
      genericHas.add(m);
    }
  }
  int byName(Medicine a, Medicine b) {
    final c = a.brand.length.compareTo(b.brand.length);
    return c != 0 ? c : a.brand.compareTo(b.brand);
  }

  starts.sort(byName);
  brandHas.sort(byName);
  genericHas.sort(_byPrice);
  return [...starts, ...brandHas, ...genericHas].take(limit).toList(growable: false);
}

/// Other brands of the same medicine (same generic, strength and form), cheapest first.
/// Brands without a price come last.
List<Medicine> sameMedicine(List<Medicine> all, Medicine m) {
  final key = m.genericKey;
  return all.where((x) => x.genericKey == key).toList()..sort(_byPrice);
}

int _byPrice(Medicine a, Medicine b) {
  final pa = a.lowestPrice, pb = b.lowestPrice;
  if (pa == null && pb == null) return a.brand.compareTo(b.brand);
  if (pa == null) return 1;
  if (pb == null) return -1;
  final c = pa.compareTo(pb);
  return c != 0 ? c : a.brand.compareTo(b.brand);
}
