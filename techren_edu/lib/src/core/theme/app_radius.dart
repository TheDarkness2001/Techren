import 'package:flutter/material.dart';

/// Corner radius — cards 16–20, inputs 14, buttons soft.
abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double input = 14;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 999;

  static const BorderRadius button = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius inputBorder = BorderRadius.all(Radius.circular(input));
  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius cardLarge = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius dialog = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius navIndicator = BorderRadius.all(Radius.circular(md));
}
