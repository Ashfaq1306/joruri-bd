import 'package:flutter/material.dart';

/// The Joruri mark on a white disc (used on the welcome screen).
class LogoBadge extends StatelessWidget {
  const LogoBadge({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.14),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Image.asset(
        'assets/images/logo_mark.png',
        fit: BoxFit.contain,
        semanticLabel: 'Joruri',
        // Decode at the size shown, not the full 512 px file.
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
      ),
    );
  }
}

/// The Joruri mark on a white rounded-square tile: the brand in the top
/// bars and on the Home panel. White keeps the green hand visible on green.
class LogoTile extends StatelessWidget {
  const LogoTile({super.key, this.size = 42});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.31),
        border: Border.all(color: const Color(0x0A000000)),
        boxShadow: const [BoxShadow(color: Color(0x59000000), blurRadius: 16, spreadRadius: -6, offset: Offset(0, 6))],
      ),
      child: Image.asset(
        'assets/images/logo_mark.png',
        fit: BoxFit.contain,
        semanticLabel: 'Joruri',
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
      ),
    );
  }
}
