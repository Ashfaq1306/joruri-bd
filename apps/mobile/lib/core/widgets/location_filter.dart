import 'package:flutter/material.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/l10n/app_strings.dart';

/// Division → district → area. Used by Hospitals and Pharmacy.
class LocationFilterFields extends StatefulWidget {
  const LocationFilterFields({
    super.key,
    required this.filter,
    required this.onDivision,
    required this.onDistrict,
    required this.onArea,
  });

  final PlaceFilter filter;
  final ValueChanged<String?> onDivision;
  final ValueChanged<String?> onDistrict;
  final ValueChanged<String> onArea;

  @override
  State<LocationFilterFields> createState() => _LocationFilterFieldsState();
}

class _LocationFilterFieldsState extends State<LocationFilterFields> {
  late final TextEditingController _area = TextEditingController(text: widget.filter.areaText);

  @override
  void dispose() {
    _area.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = s.languageCode;
    final f = widget.filter;
    final division = f.divisionId;
    final districts = [...(division == null ? BdLocations.districts : BdLocations.districtsOf(division))]
      ..sort((a, b) => a.name(lang).compareTo(b.name(lang)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _Dropdown(
                label: s.division,
                value: division,
                items: [(null, s.allDivisions), for (final d in BdLocations.divisions) (d.id, d.name(lang))],
                onChanged: widget.onDivision,
              ),
            ),
            const SizedBox(width: JSpace.sm),
            Expanded(
              child: _Dropdown(
                label: s.district,
                value: f.districtId,
                items: [(null, s.allDistricts), for (final d in districts) (d.id, d.name(lang))],
                onChanged: widget.onDistrict,
              ),
            ),
          ],
        ),
        const SizedBox(height: JSpace.sm),
        TextField(
          controller: _area,
          onChanged: widget.onArea,
          decoration: InputDecoration(
            labelText: s.searchArea,
            prefixIcon: const Icon(Icons.place_outlined),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({required this.label, required this.value, required this.items, required this.onChanged});

  final String label;
  final String? value;
  final List<(String?, String)> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          menuMaxHeight: 420,
          items: [
            for (final (v, text) in items)
              DropdownMenuItem<String?>(value: v, child: Text(text, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
