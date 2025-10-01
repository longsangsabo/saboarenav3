import 'package:flutter/material.dart';

// Lightweight replacement utilities for Sizer.
// Use judiciously; prefer fixed design tokens where possible.

bool isTablet(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return width >= 600; // simple breakpoint
}

// Viewport percentage helpers (avoid overuse for height scrolling content)
double vw(BuildContext context, double percent) => MediaQuery.of(context).size.width * (percent / 100);
double vh(BuildContext context, double percent) => MediaQuery.of(context).size.height * (percent / 100);

// Scaled text: we keep a base of 16 and scale modestly on larger screens.
double scaledFont(BuildContext context, double size) {
  final width = MediaQuery.of(context).size.width;
  if (width >= 900) return size * 1.15;
  if (width >= 600) return size * 1.07;
  return size;
}

// Spacing tokens (in logical pixels) - keep consistent across app
class Gaps() {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}
