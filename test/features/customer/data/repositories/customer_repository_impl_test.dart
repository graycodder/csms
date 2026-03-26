import 'package:csms/features/customer/data/repositories/customer_repository_impl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseDatabase extends Mock implements FirebaseDatabase {}
class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockQuery extends Mock implements Query {}
class MockDataSnapshot extends Mock implements DataSnapshot {}

void main() {
  late CustomerRepositoryImpl repository;
  late MockFirebaseDatabase mockDatabase;
  late MockDatabaseReference mockRef;
  late MockQuery mockQuery;
  late MockDataSnapshot mockSnapshot;

  setUp(() {
    mockDatabase = MockFirebaseDatabase();
    mockRef = MockDatabaseReference();
    mockQuery = MockQuery();
    mockSnapshot = MockDataSnapshot();

    when(() => mockDatabase.ref()).thenReturn(mockRef);
    when(() => mockRef.child(any())).thenReturn(mockRef);
    when(() => mockRef.update(any())).thenAnswer((_) async => null);
    
    // Default chain for paginated query
    when(() => mockRef.orderByChild(any())).thenReturn(mockQuery);
    when(() => mockQuery.startAt(any())).thenReturn(mockQuery);
    when(() => mockQuery.endAt(any())).thenReturn(mockQuery);
    when(() => mockQuery.limitToLast(any())).thenReturn(mockQuery);
    when(() => mockQuery.get()).thenAnswer((_) async => mockSnapshot);

    repository = CustomerRepositoryImpl(database: mockDatabase);
  });

  group('CustomerRepositoryImpl', () {
    test('getCustomers should build the correct paginated query', () async {
      // Arrange
      when(() => mockSnapshot.value).thenReturn(null);

      // Act
      await repository.getCustomers(shopId: 'shop1', ownerId: 'owner1');

      // Assert
      verify(() => mockRef.child('customers')).called(greaterThanOrEqualTo(1));
      verify(() => mockRef.orderByChild('owner_createdAt')).called(1);
      verify(() => mockQuery.startAt('owner1')).called(1);
      verify(() => mockQuery.endAt('owner1_\uf8ff')).called(1);
      verify(() => mockQuery.limitToLast(20)).called(1);
    });

    test('getCustomers should trigger legacy fallback if first page is empty', () async {
      // Arrange
      // First query (paginated) returns null
      when(() => mockSnapshot.value).thenReturn(null);
      
      // Setup legacy query mocks
      final mockLegacyQuery = MockQuery();
      final mockLegacySnapshot = MockDataSnapshot();
      
      // Use specific matcher to differentiate from default orderByChild
      when(() => mockRef.orderByChild('ownerId')).thenReturn(mockLegacyQuery);
      when(() => mockLegacyQuery.equalTo(any())).thenReturn(mockLegacyQuery);
      when(() => mockLegacyQuery.get()).thenAnswer((_) async => mockLegacySnapshot);
      when(() => mockLegacySnapshot.value).thenReturn({'c1': {'name': 'Legacy', 'shopId': 'shop1'}});

      // Act
      final result = await repository.getCustomers(shopId: 'shop1', ownerId: 'owner1');

      // Assert
      if (result.isLeft()) {
        result.fold((l) => print('REPOS_FAILURE: ${l.message}'), (r) => null);
      }
      expect(result.isRight(), true);
      final customers = result.getOrElse(() => []);
      expect(customers.length, 1);
      expect(customers.first.name, 'Legacy');
      
      // Verify legacy query was called
      verify(() => mockRef.orderByChild('ownerId')).called(1);
      verify(() => mockLegacyQuery.equalTo('owner1')).called(1);
    });
  });
}
