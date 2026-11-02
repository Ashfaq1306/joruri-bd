import 'package:flutter/material.dart';

import 'tokens.dart';

/// Shrinks a widget slightly while it is pressed: a small, native-feeling
/// confirmation that the tap registered. Off when the phone asks for less motion.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scale = 0.96});

  final Widget child;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down && !reduce ? widget.scale : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Soft, tinted shadows (never flat black).
abstract final class JShadows {
  static List<BoxShadow> soft(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    // One soft shadow (cheap for low-end phones), tinted, never flat black.
    return dark
        ? const [BoxShadow(color: Color(0x66000000), blurRadius: 16, spreadRadius: -8, offset: Offset(0, 8))]
        : const [BoxShadow(color: Color(0x24103026), blurRadius: 16, spreadRadius: -8, offset: Offset(0, 6))];
  }

  static const sosGlow = [
    BoxShadow(color: Color(0x66C8102E), blurRadius: 32, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x47C8102E), blurRadius: 10, offset: Offset(0, 2)),
  ];
}

/// A very subtle green/red mesh behind the main screens, for depth.
class MeshBackground extends StatelessWidget {
  const MeshBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    Widget glow(Alignment at, Color color, double radius) => Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(center: at, radius: radius, colors: [color, color.withAlpha(0)]),
            ),
          ),
        );
    return Stack(
      children: [
        // Drawn once and cached: scrolling never repaints the background.
        Positioned.fill(
          child: RepaintBoundary(
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: dark ? JColors.night : JColors.paper)),
                glow(const Alignment(-1, -1), dark ? const Color(0x29008C64) : const Color(0x1C006A4E), 1.2),
                glow(const Alignment(1, -0.85), dark ? const Color(0x1AC8102E) : const Color(0x0FC8102E), 0.9),
                glow(const Alignment(0, 1.25), dark ? const Color(0x24006A4E) : const Color(0x14006A4E), 1.2),
              ],
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

/// The red SOS disc with a soft glow. The one bold element on every screen.
class SosButton extends StatelessWidget {
  const SosButton({
    super.key,
    required this.label,
    required this.hint,
    required this.onPressed,
    this.diameter = JSize.sosButton,
  });

  final String label;
  final String hint;
  final VoidCallback onPressed;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label. $hint',
      excludeSemantics: true,
      child: PressScale(
        scale: 0.95,
        child: RepaintBoundary(child: Container(
          width: diameter,
          height: diameter,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x24FFFFFF),
            border: Border.all(color: const Color(0x38FFFFFF)),
          ),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment(-0.3, -0.45),
                radius: 0.95,
                colors: [Color(0xFFEF3D58), JColors.sos, Color(0xFFA00B23)],
                stops: [0, 0.55, 1],
              ),
              boxShadow: JShadows.sosGlow,
            ),
            child: Material(
              type: MaterialType.transparency,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                splashColor: JColors.sosPressed,
                onTap: onPressed,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: diameter * 0.26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: diameter * 0.015,
                          height: 1,
                          shadows: const [Shadow(color: Color(0x2E000000), blurRadius: 8, offset: Offset(0, 2))],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Text(
                          hint,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontSize: diameter * 0.075, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )),
      ),
    );
  }
}

/// Glossy rounded-square icon chip used on tiles and lists.
class IconChip extends StatelessWidget {
  const IconChip({super.key, required this.icon, required this.color, this.size = 44});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.white, 0.18)!, color],
        ),
        boxShadow: [BoxShadow(color: color.withAlpha(100), blurRadius: 10, spreadRadius: -5, offset: const Offset(0, 6))],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.5),
    );
  }
}

/// A home-screen action: glossy icon chip and a label on a soft card.
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.vertical = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  /// Icon above the label, for a 3-column grid.
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final chip = IconChip(icon: icon, color: color, size: vertical ? 44 : 40);
    final text = Text(
      label,
      maxLines: 2,
      textAlign: vertical ? TextAlign.center : TextAlign.start,
      overflow: TextOverflow.ellipsis,
      style: (vertical ? theme.textTheme.bodyMedium : theme.textTheme.titleMedium)
          ?.copyWith(fontWeight: FontWeight.w600, height: 1.2),
    );
    final radius = BorderRadius.circular(20);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: PressScale(
        child: RepaintBoundary(child: DecoratedBox(
          decoration: BoxDecoration(borderRadius: radius, boxShadow: JShadows.soft(context)),
          child: Material(
            color: dark ? JColors.nightSurface : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(color: dark ? const Color(0x14FFFFFF) : const Color(0x1A103026)),
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: vertical ? 6 : 12, vertical: vertical ? 10 : 0),
                child: vertical
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [chip, const SizedBox(height: 8), text],
                      )
                    : Row(children: [chip, const SizedBox(width: 12), Expanded(child: text)]),
              ),
            ),
          ),
        )),
      ),
    );
  }
}

/// A full-width, very large action used in Easy Mode and accident mode.
class BigActionButton extends StatelessWidget {
  const BigActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.background,
    required this.onTap,
    this.foreground = Colors.white,
    this.height = JSize.bigButtonHeight,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: PressScale(child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(icon, color: foreground, size: 34),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(color: foreground, fontSize: 21, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      )),
    );
  }
}

/// A selectable option card (onboarding and settings).
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(JSize.radius),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(JSize.radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 16)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? scheme.primary : scheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small rounded status label with a coloured dot (online / offline).
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.dotColor, this.onDark = false});

  final String label;
  final Color dotColor;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final textColor = onDark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: onDark ? const Color(0x26FFFFFF) : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
