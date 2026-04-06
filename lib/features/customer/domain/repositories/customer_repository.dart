import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/customer_entity.dart';

abstract class CustomerRepository {
  Stream<Either<Failure, List<CustomerEntity>>> getCustomers({
    required String shopId,
    required String ownerId,
    int limit = 5000,
    dynamic lastDoc,
  });

  Future<Either<Failure, String>> addCustomer(CustomerEntity customer);
  Future<Either<Failure, void>> updateCustomer(
    CustomerEntity customer, {
    String? paymentMode,
  });
  Future<Either<Failure, void>> deleteCustomer(String customerId);
}
