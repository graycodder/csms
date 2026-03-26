import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:csms/features/notifications/domain/entities/notification_entity.dart';
import 'package:csms/features/notifications/domain/repositories/notification_repository.dart';
import 'package:csms/core/utils/terminology_helper.dart';

// --- Events ---
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class StartListeningNotifications extends NotificationEvent {
  final String ownerId;
  final String shopId;
  final String shopCategory;
  const StartListeningNotifications(this.ownerId, this.shopId, this.shopCategory);
  @override
  List<Object?> get props => [ownerId, shopId, shopCategory];
}

class _NotificationsUpdatedInternal extends NotificationEvent {
  final List<NotificationEntity> notifications;
  const _NotificationsUpdatedInternal(this.notifications);
  @override
  List<Object?> get props => [notifications];
}

class _NotificationErrorInternal extends NotificationEvent {
  final Object error;
  const _NotificationErrorInternal(this.error);
  @override
  List<Object?> get props => [error];
}

class MarkNotificationAsRead extends NotificationEvent {
  final String ownerId;
  final String notificationId;
  const MarkNotificationAsRead(this.ownerId, this.notificationId);
  @override
  List<Object?> get props => [ownerId, notificationId];
}

class ResetNotification extends NotificationEvent {}

// --- States ---
abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationListening extends NotificationState {
  final List<NotificationEntity> notifications;
  final int unreadCount;
  const NotificationListening(this.notifications, this.unreadCount);
  @override
  List<Object?> get props => [notifications, unreadCount];
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);
  @override
  List<Object?> get props => [message];
}

// --- BLoC ---
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository repository;
  StreamSubscription? _subscription;

  // Track IDs we've already shown popups for to avoid duplicates on re-listen
  final Set<String> _shownIds = {};
  bool _isInitialLoad = true;
  String _shopCategory = '';

  final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'custom_sound_channel',
    'Specific Alerts',
    channelDescription: 'Used for important staff alerts',
    importance: Importance.max,
    priority: Priority.max,
    playSound: true,
    icon: '@mipmap/ic_launcher',
  );

  static const DarwinNotificationDetails _iosDetails = DarwinNotificationDetails(
    sound: 'notification_sound.caf',
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: _androidDetails,
    iOS: _iosDetails,
  );

  NotificationBloc({required this.repository}) : super(NotificationInitial()) {
    on<StartListeningNotifications>(_onStartListening);
    on<_NotificationsUpdatedInternal>(_onNotificationsUpdated);
    on<_NotificationErrorInternal>(_onErrorInternal);
    on<MarkNotificationAsRead>(_onMarkAsRead);
    on<ResetNotification>(_onReset);
  }

  void _onReset(ResetNotification event, Emitter<NotificationState> emit) {
    _subscription?.cancel();
    _subscription = null;
    _shownIds.clear();
    _isInitialLoad = true;
    emit(NotificationInitial());
  }

  void _onStartListening(
    StartListeningNotifications event,
    Emitter<NotificationState> emit,
  ) {
    _subscription?.cancel();
    _isInitialLoad = true;
    _shopCategory = event.shopCategory;
    _subscription = repository
        .streamNotifications(event.ownerId, event.shopId)
        .listen((notifications) {
      add(_NotificationsUpdatedInternal(notifications));
    }, onError: (error) {
      add(_NotificationErrorInternal(error));
    });
  }

  void _onErrorInternal(
    _NotificationErrorInternal event,
    Emitter<NotificationState> emit,
  ) {
    final errorString = event.error.toString();
    
    // Ignore permission errors if we just reset (e.g. logging out)
    if (state is NotificationInitial && errorString.contains('permission-denied')) {
      return; 
    }

    print("Notification stream error: $errorString");
    if (errorString.contains('permission-denied')) {
      emit(const NotificationError("Permission denied: Ask shop owner to allow staff notifications in Firebase Rules."));
    } else {
      emit(NotificationError(errorString));
    }
  }

  Future<void> _onNotificationsUpdated(
    _NotificationsUpdatedInternal event,
    Emitter<NotificationState> emit,
  ) async {
    final unreadCount = event.notifications.where((n) => !n.isRead).length;

    if (_isInitialLoad) {
      _isInitialLoad = false;
      // Just seed the shown IDs so we don't popup old notifications on start
      for (final notif in event.notifications) {
        _shownIds.add(notif.id);
      }
    } else {
      // Show a local popup for any NEW unread notification we haven't shown yet
      for (final notif in event.notifications) {
        if (!notif.isRead && !_shownIds.contains(notif.id)) {
          _shownIds.add(notif.id);
          // Small delay so it doesn't overlap excessively 
          await Future.delayed(const Duration(milliseconds: 300));
          final term = TerminologyHelper.getTerminology(_shopCategory);
          String displayTitle = notif.title
              .replaceAll('Subscription', term.subscriptionLabel)
              .replaceAll('subscription', term.subscriptionLabel.toLowerCase())
              .replaceAll('Customer', term.customerLabel)
              .replaceAll('customer', term.customerLabel.toLowerCase());
          String displayBody = notif.body
              .replaceAll('Subscription', term.subscriptionLabel)
              .replaceAll('subscription', term.subscriptionLabel.toLowerCase())
              .replaceAll('Customer', term.customerLabel)
              .replaceAll('customer', term.customerLabel.toLowerCase());

          await _localPlugin.show(
            id: notif.id.hashCode,
            title: displayTitle,
            body: displayBody,
            notificationDetails: _notificationDetails,
            payload: notif.id,
          );
        }
      }
    }

    emit(NotificationListening(event.notifications, unreadCount));
  }

  Future<void> _onMarkAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    await repository.markAsRead(event.ownerId, event.notificationId);
    // state updates automatically via stream
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
