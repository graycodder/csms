import 'package:firebase_database/firebase_database.dart';
import 'package:dartz/dartz.dart';
import 'package:csms/core/error/failures.dart';
import 'package:csms/features/shop/domain/entities/shop_entity.dart';
import 'package:csms/features/shop/domain/repositories/shop_repository.dart';
import 'package:csms/features/shop/data/models/shop_model.dart';
import 'package:csms/features/shop/data/datasources/shop_local_data_source.dart';

class ShopRepositoryImpl implements ShopRepository {
  final FirebaseDatabase _database;
  final ShopLocalDataSource localDataSource;

  ShopRepositoryImpl({
    FirebaseDatabase? database,
    required this.localDataSource,
  }) : _database = database ?? FirebaseDatabase.instance;


  @override
  Stream<Either<Failure, ShopEntity>> getShop(String shopId) {
    return _database.ref().child('shops').child(shopId).onValue.map((event) {
      try {
        if (event.snapshot.value != null) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          return Right(ShopModel.fromJson(data, shopId));
        } else {
          return Left(ServerFailure('Shop not found'));
        }
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    });
  }

  @override
  Future<Either<Failure, List<ShopEntity>>> getShopsByOwner(
    String ownerId,
  ) async {
    try {
      final snapshot = await _database
          .ref()
          .child('shops')
          .orderByChild('ownerId')
          .equalTo(ownerId)
          .get();

      final shops = <ShopEntity>[];
      if (snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          final shopData = Map<String, dynamic>.from(value as Map);
          shops.add(
            ShopEntity(
              shopId: key.toString(),
              ownerId: shopData['ownerId'] ?? '',
              shopName: shopData['shopName'] ?? '',
              shopAddress: shopData['shopAddress'] ?? '',
              category: shopData['category'] ?? '',
              phone: shopData['phone'],
              settings: ShopSettings.fromJson(shopData['settings'] ?? {}),
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                shopData['createdAt'] ?? 0,
              ),
              updatedAt: DateTime.fromMillisecondsSinceEpoch(
                shopData['updatedAt'] ?? 0,
              ),
              updatedById: shopData['updatedById'] ?? '',
            ),
          );
        });
      }

      return Right(shops);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateShop(ShopEntity shop) async {
    try {
      final model = ShopModel(
        shopId: shop.shopId,
        ownerId: shop.ownerId,
        shopName: shop.shopName,
        shopAddress: shop.shopAddress,
        category: shop.category,
        phone: shop.phone,
        settings: shop.settings,
        createdAt: shop.createdAt,
        updatedAt: DateTime.now(),
        updatedById: shop.updatedById,
      );

      await _database.ref().child('shops').child(shop.shopId).update(model.toJson());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<void> saveSelectedShopId(String shopId) async {
    await localDataSource.saveSelectedShopId(shopId);
  }

  @override
  String? getSelectedShopId() {
    return localDataSource.getSelectedShopId();
  }

  @override
  Future<void> clearSelectedShopId() async {
    await localDataSource.clearSelectedShopId();
  }
}
