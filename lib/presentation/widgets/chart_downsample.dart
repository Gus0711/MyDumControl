import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';

/// Maximum number of points handed to fl_chart for one curve.
const int kMaxChartPoints = 1500;

/// Above this number of displayed points, expensive decorations (curve
/// smoothing, shadow, animation) should be disabled.
const int kRichRenderingMaxPoints = 500;

/// Returns the spots whose x lies in [minX, maxX], plus one neighbour on each
/// side so the line reaches the edges of the window. [spots] must be sorted
/// by x (ascending).
List<FlSpot> visibleWindow(List<FlSpot> spots, double minX, double maxX) {
  if (spots.isEmpty) return const [];
  // First index with x >= minX
  var lo = 0;
  var hi = spots.length;
  while (lo < hi) {
    final mid = (lo + hi) >> 1;
    if (spots[mid].x < minX) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  final start = math.max(0, lo - 1);
  // First index with x > maxX
  var lo2 = lo;
  var hi2 = spots.length;
  while (lo2 < hi2) {
    final mid = (lo2 + hi2) >> 1;
    if (spots[mid].x <= maxX) {
      lo2 = mid + 1;
    } else {
      hi2 = mid;
    }
  }
  final end = math.min(spots.length, lo2 + 1);
  if (start == 0 && end == spots.length) return spots;
  return spots.sublist(start, end);
}

/// Min/max-per-bucket decimation: keeps the first and last point and, for
/// each bucket, the lowest and highest point (in x order). Preserves peaks,
/// so the global min and max are never lost. Returns [spots] unchanged when
/// it is already small enough. Result size is at most about [maxPoints].
List<FlSpot> downsampleMinMax(List<FlSpot> spots, {int maxPoints = kMaxChartPoints}) {
  if (maxPoints < 4 || spots.length <= maxPoints) return spots;

  final inner = spots.length - 2;
  final bucketCount = (maxPoints - 2) ~/ 2;
  final bucketSize = inner / bucketCount;
  final result = <FlSpot>[spots.first];

  for (var b = 0; b < bucketCount; b++) {
    final from = 1 + (b * bucketSize).floor();
    final to = math.min(1 + ((b + 1) * bucketSize).floor(), spots.length - 1);
    if (from >= to) continue;
    var minI = from;
    var maxI = from;
    for (var i = from + 1; i < to; i++) {
      if (spots[i].y < spots[minI].y) minI = i;
      if (spots[i].y > spots[maxI].y) maxI = i;
    }
    if (minI == maxI) {
      result.add(spots[minI]);
    } else if (minI < maxI) {
      result..add(spots[minI])..add(spots[maxI]);
    } else {
      result..add(spots[maxI])..add(spots[minI]);
    }
  }
  result.add(spots.last);
  return result;
}
