import 'package:flutter_test/flutter_test.dart';
import 'package:myglobaldc/application/providers/bacnet_type_codes.dart';
import 'package:myglobaldc/application/providers/super_favorites_provider.dart';
import 'package:myglobaldc/data/database/app_database.dart';
import 'package:myglobaldc/domain/models/bacnet_object.dart';

Favorite _fav(int id, String ref) => Favorite(
      id: id,
      connectionId: 1,
      pointRef: ref,
      pointName: 'P$id',
      objectType: 'analogValue',
      sortOrder: id,
      isSuperFavorite: true,
      wasPromoted: false,
      createdAt: DateTime(2026),
    );

void main() {
  group('mergeSuperFavoriteRefresh', () {
    test('applies results to the current list only', () {
      // AV:1 was removed during the refresh, AV:3 was added
      final current = [
        SuperFavoriteWithValue(favorite: _fav(2, 'AV:2')),
        SuperFavoriteWithValue(favorite: _fav(3, 'AV:3')),
      ];
      final now = DateTime(2026, 10, 15);
      final live = BacnetObject(type: BacnetObjectType.analogValue, instance: 2, objectName: 'P2', presentValue: 21.0);
      final merged = mergeSuperFavoriteRefresh(current, {
        'AV:1': (liveData: null, error: 'Point non trouvé'),
        'AV:2': (liveData: live, error: null),
      }, now);

      expect(merged.map((e) => e.favorite.pointRef), ['AV:2', 'AV:3']);
      expect(merged[0].liveData, same(live));
      expect(merged[0].lastRefreshed, now);
      expect(merged[1].lastRefreshed, isNull);
    });
  });

  group('parseBacnetPointRef', () {
    test('parses shortName:instance', () {
      final p = parseBacnetPointRef('AV:5');
      expect(p, isNotNull);
      expect(p!.type, BacnetObjectType.analogValue);
      expect(p.instance, 5);
      expect(p.typeCode, 2);
    });

    test('rejects invalid refs', () {
      expect(parseBacnetPointRef('AV'), isNull);
      expect(parseBacnetPointRef('XX:1'), isNull);
      expect(parseBacnetPointRef('AV:abc'), isNull);
    });
  });
}
