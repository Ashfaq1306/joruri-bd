import 'package:flutter/material.dart';
import 'package:joruri_design_system/joruri_design_system.dart';
import 'package:url_launcher/url_launcher.dart';

/// Small icon + text label (services, "open 24 hours").
class Tag extends StatelessWidget {
  const Tag({super.key, required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}

/// Outlined card used for hospitals and pharmacies.
class PlaceCard extends StatelessWidget {
  const PlaceCard({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: JShadows.soft(context)),
        child: Material(
        color: theme.brightness == Brightness.dark ? JColors.nightSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(140)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(JSpace.md), child: child),
        ),
      ),
      ),
    );
  }
}

/// Opens Google Maps searching near the phone's position. Needs internet.
Future<void> searchInMaps(String query) => launchUrl(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}'),
      mode: LaunchMode.externalApplication,
    );
