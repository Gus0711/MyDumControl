import 'package:flutter_test/flutter_test.dart';
import 'package:myglobaldc/application/providers/dashboard_provider.dart';
import 'package:myglobaldc/domain/models/trend_log.dart';

void main() {
  group('TrendLog parsing', () {
    test('fromJson accepts textual/num booleans and double ints', () {
      final tl = TrendLog.fromJson(1, {
        'enable': 'true',
        'log-interval': 900.0,
        'buffer-size': '1000',
      });
      expect(tl.enabled, isTrue);
      expect(tl.logInterval, 900);
      expect(tl.bufferSize, 1000);
      expect(TrendLog.fromJson(1, {'enabled': 0}).enabled, isFalse);
    });

    test('NaN values are ignored in statistics', () {
      final t = DateTime(2026);
      final data = TrendLogData.fromRecords([
        TrendLogRecord(timestamp: t, value: 1.0, type: TrendRecordType.value),
        TrendLogRecord(timestamp: t.add(const Duration(minutes: 1)), value: 'NaN', type: TrendRecordType.value),
        TrendLogRecord(timestamp: t.add(const Duration(minutes: 2)), value: 3.0, type: TrendRecordType.value),
      ]);
      expect(data.minValue, 1.0);
      expect(data.maxValue, 3.0);
      expect(data.avgValue, 2.0);
    });

    test('parseV2 tolerates a textual record type', () {
      final data = TrendLogBufferParser.parseV2([
        {'timestamp': '2026-01-01T00:00:00Z', 'value': 1.0, 'type': '2'},
        {'timestamp': '2026-01-01T00:01:00Z', 'value': 2.0, 'type': 'real'},
      ]);
      expect(data.records.length, 2);
    });
  });

  group('Dashboard widget configs', () {
    test('MultiCurveWidgetConfig tolerates doubles and bad keys', () {
      final config = MultiCurveWidgetConfig.fromJson({
        'trendLogInstances': [300454.0, 2],
        'curveNames': {'300454': 'A', 'bad': 'B'},
        'curveUnits': {'2': null},
      });
      expect(config.trendLogInstances, [300454, 2]);
      expect(config.curveNamesAsInt, {300454: 'A'});
      expect(config.curveUnitsAsInt, {2: null});
    });

    test('SingleChartWidgetConfig accepts a double instance', () {
      final config = SingleChartWidgetConfig.fromJson({'trendLogInstance': 12.0});
      expect(config.trendLogInstance, 12);
    });
  });
}
