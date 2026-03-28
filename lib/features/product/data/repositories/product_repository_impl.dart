import 'package:firebase_database/firebase_database.dart';
import 'package:dartz/dartz.dart';
import 'package:csms/core/error/failures.dart';
import 'package:csms/features/product/domain/entities/product_entity.dart';
import 'package:csms/features/product/domain/repositories/product_repository.dart';
import 'package:csms/features/product/data/models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final FirebaseDatabase _database;

  ProductRepositoryImpl({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;


  @override
  Stream<Either<Failure, List<ProductEntity>>> getProducts(
    String shopId,
    String ownerId,
  ) {
    return _database
        .ref()
        .child('products')
        .orderByChild('ownerId')
        .equalTo(ownerId)
        .onValue
        .map((event) {
          try {
            final products = <ProductEntity>[];
            if (event.snapshot.value != null) {
              final data = event.snapshot.value as Map<dynamic, dynamic>;
              data.forEach((key, value) {
                final productData = Map<String, dynamic>.from(value as Map);
                // Filter by shopId locally
                if (productData['shopId'] == shopId) {
                  products.add(ProductModel.fromJson(productData, key.toString()));
                }
              });
            }
            return Right(products);
          } catch (e) {
            return Left(ServerFailure(e.toString()));
          }
        });
  }

  @override
  Future<Either<Failure, void>> addProduct(ProductEntity product) async {
    try {
      final docRef = _database.ref().child('products').push();
      final model = ProductModel(
        productId: docRef.key!,
        shopId: product.shopId,
        name: product.name,
        price: product.price,
        validityValue: product.validityValue,
        validityUnit: product.validityUnit,
        validityDays: product.validityDays,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        updatedById: product.updatedById,
        ownerId: product.ownerId,
        status: 'active',
        priceType: product.priceType,
        validityType: product.validityType,
      );

      await docRef.set(model.toJson());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(ProductEntity product) async {
    try {
      await _database.ref().child('products').child(product.productId).update({
        'name': product.name,
        'price': product.price,
        'validityValue': product.validityValue,
        'validityUnit': product.validityUnit,
        'validityDays': product.validityDays,
        'updatedAt': ServerValue.timestamp,
        'updatedById': product.updatedById,
        'status': product.status,
        'priceType': product.priceType,
        'validityType': product.validityType,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
