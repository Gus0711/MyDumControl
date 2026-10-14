import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myglobaldc/presentation/widgets/chart_downsample.dart';

void main() {
  List<FlSpot> series(int n) =>
      List.generate(n, (i) => FlSpot(i.toDouble(), (i % 100).toDouble()));

  test('downsampleMinMax returns input when small', () {
    final s = series(100);
    expect(identical(downsampleMinMax(s, maxPoints: 200), s), isTrue);
  });

  test('downsampleMinMax bounds size and keeps extremes and order', () {
    final s = series(10000)..[4321] = const FlSpot(4321, 999);
    final d = downsampleMinMax(s, maxPoints: 1000);
    expect(d.length, lessThanOrEqualTo(1000));
    expect(d.first, s.first);
    expect(d.last, s.last);
    expect(d.any((p) => p.y == 999), isTrue);
    for (var i = 1; i < d.length; i++) {
      expect(d[i].x, greaterThanOrEqualTo(d[i - 1].x));
    }
  });

  test('visibleWindow keeps one neighbour on each side', () {
    final s = series(100);
    final w = visibleWindow(s, 10.5, 20.5);
    expect(w.first.x, 10);
    expect(w.last.x, 21);
    expect(visibleWindow(const [], 0, 1), isEmpty);
  });
}
