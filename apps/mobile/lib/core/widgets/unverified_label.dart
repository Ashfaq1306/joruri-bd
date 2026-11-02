import 'package:flutter/material.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/l10n/app_strings.dart';

/// Amber "Not yet verified" label shown on any unconfirmed entry.
class UnverifiedLabel extends StatelessWidget {
  const UnverifiedLabel({super.key, this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x33FFB300),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: JColors.amber),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, size: 16),
          const SizedBox(width: 6),
          Text(text ?? context.s.notYetVerified, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
