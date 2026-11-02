import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:joruri_design_system/joruri_design_system.dart';

import 'package:joruri_bd/core/widgets/glass_app_bar.dart';
import 'package:joruri_bd/core/utils/digits.dart';
import 'package:joruri_bd/l10n/app_strings.dart';

class CompassScreen extends StatelessWidget {
  const CompassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final events = FlutterCompass.events;

    return Scaffold(
      appBar: GlassAppBar(title: Text(s.compass)),
      body: events == null
          ? Center(child: Text(s.compassUnavailable, style: theme.textTheme.titleMedium))
          : StreamBuilder<CompassEvent>(
              stream: events,
              builder: (context, snapshot) {
                final heading = snapshot.data?.heading;
                if (heading == null) {
                  return Center(
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? const CircularProgressIndicator()
                        : Text(s.compassUnavailable, style: theme.textTheme.titleMedium),
                  );
                }
                final normalized = (heading % 360 + 360) % 360;
                final index = ((normalized + 22.5) ~/ 45) % 8;
                return Padding(
                  padding: const EdgeInsets.all(JSpace.lg),
                  child: Column(
                    children: [
                      const Spacer(),
                      // The arrow always points north.
                      Transform.rotate(
                        angle: -normalized * math.pi / 180,
                        child: const Icon(Icons.navigation, size: 200, color: JColors.sos),
                      ),
                      const SizedBox(height: JSpace.lg),
                      Text(
                        '${localizedDigits('${normalized.round()}', s.languageCode)}°  ${s.directions[index]}',
                        style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(s.compassHint, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
