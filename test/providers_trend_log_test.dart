import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myglobaldc/application/providers/active_connection_provider.dart';
import 'package:myglobaldc/application/providers/bacnet_provider.dart';
import 'package:myglobaldc/application/providers/trend_log_provider.dart';
import 'package:myglobaldc/data/database/app_database.dart';
import 'package:myglobaldc/data/services/bacnet_service.dart';

class FakeTrendBacnetService extends BacnetService {
  final List<int?> requestedMaxRecords = [];

  @override
  Future<List<TrendLogRecordData>> readTrendLogBuffer({
    required String host,
    required int port,
    required int trendLogInstance,
    int? maxRecords,
    int? totalRecordCount,
  }) async {
    requestedMaxRecords.add(maxRecords);
    final now = DateTime.now();
    return [
      for (var i = 0; i < 5; i++)
        TrendLogRecordData(timestamp: now.subtract(Duration(minutes: 15 * i)), value: 20.0 + i),
    ];
  }
}

class FakeActiveConnectionNotifier extends ActiveConnectionNotifier {
  FakeActiveConnectionNotifier(super.ref, ActiveConnectionState initial) {
    state = initial;
  }
}

void main() {
  late FakeTrendBacnetService bacnet;
  late ProviderContainer container;

  setUp(() {
    bacnet = FakeTrendBacnetService();
    container = ProviderContainer(overrides: [
      bacnetServiceProvider.overrideWithValue(bacnet),
      activeConnectionProvider.overrideWith((ref) => FakeActiveConnectionNotifier(
            ref,
            ActiveConnectionState(
              connection: Connection(
                id: 1,
                name: 'D',
                host: '10.0.0.1',
                port: 47808,
                useHttps: false,
                username: '',
                passwordKey: '',
                connectionType: 'bacnet',
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026),
              ),
              isBacnetConnection: true,
              bacnetDeviceId: 1001,
            ),
          )),
    ]);
    container.read(activeBacnetConnectionProvider.notifier).state =
        ActiveBacnetConnection(connectionId: 1, host: '10.0.0.1', port: 47808, deviceId: 1001);
  });

  tearDown(() => container.dispose());

  test('BACnet viewer reloads only when a longer period is requested', () async {
    final sub = container.listen(trendLogViewerProvider(300001), (_, __) {});
    final notifier = container.read(trendLogViewerProvider(300001).notifier);

    await notifier.loadData(period: TrendPeriod.hour);
    expect(bacnet.requestedMaxRecords, [10]);

    // Shorter or equal coverage: cache only
    await notifier.loadData(period: TrendPeriod.hour);
    expect(bacnet.requestedMaxRecords, [10]);

    // Longer period: the 10-record cache does not cover 7 days
    await notifier.loadData(period: TrendPeriod.week);
    expect(bacnet.requestedMaxRecords, [10, 800]);

    // Back to a shorter period: served from cache
    await notifier.loadData(period: TrendPeriod.day);
    expect(bacnet.requestedMaxRecords, [10, 800]);
    expect(container.read(trendLogViewerProvider(300001)).selectedPeriod, TrendPeriod.day);

    // refresh() always re-downloads
    await notifier.refresh();
    expect(bacnet.requestedMaxRecords.length, 3);
    sub.close();
  });
}
