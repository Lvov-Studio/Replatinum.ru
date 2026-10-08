import 'package:flutter/material.dart';

/// Brief feedback; scrolling and page navigation retain platform physics.
abstract final class AppMotion {
  static const feedback = Duration(milliseconds: 180);
  static const curve = Curves.easeOutCubic;

  static Duration durationOf(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : feedback;
}
