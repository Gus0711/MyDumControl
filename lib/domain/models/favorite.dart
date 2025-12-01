import 'bacnet_object.dart';

/// Modèle de favori pour la couche domain
class Favorite {
  final int id;
  final int connectionId;
  final String pointRef;
  final String pointName;
  final String? pointDescription;
  final BacnetObjectType objectType;
  final int sortOrder;
  final bool isSuperFavorite;
  final DateTime createdAt;

  /// Données live du point (chargées séparément)
  final BacnetObject? liveData;

  const Favorite({
    required this.id,
    required this.connectionId,
    required this.pointRef,
    required this.pointName,
    this.pointDescription,
    required this.objectType,
    required this.sortOrder,
    this.isSuperFavorite = false,
    required this.createdAt,
    this.liveData,
  });

  /// Crée un favori depuis un BacnetObject
  factory Favorite.fromBacnetObject({
    required int connectionId,
    required BacnetObject object,
    int sortOrder = 0,
    bool isSuperFavorite = false,
  }) {
    return Favorite(
      id: 0, // Sera assigné par la DB
      connectionId: connectionId,
      pointRef: object.objectId,
      pointName: object.objectName,
      pointDescription: object.description,
      objectType: object.type,
      sortOrder: sortOrder,
      isSuperFavorite: isSuperFavorite,
      createdAt: DateTime.now(),
      liveData: object,
    );
  }

  /// Crée une copie avec des données live mises à jour
  Favorite copyWithLiveData(BacnetObject? liveData) {
    return Favorite(
      id: id,
      connectionId: connectionId,
      pointRef: pointRef,
      pointName: pointName,
      pointDescription: pointDescription,
      objectType: objectType,
      sortOrder: sortOrder,
      isSuperFavorite: isSuperFavorite,
      createdAt: createdAt,
      liveData: liveData,
    );
  }

  /// Crée une copie avec un nouvel ordre
  Favorite copyWithSortOrder(int newSortOrder) {
    return Favorite(
      id: id,
      connectionId: connectionId,
      pointRef: pointRef,
      pointName: pointName,
      pointDescription: pointDescription,
      objectType: objectType,
      sortOrder: newSortOrder,
      isSuperFavorite: isSuperFavorite,
      createdAt: createdAt,
      liveData: liveData,
    );
  }

  /// Crée une copie avec le statut super favori modifié
  Favorite copyWithSuperFavorite(bool isSuperFavorite) {
    return Favorite(
      id: id,
      connectionId: connectionId,
      pointRef: pointRef,
      pointName: pointName,
      pointDescription: pointDescription,
      objectType: objectType,
      sortOrder: sortOrder,
      isSuperFavorite: isSuperFavorite,
      createdAt: createdAt,
      liveData: liveData,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Favorite &&
          runtimeType == other.runtimeType &&
          connectionId == other.connectionId &&
          pointRef == other.pointRef;

  @override
  int get hashCode => connectionId.hashCode ^ pointRef.hashCode;
}
