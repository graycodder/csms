import 'package:csms/features/customer/data/repositories/customer_repository_impl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseDatabase extends Mock implements FirebaseDatabase {}
class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockQuery extends Mock implements Query {}
class MockDataSnapshot extends Mock implements DataSnapshot {}
class MockDatabaseEvent extends Mock implements DatabaseEvent {}

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
      final mockEvent = MockDatabaseEvent();
      when(() => mockQuery.onValue).thenAnswer((_) => Stream.value(mockEvent));
      when(() => mockEvent.snapshot).thenReturn(mockSnapshot);
      when(() => mockSnapshot.value).thenReturn(null);

      // Act
      final resultStream = repository.getCustomers(shopId: 'shop1', ownerId: 'owner1', limit: 20);
      await resultStream.first;

      // Assert
      verify(() => mockRef.child('customers')).called(greaterThanOrEqualTo(1));
      verify(() => mockRef.orderByChild('owner_createdAt')).called(1);
      verify(() => mockQuery.startAt('owner1')).called(1);
      verify(() => mockQuery.endAt('owner1_\uf8ff')).called(1);
      verify(() => mockQuery.limitToLast(20)).called(1);
    });

    test('getCustomers should return list of customers successfully', () async {
      // Arrange
      final mockEvent = MockDatabaseEvent();
      when(() => mockQuery.onValue).thenAnswer((_) => Stream.value(mockEvent));
      when(() => mockEvent.snapshot).thenReturn(mockSnapshot);
      
      when(() => mockSnapshot.value).thenReturn({
        'c1': {
          'name': 'Customer 1',
          'shopId': 'shop1',
          'owner_createdAt': '2023-01-02'
        },
        'c2': {
          'name': 'Customer 2',
          'shopId': 'shop2', // Different shopId, should be filtered out
          'owner_createdAt': '2023-01-01'
        }
      });

      // Act
      final resultStream = repository.getCustomers(shopId: 'shop1', ownerId: 'owner1');
      final result = await resultStream.first;

      // Assert
      expect(result.isRight(), true);
      final customers = result.getOrElse(() => []);
      expect(customers.length, 1);
      expect(customers.first.name, 'Customer 1');
    });
  });
}
