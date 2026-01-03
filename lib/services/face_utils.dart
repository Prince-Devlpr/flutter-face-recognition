import 'dart:math';

double euclideanDistance(List<double> a, List<double> b) {
  final n = min(a.length, b.length);
  double sum = 0.0;
  for (var i = 0; i < n; i++) {
    final d = a[i] - b[i];
    sum += d * d;
  }
  return sqrt(sum);
}

/// return true if distance < threshold (0.6 is a commonly used starting point)
bool isMatch(List<double> a, List<double> b, {double threshold = 0.6}) {
  return euclideanDistance(a, b) <= threshold;
}
