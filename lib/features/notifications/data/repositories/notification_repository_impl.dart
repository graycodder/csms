import 'package:firebase_database/firebase_database.dart';
import 'package:dartz/dartz.dart';
import 'package:csms/core/error/failures.dart';
import 'package:csms/features/notifications/domain/entities/notification_entity.dart';
import 'package:csms/features/notifications/domain/repositories/notification_repository.dart';
import 'package:csms/features/notifications/data/models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final FirebaseDatabase _database;

  NotificationRepositoryImpl({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;

  @override
  Stream<List<NotificationEntity>> streamNotifications(String ownerId, String shopId) {
    return _database
        .ref()
        .child('notifications')
        .child(ownerId)
        .orderByChild('createdAt')
        .onValue
        .map((event) {
          final notifications = <NotificationEntity>[];
          if (event.snapshot.value != null) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            data.forEach((key, value) {
              final notifData = Map<String, dynamic>.from(value as Map);
              // Filter by shopId locally
              if (notifData['shopId'] == shopId) {
                notifications.add(
                  NotificationModel.fromJson(notifData, key.toString()),
                );
              }
            });
            // Sort by descending (newest first)
            notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }
          return notifications;
        });
  }

  @override
  Future<Either<Failure, void>> pushNotification({
    required String ownerId,
    required String shopId,
    required String title,
    required String body,
    required String type,
    required String updatedById,
  }) async {
    try {
      final ref = _database.ref().child('notifications').child(ownerId).push();
      final model = NotificationModel(
        id: ref.key ?? '',
        shopId: shopId,
        title: title,
        body: body,
        type: type,
        isRead: false,
        createdAt: DateTime.now(),
      );

      final data = model.toJson();
      data['ownerId'] = ownerId;
      data['updatedById'] = updatedById;

      await ref.set(data);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String ownerId, String notificationId) async {
    try {
      await _database
          .ref()
          .child('notifications')
          .child(ownerId)
          .child(notificationId)
          .update({'isRead': true});
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
