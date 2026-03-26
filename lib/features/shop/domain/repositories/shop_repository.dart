import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/shop_entity.dart';

abstract class ShopRepository {
  Future<Either<Failure, List<ShopEntity>>> getShopsByOwner(String ownerId);
  Future<Either<Failure, ShopEntity>> getShop(String shopId);
  Future<Either<Failure, void>> updateShop(ShopEntity shop);
  Future<void> saveSelectedShopId(String shopId);
  String? getSelectedShopId();
  Future<void> clearSelectedShopId();
}
