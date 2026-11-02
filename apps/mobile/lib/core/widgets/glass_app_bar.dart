import 'package:flutter/material.dart';

import 'package:joruri_bd/core/widgets/logo.dart';

/// Frosted, slightly see-through top bar with a hairline edge.
/// Tab screens show the logo tile where a back button would be.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.bottom,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.showLogo = false,
  });

  final Widget? title;
  final PreferredSizeWidget? bottom;
  final bool automaticallyImplyLeading;

  /// Solid colour for special screens (SOS red, accident amber).
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool showLogo;

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final glass = dark ? const Color(0xB3121E19) : const Color(0xBFFAFCFB);
    final edge = dark ? const Color(0x59000000) : const Color(0x14103026);
    return AppBar(
      title: title,
      bottom: bottom,
      automaticallyImplyLeading: automaticallyImplyLeading && !showLogo,
      leading: showLogo ? const Padding(padding: EdgeInsets.all(11), child: LogoTile(size: 34)) : null,
      leadingWidth: showLogo ? 60 : null,
      backgroundColor: backgroundColor ?? glass,
      foregroundColor: foregroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: foregroundColor,
          ),
      shape: backgroundColor == null ? Border(bottom: BorderSide(color: edge)) : null,
    );
  }
}
