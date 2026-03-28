import 'package:flutter_test/flutter_test.dart';
import 'package:csms/features/customer/data/models/customer_model.dart';
import 'package:csms/features/customer/domain/entities/customer_entity.dart';

void main() {
  final tCreatedAt = DateTime.utc(2023, 1, 1);
  final tUpdatedAt = DateTime.utc(2023, 1, 2);
  
  final tCustomerModel = CustomerModel(
    customerId: '123',
    shopId: 'shop1',
    name: 'John Doe',
    mobileNumber: '1234567890',
    email: 'john@example.com',
    assignedProductIds: {'p1': true},
    createdAt: tCreatedAt,
    updatedAt: tUpdatedAt,
    updatedById: 'admin1',
    ownerId: 'owner1',
    status: 'active',
    owner_createdAt: 'owner1_1672531200000',
  );

  group('CustomerModel', () {
    test('should be a subclass of CustomerEntity', () {
      expect(tCustomerModel, isA<CustomerEntity>());
    });

    test('fromJson should return a valid model when JSON has int dates', () {
      // Arrange
      final json = {
        'shopId': 'shop1',
        'name': 'John Doe',
        'mobileNumber': '1234567890',
        'email': 'john@example.com',
        'assignedProductIds': {'p1': true},
        'createdAt': 1672531200000, // Jan 1 2023
        'updatedAt': 1672617600000, // Jan 2 2023
        'updatedById': 'admin1',
        'ownerId': 'owner1',
        'status': 'active',
        'owner_createdAt': 'owner1_1672531200000',
      };

      // Act
      final result = CustomerModel.fromJson(json, '123');

      // Assert
      expect(result, tCustomerModel);
      expect(result.createdAt, tCreatedAt);
    });

    test('fromJson should handle status strings in assignedProductIds', () {
      // Arrange
      final json = {
        'assignedProductIds': {'p1': 'active', 'p2': 'inactive', 'p3': true, 'p4': false},
      };

      // Act
      final result = CustomerModel.fromJson(json, '123');

      // Assert
      expect(result.assignedProductIds['p1'], true);
      expect(result.assignedProductIds['p2'], false);
      expect(result.assignedProductIds['p3'], true);
      expect(result.assignedProductIds['p4'], false);
    });

    test('toJson should return a JSON map containing proper data', () {
      // Act
      final result = tCustomerModel.toJson();

      // Assert
      final expectedJson = {
        'shopId': 'shop1',
        'name': 'John Doe',
        'mobileNumber': '1234567890',
        'email': 'john@example.com',
        'assignedProductIds': {'p1': true},
        'createdAt': 1672531200000,
        'updatedAt': 1672617600000,
        'updatedById': 'admin1',
        'ownerId': 'owner1',
        'status': 'active',
        'owner_createdAt': 'owner1_1672531200000',
      };
      expect(result, expectedJson);
    });

    test('toJson should auto-generate owner_createdAt if it is empty', () {
      // Arrange
      final modelWithoutIndex = CustomerModel(
        customerId: '123',
        shopId: 'shop1',
        name: 'John Doe',
        mobileNumber: '1234567890',
        email: 'john@example.com',
        assignedProductIds: {},
        createdAt: tCreatedAt,
        updatedAt: tUpdatedAt,
        updatedById: 'admin1',
        ownerId: 'owner1',
        owner_createdAt: '', // Empty
      );

      // Act
      final result = modelWithoutIndex.toJson();

      // Assert
      expect(result['owner_createdAt'], 'owner1_1672531200000');
    });
  });
}
