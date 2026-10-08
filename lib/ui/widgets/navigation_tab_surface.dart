import 'package:flutter/material.dart';
import '../../core/theme/app_motion.dart';

/// The persistent tab acknowledges selection without moving the page or losing
/// the nested navigator's scroll position.
class NavigationTabSurface extends StatelessWidget {
  const NavigationTabSurface(
      {super.key,
      required this.selected,
      required this.color,
      required this.onTap,
      required this.child});
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
        selected: selected,
        button: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          child: AnimatedContainer(
            duration: AppMotion.durationOf(context),
            curve: AppMotion.curve,
            decoration: BoxDecoration(
              color:
                  selected ? color.withValues(alpha: .11) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: child,
              ),
            ),
          ),
        ),
      );
}
