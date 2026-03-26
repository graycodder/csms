import 'package:dartz/dartz.dart';
import 'package:csms/core/error/failures.dart';
import 'package:csms/features/notifications/domain/entities/notification_entity.dart';

abstract class NotificationRepository {
  /// Stream a list of notifications natively for the specific owner and shop
  Stream<List<NotificationEntity>> streamNotifications(String ownerId, String shopId);

  /// Dispatch an internal alert onto the specific owner's notification node natively
  Future<Either<Failure, void>> pushNotification({
    required String ownerId,
    required String shopId,
    required String title,
    required String body,
    required String type,
    required String updatedById,
  });

  /// Mark specific notification as read by the owner locally
  Future<Either<Failure, void>> markAsRead(String ownerId, String notificationId);
}
