import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joruri_core/joruri_core.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/features/profile/domain/user_profile.dart';
import 'package:joruri_bd/features/profile/presentation/profile_controller.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

/// The account form, used in onboarding and on the profile screen.
/// Call [ProfileFormState.submit] to validate; it returns null and shows
/// the errors when something required is missing.
class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({super.key});

  @override
  ConsumerState<ProfileForm> createState() => ProfileFormState();
}

class ProfileFormState extends ConsumerState<ProfileForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _area;
  BloodGroup? _group;
  String? _division;
  String? _district;
  bool _donor = true;
  bool _available = true;
  bool _consent = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider);
    _name = TextEditingController(text: p?.name ?? '');
    _phone = TextEditingController(text: p == null ? '' : BdPhone.display(p.phone).replaceAll('-', ''));
    _area = TextEditingController(text: p?.area ?? '');
    _group = p?.bloodGroup;
    _district = p?.districtId;
    _division = p?.divisionId ?? BdLocations.district(p?.districtId)?.divisionId;
    _donor = p?.donor ?? true;
    _available = p?.available ?? true;
    _consent = p?.consent ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _area.dispose();
    super.dispose();
  }

  /// Returns the profile when everything required is filled in, else null.
  UserProfile? submit() {
    setState(() => _submitted = true);
    final fieldsOk = _form.currentState?.validate() ?? false;
    final group = _group;
    final district = _district;
    final phone = BdPhone.normalizeMobile(_phone.text);
    if (!fieldsOk || group == null || district == null || phone == null || (_donor && !_consent)) return null;
    return UserProfile(
      name: _name.text.trim(),
      phone: phone,
      bloodGroup: group,
      districtId: district,
      divisionId: _division,
      area: _area.text.trim(),
      donor: _donor,
      available: _available,
      consent: _consent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = s.languageCode;
    final theme = Theme.of(context);
    final division = _division;
    final districts = [...(division == null ? BdLocations.districts : BdLocations.districtsOf(division))]
      ..sort((a, b) => a.name(lang).compareTo(b.name(lang)));

    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(top: JSpace.md, bottom: JSpace.sm),
          child: Row(
            children: [
              Text(text, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              _RequiredMark(text: s.requiredMark),
            ],
          ),
        );
    Widget error(String text) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(text, style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
        );

    return Form(
      key: _form,
      autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          label(s.fullName),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            validator: (v) => (v == null || v.trim().isEmpty) ? s.errName : null,
          ),
          label(s.mobileNumber),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '01712345678'),
            validator: (v) => BdPhone.normalizeMobile(v ?? '') == null ? s.invalidPhone : null,
          ),
          label(s.yourBloodGroup),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.5,
            children: [
              for (final g in BloodGroup.values)
                _GroupChip(group: g, selected: g == _group, onTap: () => setState(() => _group = g)),
            ],
          ),
          if (_submitted && _group == null) error(s.errGroup),
          label(s.yourLocation),
          Row(
            children: [
              Expanded(
                child: _Dropdown(
                  label: s.division,
                  value: division,
                  items: [for (final d in BdLocations.divisions) (d.id, d.name(lang))],
                  onChanged: (v) => setState(() {
                    _division = v;
                    _district = null;
                  }),
                ),
              ),
              const SizedBox(width: JSpace.sm),
              Expanded(
                child: _Dropdown(
                  label: s.district,
                  value: _district,
                  items: [for (final d in districts) (d.id, d.name(lang))],
                  onChanged: (v) => setState(() {
                    _district = v;
                    _division = BdLocations.district(v)?.divisionId ?? _division;
                  }),
                ),
              ),
            ],
          ),
          if (_submitted && _district == null) error(s.errDistrict),
          const SizedBox(height: JSpace.sm),
          TextField(
            controller: _area,
            decoration: InputDecoration(labelText: s.searchArea, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: JSpace.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(s.wantDonate),
                  value: _donor,
                  onChanged: (v) => setState(() => _donor = v),
                ),
                if (_donor) ...[
                  SwitchListTile(
                    title: Text(s.availableToggle),
                    value: _available,
                    onChanged: (v) => setState(() => _available = v),
                  ),
                  SwitchListTile(
                    title: Text(s.consentShow),
                    value: _consent,
                    onChanged: (v) => setState(() => _consent = v),
                  ),
                  if (_submitted && !_consent)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Align(alignment: Alignment.centerLeft, child: error(s.errConsent)),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequiredMark extends StatelessWidget {
  const _RequiredMark({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(color: const Color(0x14C8102E), borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: const TextStyle(color: JColors.sos, fontSize: 11, fontWeight: FontWeight.w500)),
      );
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({required this.group, required this.selected, required this.onTap});

  final BloodGroup group;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(14);
    return Semantics(
      selected: selected,
      button: true,
      label: group.label,
      excludeSemantics: true,
      child: PressScale(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: selected
                ? const [BoxShadow(color: Color(0x80B71C1C), blurRadius: 16, spreadRadius: -6, offset: Offset(0, 8))]
                : JShadows.soft(context),
          ),
          child: Material(
            color: selected ? JColors.blood : (dark ? JColors.nightSurface : Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(color: selected ? JColors.blood : const Color(0x1A103026)),
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: Center(
                child: Text(
                  group.label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({required this.label, required this.value, required this.items, required this.onChanged});

  final String label;
  final String? value;
  final List<(String, String)> items;
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
        child: DropdownButton<String>(
          value: items.any((i) => i.$1 == value) ? value : null,
          isExpanded: true,
          menuMaxHeight: 420,
          hint: const Text('—'),
          items: [
            for (final (id, text) in items)
              DropdownMenuItem<String>(value: id, child: Text(text, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
