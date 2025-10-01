/// Lightweight size extensions to neutralize deprecated .w/.h/.v usages.
/// These simply return the numeric value as double to keep layouts compiling.
extension NumSizeExtensions on num {
  double get w => toDouble();
  double get h => toDouble();
  double get v => toDouble();
  double get fSize => toDouble();
  double get adaptSize => toDouble();
}
