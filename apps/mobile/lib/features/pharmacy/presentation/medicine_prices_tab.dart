import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/core/utils/digits.dart';
import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/core/widgets/place_widgets.dart';
import 'package:joruri_bd/features/directory/data/places_repository.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// Search every DGDA-registered medicine by brand or generic name and see
/// its approved maximum retail price.
class MedicinePricesTab extends ConsumerStatefulWidget {
  const MedicinePricesTab({super.key});

  @override
  ConsumerState<MedicinePricesTab> createState() => _MedicinePricesTabState();
}

class _MedicinePricesTabState extends ConsumerState<MedicinePricesTab> with AutomaticKeepAliveClientMixin {
  final _query = TextEditingController();
  String _text = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = context.s;
    final theme = Theme.of(context);
    final medicines = ref.watch(medicinesProvider);

    final search = Padding(
      padding: const EdgeInsets.fromLTRB(JSpace.md, JSpace.md, JSpace.md, JSpace.sm),
      child: TextField(
        controller: _query,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          labelText: s.searchMedicine,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() {
                    _query.clear();
                    _text = '';
                  }),
                ),
        ),
        onChanged: (v) => setState(() => _text = v),
      ),
    );

    return medicines.when(
      loading: () => ListView(children: [search, const Center(child: CircularProgressIndicator())]),
      error: (_, __) => ListView(children: [search, Center(child: Text(s.genericError))]),
      data: (data) {
        final found = searchMedicines(data.items, _text);
        final top = <Widget>[
          search,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: JSpace.md),
            child: _text.trim().isEmpty
                ? Text(s.medicineSearchHint, style: theme.textTheme.bodyLarge)
                : Text(
                    found.isEmpty ? s.noMedicineFound : localizedDigits(s.medicinesFound(found.length), s.languageCode),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
          ),
          const SizedBox(height: JSpace.sm),
        ];
        final note = Padding(
          padding: const EdgeInsets.all(JSpace.md),
          child: Text(localizedDigits(s.medicinePriceNote(data.downloadedOn), s.languageCode),
              style: theme.textTheme.bodySmall),
        );
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: JSpace.xl),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: top.length + found.length + 1,
          itemBuilder: (context, i) {
            if (i < top.length) return top[i];
            i -= top.length;
            if (i == found.length) return note;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: JSpace.md),
              child: MedicineCard(
                medicine: found[i],
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => MedicineDetailScreen(medicine: found[i], all: data.items, downloadedOn: data.downloadedOn),
                )),
              ),
            );
          },
        );
      },
    );
  }
}

String formatTaka(double v) {
  final s = v.toStringAsFixed(2);
  return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
}

class MedicineCard extends StatelessWidget {
  const MedicineCard({super.key, required this.medicine, this.onTap, this.highlight = false});

  final Medicine medicine;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = s.languageCode;
    final theme = Theme.of(context);
    final m = medicine;
    final price = m.lowestPrice;
    return PlaceCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${m.brand}  ${m.strength}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text('${m.generic} · ${m.form}', style: theme.textTheme.bodyMedium),
                Text(m.company, style: theme.textTheme.bodySmall),
                if (highlight) Tag(icon: Icons.savings_outlined, text: s.cheapest, color: JColors.ok),
              ],
            ),
          ),
          const SizedBox(width: JSpace.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price == null ? '—' : localizedDigits(s.taka(formatTaka(price)), lang),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(price == null ? s.noPublishedPrice : s.pricePerUnit, style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class MedicineDetailScreen extends StatelessWidget {
  const MedicineDetailScreen({super.key, required this.medicine, required this.all, required this.downloadedOn});

  final Medicine medicine;
  final List<Medicine> all;
  final String downloadedOn;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = s.languageCode;
    final theme = Theme.of(context);
    final m = medicine;
    final others = sameMedicine(all, m).where((x) => !identical(x, m)).toList();
    final cheapest = others.isNotEmpty && others.first.lowestPrice != null ? others.first : null;

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text.rich(TextSpan(children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: value),
          ])),
        );

    return Scaffold(
      appBar: GlassAppBar(title: Text(m.brand)),
      body: ListView(
        padding: const EdgeInsets.all(JSpace.md),
        children: [
          Text('${m.brand}  ${m.strength}', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: JSpace.sm),
          row(s.medicineGeneric, '${m.generic} ${m.strength}'),
          row(s.medicineCompany, m.company),
          if (m.dar.isNotEmpty) row(s.medicineDar, m.dar),
          const SizedBox(height: JSpace.md),
          if (m.packs.isEmpty)
            Text(s.noPublishedPrice, style: theme.textTheme.titleMedium)
          else
            for (final p in m.packs)
              PlaceCard(
                child: Row(
                  children: [
                    Expanded(child: Text('${s.medicinePack}: ${p.pack}', style: theme.textTheme.bodyLarge)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(localizedDigits(s.taka(formatTaka(p.priceBdt)), lang),
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                        Text(s.pricePerUnit, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
          if (others.isNotEmpty) ...[
            const SizedBox(height: JSpace.md),
            Text(s.sameMedicineOtherBrands, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: JSpace.sm),
            for (final o in others.take(60))
              MedicineCard(
                medicine: o,
                highlight: identical(o, cheapest) && (m.lowestPrice == null || o.lowestPrice! < m.lowestPrice!),
                onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
                  builder: (_) => MedicineDetailScreen(medicine: o, all: all, downloadedOn: downloadedOn),
                )),
              ),
          ],
          const SizedBox(height: JSpace.md),
          if (m.updatedOn.isNotEmpty) ...[
            Text(localizedDigits(s.medicineCheckedByTeam(m.updatedOn), lang),
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: JSpace.xs),
          ],
          Text(localizedDigits(s.medicinePriceNote(downloadedOn), lang), style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
